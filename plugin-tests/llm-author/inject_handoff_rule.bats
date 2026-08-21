#!/usr/bin/env bats
# bats file_tags=llm-author

load 'test_helper/common_setup'

setup() {
    common_setup
}

# =============================================================================
# GATING TESTS - silent no-op (exit 0, no output)
# =============================================================================

# bats test_tags=gating
@test "post-tool-use: ignores a different skill" {
    run_post_tool_use "superpowers:brainstorming"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "post-tool-use: ignores a same-plugin skill that is not the handoff skill" {
    run_post_tool_use "llm-author:prompt-engineering"
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
@test "user-prompt: ignores a prompt without a handoff word" {
    run_user_prompt "please review the branch with codex"
    assert_success
    assert_output ""
}

# bats test_tags=gating
@test "gates silently when CLAUDE_PROJECT_DIR is unset" {
    unset CLAUDE_PROJECT_DIR
    run_post_tool_use "$SKILL"
    assert_success
    assert_output ""
}

# =============================================================================
# FAILURE TESTS - loud exit 1
# =============================================================================

@test "fails loudly on a missing mode argument" {
    run bash -c 'printf "%s" "{}" | bash "$1"' _ "$SCRIPT"
    assert_failure
    assert_output --partial "unknown or missing mode argument"
}

@test "fails loudly on an unknown mode argument" {
    run bash -c 'printf "%s" "{}" | bash "$1" pre-tool-use' _ "$SCRIPT"
    assert_failure
    assert_output --partial "unknown or missing mode argument"
}

# =============================================================================
# DELIVERY TESTS
# =============================================================================

@test "post-tool-use: delivers the rule for the handoff skill" {
    run_post_tool_use "$SKILL"
    assert_success
    assert_output --partial '"hookEventName": "PostToolUse"'
    assert_output --partial "handoff_referent_rule"
    assert_output --partial "Referent Verification"
}

@test "post-tool-use: output is valid JSON with additionalContext" {
    run_post_tool_use "$SKILL"
    assert_success
    printf '%s' "$output" | jq -e '.hookSpecificOutput.additionalContext | length > 0'
}

@test "user-prompt: delivers the rule and the invoke reminder on 'handoff'" {
    run_user_prompt "write a handoff prompt for the next session"
    assert_success
    assert_output --partial '"hookEventName": "UserPromptSubmit"'
    assert_output --partial "invoke the ${SKILL} skill"
    assert_output --partial "Referent Verification"
}

@test "user-prompt: matches 'hand-off' and 'hand off' variants" {
    run_user_prompt "prepare a hand-off for the other session"
    assert_success
    assert_output --partial "handoff_referent_rule"
    run_user_prompt "Hand off this work to a fresh session"
    assert_success
    assert_output --partial "handoff_referent_rule"
}

@test "user-prompt: matches all-uppercase HANDOFF" {
    run_user_prompt "read HANDOFF-AND-FEEDBACK-PROMPTS.md and continue"
    assert_success
    assert_output --partial "handoff_referent_rule"
}

@test "post-tool-use: missing rule file gates silently for non-handoff skills" {
    # The copy resolves its rule file relative to its own location, where no
    # rules/ tree exists — the relevance gate must exit 0 before that matters.
    run bash -c 'cp "$1" "$2" && printf "%s" "{\"tool_input\": {\"skill\": \"other:skill\"}}" | bash "$2" post-tool-use' _ "$SCRIPT" "${BATS_TEST_TMPDIR}/hook-copy.sh"
    assert_success
    assert_output ""
}

@test "delivered content matches the shipped rule file" {
    run_post_tool_use "$SKILL"
    assert_success
    local ctx
    ctx=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.additionalContext')
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        case "$ctx" in
            *"$line"*) ;;
            *) fail "rule line not delivered: $line" ;;
        esac
    done < "$RULE_FILE"
}
