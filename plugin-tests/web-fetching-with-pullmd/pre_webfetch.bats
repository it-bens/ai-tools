#!/usr/bin/env bats
# bats file_tags=pullmd,pre-webfetch

load 'test_helper/common_setup'

CONFIGURED='{"instance":"https://pullmd.example.com"}'

# =============================================================================
# NO-OP — hook inactive
# =============================================================================

# bats test_tags=allow,noop
@test "allows any WebFetch when no instance is configured" {
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_success
}

# bats test_tags=allow,noop
@test "allows WebFetch when enabled is false" {
    write_project_config '{"instance":"https://pullmd.example.com","enabled":false}'
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_success
}

# =============================================================================
# ALLOW — host exceptions
# =============================================================================

# bats test_tags=allow
@test "allows WebFetch of the configured instance host" {
    write_project_config "$CONFIGURED"
    run_pre_webfetch "s1" "https://pullmd.example.com/s/abc123"
    assert_success
}

# bats test_tags=allow
@test "allows WebFetch of GitHub" {
    write_project_config "$CONFIGURED"
    run_pre_webfetch "s1" "https://github.com/owner/repo"
    assert_success
    run_pre_webfetch "s1" "https://raw.githubusercontent.com/o/r/main/f"
    assert_success
}

# bats test_tags=allow
@test "allows WebFetch of a configured allow_hosts entry and its subdomains" {
    write_project_config '{"instance":"https://pullmd.example.com","allow_hosts":["internal.test"]}'
    run_pre_webfetch "s1" "https://api.internal.test/v1"
    assert_success
}

# =============================================================================
# DENY — normal pages redirected to the MCP tool
# =============================================================================

# bats test_tags=deny
@test "blocks WebFetch of a normal page on the first attempt" {
    write_project_config "$CONFIGURED"
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2
}

# bats test_tags=deny,message
@test "deny message names the MCP tool and the URL" {
    write_project_config "$CONFIGURED"
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2
    assert_output --partial "mcp__pullmd__read_url"
    assert_output --partial "https://news.example.org/article"
}

# bats test_tags=deny,message
@test "deny message uses a configured custom mcp_tool name" {
    write_project_config '{"instance":"https://pullmd.example.com","mcp_tool":"mcp__plugin_x_pullmd__read_url"}'
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2
    assert_output --partial "mcp__plugin_x_pullmd__read_url"
}

# =============================================================================
# ESCAPE HATCH
# =============================================================================

# bats test_tags=escape
@test "allows the same URL on the second attempt (escape_after default 2)" {
    write_project_config "$CONFIGURED"

    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2

    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_success
}

# bats test_tags=escape
@test "records the attempt count in the state file" {
    write_project_config "$CONFIGURED"
    run_pre_webfetch "s1" "https://news.example.org/article"

    local count
    count=$(read_attempts "s1" | jq -r '.urls["https://news.example.org/article"]')
    [[ "$count" == "1" ]]
}

# bats test_tags=escape
@test "respects a higher escape_after before allowing" {
    write_project_config '{"instance":"https://pullmd.example.com","escape_after":3}'

    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_failure 2
    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_success
}

# bats test_tags=escape
@test "tracks attempts per URL independently" {
    write_project_config "$CONFIGURED"

    run_pre_webfetch "s1" "https://a.example.org/x"
    assert_failure 2
    # A different URL is still on its first attempt → still blocked
    run_pre_webfetch "s1" "https://b.example.org/y"
    assert_failure 2
}

# bats test_tags=escape
@test "allows immediately when seeded state already reached the threshold" {
    write_project_config "$CONFIGURED"
    write_attempts "s1" '{"urls":{"https://news.example.org/article":1}}'

    run_pre_webfetch "s1" "https://news.example.org/article"
    assert_success
}
