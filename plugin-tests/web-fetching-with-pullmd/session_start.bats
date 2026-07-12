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
