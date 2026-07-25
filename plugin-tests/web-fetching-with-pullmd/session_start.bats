#!/usr/bin/env bats
# bats file_tags=pullmd,session-start

load 'test_helper/common_setup'

# bats test_tags=wipe
@test "startup wipes the escape-hatch state for the current session" {
    write_attempts "sess-1" '{"urls":{"https://a.test/x":1}}'

    run_session_start "sess-1" "startup"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-1/webfetch-attempts.json" ]]
}

# bats test_tags=wipe
@test "compact wipes the escape-hatch state for the current session" {
    write_attempts "sess-2" '{"urls":{"https://b.test/y":2}}'

    run_session_start "sess-2" "compact"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-2/webfetch-attempts.json" ]]
}

# bats test_tags=wipe
@test "startup does not wipe other sessions" {
    write_attempts "sess-A" '{"urls":{}}'
    write_attempts "sess-B" '{"urls":{}}'

    run_session_start "sess-A" "startup"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-A/webfetch-attempts.json" ]]
    [[ -f "${CLAUDE_PLUGIN_DATA}/sess-B/webfetch-attempts.json" ]]
}

# bats test_tags=wipe
@test "startup succeeds when no state file exists" {
    run_session_start "sess-new" "startup"
    assert_success
}

# bats test_tags=wipe,codex
@test "startup wipes state through the Codex PLUGIN_DATA directory" {
    unset CLAUDE_PLUGIN_DATA
    export PLUGIN_DATA="${TEST_TEMP_DIR}/codex-plugin-data"
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    mkdir -p "${PLUGIN_DATA}/sess-codex"
    printf '%s' '{"urls":{"https://a.test/x":1}}' > "${PLUGIN_DATA}/sess-codex/webfetch-attempts.json"

    run_session_start "sess-codex" "startup"
    assert_success

    [[ ! -f "${PLUGIN_DATA}/sess-codex/webfetch-attempts.json" ]]
}

# =============================================================================
# Codex routing guidance
# =============================================================================

# bats test_tags=codex,directive
@test "Codex startup injects PullMD routing guidance" {
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"

    run_session_start "sess-c1" "startup"
    assert_success
    assert_output --partial 'prefer the `read_url` tool'
    assert_output --partial 'native web research'
}

# bats test_tags=codex,directive
@test "Codex compact reinjects PullMD routing guidance" {
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"

    run_session_start "sess-c2" "compact"
    assert_success
    assert_output --partial 'prefer the `read_url` tool'
}

# bats test_tags=codex,directive,block
@test "Codex startup injects the hardcoded block directive naming Reddit" {
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"

    run_session_start "sess-c5" "startup"
    assert_success
    assert_output --partial "Do not use the PullMD read_url tool for these hosts"
    assert_output --partial "reddit.com"
}

# bats test_tags=codex,directive,block
@test "a malformed host-rule table fails the hook instead of injecting an empty directive" {
    local fake_scripts
    fake_scripts="${TEST_TEMP_DIR}/hooks/scripts"
    mkdir -p "$fake_scripts"
    cp "${SCRIPTS_DIR}/session-start.sh" "${SCRIPTS_DIR}/lib.sh" "$fake_scripts/"
    # Appended after lib.sh's own definition: the file is sourced whole before
    # any function runs, so the last assignment wins. This fails only if the
    # rendering failure propagates — reverting to a status-discarding
    # invocation makes the hook exit 0 and this test fail.
    printf "\nPULLMD_HOST_RULES='not valid json'\n" >> "${fake_scripts}/lib.sh"

    export PLUGIN_ROOT="${TEST_TEMP_DIR}/hooks"

    local stdin
    stdin=$(jq -n -c --arg cwd "$TEST_PROJECT_DIR" \
        '{session_id: "sess-bad", cwd: $cwd, source: "startup"}')

    run bash -c 'printf "%s" "$1" | bash "$2"' _ "$stdin" "${fake_scripts}/session-start.sh"
    assert_failure
}

# bats test_tags=directive,block
@test "Claude Code startup does not inject the hardcoded block directive" {
    write_user_config '{"instance":"https://pullmd.example.com"}'
    write_user_claude_json '{"mcpServers":{}}'

    run_session_start "sess-n7" "startup"
    assert_success
    refute_output --partial "Do not use the PullMD read_url tool for these hosts"
}

# bats test_tags=codex,nudge
@test "Codex startup uses Codex setup commands when the server is absent" {
    install_fake_codex
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    export FAKE_CODEX_MCP_LIST='[]'
    write_user_config '{"instance":"https://pullmd.example.com"}'

    run_session_start "sess-c3" "startup"
    assert_success
    assert_output --partial 'codex mcp add pullmd --url https://pullmd.example.com/mcp'
    refute_output --partial 'claude mcp add'
}

# bats test_tags=codex,nudge
@test "Codex startup omits the setup nudge when the server is enabled" {
    install_fake_codex
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    export FAKE_CODEX_MCP_LIST='[{"name":"pullmd","enabled":true}]'
    write_user_config '{"instance":"https://pullmd.example.com"}'

    run_session_start "sess-c4" "startup"
    assert_success
    assert_output --partial 'prefer the `read_url` tool'
    refute_output --partial 'codex mcp add'
}

# =============================================================================
# MCP registration nudge (startup only)
# =============================================================================

# bats test_tags=nudge
@test "startup nudges when an instance is set but the server is unregistered" {
    write_user_config '{"instance":"https://pullmd.example.com"}'
    write_user_claude_json '{"mcpServers":{}}'

    run_session_start "sess-n1" "startup"
    assert_success
    assert_output --partial 'additionalContext'
    assert_output --partial 'claude mcp add'
    assert_output --partial 'pullmd.example.com/mcp'
}

# bats test_tags=nudge
@test "startup is silent when the server is registered" {
    write_user_config '{"instance":"https://pullmd.example.com"}'
    write_user_claude_json '{"mcpServers":{"pullmd":{"type":"http","url":"https://pullmd.example.com/mcp"}}}'

    run_session_start "sess-n2" "startup"
    assert_success
    assert_output ""
}

# bats test_tags=nudge
@test "compact never nudges, even when the server is unregistered" {
    write_user_config '{"instance":"https://pullmd.example.com"}'
    write_user_claude_json '{"mcpServers":{}}'

    run_session_start "sess-n3" "compact"
    assert_success
    assert_output ""
}

# bats test_tags=nudge
@test "startup is silent when no instance is configured" {
    write_user_claude_json '{"mcpServers":{}}'

    run_session_start "sess-n4" "startup"
    assert_success
    assert_output ""
}

# bats test_tags=nudge
@test "startup is silent when the hook is disabled" {
    write_user_config '{"instance":"https://pullmd.example.com","enabled":false}'
    write_user_claude_json '{"mcpServers":{}}'

    run_session_start "sess-n5" "startup"
    assert_success
    assert_output ""
}

# bats test_tags=nudge
@test "nudge uses the server name derived from a custom mcp_tool" {
    write_user_config '{"instance":"https://pullmd.example.com","mcp_tool":"mcp__pmdprod__read_url"}'
    # "pullmd" is registered, but the configured tool points at server "pmdprod"
    write_user_claude_json '{"mcpServers":{"pullmd":{}}}'

    run_session_start "sess-n6" "startup"
    assert_success
    assert_output --partial 'pmdprod'
}
