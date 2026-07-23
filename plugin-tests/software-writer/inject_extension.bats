#!/usr/bin/env bats
# bats file_tags=software-writer

load 'test_helper/common_setup'

setup() {
    common_setup
}

# =============================================================================
# GATING TESTS - silent no-op (exit 0, no output)
# =============================================================================

# bats test_tags=gating
@test "post-tool-use: ignores non-software-writer skill" {
    make_extension "writing-tests" "## Post-Step-2"
    run_post_tool_use "superpowers:brainstorming"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores software-writer skill without extension file" {
    run_post_tool_use "software-writer:writing-tests"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores input without tool_input.skill" {
    run bash -c 'printf "%s" "{\"tool_input\": {}}" | bash "$1" post-tool-use' _ "$SCRIPT"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores prompt without software-writer slash command" {
    make_extension "writing-tests" "## Post-Step-2"
    run_user_prompt "please fix the tests"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores software-writer prompt without extension file" {
    run_user_prompt "/software-writer:writing-tests add coverage"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores slash command with trailing characters in skill name" {
    make_extension "writing-tests" "## Post-Step-2"
    run_user_prompt "/software-writer:writing-testsx"
    assert_success
    assert_output ""
}

# =============================================================================
# DELIVERY TESTS - post-tool-use mode
# =============================================================================

# bats test_tags=delivery
@test "post-tool-use: delivers extension for writing-tests" {
    make_extension "writing-tests" "## Post-Step-2

Check the fixture registry."
    run_post_tool_use "software-writer:writing-tests"
    assert_success

    local event context
    event=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName')
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [ "$event" = "PostToolUse" ]

    [[ "$context" == '<project_extension skill="software-writer:writing-tests" position="after-skill-body">'* ]]
    [[ "$context" == *'</project_extension>' ]]
    [[ "$context" == *'<handling_instructions>'* ]]
    [[ "$context" == *'inert on its own'* ]]
    [[ "$context" == *'You are about to execute that skill'* ]]
    [[ "$context" == *'<extension_content>'* ]]
    [[ "$context" == *'Check the fixture registry.'* ]]
}

# bats test_tags=delivery
@test "post-tool-use: delivers extension for writing-docs" {
    make_extension "writing-docs" "## Named-value assignments"
    run_post_tool_use "software-writer:writing-docs"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'skill="software-writer:writing-docs"'* ]]
}

# bats test_tags=delivery
@test "post-tool-use: preserves quotes and backslashes from extension content" {
    make_extension "writing-code" 'Use `jq -r "\(.a)\t\(.b)"` for TSV output.'
    run_post_tool_use "software-writer:writing-code"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'Use `jq -r "\(.a)\t\(.b)"` for TSV output.'* ]]
}

# =============================================================================
# DELIVERY TESTS - user-prompt mode
# =============================================================================

# bats test_tags=delivery
@test "user-prompt: delivers extension for writing-code with arguments" {
    make_extension "writing-code" "## Pre-Step-4

Consult the DI container docs."
    run_user_prompt "/software-writer:writing-code add the parser"
    assert_success

    local event context
    event=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName')
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [ "$event" = "UserPromptSubmit" ]

    [[ "$context" == '<project_extension skill="software-writer:writing-code" position="before-skill-body">'* ]]
    [[ "$context" == *'The skill body has not been loaded yet'* ]]
    [[ "$context" == *'Consult the DI container docs.'* ]]
}

# bats test_tags=delivery
@test "user-prompt: delivers extension for bare slash command" {
    make_extension "writing-docs" "## Post-Step-1"
    run_user_prompt "/software-writer:writing-docs"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'skill="software-writer:writing-docs"'* ]]
    [[ "$context" == *'position="before-skill-body"'* ]]
}

# =============================================================================
# CODEX HOST TESTS - no CLAUDE_PROJECT_DIR: self-gate silently
# =============================================================================
# Codex runs the same plugin hooks but never sets CLAUDE_PROJECT_DIR; it
# delivers extensions through a committed AGENTS.override.md, not this hook.
# The hook must produce nothing (exit 0, no output) on that host, for every
# mode and prompt — including a matching software-writer invocation.

# bats test_tags=codex
@test "user-prompt: self-gates silently when CLAUDE_PROJECT_DIR is unset (Codex)" {
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "{\"prompt\": \"please fix the tests\", \"cwd\": \"/tmp/project\"}" | bash "$1" user-prompt' _ "$SCRIPT"
    assert_success
    assert_output ""
}

# bats test_tags=codex
@test "user-prompt: ignores cwd extension file on Codex (no CLAUDE_PROJECT_DIR)" {
    make_extension "writing-code" "## Pre-Step-4"
    local json
    json=$(jq -n --arg cwd "$CLAUDE_PROJECT_DIR" '{prompt: "/software-writer:writing-code add the parser", cwd: $cwd}')
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "$1" | bash "$2" user-prompt' _ "$json" "$SCRIPT"
    assert_success
    assert_output ""
}

# bats test_tags=codex
@test "post-tool-use: self-gates silently when CLAUDE_PROJECT_DIR is unset (Codex)" {
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "{\"tool_input\": {\"skill\": \"software-writer:writing-code\"}, \"cwd\": \"/tmp/project\"}" | bash "$1" post-tool-use' _ "$SCRIPT"
    assert_success
    assert_output ""
}

# =============================================================================
# FAILURE TESTS - loud failures (non-zero exit, stderr message)
# =============================================================================

# bats test_tags=failure
@test "fails on unknown mode argument" {
    run bash -c 'printf "%s" "{}" | bash "$1" session-start 2>&1' _ "$SCRIPT"
    assert_failure
    assert_output --partial "mode"
}

# bats test_tags=failure
@test "fails on missing mode argument" {
    run bash -c 'printf "%s" "{}" | bash "$1" 2>&1' _ "$SCRIPT"
    assert_failure
    assert_output --partial "mode"
}

# bats test_tags=failure
@test "fails on malformed stdin JSON" {
    run bash -c 'printf "%s" "not json {" | bash "$1" post-tool-use 2>&1' _ "$SCRIPT"
    assert_failure
    assert_output --partial "JSON"
}

# bats test_tags=failure
@test "fails when extension file exists but is not readable" {
    make_extension "writing-tests" "## Post-Step-2"
    chmod 000 "${CLAUDE_PROJECT_DIR}/.claude/extensions/software-writer/writing-tests.md"
    run_post_tool_use "software-writer:writing-tests"
    chmod 644 "${CLAUDE_PROJECT_DIR}/.claude/extensions/software-writer/writing-tests.md"
    assert_failure
}
