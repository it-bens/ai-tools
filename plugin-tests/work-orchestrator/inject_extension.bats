#!/usr/bin/env bats
# bats file_tags=work-orchestrator

load 'test_helper/common_setup'

setup() {
    common_setup
}

# =============================================================================
# GATING TESTS - silent no-op (exit 0, no output)
# =============================================================================

# bats test_tags=gating
@test "post-tool-use: ignores a different plugin's skill" {
    make_extension "## Post-Dispatch"
    run_post_tool_use "superpowers:brainstorming"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores a same-plugin prefix that is not the skill" {
    make_extension "## Post-Dispatch"
    run_post_tool_use "work-orchestrator:orchestrating"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores the companion setup plugin's skill" {
    make_extension "## Post-Dispatch"
    run_post_tool_use "work-orchestrator-extension-setup:setting-up-work-orchestrator-extension"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores the companion setup plugin's slash command" {
    make_extension "## Post-Dispatch"
    run_user_prompt "/work-orchestrator-extension-setup:setting-up-work-orchestrator-extension"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores the skill without an extension file" {
    run_post_tool_use "$SKILL"
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
@test "user-prompt: ignores a prompt without the slash command" {
    make_extension "## Post-Dispatch"
    run_user_prompt "please review the branch with codex"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores the slash command without an extension file" {
    run_user_prompt "/work-orchestrator:orchestrating-subagent-work review the branch"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores a slash command with trailing characters in the skill name" {
    make_extension "## Post-Dispatch"
    run_user_prompt "/work-orchestrator:orchestrating-subagent-workx"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores the slash command when it is not at the start of the prompt" {
    make_extension "## Post-Dispatch"
    run_user_prompt "run /work-orchestrator:orchestrating-subagent-work please"
    assert_success
    assert_output ""
}

# =============================================================================
# DELIVERY TESTS - post-tool-use mode
# =============================================================================

# bats test_tags=delivery
@test "post-tool-use: delivers the extension" {
    make_extension "## Named-value assignments

- \`project.gates\` = go test ./..."
    run_post_tool_use "$SKILL"
    assert_success

    local event context
    event=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName')
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [ "$event" = "PostToolUse" ]

    [[ "$context" == '<project_extension skill="work-orchestrator:orchestrating-subagent-work" position="after-skill-body">'* ]]
    [[ "$context" == *'</project_extension>' ]]
    [[ "$context" == *'<handling_instructions>'* ]]
    [[ "$context" == *'inert on its own'* ]]
    [[ "$context" == *'You are about to execute that skill'* ]]
    [[ "$context" == *'<extension_content>'* ]]
    [[ "$context" == *'`project.gates` = go test ./...'* ]]
}

# bats test_tags=delivery
@test "post-tool-use: preserves quotes and backslashes from extension content" {
    make_extension 'Use `jq -r "\(.a)\t\(.b)"` for TSV output.'
    run_post_tool_use "$SKILL"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'Use `jq -r "\(.a)\t\(.b)"` for TSV output.'* ]]
}

# =============================================================================
# DELIVERY TESTS - user-prompt mode
# =============================================================================

# bats test_tags=delivery
@test "user-prompt: delivers the extension for a slash command with arguments" {
    make_extension "## Pre-Strategy

List the project gates before stating the strategy."
    run_user_prompt "/work-orchestrator:orchestrating-subagent-work review the branch"
    assert_success

    local event context
    event=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName')
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [ "$event" = "UserPromptSubmit" ]

    [[ "$context" == '<project_extension skill="work-orchestrator:orchestrating-subagent-work" position="before-skill-body">'* ]]
    [[ "$context" == *'The skill body has not been loaded yet'* ]]
    [[ "$context" == *'List the project gates before stating the strategy.'* ]]
}

# bats test_tags=delivery
@test "user-prompt: delivers the extension for a bare slash command" {
    make_extension "## Post-Report"
    run_user_prompt "/work-orchestrator:orchestrating-subagent-work"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'skill="work-orchestrator:orchestrating-subagent-work"'* ]]
    [[ "$context" == *'position="before-skill-body"'* ]]
}

# =============================================================================
# DELIVERY TESTS - orchestrating-session-work
# =============================================================================

# bats test_tags=delivery
@test "post-tool-use: delivers the session-work extension" {
    make_extension "## Named-value assignments

- \`sessions.topology\` = owner/implementer/reviewer" "$SESSION_EXTENSION_REL"
    run_post_tool_use "$SESSION_SKILL"
    assert_success

    local event context
    event=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.hookEventName')
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [ "$event" = "PostToolUse" ]

    [[ "$context" == '<project_extension skill="work-orchestrator:orchestrating-session-work" position="after-skill-body">'* ]]
    [[ "$context" == *'`sessions.topology` = owner/implementer/reviewer'* ]]
}

# bats test_tags=delivery
@test "user-prompt: delivers the session-work extension for a slash command with arguments" {
    make_extension "## Pre-Strategy" "$SESSION_EXTENSION_REL"
    run_user_prompt "/work-orchestrator:orchestrating-session-work distribute the review"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'skill="work-orchestrator:orchestrating-session-work"'* ]]
    [[ "$context" == *'position="before-skill-body"'* ]]
}

# bats test_tags=delivery
@test "post-tool-use: session-work resolves its own extension file when both are present" {
    make_extension "SUBAGENT-CONTENT" "$EXTENSION_REL"
    make_extension "SESSION-CONTENT" "$SESSION_EXTENSION_REL"
    run_post_tool_use "$SESSION_SKILL"
    assert_success

    local context
    context=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    [[ "$context" == *'SESSION-CONTENT'* ]]
    [[ "$context" != *'SUBAGENT-CONTENT'* ]]
}

# bats test_tags=gating
@test "post-tool-use: session-work invocation stays silent with only the subagent-work extension present" {
    make_extension "## Post-Dispatch" "$EXTENSION_REL"
    run_post_tool_use "$SESSION_SKILL"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "user-prompt: ignores a session-work slash command with trailing characters" {
    make_extension "## Pre-Strategy" "$SESSION_EXTENSION_REL"
    run_user_prompt "/work-orchestrator:orchestrating-session-workx"
    assert_success
    assert_output ""
}

# =============================================================================
# NON-CLAUDE HOST TESTS - no CLAUDE_PROJECT_DIR: self-gate silently
# =============================================================================
# This plugin ships no Codex manifest, but another host may still run the
# hooks. Without CLAUDE_PROJECT_DIR there is no project root to resolve the
# extension file against, so the hook must produce nothing (exit 0, no output)
# for every mode and prompt — including a matching invocation.

# bats test_tags=host
@test "user-prompt: self-gates silently when CLAUDE_PROJECT_DIR is unset" {
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "{\"prompt\": \"review the branch\", \"cwd\": \"/tmp/project\"}" | bash "$1" user-prompt' _ "$SCRIPT"
    assert_success
    assert_output ""
}

# bats test_tags=host
@test "user-prompt: ignores a cwd extension file when CLAUDE_PROJECT_DIR is unset" {
    make_extension "## Pre-Strategy"
    local json
    json=$(jq -n --arg cwd "$CLAUDE_PROJECT_DIR" '{prompt: "/work-orchestrator:orchestrating-subagent-work review", cwd: $cwd}')
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "$1" | bash "$2" user-prompt' _ "$json" "$SCRIPT"
    assert_success
    assert_output ""
}

# bats test_tags=host
@test "post-tool-use: self-gates silently when CLAUDE_PROJECT_DIR is unset" {
    run bash -c 'unset CLAUDE_PROJECT_DIR; printf "%s" "{\"tool_input\": {\"skill\": \"work-orchestrator:orchestrating-subagent-work\"}, \"cwd\": \"/tmp/project\"}" | bash "$1" post-tool-use' _ "$SCRIPT"
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
@test "fails when the extension file exists but is not readable" {
    make_extension "## Post-Dispatch"
    chmod 000 "${CLAUDE_PROJECT_DIR}/${EXTENSION_REL}"
    run_post_tool_use "$SKILL"
    chmod 644 "${CLAUDE_PROJECT_DIR}/${EXTENSION_REL}"
    assert_failure
}
