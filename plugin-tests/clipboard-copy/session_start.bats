#!/usr/bin/env bats
# bats file_tags=clipboard-copy,session-start
bats_require_minimum_version 1.11.0

load 'test_helper/common_setup'

SESSION_SCRIPT="${REPO_ROOT}/plugins/clipboard-copy/hooks/scripts/session-start.sh"

run_session_start() {
    run bash -c 'echo "{}" | bash "$1"' _ "$SESSION_SCRIPT"
}

extract_context() {
    echo "$output" | jq -r '.hookSpecificOutput.additionalContext'
}

# ============================================================================
# JSON output structure
# ============================================================================

# bats test_tags=output
@test "outputs valid JSON" {
    run_session_start
    assert_success
    echo "$output" | jq -e . >/dev/null
}

@test "hookEventName is SessionStart" {
    run_session_start
    assert_success
    echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
}

@test "additionalContext is a non-empty string" {
    run_session_start
    assert_success
    echo "$output" | jq -e '.hookSpecificOutput.additionalContext | type == "string"' >/dev/null
    echo "$output" | jq -e '.hookSpecificOutput.additionalContext | length > 0' >/dev/null
}

# ============================================================================
# Directive content — names tools and the Bash commands they replace
# ============================================================================

# bats test_tags=content
@test "directive opens with ALWAYS / NEVER framing" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "$context" == *"ALWAYS"*"clipboard-copy MCP tools"* ]]
    [[ "$context" == *"NEVER"*"Bash"* ]]
}

@test "directive names both MCP tools" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "$context" == *"clipboard_copy("* ]]
    [[ "$context" == *"clipboard_copy_file("* ]]
}

@test "directive lists every blocked Bash command" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "$context" == *"pbcopy"* ]]
    [[ "$context" == *"wl-copy"* ]]
    [[ "$context" == *"xclip"* ]]
    [[ "$context" == *"xsel"* ]]
    [[ "$context" == *"clip.exe"* ]]
    [[ "$context" == *"clip"* ]]
}

@test "directive bans reprinting copied content into the session" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "$context" == *"NEVER print the copied content into the session"* ]]
    [[ "$context" == *"overrides an instruction to output that same content"* ]]
}

@test "directive notes paste-mode reads remain available via Bash" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "$context" == *"pbpaste"* ]]
    [[ "$context" == *"xclip -o"* ]]
}

# ============================================================================
# Silent no-op when the prompt template is missing
# ============================================================================

# bats test_tags=fallback
@test "silent success when prompt template is absent" {
    # Copy just the script into a sandbox without a sibling prompts/ directory
    # so the inline existence check trips and the script exits 0 with no output.
    cp "$SESSION_SCRIPT" "${BATS_TEST_TMPDIR}/session-start.sh"
    run bash -c 'echo "{}" | bash "$1"' _ "${BATS_TEST_TMPDIR}/session-start.sh"
    assert_success
    assert_output ""
}
