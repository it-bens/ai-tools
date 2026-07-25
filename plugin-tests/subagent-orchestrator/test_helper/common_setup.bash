#!/bin/bash
# Test fixtures for subagent-orchestrator inject-extension hook script testing

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

# Path to hook scripts
SCRIPTS_DIR="${REPO_ROOT}/plugins/subagent-orchestrator/hooks/scripts"
SCRIPT="${SCRIPTS_DIR}/inject-extension.sh"

# The one skill this plugin delivers for
SKILL="subagent-orchestrator:orchestrating-subagent-work"
EXTENSION_REL=".claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md"

common_setup() {
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}/project"
    mkdir -p "${CLAUDE_PROJECT_DIR}"
}

# Write the extension file into the fake project
make_extension() {
    local content="$1"
    mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/extensions/subagent-orchestrator"
    printf '%s\n' "$content" > "${CLAUDE_PROJECT_DIR}/${EXTENSION_REL}"
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
