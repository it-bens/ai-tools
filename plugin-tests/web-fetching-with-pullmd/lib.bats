#!/usr/bin/env bats
# bats file_tags=pullmd,lib

load 'test_helper/common_setup'

# Source lib.sh directly for unit testing
source "${SCRIPTS_DIR}/lib.sh"

# =============================================================================
# extract_host
# =============================================================================

# bats test_tags=host
@test "extract_host pulls the host from a full URL" {
    [[ "$(extract_host "https://example.com/path?a=b#frag")" == "example.com" ]]
}

# bats test_tags=host
@test "extract_host strips port, userinfo, and lowercases" {
    [[ "$(extract_host "https://User:pw@Example.COM:8443/x")" == "example.com" ]]
}

# bats test_tags=host
@test "extract_host handles a query with no path" {
    [[ "$(extract_host "https://example.com?x=y")" == "example.com" ]]
}

# bats test_tags=host
@test "extract_host tolerates a missing scheme" {
    [[ "$(extract_host "example.com/path")" == "example.com" ]]
}

# =============================================================================
# host_allowed
# =============================================================================

# bats test_tags=allow-host
@test "host_allowed accepts the builtin GitHub hosts" {
    PULLMD_ALLOW_HOSTS=""
    host_allowed "github.com"
    host_allowed "raw.githubusercontent.com"
}

# bats test_tags=allow-host
@test "host_allowed rejects an unlisted host" {
    PULLMD_ALLOW_HOSTS=""
    run host_allowed "news.example.org"
    assert_failure
}

# bats test_tags=allow-host
@test "host_allowed matches a configured host and its subdomains" {
    PULLMD_ALLOW_HOSTS="internal.test"
    host_allowed "internal.test"
    host_allowed "api.internal.test"
    run host_allowed "notinternal.test"
    assert_failure
}

# =============================================================================
# PULLMD_HOST_RULES / host_block_rule / render_block_directive
# =============================================================================

# bats test_tags=block-rules
@test "PULLMD_HOST_RULES parses as valid JSON" {
    printf '%s' "$PULLMD_HOST_RULES" | jq empty
}

# bats test_tags=block-rules
@test "host_block_rule prints nothing for an unmatched host" {
    # Assigned before asserting: a substitution inside [[ ]] would swallow a
    # lookup failure, so a broken function emitting nothing would still pass.
    local result
    result=$(host_block_rule "news.example.org")
    [[ -z "$result" ]]
}

# bats test_tags=block-rules
@test "host_block_rule returns tab-separated reason and guidance for an exact match and a subdomain match" {
    local host result reason guidance
    for host in "reddit.com" "www.reddit.com"; do
        result=$(host_block_rule "$host")
        IFS=$'\t' read -r reason guidance <<< "$result"
        [[ "$reason" == "Reddit is not readable here." ]]
        # Asserted non-empty: a trailing-wildcard match alone would also accept
        # a rule that emitted no guidance at all.
        [[ -n "$guidance" ]]
    done
}

# bats test_tags=block-rules
@test "host_block_rule requires a dot boundary and does not match a bare suffix" {
    local host result
    for host in "notreddit.com" "myredd.it" "xreddit.com" "reddit.com.evil.example"; do
        result=$(host_block_rule "$host")
        [[ -z "$result" ]]
    done
}

# bats test_tags=block-rules
@test "every host rule's reason and guidance are single-line" {
    run jq -e 'all(.[]; ((.reason | test("[\t\n]") | not) and (.guidance | test("[\t\n]") | not)))' <<< "$PULLMD_HOST_RULES"
    assert_success
}

# bats test_tags=block-rules
@test "render_block_directive prints nothing when the rules table is empty" {
    PULLMD_HOST_RULES='[]'
    local output
    output=$(render_block_directive)
    [[ -z "$output" ]]
}

# bats test_tags=block-rules
@test "render_block_directive names every host in the table" {
    local output
    output=$(render_block_directive)
    local hosts
    hosts=$(printf '%s' "$PULLMD_HOST_RULES" | jq -r '.[].hosts[]')
    while IFS= read -r host; do
        [[ -z "$host" ]] && continue
        [[ "$output" == *"$host"* ]]
    done <<< "$hosts"
}

# =============================================================================
# load_config — defaults
# =============================================================================

# bats test_tags=config
@test "load_config yields no instance and defaults when no files exist" {
    load_config "$TEST_PROJECT_DIR"
    [[ -z "$PULLMD_INSTANCE" ]]
    [[ "$PULLMD_ENABLED" == "true" ]]
    [[ "$PULLMD_MCP_TOOL" == "mcp__pullmd__read_url" ]]
    [[ "$PULLMD_ESCAPE_AFTER" == "2" ]]
    [[ "$PULLMD_DEBUG" == "false" ]]
}

# =============================================================================
# load_config — sources and precedence
# =============================================================================

# bats test_tags=config
@test "load_config reads a user-level instance" {
    write_user_config '{"instance":"https://pullmd.user.test"}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_INSTANCE" == "https://pullmd.user.test" ]]
}

# bats test_tags=config
@test "load_config reads a project-root pullmd.json when no .claude config exists" {
    write_project_root_config '{"instance":"https://pullmd.root.test"}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_INSTANCE" == "https://pullmd.root.test" ]]
}

# bats test_tags=config
@test "load_config prefers .claude/pullmd.json over project-root pullmd.json" {
    write_project_root_config '{"instance":"https://root.test"}'
    write_project_config '{"instance":"https://dot-claude.test"}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_INSTANCE" == "https://dot-claude.test" ]]
}

# bats test_tags=config,precedence
@test "project config overrides user config per key" {
    write_user_config '{"instance":"https://pullmd.user.test","escape_after":5}'
    write_project_config '{"escape_after":3}'
    load_config "$TEST_PROJECT_DIR"
    # instance is inherited from the user level (project did not set it)
    [[ "$PULLMD_INSTANCE" == "https://pullmd.user.test" ]]
    # escape_after is overridden by the project level
    [[ "$PULLMD_ESCAPE_AFTER" == "3" ]]
}

# bats test_tags=config
@test "load_config collects allow_hosts" {
    write_project_config '{"instance":"https://x.test","allow_hosts":["a.test","b.test"]}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_ALLOW_HOSTS" == *"a.test"* ]]
    [[ "$PULLMD_ALLOW_HOSTS" == *"b.test"* ]]
}

# =============================================================================
# load_config — robustness
# =============================================================================

# bats test_tags=config
@test "load_config falls back to the user config when the project config is invalid JSON" {
    write_user_config '{"instance":"https://pullmd.user.test"}'
    printf '%s' '{ not valid json' > "${TEST_PROJECT_DIR}/.claude/pullmd.json"
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_INSTANCE" == "https://pullmd.user.test" ]]
}

# bats test_tags=config
@test "load_config coerces a non-positive escape_after back to the default" {
    write_project_config '{"instance":"https://x.test","escape_after":0}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_ESCAPE_AFTER" == "2" ]]
}

# bats test_tags=config
@test "load_config honors enabled:false" {
    write_project_config '{"instance":"https://x.test","enabled":false}'
    load_config "$TEST_PROJECT_DIR"
    [[ "$PULLMD_ENABLED" == "false" ]]
}

# =============================================================================
# mcp_server_from_tool
# =============================================================================

# bats test_tags=mcp-name
@test "mcp_server_from_tool extracts the server segment" {
    [[ "$(mcp_server_from_tool "mcp__pullmd__read_url")" == "pullmd" ]]
}

# bats test_tags=mcp-name
@test "mcp_server_from_tool handles a hyphenated server name" {
    [[ "$(mcp_server_from_tool "mcp__pmd-prod__read_url")" == "pmd-prod" ]]
}

# bats test_tags=mcp-name
@test "mcp_server_from_tool takes the first segment when the tool name has extra __" {
    [[ "$(mcp_server_from_tool "mcp__pullmd__read__url")" == "pullmd" ]]
}

# bats test_tags=mcp-name
@test "mcp_server_from_tool returns empty for a non-wire name" {
    [[ -z "$(mcp_server_from_tool "read_url")" ]]
    [[ -z "$(mcp_server_from_tool "mcp__only_one")" ]]
    [[ -z "$(mcp_server_from_tool "")" ]]
}

# =============================================================================
# mcp_server_configured
# =============================================================================

# bats test_tags=mcp-config
@test "mcp_server_configured finds a user-scope server" {
    write_user_claude_json '{"mcpServers":{"pullmd":{"type":"http","url":"https://x.test/mcp"}}}'
    mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
}

# bats test_tags=mcp-config
@test "mcp_server_configured finds a local-scope server (projects[].mcpServers)" {
    write_user_claude_json '{"mcpServers":{},"projects":{"/some/proj":{"mcpServers":{"pullmd":{}}}}}'
    mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
}

# bats test_tags=mcp-config
@test "mcp_server_configured finds a project-scope server (.mcp.json)" {
    write_user_claude_json '{"mcpServers":{}}'
    write_project_mcp_json '{"mcpServers":{"pullmd":{}}}'
    mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
}

# bats test_tags=mcp-config
@test "mcp_server_configured fails when the server is absent" {
    write_user_claude_json '{"mcpServers":{"other":{}}}'
    run mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
    assert_failure
}

# bats test_tags=mcp-config
@test "mcp_server_configured fails when no config files exist" {
    run mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
    assert_failure
}

# bats test_tags=mcp-config
@test "mcp_server_configured tolerates an invalid ~/.claude.json" {
    printf '%s' '{ not valid json' > "${HOME}/.claude.json"
    run mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
    assert_failure
}

# bats test_tags=mcp-config
@test "mcp_server_configured fails for an empty server name" {
    write_user_claude_json '{"mcpServers":{"pullmd":{}}}'
    run mcp_server_configured "" "$TEST_PROJECT_DIR"
    assert_failure
}

# bats test_tags=mcp-config,codex
@test "mcp_server_configured finds an enabled Codex server" {
    install_fake_codex
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    export FAKE_CODEX_MCP_LIST='[{"name":"pullmd","enabled":true}]'

    mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
}

# bats test_tags=mcp-config,codex
@test "mcp_server_configured rejects a disabled Codex server" {
    install_fake_codex
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    export FAKE_CODEX_MCP_LIST='[{"name":"pullmd","enabled":false}]'

    run mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
    assert_failure
}

# bats test_tags=mcp-config,codex
@test "mcp_server_configured rejects an absent Codex server" {
    install_fake_codex
    export PLUGIN_ROOT="${REPO_ROOT}/plugins/web-fetching-with-pullmd"
    export FAKE_CODEX_MCP_LIST='[{"name":"other","enabled":true}]'

    run mcp_server_configured "pullmd" "$TEST_PROJECT_DIR"
    assert_failure
}
