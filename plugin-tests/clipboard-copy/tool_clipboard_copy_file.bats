#!/usr/bin/env bats
# bats file_tags=clipboard-copy,tool

load 'test_helper/common_setup'

setup() {
    # Source the lib with a no-op log shim (real log is in mcpserver_core.sh).
    log() { :; }
    source "${LIB_DIR}/clipboard.sh"

    # Capture-mode stub for the dispatcher: write stdin to a tempfile so
    # tests can assert the bytes that would have been sent to the clipboard
    # without needing pbcopy/xclip/etc. to actually be installed.
    CAPTURE_FILE="${BATS_TEST_TMPDIR}/clipboard_capture"
    _clipboard_send_stdin() { cat > "${CAPTURE_FILE}"; }

    # Pin the detected backend so the success message is predictable
    # regardless of host environment.
    _clipboard_detect_backend() { printf 'pbcopy\n'; }
}

# =============================================================================
# Path validation — every branch returns exit 1 with a specific message
# =============================================================================

# bats test_tags=validate,missing
@test "missing path argument → 'path is required'" {
    run tool_clipboard_copy_file '{}'
    assert_failure
    assert_output --partial "path is required"
}

# bats test_tags=validate,missing
@test "empty string path → 'path is required'" {
    run tool_clipboard_copy_file '{"path":""}'
    assert_failure
    assert_output --partial "path is required"
}

# bats test_tags=validate,relative
@test "relative path → 'path must be absolute'" {
    run tool_clipboard_copy_file '{"path":"relative.txt"}'
    assert_failure
    assert_output --partial "must be absolute"
    assert_output --partial "relative.txt"
}

# bats test_tags=validate,relative
@test "tilde-prefixed path → 'path must be absolute' (no shell expansion in JSON)" {
    run tool_clipboard_copy_file '{"path":"~/file.txt"}'
    assert_failure
    assert_output --partial "must be absolute"
}

# bats test_tags=validate,nonexistent
@test "nonexistent absolute path → 'file not found'" {
    run tool_clipboard_copy_file '{"path":"/no/such/file/here.txt"}'
    assert_failure
    assert_output --partial "file not found"
}

# bats test_tags=validate,directory
@test "directory path → 'not a regular file'" {
    local dir="${BATS_TEST_TMPDIR}/somedir"
    mkdir -p "$dir"
    run tool_clipboard_copy_file "{\"path\":\"${dir}\"}"
    assert_failure
    assert_output --partial "not a regular file"
}

# bats test_tags=validate,unreadable
@test "unreadable file → 'file not readable'" {
    if [[ "$(id -u)" == "0" ]]; then
        skip "root bypasses POSIX permissions"
    fi
    local f="${BATS_TEST_TMPDIR}/secret"
    printf 'classified\n' > "$f"
    chmod 000 "$f"
    run tool_clipboard_copy_file "{\"path\":\"${f}\"}"
    local rc=$status
    chmod 600 "$f"  # restore so BATS can clean up
    [[ "$rc" -ne 0 ]] || fail "expected non-zero exit, got 0"
    assert_output --partial "file not readable"
}

# =============================================================================
# Success path — bytes reach the dispatcher unchanged
# =============================================================================

# bats test_tags=success,dispatch
@test "valid file → dispatcher receives the file's bytes verbatim" {
    local f="${BATS_TEST_TMPDIR}/payload.txt"
    printf 'line one\nline two\n' > "$f"

    run tool_clipboard_copy_file "{\"path\":\"${f}\"}"
    assert_success
    assert_output --partial "Copied 18 bytes from ${f} to clipboard via pbcopy"

    # Verify the captured bytes match the file
    [[ -f "$CAPTURE_FILE" ]] || fail "dispatcher was not called"
    run cat "$CAPTURE_FILE"
    assert_output 'line one
line two'
}

# bats test_tags=success,dispatch
@test "empty file → 0 bytes copied, dispatcher still invoked" {
    local f="${BATS_TEST_TMPDIR}/empty.txt"
    : > "$f"

    run tool_clipboard_copy_file "{\"path\":\"${f}\"}"
    assert_success
    assert_output --partial "Copied 0 bytes from ${f} to clipboard via pbcopy"
    [[ -f "$CAPTURE_FILE" ]] || fail "dispatcher was not called"
}

# bats test_tags=success,dispatch
@test "binary-ish file with embedded newlines → byte-exact" {
    local f="${BATS_TEST_TMPDIR}/binary.bin"
    printf 'a\0b\nc\td\n' > "$f"

    run tool_clipboard_copy_file "{\"path\":\"${f}\"}"
    assert_success

    # Compare captured bytes to file via cmp (handles NULs)
    run cmp "$CAPTURE_FILE" "$f"
    assert_success
}

# =============================================================================
# clipboard_copy — quick parity check that text validation also fails hard
# =============================================================================

# bats test_tags=validate,text
@test "clipboard_copy with missing text → 'text is required'" {
    run tool_clipboard_copy '{}'
    assert_failure
    assert_output --partial "text is required"
}

# bats test_tags=validate,text
@test "clipboard_copy with empty text → 'text is required'" {
    run tool_clipboard_copy '{"text":""}'
    assert_failure
    assert_output --partial "text is required"
}

# bats test_tags=success,text
@test "clipboard_copy with valid text → bytes reach dispatcher verbatim" {
    run tool_clipboard_copy '{"text":"hello, clipboard"}'
    assert_success
    assert_output --partial "Copied 16 bytes to clipboard via pbcopy"

    run cat "$CAPTURE_FILE"
    assert_output "hello, clipboard"
}
