#!/bin/bash
# Test fixtures for llm-author inject-handoff-rule hook script testing

# Calculate repo root by walking up until we find .bats/ directory
_get_repo_root() {
    local test_dir="${BATS_TEST_DIRNAME}"
    while [[ ! -d "${test_dir}/.bats" ]] && [[ "${test_dir}" != "/" ]]; do
        test_dir="$(dirname "$test_dir")"
    done
    echo "$test_dir"
}

REPO_ROOT="$(_get_repo_root)"

# Load BATS helper libraries
load "${REPO_ROOT}/.bats/bats-support/load"
load "${REPO_ROOT}/.bats/bats-assert/load"

# Path to hook script and the shipped rule file
SCRIPTS_DIR="${REPO_ROOT}/plugins/llm-author/hooks/scripts"
SCRIPT="${SCRIPTS_DIR}/inject-handoff-rule.sh"
RULE_FILE="${REPO_ROOT}/plugins/llm-author/rules/referent-verification.md"

SKILL="llm-author:writing-handoff-prompts"

common_setup() {
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}/project"
    mkdir -p "${CLAUDE_PROJECT_DIR}"
}

# Run the script in post-tool-use mode with a Skill tool_input
run_post_tool_use() {
    local skill="$1"
    local json
    json=$(jq -n --arg skill "$skill" '{tool_input: {skill: $skill}}')
    run bash -c 'printf "%s" "$1" | bash "$2" post-tool-use' _ "$json" "$SCRIPT"
}

# Run the script in user-prompt mode with a prompt
run_user_prompt() {
    local prompt="$1"
    local json
    json=$(jq -n --arg prompt "$prompt" '{prompt: $prompt}')
    run bash -c 'printf "%s" "$1" | bash "$2" user-prompt' _ "$json" "$SCRIPT"
}
