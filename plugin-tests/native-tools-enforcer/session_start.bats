#!/usr/bin/env bats
# bats file_tags=native-tools-enforcer,session-start

load 'test_helper/common_setup'
load 'test_helper/mode_setup'

setup() {
    mode_setup_init
    # session-start.sh needs jq on PATH. mode_setup replaces PATH with a
    # minimal sandbox; symlink the real jq into MODE_MOCK_DIR so the script
    # still finds it without leaking bfs/ugrep from the host.
    if command -v jq >/dev/null 2>&1; then
        local real_jq
        real_jq="$(PATH="${MODE_ORIG_PATH}" command -v jq)"
        ln -sf "${real_jq}" "${MODE_MOCK_DIR}/jq"
    fi
    SCRIPT="${REPO_ROOT}/plugins/native-tools-enforcer/hooks/scripts/session-start.sh"
}

teardown() {
    mode_setup_cleanup
}

run_session_start() {
    # session-start hooks receive JSON on stdin (ignored) and emit JSON on stdout.
    run bash -c 'echo "{}" | "$1"' _ "$SCRIPT"
}

# bats test_tags=session-start,new
@test "new mode: emits JSON with additionalContext mentioning bfs and ugrep" {
    mode_set os=Darwin bfs=1 ugrep=1
    run_session_start
    [[ "$status" -eq 0 ]]
    [[ -n "$output" ]]
    echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
    local ctx
    ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$ctx" == *"bfs"* ]]
    [[ "$ctx" == *"ugrep"* ]]
}

# bats test_tags=session-start,new,env-var
@test "force-new overrides OS: emits new-mode context even on Windows" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0 force_new=1
    run_session_start
    [[ "$status" -eq 0 ]]
    local ctx
    ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$ctx" == *"bfs"* ]]
    [[ "$ctx" == *"ugrep"* ]]
}

# bats test_tags=session-start,classic
@test "classic mode: emits JSON with additionalContext mentioning Glob and Grep tools" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run_session_start
    [[ "$status" -eq 0 ]]
    local ctx
    ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$ctx" == *"Glob"* ]]
    [[ "$ctx" == *"Grep"* ]]
    # Classic mode must NOT mention bfs/ugrep — those only exist in new mode.
    [[ "$ctx" != *"bfs"* ]]
    [[ "$ctx" != *"ugrep"* ]]
}

# bats test_tags=session-start,pass
@test "pass mode: emits no output and exits 0 (Darwin, no bfs/ugrep)" {
    mode_set os=Darwin bfs=0 ugrep=0
    run_session_start
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

# bats test_tags=session-start,pass
@test "pass mode: emits no output on unknown OS" {
    mode_set os=WeirdOS bfs=0 ugrep=0
    run_session_start
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

# bats test_tags=session-start,robustness
@test "drains stdin without blocking on large payload" {
    mode_set os=Darwin bfs=1 ugrep=1
    # Send a multi-line payload; hook must not block or propagate stdin.
    run bash -c 'printf "{\n  \"session_id\": \"abc\",\n  \"hook_event_name\": \"SessionStart\"\n}\n" | "$1"' _ "$SCRIPT"
    [[ "$status" -eq 0 ]]
    echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
}
