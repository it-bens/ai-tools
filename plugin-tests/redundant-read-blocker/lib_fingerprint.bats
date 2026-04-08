#!/usr/bin/env bats
# bats file_tags=redundant-read-blocker,lib

load 'test_helper/common_setup'

# Source lib.sh directly for unit testing
source "${SCRIPTS_DIR}/lib.sh"

# bats test_tags=fingerprint
@test "file_fingerprint returns 32-char hex string for a real file" {
    local test_file="${TEST_TEMP_DIR}/fp-test.txt"
    echo "hello world" > "$test_file"

    local hash
    hash=$(file_fingerprint "$test_file")

    # md5 produces 32 hex chars
    [[ ${#hash} -eq 32 ]]
    [[ "$hash" =~ ^[0-9a-f]+$ ]]
}

# bats test_tags=fingerprint
@test "file_fingerprint returns same hash for same content" {
    local file_a="${TEST_TEMP_DIR}/same-a.txt"
    local file_b="${TEST_TEMP_DIR}/same-b.txt"
    echo "identical content" > "$file_a"
    echo "identical content" > "$file_b"

    local hash_a hash_b
    hash_a=$(file_fingerprint "$file_a")
    hash_b=$(file_fingerprint "$file_b")

    [[ "$hash_a" == "$hash_b" ]]
}

# bats test_tags=fingerprint
@test "file_fingerprint returns different hash for different content" {
    local file_a="${TEST_TEMP_DIR}/diff-a.txt"
    local file_b="${TEST_TEMP_DIR}/diff-b.txt"
    echo "content version 1" > "$file_a"
    echo "content version 2" > "$file_b"

    local hash_a hash_b
    hash_a=$(file_fingerprint "$file_a")
    hash_b=$(file_fingerprint "$file_b")

    [[ "$hash_a" != "$hash_b" ]]
}

# bats test_tags=fingerprint
@test "file_fingerprint returns empty string for nonexistent file" {
    local hash
    hash=$(file_fingerprint "/tmp/does-not-exist-rrb-test-$$")

    [[ -z "$hash" ]]
}

# bats test_tags=fingerprint
@test "file_fingerprint returns same hash after touch (mtime change)" {
    local test_file="${TEST_TEMP_DIR}/touch-test.txt"
    echo "stable content" > "$test_file"

    local hash_before
    hash_before=$(file_fingerprint "$test_file")

    sleep 1
    touch "$test_file"

    local hash_after
    hash_after=$(file_fingerprint "$test_file")

    [[ "$hash_before" == "$hash_after" ]]
}
