#!/bin/bash
# Shared functions for redundant-read-blocker hook scripts.
# Sourced by all hook scripts — not executed directly.
#
# Naming convention:
#   UPPERCASE  — env vars (CLAUDE_PLUGIN_DATA), config constants (RRB_*), SCRIPT_DIR
#   lowercase  — all script-local and function-local variables

# --- Config ---

# Defaults
RRB_DECAY_THRESHOLD=80000
RRB_DEBUG=false
RRB_VERBOSE_DENY=false

# Load config from .claude/redundant-read-blocker.json if it exists.
# Overrides RRB_DECAY_THRESHOLD, RRB_DEBUG, RRB_VERBOSE_DENY.
load_config() {
    local cwd="$1"
    local config_file="${cwd}/.claude/redundant-read-blocker.json"

    if [[ -f "$config_file" ]]; then
        local val
        val=$(jq -r '.decay_threshold // empty' "$config_file" 2>/dev/null)
        [[ -n "$val" ]] && RRB_DECAY_THRESHOLD="$val"

        val=$(jq -r '.debug // empty' "$config_file" 2>/dev/null)
        [[ "$val" == "true" ]] && RRB_DEBUG=true

        val=$(jq -r '.verbose_deny // empty' "$config_file" 2>/dev/null)
        [[ "$val" == "true" ]] && RRB_VERBOSE_DENY=true

        return 0
    fi
}

# --- Debug logging ---

debug_log() {
    if [[ "$RRB_DEBUG" == "true" ]]; then
        printf '[RRB] %s\n' "$1" >&2
    fi
}

# --- File fingerprinting ---

# Returns the md5 hash of a file's contents.
# Cross-platform: md5 -q (macOS) with md5sum (Linux) fallback.
# Returns empty string on failure (fail open).
# Args: $1 = file_path
file_fingerprint() {
    local file_path="$1"
    local hash
    hash=$(md5 -q "$file_path" 2>/dev/null || md5sum "$file_path" 2>/dev/null | cut -d' ' -f1) || true
    if [[ -z "$hash" ]]; then
        debug_log "WARN: failed to hash ${file_path}"
    fi
    printf '%s\n' "${hash:-}"
}

# --- Paths ---

# Returns the path to the tracking file for the given agent.
# Args: $1 = data_dir, $2 = session_id, $3 = agent_id (or "main")
tracker_path() {
    local data_dir="$1"
    local session_id="$2"
    local agent_id="$3"
    printf '%s\n' "${data_dir}/${session_id}/read-tracker-${agent_id}.json"
}

# Returns the session directory path.
# Args: $1 = data_dir, $2 = session_id
session_dir() {
    local data_dir="$1"
    local session_id="$2"
    printf '%s\n' "${data_dir}/${session_id}"
}

# --- Tracker I/O ---

# Load tracker JSON. Returns empty tracker if file doesn't exist.
load_tracker() {
    local path="$1"
    if [[ -f "$path" ]]; then
        cat -- "$path"
    else
        printf '%s\n' '{"transcript_size":0,"files":{}}'
    fi
}

# Save tracker JSON to path atomically via tmp+mv.
save_tracker() {
    local path="$1"
    local json="$2"
    local dir
    dir="$(dirname -- "$path")"
    mkdir -p "$dir"
    local tmp
    tmp=$(mktemp "${dir}/.rrb-tmp.XXXXXX")
    printf '%s\n' "$json" > "$tmp" && mv -- "$tmp" "$path"
}

# --- Transcript parsing ---

# Get total context tokens from the latest assistant message in transcript.
# Returns: integer (total tokens), defaults to 0 on any failure.
# Args: $1 = transcript_path
get_latest_context_tokens() {
    local transcript_path="$1"
    local result
    result=$(tail -20 "$transcript_path" 2>/dev/null | \
        jq -r 'select(.message.usage != null) | .message.usage |
            ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) +
             (.cache_read_input_tokens // 0) + (.output_tokens // 0))' 2>/dev/null | \
        tail -1) || true
    printf '%s\n' "${result:-0}"
}

# --- Range operations ---

# Check if a requested range is fully covered by any single tracked range.
# Args: $1 = tracker JSON, $2 = file_path, $3 = req_start, $4 = req_end ("null" for unbounded)
# Returns: 0 if covered (should DENY), 1 if not covered (should ALLOW)
is_range_covered() {
    local tracker="$1"
    local file_path="$2"
    local req_start="$3"
    local req_end="$4"

    printf '%s\n' "$tracker" | jq -e --arg fp "$file_path" \
        --argjson rs "$req_start" --argjson re "$req_end" '
        .files[$fp].ranges // [] | any(
            .start as $s | .end as $e |
            $rs >= $s and (
                $e == null or
                ($re != null and $re <= $e)
            )
        )
    ' > /dev/null 2>&1
}

# Sort and merge ranges, handling null ends (unbounded).
# Reads JSON array from stdin, writes merged array to stdout.
merge_ranges() {
    jq -c '
        sort_by(.start) |
        reduce .[] as $r ([];
            if length == 0 then [$r]
            else
                (last) as $last |
                if $last.end == null then .
                elif $r.start <= ($last.end + 1) then
                    .[length-1].end = (
                        if $r.end == null then null
                        elif $last.end == null then null
                        elif $r.end > $last.end then $r.end
                        else $last.end
                        end
                    )
                else . + [$r]
                end
            end
        )
    '
}
