#!/usr/bin/env bats
# bats file_tags=native-tools-enforcer

load 'test_helper/common_setup'

SCRIPT="check-native-tools.sh"

# =============================================================================
# BLOCKING TESTS - Commands that should be blocked (exit 2)
# =============================================================================

# bats test_tags=blocking
@test "blocks cat → suggests Read tool" {
    run_hook "$SCRIPT" "cat README.md"
    assert_failure 2
    assert_output --partial "Read tool"
}

# bats test_tags=blocking
@test "blocks find → suggests Glob tool" {
    run_hook "$SCRIPT" "find . -name '*.js'"
    assert_failure 2
    assert_output --partial "Glob tool"
}

# bats test_tags=blocking
@test "blocks grep → suggests Grep tool" {
    run_hook "$SCRIPT" "grep pattern file.txt"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=blocking
@test "blocks piped grep → suggests Grep tool" {
    run_hook "$SCRIPT" "ls | grep foo"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=blocking
@test "blocks rg → suggests Grep tool" {
    run_hook "$SCRIPT" "rg pattern src/"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=blocking
@test "blocks echo redirect → suggests Write tool" {
    run_hook "$SCRIPT" "echo 'content' > file.txt"
    assert_failure 2
    assert_output --partial "Write tool"
}

# bats test_tags=blocking
@test "blocks heredoc → suggests Write tool" {
    run_hook "$SCRIPT" "cat <<EOF"
    assert_failure 2
    assert_output --partial "Write tool"
}

# bats test_tags=blocking
@test "blocks heredoc with file redirect → suggests Write tool" {
    run_hook "$SCRIPT" "cat << EOF > file.txt"
    assert_failure 2
    assert_output --partial "Write tool"
}

# bats test_tags=allow
@test "allows heredoc piped to command (clipboard)" {
    run_hook "$SCRIPT" "cat << 'EOF' | pbcopy"
    assert_success
}

# bats test_tags=allow
@test "allows heredoc piped to jq" {
    run_hook "$SCRIPT" "cat << EOF | jq .field"
    assert_success
}

# bats test_tags=blocking
@test "blocks sed → suggests Edit tool" {
    run_hook "$SCRIPT" "sed 's/foo/bar/' file.txt"
    assert_failure 2
    assert_output --partial "Edit tool"
}

# bats test_tags=blocking
@test "blocks awk → suggests Edit tool" {
    run_hook "$SCRIPT" "awk '{print \$1}' file.txt"
    assert_failure 2
    assert_output --partial "Edit tool"
}

# bats test_tags=blocking
@test "blocks command after &&" {
    run_hook "$SCRIPT" "cd src && grep pattern *.js"
    assert_failure 2
}

# =============================================================================
# WARNING TESTS - Commands that show warning but are allowed (exit 0)
# =============================================================================

# bats test_tags=warning
@test "warns on simple ls → suggests Glob tool" {
    run_hook "$SCRIPT" "ls"
    assert_success
    assert_output --partial "Glob tool"
}

# bats test_tags=warning
@test "warns on ls with directory → suggests Glob tool" {
    run_hook "$SCRIPT" "ls src"
    assert_success
    assert_output --partial "Glob tool"
}

# bats test_tags=warning
@test "warns on ls -a → suggests Glob tool" {
    run_hook "$SCRIPT" "ls -a"
    assert_success
    assert_output --partial "Glob tool"
}

# bats test_tags=warning
@test "warns on ls -R → suggests Glob tool" {
    run_hook "$SCRIPT" "ls -R"
    assert_success
    assert_output --partial "Glob tool"
}

# =============================================================================
# ALLOW TESTS - Commands that should pass without warning
# =============================================================================

# bats test_tags=allow
@test "allows ls -l without warning (needs metadata)" {
    run_hook "$SCRIPT" "ls -l"
    assert_success
    refute_output --partial "Glob"
}

# bats test_tags=allow
@test "allows ls -la without warning (needs metadata)" {
    run_hook "$SCRIPT" "ls -la"
    assert_success
    refute_output --partial "Glob"
}

# bats test_tags=allow
@test "allows ls -lh without warning (needs metadata)" {
    run_hook "$SCRIPT" "ls -lh"
    assert_success
    refute_output --partial "Glob"
}

# bats test_tags=allow
@test "allows safe commands" {
    run_hook "$SCRIPT" "git status"
    assert_success
}

# =============================================================================
# INPUT VALIDATION TESTS
# =============================================================================

# bats test_tags=input
@test "allows empty command" {
    run bash -c 'echo "{\"tool_input\": {\"command\": \"\"}}" | bash "$1"' _ "${SCRIPTS_DIR}/check-native-tools.sh"
    assert_success
}

# bats test_tags=input
@test "allows missing command field" {
    run bash -c 'echo "{\"tool_input\": {}}" | bash "$1"' _ "${SCRIPTS_DIR}/check-native-tools.sh"
    assert_success
}
