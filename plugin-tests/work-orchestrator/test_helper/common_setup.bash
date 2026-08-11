#!/bin/bash
# Test fixtures for work-orchestrator inject-extension hook script testing

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
SCRIPTS_DIR="${REPO_ROOT}/plugins/work-orchestrator/hooks/scripts"
SCRIPT="${SCRIPTS_DIR}/inject-extension.sh"

# The two skills this plugin delivers for
SKILL="work-orchestrator:orchestrating-subagent-work"
EXTENSION_REL=".claude/extensions/work-orchestrator/orchestrating-subagent-work.md"
SESSION_SKILL="work-orchestrator:orchestrating-session-work"
SESSION_EXTENSION_REL=".claude/extensions/work-orchestrator/orchestrating-session-work.md"

common_setup() {
    export CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}/project"
    mkdir -p "${CLAUDE_PROJECT_DIR}"
}

# Write an extension file into the fake project; second argument selects the
# skill's file (defaults to orchestrating-subagent-work)
make_extension() {
    local content="$1"
    local rel="${2:-$EXTENSION_REL}"
    mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/extensions/work-orchestrator"
    printf '%s\n' "$content" > "${CLAUDE_PROJECT_DIR}/${rel}"
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
