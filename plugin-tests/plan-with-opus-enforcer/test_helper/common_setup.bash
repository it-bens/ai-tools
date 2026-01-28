#!/bin/bash
# Test fixtures for plan-with-opus-enforcer hook script testing

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
SCRIPTS_DIR="${REPO_ROOT}/plugins/plan-with-opus-enforcer/hooks/scripts"

# Run hook with Task tool input (subagent_type and optional model)
run_task_hook() {
    local script="$1"
    local subagent_type="$2"
    local model="${3:-}"

    local json
    if [[ -n "$model" ]]; then
        json=$(printf '{"tool_input": {"subagent_type": "%s", "model": "%s"}}' "$subagent_type" "$model")
    else
        json=$(printf '{"tool_input": {"subagent_type": "%s"}}' "$subagent_type")
    fi

    run bash -c 'echo "$1" | bash "$2"' _ "$json" "${SCRIPTS_DIR}/${script}"
}
