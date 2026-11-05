#!/usr/bin/env bash
# Manual verification harness for the decision-handback-guard plugin.
#
# Not a BATS suite and not run in CI: every check starts live `claude -p` runs
# that load the plugin with --plugin-dir and spend tokens on the developer's
# credentials.
#
# Usage:
#   DHG_WORK_DIR=<absolute dir> plugin-tests/decision-handback-guard/run-checks.sh [v1|v2|v3|v4|v5|v6|v7]
#
# Without an argument all checks run in order. Each check prints one summary
# line, `V<n> PASS|FAIL <evidence>`. The exit status is non-zero when any
# implemented check fails. A failed `claude` run or missing evidence aborts the
# harness with the offending value.
#
# DHG_WORK_DIR receives one directory per harness run, holding for every
# `claude` run its throwaway project directory, debug log, JSON result,
# permission-host log and MCP config. Requires bash 4 or later.
#
# Main-agent model: sonnet (DHG_MAIN_MODEL overrides it). The hooks use Claude
# Code's default hook model; the plugin pins none.
#
# Isolation from the developer's own setup:
#   --setting-sources ""            loads no user, project or local settings, so
#                                   no user hooks, no enabled plugins and no
#                                   permission rules reach the run; plugins
#                                   passed with --plugin-dir still load
#   --strict-mcp-config             only the MCP servers in --mcp-config load
#   CLAUDE_CODE_DISABLE_CLAUDE_MDS=1    no CLAUDE.md or rules files load
#   CLAUDE_CODE_DISABLE_AUTO_MEMORY=1   no auto memory loads
#   each run's cwd is a fresh `git init` directory under DHG_WORK_DIR, so no
#   repository instructions, settings or git status of this repository reach
#   the run.
# Every run asserts from its debug log that only the expected plugin hooks
# were registered. The harness never passes --bare: bare mode skips the hooks
# of plugins loaded with --plugin-dir.
#
# Checks that need AskUserQuestion run with a permission host: print mode
# offers AskUserQuestion only when a permission host is present. The host is
# permission_host.py, an MCP stdio server passed with --permission-prompt-tool.
# It allows every request, answers each AskUserQuestion question with its first
# option, and logs every request it receives.
#
# How a Stop prompt-hook continuation appears in the transcript: an entry with
# "type":"user" whose message.content is a string starting with
# "Stop hook feedback:", followed by the hook prompt in brackets and the
# block reason. A Step 2 denial appears as the tool_result of the
# AskUserQuestion call, with is_error true and text starting with
# "PreToolUse:AskUserQuestion hook error:" that carries the deny reason.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PLUGIN_DIR="${REPO_ROOT}/plugins/decision-handback-guard"
FIXTURES="${SCRIPT_DIR}/fixtures/gate"
TIMEOUT_PLUGIN_DIR="${FIXTURES}/timeout-plugin"
HOST_SCRIPT="${SCRIPT_DIR}/permission_host.py"
HOST_TOOL="mcp__permission_host__approve"
MAIN_MODEL="${DHG_MAIN_MODEL:-sonnet}"
PROJECTS_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/projects"

# First line of each plugin hook prompt, used to recognise the hook in debug logs.
STOP_PROMPT_HEAD="Allow this stop unless Claude's final message at this turn end hands the user a decision"
PRETOOL_PROMPT_HEAD="Claude is about to ask the user questions through the AskUserQuestion tool."
DENY_TAG="decision-handback-guard:"

die() {
    echo "run-checks: $*" >&2
    exit 2
}

require_tools() {
    ((BASH_VERSINFO[0] >= 4)) || die "bash 4 or later required, running ${BASH_VERSION}"
    local tool
    for tool in claude jq git python3; do
        command -v "${tool}" >/dev/null || die "required tool not found: ${tool}"
    done
}

require_work_dir() {
    [[ -n "${DHG_WORK_DIR:-}" ]] || die "DHG_WORK_DIR is not set"
    [[ "${DHG_WORK_DIR}" = /* ]] || die "DHG_WORK_DIR must be absolute: ${DHG_WORK_DIR}"
    mkdir -p "${DHG_WORK_DIR}"
    RUN_ROOT="${DHG_WORK_DIR}/run-$(date +%Y%m%d-%H%M%S)-$$"
    mkdir "${RUN_ROOT}"
}

# run_claude <name> <plugin dir> <expected hook count> <host: yes|no> <prompt file>
# Sets RUN_DIR, TRANSCRIPT, DEBUG_LOG, HOST_LOG (empty without host).
run_claude() {
    local name="$1" plugin_dir="$2" expected_hooks="$3" host="$4" prompt_file="$5"
    [[ -f "${prompt_file}" ]] || die "fixture prompt missing: ${prompt_file}"
    RUN_DIR="${RUN_ROOT}/${name}"
    mkdir -p "${RUN_DIR}/project"
    git -C "${RUN_DIR}/project" init -q
    DEBUG_LOG="${RUN_DIR}/debug.log"
    HOST_LOG=""
    local session_id
    session_id="$(python3 -c 'import uuid; print(uuid.uuid4())')"

    local -a args=(
        -p
        --model "${MAIN_MODEL}"
        --setting-sources ""
        --strict-mcp-config
        --plugin-dir "${plugin_dir}"
        --session-id "${session_id}"
        --debug-file "${DEBUG_LOG}"
        --output-format json
    )
    if [[ "${host}" == yes ]]; then
        HOST_LOG="${RUN_DIR}/permission-host.log"
        jq -n --arg script "${HOST_SCRIPT}" --arg log "${HOST_LOG}" \
            '{mcpServers: {permission_host: {command: "python3", args: [$script, $log]}}}' \
            >"${RUN_DIR}/mcp.json"
        args+=(--mcp-config "${RUN_DIR}/mcp.json" --permission-prompt-tool "${HOST_TOOL}")
    elif [[ "${host}" != no ]]; then
        die "host must be yes or no: ${host}"
    fi

    local status=0
    (
        cd "${RUN_DIR}/project"
        CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
            claude "${args[@]}" "$(cat "${prompt_file}")" \
            </dev/null >"${RUN_DIR}/result.json" 2>"${RUN_DIR}/stderr.log"
    ) || status=$?
    [[ "${status}" -eq 0 ]] || die "claude run ${name} exited ${status}; see ${RUN_DIR}/stderr.log"
    [[ "$(jq -r '.is_error' "${RUN_DIR}/result.json")" == false ]] ||
        die "claude run ${name} reported an error: $(jq -c . "${RUN_DIR}/result.json")"

    grep -q "Registered ${expected_hooks} hooks from" "${DEBUG_LOG}" ||
        die "run ${name}: expected ${expected_hooks} registered plugin hooks, debug log says: $(grep -o 'Registered [0-9]* hooks from [0-9]* plugins' "${DEBUG_LOG}" || echo none)"

    local -a found
    mapfile -t found < <(find "${PROJECTS_DIR}" -name "${session_id}.jsonl" -type f)
    [[ "${#found[@]}" -eq 1 ]] || die "run ${name}: expected one transcript for session ${session_id}, found ${#found[@]}"
    TRANSCRIPT="${found[0]}"

    if [[ "${host}" == yes ]]; then
        [[ -f "${HOST_LOG}" ]] || die "run ${name}: permission host never started (no ${HOST_LOG})"
    fi
}

# Number of Stop-hook continuations in the transcript.
count_continuations() {
    jq -s '[.[] | select(.type == "user" and (.message.content | type) == "string"
        and (.message.content | startswith("Stop hook feedback:")))] | length' "${TRANSCRIPT}"
}

# Number of prompts the user typed (turns) in the transcript.
count_user_turns() {
    jq -s '[.[] | select(.type == "user" and (.message.content | type) == "string"
        and (.message.content | startswith("Stop hook feedback:") | not))] | length' "${TRANSCRIPT}"
}

# One JSON line per AskUserQuestion call: {line, id, is_error, text} of its tool result.
ask_results() {
    jq -c -s '
        [ to_entries[] | .key as $i | .value
          | select(.type == "user") | .message.content
          | select(type == "array") | .[]
          | select(.type == "tool_result")
          | {line: ($i + 1), id: .tool_use_id, is_error: (.is_error // false),
             text: (if (.content | type) == "string" then .content
                    else ([.content[]? | .text? // empty] | join("\n")) end)} ] as $results
        | [ .[] | select(.type == "assistant") | .message.content[]?
            | select(.type == "tool_use" and .name == "AskUserQuestion") | .id ] as $ids
        | $ids[] as $id
        | ($results | map(select(.id == $id)) | first) // {line: null, id: $id, is_error: null, text: null}
    ' "${TRANSCRIPT}"
}

host_ask_count() {
    jq -s '[.[] | select(.request.tool_name == "AskUserQuestion")] | length' "${HOST_LOG}"
}

FAILED=0
report() {
    local check="$1" verdict="$2" evidence="$3"
    echo "${check} ${verdict} ${evidence}"
    [[ "${verdict}" == PASS ]] || FAILED=1
}

check_v1() {
    run_claude v1 "${PLUGIN_DIR}" 2 yes "${FIXTURES}/v1-prompt.txt"
    local agent_line prompt_line
    agent_line="$(grep -n -F "Processing agent hook with prompt: ${PRETOOL_PROMPT_HEAD}" "${DEBUG_LOG}" | head -n 1 | cut -d: -f1 || true)"
    prompt_line="$(grep -n -F "Processing prompt hook with prompt:" "${DEBUG_LOG}" | grep -F "${STOP_PROMPT_HEAD}" | head -n 1 | cut -d: -f1 || true)"
    local agent_done prompt_done
    agent_done="$(grep -c -E 'Hooks: (Got structured output|Agent hook condition)' "${DEBUG_LOG}" || true)"
    prompt_done="$(grep -c -E 'Hooks: Prompt hook condition was (met|not met)' "${DEBUG_LOG}" || true)"
    if [[ -n "${agent_line}" && -n "${prompt_line}" && "${agent_done}" -ge 1 && "${prompt_done}" -ge 1 ]] &&
        grep -q -F "Read hooks.json for plugin decision-handback-guard" "${DEBUG_LOG}"; then
        report V1 PASS "agent hook on PreToolUse started at ${DEBUG_LOG}:${agent_line} (${agent_done} result line(s)); prompt hook on Stop started at line ${prompt_line} (${prompt_done} verdict line(s))"
    else
        report V1 FAIL "agent hook start line '${agent_line}', results ${agent_done}; prompt hook start line '${prompt_line}', verdicts ${prompt_done}; debug log ${DEBUG_LOG}"
    fi
}

check_v2() {
    run_claude v2 "${PLUGIN_DIR}" 2 yes "${FIXTURES}/v2-prompt.txt"
    local first host_asks
    first="$(ask_results | head -n 1)"
    host_asks="$(host_ask_count)"
    [[ -n "${first}" ]] || { report V2 FAIL "no AskUserQuestion call in ${TRANSCRIPT}"; return; }
    if [[ "$(jq -r '.is_error' <<<"${first}")" == true ]] &&
        jq -e --arg tag "${DENY_TAG}" '.text | startswith("PreToolUse:AskUserQuestion hook error:") and contains($tag)' <<<"${first}" >/dev/null &&
        [[ "${host_asks}" -eq 0 ]]; then
        report V2 PASS "first AskUserQuestion denied with reason at ${TRANSCRIPT}:$(jq -r '.line' <<<"${first}"); permission host received ${host_asks} AskUserQuestion requests"
    else
        report V2 FAIL "first AskUserQuestion result $(jq -c '{line, is_error, text: (.text // "" | .[0:200])}' <<<"${first}"); permission host AskUserQuestion requests: ${host_asks}; transcript ${TRANSCRIPT}"
    fi
}

check_v3() {
    local host continuations turns evidence="" verdict=PASS
    for host in no yes; do
        run_claude "v3-host-${host}" "${PLUGIN_DIR}" 2 "${host}" "${FIXTURES}/v3-prompt.txt"
        continuations="$(count_continuations)"
        turns="$(count_user_turns)"
        [[ "${turns}" -eq 1 ]] || die "run v3-host-${host}: expected one user turn, found ${turns} in ${TRANSCRIPT}"
        # 0 means the fixture never triggered Step 1, so the run proves nothing.
        [[ "${continuations}" -eq 1 ]] || verdict=FAIL
        evidence+="host=${host}: ${continuations} continuation(s) in 1 turn"
        if [[ "${host}" == yes ]]; then
            evidence+=", permission host received $(host_ask_count) AskUserQuestion request(s)"
        fi
        evidence+=", transcript ${TRANSCRIPT}; "
    done
    report V3 "${verdict}" "${evidence%; }"
}

check_v4() {
    echo "V4 NOT-IMPLEMENTED Step 1 classification check is not implemented yet"
}

check_v5() {
    echo "V5 NOT-IMPLEMENTED Step 2 judgment check is not implemented yet"
}

check_v6() {
    run_claude v6 "${PLUGIN_DIR}" 2 yes "${FIXTURES}/v6-prompt.txt"
    local results_json
    results_json="$(ask_results)"
    local -a results=()
    [[ -z "${results_json}" ]] || mapfile -t results <<<"${results_json}"
    local host_asks
    host_asks="$(host_ask_count)"
    if [[ "${#results[@]}" -lt 2 ]]; then
        report V6 FAIL "expected two AskUserQuestion calls, found ${#results[@]} in ${TRANSCRIPT}"
        return
    fi
    # The second hook verdict is the one for the re-ask; its reason shows what the hook relied on.
    local second_verdict
    second_verdict="$(grep -F "Hooks: Got structured output:" "${DEBUG_LOG}" | sed -n 2p | sed 's/.*Got structured output: //' || true)"
    if jq -e --arg tag "${DENY_TAG}" '.is_error == true and (.text | contains($tag))' <<<"${results[0]}" >/dev/null &&
        jq -e '.is_error == false' <<<"${results[1]}" >/dev/null &&
        jq -e '.ok == true' <<<"${second_verdict:-null}" >/dev/null &&
        [[ "${host_asks}" -ge 1 ]]; then
        report V6 PASS "denial at ${TRANSCRIPT}:$(jq -r '.line' <<<"${results[0]}"); re-ask allowed (result line $(jq -r '.line' <<<"${results[1]}")), permission host received ${host_asks} AskUserQuestion request(s); re-ask verdict: $(jq -r '.reason // "" | .[0:240]' <<<"${second_verdict}")"
    else
        report V6 FAIL "re-ask verdict '${second_verdict}'; first result $(jq -c '{line, is_error, text: (.text // "" | .[0:160])}' <<<"${results[0]}"); second result $(jq -c '{line, is_error, text: (.text // "" | .[0:160])}' <<<"${results[1]}"); permission host AskUserQuestion requests: ${host_asks}"
    fi
}

check_v7() {
    run_claude v7 "${TIMEOUT_PLUGIN_DIR}" 1 yes "${FIXTURES}/v7-prompt.txt"
    local first host_asks
    first="$(ask_results | head -n 1)"
    host_asks="$(host_ask_count)"
    [[ -n "${first}" ]] || { report V7 FAIL "no AskUserQuestion call in ${TRANSCRIPT}"; return; }
    # A timed-out agent hook logs "did not return structured output"; a finished one logs
    # "Got structured output". Only the first proves the timeout path.
    local started timed_out finished
    started="$(grep -c -F "Processing agent hook with prompt:" "${DEBUG_LOG}" || true)"
    timed_out="$(grep -n -F "Agent hook did not return structured output" "${DEBUG_LOG}" | head -n 1 | cut -d: -f1 || true)"
    finished="$(grep -c -F "Got structured output" "${DEBUG_LOG}" || true)"
    # The hook phase must have lasted the full 3 s timeout, so an early stop does not count.
    local hook_ms
    hook_ms="$(grep -o -E 'Slow PreToolUse hooks: [0-9]+ms for AskUserQuestion' "${DEBUG_LOG}" | head -n 1 | grep -o -E '[0-9]+' || true)"
    if [[ "${started}" -ge 1 && -n "${timed_out}" && "${finished}" -eq 0 && "${hook_ms:-0}" -ge 3000 && "${host_asks}" -ge 1 &&
        "$(jq -r '.is_error' <<<"${first}")" == false ]]; then
        report V7 PASS "agent hook (timeout 3 s) returned no verdict after ${hook_ms} ms at ${DEBUG_LOG}:${timed_out}; the call went through: permission host received ${host_asks} AskUserQuestion request(s), tool result at ${TRANSCRIPT}:$(jq -r '.line' <<<"${first}") is not an error"
    else
        report V7 FAIL "agent hook starts ${started}; no-verdict line '${timed_out}'; hook phase '${hook_ms}' ms; finished verdicts ${finished}; permission host AskUserQuestion requests ${host_asks}; first result $(jq -c '{line, is_error, text: (.text // "" | .[0:200])}' <<<"${first}")"
    fi
}

main() {
    require_tools
    require_work_dir
    local -a checks=(v1 v2 v3 v4 v5 v6 v7)
    if [[ "$#" -gt 1 ]]; then
        die "usage: run-checks.sh [v1|v2|v3|v4|v5|v6|v7]"
    elif [[ "$#" -eq 1 ]]; then
        [[ " ${checks[*]} " == *" $1 "* ]] || die "unknown check: $1"
        checks=("$1")
    fi
    local check
    for check in "${checks[@]}"; do
        "check_${check}"
    done
    echo "run directory: ${RUN_ROOT}"
    return "${FAILED}"
}

main "$@"
