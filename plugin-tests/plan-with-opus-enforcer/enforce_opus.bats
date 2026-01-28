#!/usr/bin/env bats
# bats file_tags=plan-with-opus-enforcer

load 'test_helper/common_setup'

SCRIPT="enforce-opus-plan.sh"

# =============================================================================
# BLOCKING TESTS - Should block (exit 2)
# =============================================================================

# bats test_tags=blocking
@test "blocks Plan with no model specified" {
    run_task_hook "$SCRIPT" "Plan"
    assert_failure 2
    assert_output --partial "requires Opus model"
}

# bats test_tags=blocking
@test "blocks Plan with haiku model" {
    run_task_hook "$SCRIPT" "Plan" "haiku"
    assert_failure 2
    assert_output --partial "requires Opus model"
}

# bats test_tags=blocking
@test "blocks Plan with sonnet model" {
    run_task_hook "$SCRIPT" "Plan" "sonnet"
    assert_failure 2
    assert_output --partial "requires Opus model"
}

# bats test_tags=blocking
@test "blocks Plan with inherit model" {
    run_task_hook "$SCRIPT" "Plan" "inherit"
    assert_failure 2
    assert_output --partial "requires Opus model"
}

# =============================================================================
# ALLOW TESTS - Should pass (exit 0)
# =============================================================================

# bats test_tags=allow
@test "allows Plan with opus model" {
    run_task_hook "$SCRIPT" "Plan" "opus"
    assert_success
    refute_output --partial "Blocked"
}

# bats test_tags=allow
@test "allows Explore subagent (not Plan)" {
    run_task_hook "$SCRIPT" "Explore" "haiku"
    assert_success
}

# bats test_tags=allow
@test "allows general-purpose subagent (not Plan)" {
    run_task_hook "$SCRIPT" "general-purpose" "haiku"
    assert_success
}

# bats test_tags=allow
@test "allows Bash subagent (not Plan)" {
    run_task_hook "$SCRIPT" "Bash"
    assert_success
}

# =============================================================================
# INPUT VALIDATION TESTS
# =============================================================================

# bats test_tags=input
@test "allows empty subagent_type" {
    run bash -c 'echo "{\"tool_input\": {}}" | bash "$1"' _ "${SCRIPTS_DIR}/${SCRIPT}"
    assert_success
}

# bats test_tags=input
@test "allows missing tool_input" {
    run bash -c 'echo "{}" | bash "$1"' _ "${SCRIPTS_DIR}/${SCRIPT}"
    assert_success
}
