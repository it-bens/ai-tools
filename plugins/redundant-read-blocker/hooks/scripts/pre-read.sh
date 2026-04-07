#!/bin/bash
# PreToolUse Read hook: block redundant reads of unchanged files.
#
# Exit codes:
#   0 - Allow the read
#   2 - Block the read (deny message on stderr)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "main"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
OFFSET=$(echo "$INPUT" | jq -r '.tool_input.offset // empty')
LIMIT=$(echo "$INPUT" | jq -r '.tool_input.limit // empty')

if [[ -z "$SESSION_ID" || -z "$FILE_PATH" ]]; then
    exit 0
fi

load_config "$CWD"

TRACKER_FILE=$(tracker_path "$CLAUDE_PLUGIN_DATA" "$SESSION_ID" "$AGENT_ID")
TRACKER=$(load_tracker "$TRACKER_FILE")

# --- Step 5: Rewind detection ---
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    CURRENT_TRANSCRIPT_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
    STORED_TRANSCRIPT_SIZE=$(echo "$TRACKER" | jq '.transcript_size // 0')

    if [[ "$CURRENT_TRANSCRIPT_SIZE" -lt "$STORED_TRANSCRIPT_SIZE" ]]; then
        debug_log "Rewind detected (transcript: ${CURRENT_TRANSCRIPT_SIZE} < ${STORED_TRANSCRIPT_SIZE})"

        CURRENT_TOKENS=$(get_latest_context_tokens "$TRANSCRIPT_PATH")
        CURRENT_TOKENS=${CURRENT_TOKENS:-0}

        # Invalidate entries made after the rewind point
        TRACKER=$(echo "$TRACKER" | jq -c --argjson ct "$CURRENT_TOKENS" \
            '.files |= with_entries(select(.value.context_tokens <= $ct))')

        # Update transcript size
        TRACKER=$(echo "$TRACKER" | jq -c --argjson ts "$CURRENT_TRANSCRIPT_SIZE" \
            '.transcript_size = $ts')

        save_tracker "$TRACKER_FILE" "$TRACKER"
    fi
fi

# --- Step 6: File lookup ---
HAS_FILE=$(echo "$TRACKER" | jq --arg fp "$FILE_PATH" '.files | has($fp)')
if [[ "$HAS_FILE" != "true" ]]; then
    debug_log "ALLOW ${FILE_PATH} — not tracked"
    exit 0
fi

# --- Step 7: External change detection ---
TRACKED_MTIME=$(echo "$TRACKER" | jq --arg fp "$FILE_PATH" '.files[$fp].mtime')
CURRENT_MTIME=$(stat -f %m "$FILE_PATH" 2>/dev/null || stat -c %Y "$FILE_PATH" 2>/dev/null || echo "0")

if [[ "$CURRENT_MTIME" != "$TRACKED_MTIME" ]]; then
    # Invalidate and save
    TRACKER=$(echo "$TRACKER" | jq -c --arg fp "$FILE_PATH" 'del(.files[$fp])')
    save_tracker "$TRACKER_FILE" "$TRACKER"
    debug_log "ALLOW ${FILE_PATH} — mtime changed (${TRACKED_MTIME} → ${CURRENT_MTIME})"
    exit 0
fi

# --- Step 8: Context decay check ---
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    CURRENT_TOKENS=$(get_latest_context_tokens "$TRANSCRIPT_PATH")
    CURRENT_TOKENS=${CURRENT_TOKENS:-0}
    TRACKED_TOKENS=$(echo "$TRACKER" | jq --arg fp "$FILE_PATH" '.files[$fp].context_tokens // 0')

    DECAY_DELTA=$(( CURRENT_TOKENS - TRACKED_TOKENS ))

    if [[ "$DECAY_DELTA" -gt "$RRB_DECAY_THRESHOLD" ]]; then
        # Invalidate and save
        TRACKER=$(echo "$TRACKER" | jq -c --arg fp "$FILE_PATH" 'del(.files[$fp])')
        save_tracker "$TRACKER_FILE" "$TRACKER"
        debug_log "ALLOW ${FILE_PATH} — context decay exceeded (${DECAY_DELTA}/${RRB_DECAY_THRESHOLD})"
        exit 0
    fi
fi

# --- Step 9: Range coverage check ---
if [[ -n "$OFFSET" && -n "$LIMIT" ]]; then
    REQ_START="$OFFSET"
    REQ_END=$(( OFFSET + LIMIT - 1 ))
else
    REQ_START=1
    REQ_END="null"
fi

if is_range_covered "$TRACKER" "$FILE_PATH" "$REQ_START" "$REQ_END"; then
    # Format range for message
    if [[ "$REQ_END" == "null" ]]; then
        RANGE_DESC="(full file)"
    else
        RANGE_DESC="lines ${REQ_START}-${REQ_END}"
    fi

    debug_log "DENY ${FILE_PATH}:${REQ_START}-${REQ_END} — fully covered, mtime unchanged"

    # Build deny message
    DENY_MSG="File ${FILE_PATH} ${RANGE_DESC} already read and unchanged."

    if [[ "$RRB_VERBOSE_DENY" == "true" && -n "${DECAY_DELTA:-}" ]]; then
        DENY_MSG="${DENY_MSG}
Context decay: ${DECAY_DELTA}/${RRB_DECAY_THRESHOLD} tokens since read. Mtime unchanged."
    fi

    DENY_MSG="${DENY_MSG}
If you need to re-read after edits, the file will be automatically unblocked."

    echo "$DENY_MSG" >&2
    exit 2
fi

debug_log "ALLOW ${FILE_PATH}:${REQ_START}-${REQ_END} — partial coverage"
exit 0