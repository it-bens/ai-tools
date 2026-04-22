#!/usr/bin/env bats
# bats file_tags=native-tools-enforcer

load 'test_helper/common_setup'
load 'test_helper/mode_setup'

setup() {
    mode_setup_init
    # Default all existing tests to classic mode (Windows stub, no binaries).
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
}

teardown() {
    mode_setup_cleanup
}

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
@test "blocks piped grep from cat (file content)" {
    run_hook "$SCRIPT" "cat file.txt | grep pattern"
    assert_failure 2
    # Blocked by cat check first (Read tool) - expected behavior
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

# bats test_tags=allow
@test "allows << in printf argument (false positive fix)" {
    run_hook "$SCRIPT" "printf '%s' 'text with cat << EOF inside'"
    assert_success
}

# bats test_tags=allow
@test "allows heredoc pattern in commit message" {
    run_hook "$SCRIPT" "git commit -m 'fix: update regex from cat<<EOF to better pattern'"
    assert_success
}

# bats test_tags=allow
@test "allows > in quoted printf argument" {
    run_hook "$SCRIPT" "printf '%s' 'regex pattern (\$|>)' | pbcopy"
    assert_success
}

# bats test_tags=allow
@test "allows > in echo argument when followed by special char" {
    run_hook "$SCRIPT" "echo 'regex: (\$|>)' && true"
    assert_success
}

# bats test_tags=blocking
@test "still blocks printf redirect to file" {
    run_hook "$SCRIPT" "printf '%s' 'content' > output.txt"
    assert_failure 2
    assert_output --partial "Write tool"
}

# bats test_tags=blocking
@test "still blocks echo redirect to file" {
    run_hook "$SCRIPT" "echo content > file.txt"
    assert_failure 2
    assert_output --partial "Write tool"
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

# =============================================================================
# PIPED GREP TESTS - Allowed vs Blocked based on source command
# =============================================================================

# bats test_tags=allow,piped-grep
@test "allows piped grep from unzip -l (archive metadata)" {
    run_hook "$SCRIPT" "unzip -l dist/*.whl | grep -i dockerfile"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from git log (command output)" {
    run_hook "$SCRIPT" "git log --oneline | grep feat"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from docker ps (command output)" {
    run_hook "$SCRIPT" "docker ps | grep running"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from npm ls (package listing)" {
    run_hook "$SCRIPT" "npm ls | grep lodash"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from ps (process list)" {
    run_hook "$SCRIPT" "ps aux | grep node"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from env (environment vars)" {
    run_hook "$SCRIPT" "env | grep PATH"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from ls (directory listing)" {
    run_hook "$SCRIPT" "ls | grep foo"
    assert_success
}

# bats test_tags=allow,piped-grep
@test "allows piped grep from tar -tf (archive listing)" {
    run_hook "$SCRIPT" "tar -tf archive.tar.gz | grep config"
    assert_success
}

# bats test_tags=blocking,piped-grep
@test "blocks piped grep from strings (binary inspector)" {
    run_hook "$SCRIPT" "strings binary | grep pattern"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=blocking,piped-grep
@test "blocks piped grep from head (file content)" {
    run_hook "$SCRIPT" "head -100 log.txt | grep error"
    assert_failure 2
    # Blocked by head check first (Read tool) - expected behavior
}

# bats test_tags=blocking,piped-grep
@test "blocks piped grep from tail (file content)" {
    run_hook "$SCRIPT" "tail -f log.txt | grep error"
    assert_failure 2
    # Blocked by tail check first (Read tool) - expected behavior
}

# bats test_tags=blocking,piped-grep
@test "blocks piped grep from zcat (compressed file)" {
    run_hook "$SCRIPT" "zcat file.gz | grep pattern"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=blocking,piped-grep
@test "blocks piped rg from cat (file content)" {
    run_hook "$SCRIPT" "cat file.txt | rg pattern"
    assert_failure 2
    # Blocked by cat check first (Read tool) - expected behavior
}

# bats test_tags=allow,piped-grep
@test "allows piped rg from kubectl (k8s command)" {
    run_hook "$SCRIPT" "kubectl get pods | rg running"
    assert_success
}

# =============================================================================
# PASS-THROUGH TESTS (mode=pass, macOS/Linux without bfs/ugrep)
# =============================================================================

# bats test_tags=pass-through
@test "pass mode: find command exits 0 with no output" {
    mode_set os=Darwin bfs=0 ugrep=0
    run_hook "$SCRIPT" "find . -name '*.js'"
    assert_success
    [[ -z "$output" ]]
}

# bats test_tags=pass-through
@test "pass mode: grep command exits 0 with no output" {
    mode_set os=Darwin bfs=0 ugrep=0
    run_hook "$SCRIPT" "grep foo file.txt"
    assert_success
    [[ -z "$output" ]]
}

# bats test_tags=pass-through
@test "pass mode: cat command also passes (no Read-tool message)" {
    mode_set os=Darwin bfs=0 ugrep=0
    run_hook "$SCRIPT" "cat README.md"
    assert_success
    [[ -z "$output" ]]
}

# =============================================================================
# NEW-MODE MESSAGE TESTS (mode=new, Darwin+bfs+ugrep)
# =============================================================================

# bats test_tags=messages-new
@test "new mode: blocks find → suggests bfs" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "find . -name '*.js'"
    assert_failure 2
    assert_output --partial "bfs"
    refute_output --partial "Glob tool"
}

# bats test_tags=messages-new
@test "new mode: blocks locate → suggests bfs" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "locate README"
    assert_failure 2
    assert_output --partial "bfs"
    refute_output --partial "Glob tool"
}

# bats test_tags=messages-classic,regression
@test "classic mode: blocks find → still suggests Glob tool (regression)" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run_hook "$SCRIPT" "find . -name '*.js'"
    assert_failure 2
    assert_output --partial "Glob tool"
}

# bats test_tags=messages-new
@test "new mode: blocks grep → suggests ugrep" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "grep foo file.txt"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
}

# bats test_tags=messages-new
@test "new mode: blocks rg → suggests ugrep, no Grep tool, no placeholder" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "rg pattern src/"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
    refute_output --partial "selected content-search tool"
}

# bats test_tags=messages-classic,regression
@test "classic mode: blocks rg → suggests Grep tool, no placeholder (regression)" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run_hook "$SCRIPT" "rg pattern src/"
    assert_failure 2
    assert_output --partial "Grep tool"
    assert_output --partial "ripgrep"
    refute_output --partial "selected content-search tool"
}

# bats test_tags=messages-new
@test "new mode: blocks ag → suggests ugrep, no Grep tool" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "ag foo"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
}

# bats test_tags=messages-new
@test "new mode: blocks ack → suggests ugrep, no Grep tool" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "ack pattern"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
}

# bats test_tags=messages-new,piped-grep
@test "new mode: blocks zcat | grep → suggests ugrep, no Grep tool" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "zcat file.gz | grep pattern"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
}

# bats test_tags=messages-new,piped-grep
@test "new mode: blocks xxd | grep (file-content piped grep) → suggests ugrep" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "xxd binary | grep pattern"
    assert_failure 2
    assert_output --partial "ugrep"
    refute_output --partial "Grep tool"
}

# bats test_tags=messages-classic,regression
@test "classic mode: blocks grep → still suggests Grep tool (regression)" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run_hook "$SCRIPT" "grep foo file.txt"
    assert_failure 2
    assert_output --partial "Grep tool"
}

# bats test_tags=messages-new,warn
@test "new mode: ls produces no warning" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_hook "$SCRIPT" "ls"
    assert_success
    refute_output --partial "Glob tool"
    refute_output --partial "bfs"
    [[ -z "$output" ]]
}

# bats test_tags=messages-classic,warn,regression
@test "classic mode: ls still warns about Glob tool" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run_hook "$SCRIPT" "ls"
    assert_success
    assert_output --partial "Glob tool"
}

# =============================================================================
# DEBUG LOGGING TESTS
# =============================================================================

# bats test_tags=logging
@test "DEBUG unset: no log file created" {
    mode_set os=Darwin bfs=1 ugrep=1
    local plugin_data
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "git status"
    [[ ! -f "${plugin_data}/debug.log" ]]
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + block: log line written with mode=new and decision=block" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    local plugin_data
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "grep foo file.txt"
    [[ -f "${plugin_data}/debug.log" ]]
    run cat "${plugin_data}/debug.log"
    assert_output --partial "new"
    assert_output --partial "block"
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + pass mode: log line records pass decision" {
    mode_set os=Darwin bfs=0 ugrep=0 debug=1
    local plugin_data
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "grep foo file.txt"
    [[ -f "${plugin_data}/debug.log" ]]
    run cat "${plugin_data}/debug.log"
    assert_output --partial "pass"
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + unwritable dir: hook still exits normally" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    export CLAUDE_PLUGIN_DATA="/nonexistent/unwritable/path"
    run_hook "$SCRIPT" "git status"
    assert_success
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + long command: logged line is truncated (200 char cap)" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    local plugin_data long_cmd
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    # git-prefixed command is allowed by hook; use something that passes cleanly.
    long_cmd="git log --oneline $(printf 'x%.0s' {1..500})"
    run_hook "$SCRIPT" "$long_cmd"
    run cat "${plugin_data}/debug.log"
    # The logged line itself is at most ~280 chars incl. timestamp + tabs.
    # Command slot alone must be ≤ 200 chars.
    [[ "${#output}" -le 320 ]]
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + classic warn (ls): single log line with decision=warn" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0 debug=1
    local plugin_data
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "ls"
    [[ -f "${plugin_data}/debug.log" ]]
    # Exactly one line (no double-log of warn + allow).
    local line_count
    line_count="$(wc -l < "${plugin_data}/debug.log" | tr -d ' ')"
    [[ "$line_count" == "1" ]]
    run cat "${plugin_data}/debug.log"
    assert_output --partial "classic"
    assert_output --partial "warn"
    refute_output --partial "allow"
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + safe command: log records mode and decision=allow" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    local plugin_data
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "git status"
    [[ -f "${plugin_data}/debug.log" ]]
    run cat "${plugin_data}/debug.log"
    assert_output --partial "new"
    assert_output --partial "allow"
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1: log line has 5 tab-separated fields (TSV format)" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    local plugin_data line fields
    plugin_data="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="$plugin_data"
    run_hook "$SCRIPT" "grep foo file.txt"
    [[ -f "${plugin_data}/debug.log" ]]
    read -r line < "${plugin_data}/debug.log"
    IFS=$'\t' read -ra fields <<< "$line"
    # Fields: timestamp, session_id, mode, decision, command
    [[ "${#fields[@]}" == "5" ]]
    [[ "${fields[1]}" == "-" ]]      # session_id placeholder
    [[ "${fields[2]}" == "new" ]]    # mode
    [[ "${fields[3]}" == "block" ]]  # decision
    rm -rf -- "$plugin_data"
    unset CLAUDE_PLUGIN_DATA
}

# bats test_tags=logging
@test "DEBUG=1 + CLAUDE_PLUGIN_DATA unset: hook exits 0, no crash" {
    mode_set os=Darwin bfs=1 ugrep=1 debug=1
    unset CLAUDE_PLUGIN_DATA
    run_hook "$SCRIPT" "git status"
    assert_success
}
