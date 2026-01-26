#!/usr/bin/env bats
# bats file_tags=explore-with-sonnet-enforcer

load 'test_helper/common_setup'

SCRIPT="enforce-sonnet-explore.sh"

# =============================================================================
# BLOCKING TESTS - Should block (exit 2)
# =============================================================================

# bats test_tags=blocking
@test "blocks Explore with no model specified" {
    run_task_hook "$SCRIPT" "Explore"
    assert_failure 2
    assert_output --partial "requires Sonnet model"
}

# bats test_tags=blocking
@test "blocks Explore with haiku model" {
    run_task_hook "$SCRIPT" "Explore" "haiku"
    assert_failure 2
    assert_output --partial "requires Sonnet model"
}

# bats test_tags=blocking
@test "blocks Explore with opus model" {
    run_task_hook "$SCRIPT" "Explore" "opus"
    assert_failure 2
    assert_output --partial "requires Sonnet model"
}

# bats test_tags=blocking
@test "blocks Explore with inherit model" {
    run_task_hook "$SCRIPT" "Explore" "inherit"
    assert_failure 2
    assert_output --partial "requires Sonnet model"
}

# =============================================================================
# ALLOW TESTS - Should pass (exit 0)
# =============================================================================

# bats test_tags=allow
@test "allows Explore with sonnet model" {
    run_task_hook "$SCRIPT" "Explore" "sonnet"
    assert_success
    refute_output --partial "Blocked"
}

# bats test_tags=allow
@test "allows Plan subagent (not Explore)" {
    run_task_hook "$SCRIPT" "Plan" "haiku"
    assert_success
}

# bats test_tags=allow
@test "allows general-purpose subagent (not Explore)" {
    run_task_hook "$SCRIPT" "general-purpose" "haiku"
    assert_success
}

# bats test_tags=allow
@test "allows Bash subagent (not Explore)" {
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
