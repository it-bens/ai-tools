#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,post-edit-write

load 'test_helper/common_setup'

# =============================================================================
# INVALIDATION TESTS
# =============================================================================

# bats test_tags=invalidate
@test "removes edited file from main agent tracker" {
    write_tracker "sess-1" "main" '{"transcript_size":100,"files":{"/a.txt":{"ranges":[{"start":1,"end":50}],"hash":"abc123","context_tokens":1000},"/b.txt":{"ranges":[{"start":1,"end":null}],"hash":"def456","context_tokens":2000}}}'

    run_post_edit_write "sess-1" "/a.txt"
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local has_a has_b
    has_a=$(echo "$tracker" | jq 'has("files") and (.files | has("/a.txt"))')
    has_b=$(echo "$tracker" | jq 'has("files") and (.files | has("/b.txt"))')

    [[ "$has_a" == "false" ]]
    [[ "$has_b" == "true" ]]
}

# bats test_tags=invalidate
@test "removes edited file from all agent trackers in session" {
    write_tracker "sess-1" "main" '{"transcript_size":100,"files":{"/shared.txt":{"ranges":[{"start":1,"end":100}],"hash":"abc123","context_tokens":1000}}}'
    write_tracker "sess-1" "agent-abc" '{"transcript_size":100,"files":{"/shared.txt":{"ranges":[{"start":50,"end":200}],"hash":"abc123","context_tokens":2000}}}'

    run_post_edit_write "sess-1" "/shared.txt"
    assert_success

    local main_tracker agent_tracker
    main_tracker=$(read_tracker "sess-1" "main")
    agent_tracker=$(read_tracker "sess-1" "agent-abc")

    local main_has agent_has
    main_has=$(echo "$main_tracker" | jq '.files | has("/shared.txt")')
    agent_has=$(echo "$agent_tracker" | jq '.files | has("/shared.txt")')

    [[ "$main_has" == "false" ]]
    [[ "$agent_has" == "false" ]]
}

# bats test_tags=invalidate
@test "does not affect other sessions" {
    write_tracker "sess-1" "main" '{"transcript_size":100,"files":{"/x.txt":{"ranges":[{"start":1,"end":50}],"hash":"abc123","context_tokens":1000}}}'
    write_tracker "sess-2" "main" '{"transcript_size":100,"files":{"/x.txt":{"ranges":[{"start":1,"end":50}],"hash":"abc123","context_tokens":1000}}}'

    run_post_edit_write "sess-1" "/x.txt"
    assert_success

    local sess2_tracker
    sess2_tracker=$(read_tracker "sess-2")
    local has_x
    has_x=$(echo "$sess2_tracker" | jq '.files | has("/x.txt")')

    [[ "$has_x" == "true" ]]
}

# bats test_tags=invalidate
@test "succeeds when file not in any tracker" {
    write_tracker "sess-1" "main" '{"transcript_size":100,"files":{}}'

    run_post_edit_write "sess-1" "/nonexistent.txt"
    assert_success
}

# bats test_tags=invalidate
@test "succeeds when no tracking files exist" {
    run_post_edit_write "sess-1" "/anything.txt"
    assert_success
}
