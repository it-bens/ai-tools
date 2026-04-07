#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,pre-read

load 'test_helper/common_setup'

# =============================================================================
# ALLOW TESTS - File not tracked
# =============================================================================

# bats test_tags=allow
@test "allows read when file is not tracked" {
    append_assistant_message 10000 0 0 100

    run_pre_read "sess-1" "/tmp/unknown.txt" 1 50
    assert_success
}

# bats test_tags=allow
@test "allows read when no tracking file exists" {
    append_assistant_message 10000 0 0 100

    run_pre_read "sess-1" "/tmp/anything.txt"
    assert_success
}

# =============================================================================
# ALLOW TESTS - Mtime changed
# =============================================================================

# bats test_tags=allow,mtime
@test "allows read when file mtime has changed" {
    # Create a real file so stat works
    local test_file="${TEST_TEMP_DIR}/mtime-test.txt"
    echo "content" > "$test_file"

    # Track with a different mtime than the actual file
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: null}], mtime: 99999, context_tokens: 1000}}}')"

    append_assistant_message 1000 0 0 100

    run_pre_read "sess-1" "$test_file"
    assert_success
}

# =============================================================================
# ALLOW TESTS - Context decay
# =============================================================================

# bats test_tags=allow,decay
@test "allows read when context decay exceeds threshold" {
    local test_file="${TEST_TEMP_DIR}/decay-test.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Track with context_tokens=1000
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: null}], mtime: $mt, context_tokens: 1000}}}')"

    # Config with low threshold
    echo '{"decay_threshold": 5000}' > "${TEST_PROJECT_DIR}/.claude/redundant-read-blocker.json"

    # Transcript shows 90000 tokens now (delta = 89000 > 5000)
    append_assistant_message 80000 5000 4000 1000

    run_pre_read "sess-1" "$test_file"
    assert_success
}

# =============================================================================
# ALLOW TESTS - Partial coverage
# =============================================================================

# bats test_tags=allow,range
@test "allows read that extends beyond tracked range" {
    local test_file="${TEST_TEMP_DIR}/partial.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked: lines 1-100
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: 100}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    # Request: lines 80-150 (extends beyond 100)
    run_pre_read "sess-1" "$test_file" 80 71
    assert_success
}

# bats test_tags=allow,range
@test "allows full-file read when only partial range tracked" {
    local test_file="${TEST_TEMP_DIR}/partial-full.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked: lines 1-100 (bounded)
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: 100}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    # Full file read (no offset/limit) → requested [1, null], not covered by [1, 100]
    run_pre_read "sess-1" "$test_file"
    assert_success
}

# =============================================================================
# DENY TESTS - Fully covered
# =============================================================================

# bats test_tags=deny
@test "blocks read fully covered by tracked range" {
    local test_file="${TEST_TEMP_DIR}/covered.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked: lines 1-100
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: 100}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    # Request: lines 20-50 (fully within 1-100)
    run_pre_read "sess-1" "$test_file" 20 31
    assert_failure 2
    assert_output --partial "already read and unchanged"
}

# bats test_tags=deny
@test "blocks full-file re-read when unbounded range tracked" {
    local test_file="${TEST_TEMP_DIR}/full-reread.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked: [1, null] (full file)
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: null}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    # Full file re-read
    run_pre_read "sess-1" "$test_file"
    assert_failure 2
    assert_output --partial "already read and unchanged"
}

# bats test_tags=deny
@test "blocks partial read covered by unbounded range" {
    local test_file="${TEST_TEMP_DIR}/unbound-partial.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked: [1, null]
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: null}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    # Request: lines 500-600 (covered by [1, null])
    run_pre_read "sess-1" "$test_file" 500 101
    assert_failure 2
    assert_output --partial "already read and unchanged"
}

# =============================================================================
# DENY MESSAGE TESTS
# =============================================================================

# bats test_tags=deny,message
@test "deny message includes file path and range" {
    local test_file="${TEST_TEMP_DIR}/msg-test.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: 100}], mtime: $mt, context_tokens: 1000}}}')"

    append_assistant_message 2000 0 0 100

    run_pre_read "sess-1" "$test_file" 1 50
    assert_failure 2
    assert_output --partial "automatically unblocked"
}

# bats test_tags=deny,message
@test "verbose deny includes context decay stats" {
    local test_file="${TEST_TEMP_DIR}/verbose-test.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 100, files: {($fp): {ranges: [{start: 1, end: 100}], mtime: $mt, context_tokens: 1000}}}')"

    echo '{"verbose_deny": true}' > "${TEST_PROJECT_DIR}/.claude/redundant-read-blocker.json"

    append_assistant_message 2000 0 0 100

    run_pre_read "sess-1" "$test_file" 1 50
    assert_failure 2
    assert_output --partial "Context decay:"
}

# =============================================================================
# REWIND DETECTION TESTS
# =============================================================================

# bats test_tags=rewind
@test "allows read after rewind invalidates the entry" {
    local test_file="${TEST_TEMP_DIR}/rewind-test.txt"
    echo "content" > "$test_file"
    local mtime
    mtime=$(stat -f %m "$test_file" 2>/dev/null || stat -c %Y "$test_file" 2>/dev/null)

    # Tracked with high transcript_size and high context_tokens
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp "$test_file" \
        --argjson mt "$mtime" \
        '{transcript_size: 50000, files: {($fp): {ranges: [{start: 1, end: null}], mtime: $mt, context_tokens: 40000}}}')"

    # Current transcript is smaller (rewind happened) and tokens are lower
    append_assistant_message 5000 0 0 100

    run_pre_read "sess-1" "$test_file"
    assert_success
}

# bats test_tags=rewind
@test "rewind preserves entries from before rewind point" {
    local test_file_old="${TEST_TEMP_DIR}/old-read.txt"
    local test_file_new="${TEST_TEMP_DIR}/new-read.txt"
    echo "content" > "$test_file_old"
    echo "content" > "$test_file_new"
    local mtime_old mtime_new
    mtime_old=$(stat -f %m "$test_file_old" 2>/dev/null || stat -c %Y "$test_file_old" 2>/dev/null)
    mtime_new=$(stat -f %m "$test_file_new" 2>/dev/null || stat -c %Y "$test_file_new" 2>/dev/null)

    # Two entries: old-read at tokens=2000, new-read at tokens=40000
    # Transcript size was 50000
    write_tracker "sess-1" "main" "$(jq -n -c \
        --arg fp1 "$test_file_old" \
        --arg fp2 "$test_file_new" \
        --argjson mt1 "$mtime_old" \
        --argjson mt2 "$mtime_new" \
        '{transcript_size: 50000, files: {($fp1): {ranges: [{start: 1, end: null}], mtime: $mt1, context_tokens: 2000}, ($fp2): {ranges: [{start: 1, end: null}], mtime: $mt2, context_tokens: 40000}}}')"

    # Rewind: transcript is now small, tokens=5000 (> old 2000, < new 40000)
    append_assistant_message 4000 500 400 100

    # old-read should still be blocked (context_tokens 2000 < current 5000)
    run_pre_read "sess-1" "$test_file_old"
    assert_failure 2

    # new-read should be allowed (context_tokens 40000 > current 5000 → invalidated)
    run_pre_read "sess-1" "$test_file_new"
    assert_success
}
