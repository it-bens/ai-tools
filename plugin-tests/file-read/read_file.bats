#!/usr/bin/env bats
# bats file_tags=file-read,tool

load 'test_helper/common_setup'

# bats test_tags=validate,missing
@test "missing file_path is rejected" {
    run tool_read_file '{}'
    assert_failure
    assert_output --partial "file_path is required"
}

# bats test_tags=validate,missing
@test "missing file is rejected with resolved relative path" {
    run tool_read_file "{\"file_path\":\"missing.md\",\"cwd\":\"${TEST_PROJECT_DIR}\"}"
    assert_failure
    assert_output --partial "file not found: ${TEST_PROJECT_DIR}/missing.md"
}

# bats test_tags=validate,directory
@test "directory path is rejected" {
    run tool_read_file "{\"file_path\":\"${TEST_PROJECT_DIR}\"}"
    assert_failure
    assert_output --partial "not a regular file"
}

# bats test_tags=validate,offset
@test "invalid offset is rejected" {
    local f="${TEST_PROJECT_DIR}/README.md"
    printf 'one\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"offset\":0}"
    assert_failure
    assert_output --partial "offset must be a positive integer"
}

# bats test_tags=validate,limit
@test "invalid limit is rejected" {
    local f="${TEST_PROJECT_DIR}/README.md"
    printf 'one\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"limit\":\"many\"}"
    assert_failure
    assert_output --partial "limit must be a positive integer"
}

# bats test_tags=validate,max-bytes
@test "invalid max_bytes is rejected" {
    local f="${TEST_PROJECT_DIR}/README.md"
    printf 'one\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"max_bytes\":0}"
    assert_failure
    assert_output --partial "max_bytes must be a positive integer"
}

# bats test_tags=success,relative
@test "reads a relative file against cwd" {
    local f="${TEST_PROJECT_DIR}/README.md"
    printf '# Title\n\nBody\n' > "$f"
    local resolved
    resolved="$(cd "$(dirname "$f")" && pwd -P)/$(basename "$f")"

    run tool_read_file "{\"file_path\":\"README.md\",\"cwd\":\"${TEST_PROJECT_DIR}\"}"
    assert_success
    assert_output --partial "File: ${resolved}"
    assert_output --partial $'     1\t# Title'
    assert_output --partial $'     3\tBody'
}

# bats test_tags=success,range
@test "reads offset and limit as a bounded line range" {
    local f="${TEST_PROJECT_DIR}/notes.md"
    printf 'alpha\nbeta\ngamma\ndelta\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"offset\":2,\"limit\":2}"
    assert_success
    assert_output --partial "Lines: 2-3 of 4"
    assert_output --partial $'     2\tbeta'
    assert_output --partial $'     3\tgamma'
    refute_output --partial "alpha"
    refute_output --partial "delta"
}

# bats test_tags=success,range
@test "caps requested range at end of file" {
    local f="${TEST_PROJECT_DIR}/short.md"
    printf 'one\ntwo\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"offset\":2,\"limit\":100}"
    assert_success
    assert_output --partial "Lines: 2-2 of 2"
    assert_output --partial $'     2\ttwo'
}

# bats test_tags=success,empty
@test "empty file returns metadata without content lines" {
    local f="${TEST_PROJECT_DIR}/empty.md"
    : > "$f"

    run tool_read_file "{\"file_path\":\"${f}\"}"
    assert_success
    assert_output --partial "Lines: 0 of 0"
}

# bats test_tags=success,normalization
@test "strips utf-8 bom and normalizes crlf endings" {
    local f="${TEST_PROJECT_DIR}/windows.md"
    printf '\357\273\277first\r\nsecond\r\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\"}"
    assert_success
    assert_output --partial $'     1\tfirst'
    assert_output --partial $'     2\tsecond'
    refute_output --partial $'\r'
}

# bats test_tags=validate,binary
@test "rejects binary-looking file by extension" {
    local f="${TEST_PROJECT_DIR}/image.png"
    printf 'not really an image\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\"}"
    assert_failure
    assert_output --partial "binary file detected"
}

# bats test_tags=validate,binary
@test "rejects binary-looking file by nul byte" {
    local f="${TEST_PROJECT_DIR}/payload.txt"
    printf 'text\0more\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\"}"
    assert_failure
    assert_output --partial "binary file detected"
}

# bats test_tags=success,truncation
@test "truncates output at max_bytes" {
    local f="${TEST_PROJECT_DIR}/long.md"
    printf 'abcdef\nsecond\n' > "$f"

    run tool_read_file "{\"file_path\":\"${f}\",\"max_bytes\":4}"
    assert_success
    assert_output --partial $'     1\tabcd'
    assert_output --partial "Output truncated"
    refute_output --partial "second"
}

# bats test_tags=mcp
@test "server lists read_file tool" {
    run bash -c 'printf "%s\n" "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}" | bash "$1"' _ "${SERVER_DIR}/server.sh"
    assert_success
    assert_output --partial '"name":"read_file"'
}
