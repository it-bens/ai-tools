#!/bin/bash
# PreToolUse Read hook: block redundant reads of unchanged files.
#
# Exit codes:
#   0 - Allow the read
#   2 - Block the read (deny message on stderr)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

input=$(cat)

# Parse all input fields in a single jq invocation
{
    IFS= read -r session_id
    IFS= read -r agent_id
    IFS= read -r cwd
    IFS= read -r transcript_path
    IFS= read -r file_path
    IFS= read -r offset
    IFS= read -r limit
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.agent_id // "main"),
    (.cwd // ""),
    (.transcript_path // ""),
    (.tool_input.file_path // ""),
    (.tool_input.offset // ""),
    (.tool_input.limit // "")
')

if [[ -z "$session_id" || -z "$file_path" ]]; then
    exit 0
fi

load_config "$cwd"

tracker_file=$(tracker_path "$CLAUDE_PLUGIN_DATA" "$session_id" "$agent_id")
tracker=$(load_tracker "$tracker_file")

# --- Rewind detection ---
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    current_transcript_size=$(wc -c < "$transcript_path" | tr -d ' ')
    stored_transcript_size=$(printf '%s\n' "$tracker" | jq '.transcript_size // 0')

    if [[ "$current_transcript_size" -lt "$stored_transcript_size" ]]; then
        debug_log "Rewind detected (transcript: ${current_transcript_size} < ${stored_transcript_size})"

        current_tokens=$(get_latest_context_tokens "$transcript_path")

        # Invalidate entries made after the rewind point
        tracker=$(printf '%s\n' "$tracker" | jq -c --argjson ct "$current_tokens" \
            '.files |= with_entries(select(.value.context_tokens <= $ct))')

        # Update transcript size
        tracker=$(printf '%s\n' "$tracker" | jq -c --argjson ts "$current_transcript_size" \
            '.transcript_size = $ts')

        save_tracker "$tracker_file" "$tracker"
    fi
fi

# --- File lookup ---
has_file=$(printf '%s\n' "$tracker" | jq --arg fp "$file_path" '.files | has($fp)')
if [[ "$has_file" != "true" ]]; then
    debug_log "ALLOW ${file_path} — not tracked"
    exit 0
fi

# --- Content change detection ---
tracked_hash=$(printf '%s\n' "$tracker" | jq -r --arg fp "$file_path" '.files[$fp].hash')
current_hash=$(file_fingerprint "$file_path")

if [[ -z "$current_hash" ]]; then
    debug_log "ALLOW ${file_path} — hash failed (fail open)"
    exit 0
fi

if [[ "$current_hash" != "$tracked_hash" ]]; then
    tracker=$(printf '%s\n' "$tracker" | jq -c --arg fp "$file_path" 'del(.files[$fp])')
    save_tracker "$tracker_file" "$tracker"
    debug_log "ALLOW ${file_path} — content changed (hash ${tracked_hash} -> ${current_hash})"
    exit 0
fi

# --- Context decay check ---
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    current_tokens=$(get_latest_context_tokens "$transcript_path")
    tracked_tokens=$(printf '%s\n' "$tracker" | jq --arg fp "$file_path" '.files[$fp].context_tokens // 0')

    decay_delta=$(( current_tokens - tracked_tokens ))

    if [[ "$decay_delta" -gt "$RRB_DECAY_THRESHOLD" ]]; then
        tracker=$(printf '%s\n' "$tracker" | jq -c --arg fp "$file_path" 'del(.files[$fp])')
        save_tracker "$tracker_file" "$tracker"
        debug_log "ALLOW ${file_path} — context decay exceeded (${decay_delta}/${RRB_DECAY_THRESHOLD})"
        exit 0
    fi
fi

# --- Range coverage check ---
if [[ -n "$offset" && -n "$limit" ]]; then
    req_start="$offset"
    req_end=$(( offset + limit - 1 ))
else
    req_start=1
    req_end="null"
fi

if is_range_covered "$tracker" "$file_path" "$req_start" "$req_end"; then
    if [[ "$req_end" == "null" ]]; then
        range_desc="(full file)"
    else
        range_desc="lines ${req_start}-${req_end}"
    fi

    # Check if this is a second attempt after a previous block
    was_blocked=$(printf '%s\n' "$tracker" | jq -r --arg fp "$file_path" '.files[$fp].was_blocked // false')

    if [[ "$was_blocked" == "true" ]]; then
        debug_log "ALLOW ${file_path}:${req_start}-${req_end} — forced re-read (second attempt after block)"
        exit 0
    fi

    # First block: set was_blocked flag and deny
    tracker=$(printf '%s\n' "$tracker" | jq -c --arg fp "$file_path" '.files[$fp].was_blocked = true')
    save_tracker "$tracker_file" "$tracker"

    debug_log "DENY ${file_path}:${req_start}-${req_end} — fully covered, hash unchanged"

    deny_msg="File ${file_path} ${range_desc} already read and unchanged."

    if [[ "$RRB_VERBOSE_DENY" == "true" && -n "${decay_delta:-}" ]]; then
        deny_msg="${deny_msg}
Context decay: ${decay_delta}/${RRB_DECAY_THRESHOLD} tokens since read. Hash unchanged."
    fi

    deny_msg="${deny_msg}
If Write/Edit is blocked because the file was \"modified since read\", retry this read — a second attempt will be allowed."

    printf '%s\n' "$deny_msg" >&2
    exit 2
fi

debug_log "ALLOW ${file_path}:${req_start}-${req_end} — partial coverage"
exit 0
