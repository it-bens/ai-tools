#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,session-start

load 'test_helper/common_setup'

# =============================================================================
# WIPE TESTS - Should delete tracking files
# =============================================================================

# bats test_tags=wipe
@test "startup wipes tracking files for current session" {
    write_tracker "sess-1" "main" '{"transcript_size":100,"files":{"/a.txt":{"ranges":[{"start":1,"end":50}],"mtime":123,"context_tokens":1000}}}'
    write_tracker "sess-1" "agent-abc" '{"transcript_size":100,"files":{"/b.txt":{"ranges":[{"start":1,"end":null}],"mtime":456,"context_tokens":2000}}}'

    run_session_start "sess-1" "startup"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-1/read-tracker-main.json" ]]
    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-1/read-tracker-agent-abc.json" ]]
}

# bats test_tags=wipe
@test "compact wipes tracking files for current session" {
    write_tracker "sess-2" "main" '{"transcript_size":500,"files":{"/c.txt":{"ranges":[{"start":1,"end":100}],"mtime":789,"context_tokens":5000}}}'

    run_session_start "sess-2" "compact"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-2/read-tracker-main.json" ]]
}

# bats test_tags=wipe
@test "startup does not wipe other sessions" {
    write_tracker "sess-A" "main" '{"transcript_size":100,"files":{}}'
    write_tracker "sess-B" "main" '{"transcript_size":200,"files":{}}'

    run_session_start "sess-A" "startup"
    assert_success

    [[ ! -f "${CLAUDE_PLUGIN_DATA}/sess-A/read-tracker-main.json" ]]
    [[ -f "${CLAUDE_PLUGIN_DATA}/sess-B/read-tracker-main.json" ]]
}

# bats test_tags=wipe
@test "startup succeeds when no tracking files exist" {
    run_session_start "sess-new" "startup"
    assert_success
}