#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,post-read

load 'test_helper/common_setup'

# =============================================================================
# RECORDING TESTS
# =============================================================================

# bats test_tags=record
@test "records a partial read with correct range" {
    append_assistant_message 10000 500 5000 200

    run_post_read "sess-1" "/tmp/test-file.txt" 1 50 10 50
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local start end
    start=$(echo "$tracker" | jq '.files["/tmp/test-file.txt"].ranges[0].start')
    end=$(echo "$tracker" | jq '.files["/tmp/test-file.txt"].ranges[0].end')

    [[ "$start" == "1" ]]
    [[ "$end" == "50" ]]
}

# bats test_tags=record
@test "records a full-file read as unbounded range" {
    append_assistant_message 10000 0 0 100

    run_post_read "sess-1" "/tmp/full.txt" 1 200
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local start end
    start=$(echo "$tracker" | jq '.files["/tmp/full.txt"].ranges[0].start')
    end=$(echo "$tracker" | jq '.files["/tmp/full.txt"].ranges[0].end')

    [[ "$start" == "1" ]]
    [[ "$end" == "null" ]]
}

# bats test_tags=record
@test "stores context tokens from transcript" {
    append_assistant_message 10000 500 5000 200

    run_post_read "sess-1" "/tmp/test-file.txt" 1 50 10 50
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local tokens
    tokens=$(echo "$tracker" | jq '.files["/tmp/test-file.txt"].context_tokens')

    # 10000 + 500 + 5000 + 200 = 15700
    [[ "$tokens" == "15700" ]]
}

# bats test_tags=record
@test "stores transcript size" {
    append_assistant_message 10000 0 0 100

    local expected_size
    expected_size=$(wc -c < "$TEST_TRANSCRIPT" | tr -d ' ')

    run_post_read "sess-1" "/tmp/test-file.txt" 1 50 10 50
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local stored_size
    stored_size=$(echo "$tracker" | jq '.transcript_size')

    [[ "$stored_size" == "$expected_size" ]]
}

# =============================================================================
# RANGE MERGE TESTS
# =============================================================================

# bats test_tags=merge
@test "merges overlapping ranges" {
    append_assistant_message 10000 0 0 100

    # First read: lines 1-50
    run_post_read "sess-1" "/tmp/merge.txt" 1 50 0 50
    assert_success

    # Second read: lines 30-80
    run_post_read "sess-1" "/tmp/merge.txt" 30 51 30 51
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local range_count start end
    range_count=$(echo "$tracker" | jq '.files["/tmp/merge.txt"].ranges | length')
    start=$(echo "$tracker" | jq '.files["/tmp/merge.txt"].ranges[0].start')
    end=$(echo "$tracker" | jq '.files["/tmp/merge.txt"].ranges[0].end')

    [[ "$range_count" == "1" ]]
    [[ "$start" == "1" ]]
    [[ "$end" == "80" ]]
}

# bats test_tags=merge
@test "merges adjacent ranges" {
    append_assistant_message 10000 0 0 100

    # First read: lines 1-50
    run_post_read "sess-1" "/tmp/adj.txt" 1 50 0 50
    assert_success

    # Second read: lines 51-100
    run_post_read "sess-1" "/tmp/adj.txt" 51 50 51 50
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local range_count start end
    range_count=$(echo "$tracker" | jq '.files["/tmp/adj.txt"].ranges | length')
    start=$(echo "$tracker" | jq '.files["/tmp/adj.txt"].ranges[0].start')
    end=$(echo "$tracker" | jq '.files["/tmp/adj.txt"].ranges[0].end')

    [[ "$range_count" == "1" ]]
    [[ "$start" == "1" ]]
    [[ "$end" == "100" ]]
}

# bats test_tags=merge
@test "keeps non-overlapping ranges separate" {
    append_assistant_message 10000 0 0 100

    # First read: lines 1-50
    run_post_read "sess-1" "/tmp/gap.txt" 1 50 0 50
    assert_success

    # Second read: lines 100-150
    run_post_read "sess-1" "/tmp/gap.txt" 100 51 100 51
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local range_count
    range_count=$(echo "$tracker" | jq '.files["/tmp/gap.txt"].ranges | length')

    [[ "$range_count" == "2" ]]
}

# bats test_tags=merge
@test "unbounded range absorbs subsequent ranges" {
    append_assistant_message 10000 0 0 100

    # Full-file read (unbounded)
    run_post_read "sess-1" "/tmp/absorb.txt" 1 500
    assert_success

    # Partial read within the file
    run_post_read "sess-1" "/tmp/absorb.txt" 50 100 50 100
    assert_success

    local tracker
    tracker=$(read_tracker "sess-1")
    local range_count start end
    range_count=$(echo "$tracker" | jq '.files["/tmp/absorb.txt"].ranges | length')
    start=$(echo "$tracker" | jq '.files["/tmp/absorb.txt"].ranges[0].start')
    end=$(echo "$tracker" | jq '.files["/tmp/absorb.txt"].ranges[0].end')

    [[ "$range_count" == "1" ]]
    [[ "$start" == "1" ]]
    [[ "$end" == "null" ]]
}

# =============================================================================
# AGENT ISOLATION TESTS
# =============================================================================

# bats test_tags=agent
@test "different agents get separate tracking files" {
    append_assistant_message 10000 0 0 100

    run_post_read "sess-1" "/tmp/shared.txt" 1 50 0 50
    assert_success

    run_post_read "sess-1" "/tmp/shared.txt" 1 50 0 50 "agent-xyz"
    assert_success

    [[ -f "${CLAUDE_PLUGIN_DATA}/sess-1/read-tracker-main.json" ]]
    [[ -f "${CLAUDE_PLUGIN_DATA}/sess-1/read-tracker-agent-xyz.json" ]]
}
