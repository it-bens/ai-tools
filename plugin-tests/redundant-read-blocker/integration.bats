#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,integration

load 'test_helper/common_setup'

# =============================================================================
# FULL LIFECYCLE TESTS
# =============================================================================

# bats test_tags=lifecycle
@test "full lifecycle: read → re-read blocked → edit → re-read allowed" {
    local test_file="${TEST_TEMP_DIR}/lifecycle.txt"
    echo "original content" > "$test_file"

    append_assistant_message 10000 0 0 100

    # 1. Record a read
    run_post_read "sess-1" "$test_file" 1 50 200 1 50
    assert_success

    # 2. Re-read should be blocked
    run_pre_read "sess-1" "$test_file" 1 50
    assert_failure 2

    # 3. Edit the file → invalidates tracking
    run_post_edit_write "sess-1" "$test_file"
    assert_success

    # 4. Re-read should now be allowed
    run_pre_read "sess-1" "$test_file" 1 50
    assert_success
}

# bats test_tags=lifecycle
@test "full lifecycle: read → session wipe → re-read allowed" {
    local test_file="${TEST_TEMP_DIR}/wipe-lifecycle.txt"
    echo "content" > "$test_file"

    append_assistant_message 10000 0 0 100

    # 1. Record a read
    run_post_read "sess-1" "$test_file" 1 100
    assert_success

    # 2. Re-read should be blocked
    run_pre_read "sess-1" "$test_file" 1 100
    assert_failure 2

    # 3. Compaction wipes tracking
    run_session_start "sess-1" "compact"
    assert_success

    # 4. Re-read should now be allowed
    run_pre_read "sess-1" "$test_file" 1 100
    assert_success
}

# bats test_tags=lifecycle
@test "full lifecycle: read → external edit (content change) → re-read allowed" {
    local test_file="${TEST_TEMP_DIR}/external.txt"
    echo "content v1" > "$test_file"

    append_assistant_message 10000 0 0 100

    # 1. Record a read
    run_post_read "sess-1" "$test_file" 1 10
    assert_success

    # 2. Re-read should be blocked
    run_pre_read "sess-1" "$test_file" 1 10
    assert_failure 2

    # 3. Simulate external edit (change content)
    sleep 1
    echo "content v2" > "$test_file"

    # 4. Re-read should now be allowed (content changed)
    run_pre_read "sess-1" "$test_file" 1 10
    assert_success
}

# bats test_tags=lifecycle
@test "partial top read does not block a later deeper read of the same file" {
    local test_file="${TEST_TEMP_DIR}/two-pass.txt"
    printf 'line\n%.0s' {1..97} > "$test_file"

    append_assistant_message 10000 0 0 100

    # Pass 1: read the top (lines 1-37) of a 97-line file
    run_post_read "sess-1" "$test_file" 1 37 97 1 37
    assert_success

    # Pass 2: read the rest (lines 39-97) — must be ALLOWED, the top read
    # only covered 1-37
    run_pre_read "sess-1" "$test_file" 39 59
    assert_success
}

# bats test_tags=lifecycle
@test "agent isolation: main blocked, subagent can still read" {
    local test_file="${TEST_TEMP_DIR}/agent-iso.txt"
    echo "content" > "$test_file"

    append_assistant_message 10000 0 0 100

    # 1. Main agent records a read
    run_post_read "sess-1" "$test_file" 1 50 200 1 50
    assert_success

    # 2. Main agent re-read is blocked
    run_pre_read "sess-1" "$test_file" 1 50
    assert_failure 2

    # 3. Subagent can still read (separate tracker)
    run_pre_read "sess-1" "$test_file" 1 50 "agent-sub1"
    assert_success
}

# bats test_tags=lifecycle
@test "full lifecycle: read → touch (no content change) → re-read blocked then retry allowed" {
    local test_file="${TEST_TEMP_DIR}/touch-lifecycle.txt"
    echo "stable content" > "$test_file"

    append_assistant_message 10000 0 0 100

    # 1. Record a read
    run_post_read "sess-1" "$test_file" 1 10
    assert_success

    # 2. Re-read should be blocked (first block)
    run_pre_read "sess-1" "$test_file" 1 10
    assert_failure 2

    # 3. Touch the file (mtime changes, content doesn't)
    sleep 1
    touch "$test_file"

    # 4. Re-read should be ALLOWED (second attempt after block = retry)
    run_pre_read "sess-1" "$test_file" 1 10
    assert_success
}
