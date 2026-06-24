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
