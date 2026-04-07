#!/bin/bash
# Test fixtures for redundant-read-blocker hook script testing

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
SCRIPTS_DIR="${REPO_ROOT}/plugins/redundant-read-blocker/hooks/scripts"

# Temp directory for test state (cleaned up after each test)
setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export CLAUDE_PLUGIN_DATA="${TEST_TEMP_DIR}/plugin-data"
    mkdir -p "$CLAUDE_PLUGIN_DATA"

    # Create a fake project directory with config location
    TEST_PROJECT_DIR="${TEST_TEMP_DIR}/project"
    mkdir -p "${TEST_PROJECT_DIR}/.claude"

    # Create a fake transcript file
    TEST_TRANSCRIPT="${TEST_TEMP_DIR}/transcript.jsonl"
    touch "$TEST_TRANSCRIPT"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

# --- Transcript helpers ---

# Append an assistant message with usage data to the test transcript.
# Args: $1 = input_tokens, $2 = cache_creation, $3 = cache_read, $4 = output_tokens
append_assistant_message() {
    local input="${1:-1000}"
    local cache_creation="${2:-0}"
    local cache_read="${3:-0}"
    local output="${4:-100}"

    jq -n -c \
        --argjson it "$input" \
        --argjson cc "$cache_creation" \
        --argjson cr "$cache_read" \
        --argjson ot "$output" \
        '{
            type: "assistant",
            message: {
                role: "assistant",
                usage: {
                    input_tokens: $it,
                    cache_creation_input_tokens: $cc,
                    cache_read_input_tokens: $cr,
                    output_tokens: $ot
                }
            }
        }' >> "$TEST_TRANSCRIPT"
}

# --- Hook runner helpers ---

# Build the common stdin JSON fields.
# Args: $1 = session_id, $2 = agent_id (optional)
_base_stdin() {
    local session_id="$1"
    local agent_id="${2:-}"

    local json
    json=$(jq -n -c \
        --arg sid "$session_id" \
        --arg tp "$TEST_TRANSCRIPT" \
        --arg cwd "$TEST_PROJECT_DIR" \
        '{session_id: $sid, transcript_path: $tp, cwd: $cwd}')

    if [[ -n "$agent_id" ]]; then
        json=$(echo "$json" | jq -c --arg aid "$agent_id" '. + {agent_id: $aid}')
    fi

    echo "$json"
}

# Run session-start.sh
# Args: $1 = session_id, $2 = source (startup|compact|resume)
run_session_start() {
    local session_id="$1"
    local source="$2"

    local stdin
    stdin=$(_base_stdin "$session_id")
    stdin=$(echo "$stdin" | jq -c --arg src "$source" '. + {source: $src}')

    run bash -c 'echo "$1" | CLAUDE_PLUGIN_DATA="$2" bash "$3"' \
        _ "$stdin" "$CLAUDE_PLUGIN_DATA" "${SCRIPTS_DIR}/session-start.sh"
}

# Run pre-read.sh
# Args: $1 = session_id, $2 = file_path, $3 = offset (optional), $4 = limit (optional), $5 = agent_id (optional)
run_pre_read() {
    local session_id="$1"
    local file_path="$2"
    local offset="${3:-}"
    local limit="${4:-}"
    local agent_id="${5:-}"

    local stdin
    stdin=$(_base_stdin "$session_id" "$agent_id")

    local tool_input
    tool_input=$(jq -n -c --arg fp "$file_path" '{file_path: $fp}')
    if [[ -n "$offset" ]]; then
        tool_input=$(echo "$tool_input" | jq -c --argjson o "$offset" '. + {offset: $o}')
    fi
    if [[ -n "$limit" ]]; then
        tool_input=$(echo "$tool_input" | jq -c --argjson l "$limit" '. + {limit: $l}')
    fi

    stdin=$(echo "$stdin" | jq -c --argjson ti "$tool_input" '. + {tool_input: $ti}')

    run bash -c 'echo "$1" | CLAUDE_PLUGIN_DATA="$2" bash "$3"' \
        _ "$stdin" "$CLAUDE_PLUGIN_DATA" "${SCRIPTS_DIR}/pre-read.sh"
}

# Run post-read.sh
# Args: $1 = session_id, $2 = file_path, $3 = startLine, $4 = totalLines,
#        $5 = offset (optional), $6 = limit (optional), $7 = agent_id (optional)
run_post_read() {
    local session_id="$1"
    local file_path="$2"
    local start_line="$3"
    local total_lines="$4"
    local offset="${5:-}"
    local limit="${6:-}"
    local agent_id="${7:-}"

    local stdin
    stdin=$(_base_stdin "$session_id" "$agent_id")

    local tool_input
    tool_input=$(jq -n -c --arg fp "$file_path" '{file_path: $fp}')
    if [[ -n "$offset" ]]; then
        tool_input=$(echo "$tool_input" | jq -c --argjson o "$offset" '. + {offset: $o}')
    fi
    if [[ -n "$limit" ]]; then
        tool_input=$(echo "$tool_input" | jq -c --argjson l "$limit" '. + {limit: $l}')
    fi

    local tool_response
    tool_response=$(jq -n -c \
        --arg fp "$file_path" \
        --argjson sl "$start_line" \
        --argjson tl "$total_lines" \
        '{file: {filePath: $fp, startLine: $sl, totalLines: $tl}}')

    stdin=$(echo "$stdin" | jq -c \
        --argjson ti "$tool_input" \
        --argjson tr "$tool_response" \
        '. + {tool_input: $ti, tool_response: $tr}')

    run bash -c 'echo "$1" | CLAUDE_PLUGIN_DATA="$2" bash "$3"' \
        _ "$stdin" "$CLAUDE_PLUGIN_DATA" "${SCRIPTS_DIR}/post-read.sh"
}

# Run post-edit-write.sh
# Args: $1 = session_id, $2 = file_path, $3 = agent_id (optional)
run_post_edit_write() {
    local session_id="$1"
    local file_path="$2"
    local agent_id="${3:-}"

    local stdin
    stdin=$(_base_stdin "$session_id" "$agent_id")

    local tool_input
    tool_input=$(jq -n -c --arg fp "$file_path" '{file_path: $fp}')

    stdin=$(echo "$stdin" | jq -c --argjson ti "$tool_input" '. + {tool_input: $ti}')

    run bash -c 'echo "$1" | CLAUDE_PLUGIN_DATA="$2" bash "$3"' \
        _ "$stdin" "$CLAUDE_PLUGIN_DATA" "${SCRIPTS_DIR}/post-edit-write.sh"
}

# --- Tracker inspection helpers ---

# Read the tracker file contents for an agent.
# Args: $1 = session_id, $2 = agent_id (default "main")
read_tracker() {
    local session_id="$1"
    local agent_id="${2:-main}"
    local path="${CLAUDE_PLUGIN_DATA}/${session_id}/read-tracker-${agent_id}.json"
    if [[ -f "$path" ]]; then
        cat "$path"
    else
        echo ""
    fi
}

# Write a tracker file directly (for test setup).
# Args: $1 = session_id, $2 = agent_id, $3 = JSON content
write_tracker() {
    local session_id="$1"
    local agent_id="$2"
    local json="$3"
    local dir="${CLAUDE_PLUGIN_DATA}/${session_id}"
    mkdir -p "$dir"
    echo "$json" > "${dir}/read-tracker-${agent_id}.json"
}