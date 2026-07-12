#!/bin/bash
# SessionStart hook:
#   1. Wipe the WebFetch escape-hatch state (startup + compact) so per-URL
#      attempt counters never carry across sessions.
#   2. Inject PullMD routing guidance when running under Codex.
#   3. On startup, nudge when a configured PullMD server is not registered in
#      the active host.
# Matcher: startup, compact
#
# Exit codes:
#   0 - Always (SessionStart hooks must not block)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

HOOK_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PROMPT_FILE="${HOOK_DIR}/prompts/mcp-tool-directives.md"

input=$(cat)

{
    IFS= read -r session_id
    IFS= read -r cwd
    IFS= read -r start_source
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.cwd // ""),
    (.source // "")
')

# 1. Wipe escape-hatch state for this session.
if [[ -n "$session_id" && -n "$PULLMD_PLUGIN_DATA" ]]; then
    dir=$(session_dir "$session_id")
    if [[ -d "$dir" ]]; then
        rm -f "${dir}/webfetch-attempts.json" "${dir}"/.pullmd-tmp.*
    fi
fi

# 2. Codex cannot intercept its native web research tool, so inject the routing
# directive at startup and after compaction instead.
context=""
append_context() {
    local addition
    addition="$1"
    [[ -z "$addition" ]] && return 0
    if [[ -n "$context" ]]; then
        context+=$'\n\n'
    fi
    context+="$addition"
}

if is_codex_host && [[ -f "$PROMPT_FILE" ]]; then
    prompt=$(cat -- "$PROMPT_FILE")
    append_context "$prompt"
fi

# 3. Registration nudge — startup only, so it does not re-fire on compaction.
if [[ "$start_source" == "startup" ]]; then
    project_dir="${CLAUDE_PROJECT_DIR:-$cwd}"
    load_config "$project_dir"

    if [[ "$PULLMD_ENABLED" == "true" && -n "$PULLMD_INSTANCE" ]]; then
        server=$(mcp_server_from_tool "$PULLMD_MCP_TOOL")
        if [[ -n "$server" ]] && ! mcp_server_configured "$server" "$project_dir"; then
            if is_codex_host; then
                nudge="A PullMD instance is configured (${PULLMD_INSTANCE}) but no enabled MCP server named \"${server}\" appears in Codex, so the PullMD read_url tool is unavailable. Tell the user to run \`codex mcp add ${server} --url ${PULLMD_INSTANCE%/}/mcp\` and, for OAuth, \`codex mcp login ${server}\`, then start a new session. Until then, use native web research for content it can handle."
            else
                nudge="A PullMD instance is configured (${PULLMD_INSTANCE}) but no MCP server named \"${server}\" is registered in Claude Code, so the PullMD read_url tool is unavailable. Tell the user to run \`claude mcp add --transport http ${server} ${PULLMD_INSTANCE%/}/mcp --scope user\`, then \`/mcp\` to authenticate if the instance requires it. Until then, use WebFetch for content it can handle."
            fi
            append_context "$nudge"
        fi
    fi
fi

if [[ -n "$context" ]]; then
    jq -n --arg c "$context" '{
        hookSpecificOutput: {
            hookEventName: "SessionStart",
            additionalContext: $c
        }
    }'
fi

exit 0
