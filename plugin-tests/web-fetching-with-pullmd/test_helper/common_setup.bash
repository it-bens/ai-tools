#!/bin/bash
# Test fixtures for pullmd hook script testing

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
SCRIPTS_DIR="${REPO_ROOT}/plugins/web-fetching-with-pullmd/hooks/scripts"

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"

    unset PLUGIN_ROOT CODEX_PLUGIN_ROOT PLUGIN_DATA CODEX_PLUGIN_DATA

    # Isolate HOME so the developer's real ~/.claude/pullmd.json never leaks in.
    export HOME="${TEST_TEMP_DIR}/home"
    mkdir -p "${HOME}/.claude"

    export CLAUDE_PLUGIN_DATA="${TEST_TEMP_DIR}/plugin-data"
    mkdir -p "$CLAUDE_PLUGIN_DATA"

    TEST_PROJECT_DIR="${TEST_TEMP_DIR}/project"
    mkdir -p "${TEST_PROJECT_DIR}/.claude"
    export CLAUDE_PROJECT_DIR="$TEST_PROJECT_DIR"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# --- Config helpers ---

# Write a user-level config (~/.claude/pullmd.json). Args: $1 = JSON
write_user_config() {
    printf '%s' "$1" > "${HOME}/.claude/pullmd.json"
}

# Write a project-level config (<project>/.claude/pullmd.json). Args: $1 = JSON
write_project_config() {
    printf '%s' "$1" > "${TEST_PROJECT_DIR}/.claude/pullmd.json"
}

# Write a project-root config (<project>/pullmd.json). Args: $1 = JSON
write_project_root_config() {
    printf '%s' "$1" > "${TEST_PROJECT_DIR}/pullmd.json"
}

# Write Claude Code's MCP registry (~/.claude.json). Args: $1 = JSON
write_user_claude_json() {
    printf '%s' "$1" > "${HOME}/.claude.json"
}

# Write a project-scope MCP registry (<project>/.mcp.json). Args: $1 = JSON
write_project_mcp_json() {
    printf '%s' "$1" > "${TEST_PROJECT_DIR}/.mcp.json"
}

# Install a fake Codex CLI that serves FAKE_CODEX_MCP_LIST for
# `codex mcp list --json`.
install_fake_codex() {
    local bin_dir script
    bin_dir="${TEST_TEMP_DIR}/bin"
    script="${bin_dir}/codex"
    mkdir -p "$bin_dir"
    cat > "$script" <<'EOF'
#!/bin/bash
set -euo pipefail

if [[ "${1:-}" == "mcp" && "${2:-}" == "list" && "${3:-}" == "--json" ]]; then
    printf '%s\n' "${FAKE_CODEX_MCP_LIST:-[]}"
    exit 0
fi

exit 1
EOF
    chmod +x "$script"
    export PATH="${bin_dir}:${PATH}"
}

# --- Hook runners ---

# Run pre-webfetch.sh. Args: $1 = session_id, $2 = url
run_pre_webfetch() {
    local session_id="$1"
    local url="$2"

    local stdin
    stdin=$(jq -n -c \
        --arg sid "$session_id" \
        --arg cwd "$TEST_PROJECT_DIR" \
        --arg url "$url" \
        '{session_id: $sid, cwd: $cwd, tool_input: {url: $url}}')

    run bash -c 'printf "%s" "$1" | bash "$2"' _ "$stdin" "${SCRIPTS_DIR}/pre-webfetch.sh"
}

# Run session-start.sh. Args: $1 = session_id, $2 = source (startup|compact)
run_session_start() {
    local session_id="$1"
    local source="$2"

    local stdin
    stdin=$(jq -n -c \
        --arg sid "$session_id" \
        --arg cwd "$TEST_PROJECT_DIR" \
        --arg src "$source" \
        '{session_id: $sid, cwd: $cwd, source: $src}')

    run bash -c 'printf "%s" "$1" | bash "$2"' _ "$stdin" "${SCRIPTS_DIR}/session-start.sh"
}

# --- Escape-hatch state inspection ---

attempts_path() {
    printf '%s' "${CLAUDE_PLUGIN_DATA}/${1}/webfetch-attempts.json"
}

# Read the attempts file for a session ("" if absent). Args: $1 = session_id
read_attempts() {
    local path
    path=$(attempts_path "$1")
    if [[ -f "$path" ]]; then
        cat "$path"
    else
        echo ""
    fi
}

# Seed the attempts file directly. Args: $1 = session_id, $2 = JSON
write_attempts() {
    local session_id="$1" json="$2"
    local dir="${CLAUDE_PLUGIN_DATA}/${session_id}"
    mkdir -p "$dir"
    printf '%s' "$json" > "${dir}/webfetch-attempts.json"
}
