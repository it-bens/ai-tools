#!/bin/bash
# PostToolUse Read hook: record allowed reads with range merge.
#
# Exit codes:
#   0 - Always (PostToolUse hooks should not block)

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

START_LINE=$(echo "$INPUT" | jq -r '.tool_response.file.startLine // empty')
TOTAL_LINES=$(echo "$INPUT" | jq -r '.tool_response.file.totalLines // empty')

if [[ -z "$SESSION_ID" || -z "$FILE_PATH" || -z "$START_LINE" || -z "$TOTAL_LINES" ]]; then
    exit 0
fi

load_config "$CWD"

TRACKER_FILE=$(tracker_path "$CLAUDE_PLUGIN_DATA" "$SESSION_ID" "$AGENT_ID")
TRACKER=$(load_tracker "$TRACKER_FILE")

# Compute new range
if [[ -z "$OFFSET" && -z "$LIMIT" ]]; then
    NEW_START=1
    NEW_END="null"
else
    NEW_START="$START_LINE"
    NEW_END=$(( START_LINE + TOTAL_LINES - 1 ))
fi

# Get existing ranges or empty array
EXISTING_RANGES=$(echo "$TRACKER" | jq -c --arg fp "$FILE_PATH" '.files[$fp].ranges // []')

# Append new range and merge
MERGED_RANGES=$(echo "$EXISTING_RANGES" | jq -c --argjson s "$NEW_START" --argjson e "$NEW_END" \
    '. + [{start: $s, end: $e}]' | merge_ranges)

# Get file mtime
FILE_MTIME=$(stat -f %m "$FILE_PATH" 2>/dev/null || stat -c %Y "$FILE_PATH" 2>/dev/null || echo "0")

# Get transcript size
TRANSCRIPT_SIZE=0
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    TRANSCRIPT_SIZE=$(wc -c < "$TRANSCRIPT_PATH" | tr -d ' ')
fi

# Get context tokens
CONTEXT_TOKENS=0
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    local_tokens=$(get_latest_context_tokens "$TRANSCRIPT_PATH")
    [[ -n "$local_tokens" ]] && CONTEXT_TOKENS="$local_tokens"
fi

# Update tracker
TRACKER=$(echo "$TRACKER" | jq -c \
    --arg fp "$FILE_PATH" \
    --argjson ranges "$MERGED_RANGES" \
    --argjson mtime "$FILE_MTIME" \
    --argjson ts "$TRANSCRIPT_SIZE" \
    --argjson ct "$CONTEXT_TOKENS" \
    '.transcript_size = $ts |
     .files[$fp] = {ranges: $ranges, mtime: $mtime, context_tokens: $ct}')

save_tracker "$TRACKER_FILE" "$TRACKER"

debug_log "RECORD ${FILE_PATH}:${NEW_START}-${NEW_END} (tokens=${CONTEXT_TOKENS})"

exit 0