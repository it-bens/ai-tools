#!/usr/bin/env bats
# bats file_tags=clipboard-copy,hook

load 'test_helper/common_setup'

SCRIPT="check-clipboard.sh"

# =============================================================================
# BLOCK — clipboard-write commands at start of a command segment
# =============================================================================

# bats test_tags=block,pbcopy
@test "blocks pbcopy with stdin redirect" {
    run_hook "$SCRIPT" "pbcopy < file.txt"
    assert_failure 2
    assert_output --partial "clipboard_copy MCP tool"
}

# bats test_tags=block,pbcopy
@test "blocks pbcopy piped from another command" {
    run_hook "$SCRIPT" "echo hi | pbcopy"
    assert_failure 2
    assert_output --partial "clipboard_copy"
}

# bats test_tags=block,pbcopy
@test "blocks pbcopy after && chain" {
    run_hook "$SCRIPT" "cd /tmp && pbcopy < f.txt"
    assert_failure 2
}

# bats test_tags=block,pbcopy
@test "blocks pbcopy after ; separator" {
    run_hook "$SCRIPT" "date ; pbcopy < f.txt"
    assert_failure 2
}

# bats test_tags=block,wl-copy
@test "blocks wl-copy piped" {
    run_hook "$SCRIPT" "echo hi | wl-copy"
    assert_failure 2
    assert_output --partial "clipboard_copy"
}

# bats test_tags=block,clip
@test "blocks clip.exe piped" {
    run_hook "$SCRIPT" "ls | clip.exe"
    assert_failure 2
}

# bats test_tags=block,clip
@test "blocks bare clip command" {
    run_hook "$SCRIPT" "echo hi | clip"
    assert_failure 2
}

# bats test_tags=block,xclip
@test "blocks xclip with no flags (defaults to copy mode)" {
    run_hook "$SCRIPT" "echo hi | xclip"
    assert_failure 2
}

# bats test_tags=block,xclip
@test "blocks xclip -i" {
    run_hook "$SCRIPT" "echo hi | xclip -i"
    assert_failure 2
}

# bats test_tags=block,xclip
@test "blocks xclip -selection clipboard (no -o)" {
    run_hook "$SCRIPT" "echo hi | xclip -selection clipboard"
    assert_failure 2
}

# bats test_tags=block,xsel
@test "blocks xsel --clipboard --input" {
    run_hook "$SCRIPT" "echo hi | xsel --clipboard --input"
    assert_failure 2
}

# bats test_tags=block,xsel
@test "blocks xsel -bi" {
    run_hook "$SCRIPT" "echo hi | xsel -bi"
    assert_failure 2
}

# =============================================================================
# ALLOW — paste reads, unrelated commands, false-positive guards
# =============================================================================

# bats test_tags=allow,paste
@test "allows pbpaste" {
    run_hook "$SCRIPT" "pbpaste"
    assert_success
}

# bats test_tags=allow,paste
@test "allows wl-paste" {
    run_hook "$SCRIPT" "wl-paste"
    assert_success
}

# bats test_tags=allow,paste
@test "allows xclip -o (paste mode, first-arg flag)" {
    run_hook "$SCRIPT" "xclip -o > out.txt"
    assert_success
}

# bats test_tags=allow,paste
@test "allows xclip -selection clipboard -out" {
    run_hook "$SCRIPT" "xclip -selection clipboard -out"
    assert_success
}

# bats test_tags=allow,paste
@test "allows xsel -o" {
    run_hook "$SCRIPT" "xsel -o"
    assert_success
}

# bats test_tags=allow,paste
@test "allows xsel --clipboard --output" {
    run_hook "$SCRIPT" "xsel --clipboard --output"
    assert_success
}

# bats test_tags=allow,unrelated
@test "allows unrelated git command" {
    run_hook "$SCRIPT" "git status"
    assert_success
}

# bats test_tags=allow,unrelated
@test "allows unrelated ls command" {
    run_hook "$SCRIPT" "ls -la /tmp"
    assert_success
}

# bats test_tags=allow,false-positive
@test "does not trigger on 'clipper' (substring of clip)" {
    run_hook "$SCRIPT" "clipper --help"
    assert_success
}

# bats test_tags=allow,false-positive
@test "does not trigger on 'echo clipboard-test'" {
    run_hook "$SCRIPT" "echo clipboard-test"
    assert_success
}

# bats test_tags=allow,false-positive
@test "does not trigger on 'grep clip file.txt' (clip is the search term)" {
    run_hook "$SCRIPT" "grep clip file.txt"
    assert_success
}

# =============================================================================
# Robustness
# =============================================================================

# bats test_tags=robust
@test "empty command passes through (allow)" {
    run bash -c 'printf "%s" "{\"tool_input\":{\"command\":\"\"}}" | bash "$1"' \
        _ "${SCRIPTS_DIR}/${SCRIPT}"
    assert_success
}
