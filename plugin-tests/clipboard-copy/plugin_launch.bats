#!/usr/bin/env bats
# bats file_tags=clipboard-copy,plugin-launch
bats_require_minimum_version 1.11.0

load 'test_helper/common_setup'

MANIFEST="${PLUGIN_DIR}/.codex-plugin/plugin.json"
HOOKS_CONFIG="${PLUGIN_DIR}/hooks/hooks.json"
INITIALIZE_REQUEST='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"plugin-launch-test","version":"1"}}}'

@test "Codex MCP launcher uses plugin-root cwd and a direct entrypoint" {
    run jq -e '
        .mcpServers["clipboard-copy"] |
        .command == "bash" and
        .args == ["./mcp-server-clipboard/server.sh"] and
        .cwd == "." and
        .env == {}
    ' "${MANIFEST}"
    assert_success

    local manifest
    manifest=$(<"${MANIFEST}")
    [[ "${manifest}" != *"CODEX_PLUGIN_ROOT"* ]]
    [[ "${manifest}" != *"CLAUDE_PLUGIN_ROOT"* ]]
    [[ "${manifest}" != *"./plugins/clipboard-copy"* ]]
}

@test "Codex MCP launcher initializes from its declared cwd" {
    run bash -c '
        cd "$1"
        printf "%s\n" "$2" | bash ./mcp-server-clipboard/server.sh
    ' _ "${PLUGIN_DIR}" "${INITIALIZE_REQUEST}"
    assert_success
    jq -e '
        .id == 1 and
        .result.serverInfo.name == "clipboard-copy" and
        .result.protocolVersion == "2024-11-05"
    ' <<<"${output}" >/dev/null
}

@test "hook launchers use only host-provided plugin roots" {
    local commands
    commands=$(jq -r '[.hooks[][] | .hooks[] | .command] | join("\n")' "${HOOKS_CONFIG}")

    [[ "${commands}" == *"PLUGIN_ROOT"* ]]
    [[ "${commands}" == *"CLAUDE_PLUGIN_ROOT"* ]]
    [[ "${commands}" != *"CODEX_PLUGIN_ROOT"* ]]
    [[ "${commands}" != *"./plugins/clipboard-copy"* ]]
    [[ "${commands}" != *"./hooks/scripts"* ]]
}

@test "SessionStart hook resolves PLUGIN_ROOT outside the repository" {
    local hook_command
    hook_command=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "${HOOKS_CONFIG}")

    run bash -c '
        cd "$1"
        printf "%s\n" "{}" |
            env -u CODEX_PLUGIN_ROOT -u CLAUDE_PLUGIN_ROOT PLUGIN_ROOT="$2" bash -c "$3"
    ' _ "${BATS_TEST_TMPDIR}" "${PLUGIN_DIR}" "${hook_command}"
    assert_success
    jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' <<<"${output}" >/dev/null
}

@test "SessionStart hook remains compatible with CLAUDE_PLUGIN_ROOT" {
    local hook_command
    hook_command=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "${HOOKS_CONFIG}")

    run bash -c '
        cd "$1"
        printf "%s\n" "{}" |
            env -u CODEX_PLUGIN_ROOT -u PLUGIN_ROOT CLAUDE_PLUGIN_ROOT="$2" bash -c "$3"
    ' _ "${BATS_TEST_TMPDIR}" "${PLUGIN_DIR}" "${hook_command}"
    assert_success
    jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' <<<"${output}" >/dev/null
}

@test "hook launchers fail when the host omits the plugin root" {
    local hook_command
    while IFS= read -r hook_command; do
        run bash -c '
            printf "%s\n" "{}" |
                env -u CODEX_PLUGIN_ROOT -u PLUGIN_ROOT -u CLAUDE_PLUGIN_ROOT bash -c "$1"
        ' _ "${hook_command}"
        assert_failure
        assert_output --partial "clipboard-copy: plugin root is unavailable"
    done < <(jq -r '.hooks[][] | .hooks[] | .command' "${HOOKS_CONFIG}")
}
