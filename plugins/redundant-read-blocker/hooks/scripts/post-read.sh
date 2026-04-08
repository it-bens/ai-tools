#!/bin/bash
# PostToolUse Read hook: record allowed reads with range merge.
#
# Exit codes:
#   0 - Always (PostToolUse hooks should not block)

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
    IFS= read -r start_line
    IFS= read -r total_lines
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.agent_id // "main"),
    (.cwd // ""),
    (.transcript_path // ""),
    (.tool_input.file_path // ""),
    (.tool_input.offset // ""),
    (.tool_input.limit // ""),
    (.tool_response.file.startLine // ""),
    (.tool_response.file.totalLines // "")
')

if [[ -z "$session_id" || -z "$file_path" || -z "$start_line" || -z "$total_lines" ]]; then
    exit 0
fi

load_config "$cwd"

tracker_file=$(tracker_path "$CLAUDE_PLUGIN_DATA" "$session_id" "$agent_id")
tracker=$(load_tracker "$tracker_file")

# Compute new range (match pre-read.sh: both offset AND limit required for bounded range)
if [[ -n "$offset" && -n "$limit" ]]; then
    new_start="$start_line"
    new_end=$(( start_line + total_lines - 1 ))
else
    new_start=1
    new_end="null"
fi

# Get existing ranges or empty array
existing_ranges=$(printf '%s\n' "$tracker" | jq -c --arg fp "$file_path" '.files[$fp].ranges // []')

# Append new range and merge
merged_ranges=$(printf '%s\n' "$existing_ranges" | jq -c --argjson s "$new_start" --argjson e "$new_end" \
    '. + [{start: $s, end: $e}]' | merge_ranges)

# Get file content hash
file_hash=$(file_fingerprint "$file_path")
if [[ -z "$file_hash" ]]; then
    debug_log "SKIP recording ${file_path} — hash failed"
    exit 0
fi

# Get transcript metadata
transcript_size=0
context_tokens=0
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    transcript_size=$(wc -c < "$transcript_path" | tr -d ' ')
    context_tokens=$(get_latest_context_tokens "$transcript_path")
fi

# Update tracker
tracker=$(printf '%s\n' "$tracker" | jq -c \
    --arg fp "$file_path" \
    --argjson ranges "$merged_ranges" \
    --arg hash "$file_hash" \
    --argjson ts "$transcript_size" \
    --argjson ct "$context_tokens" \
    '.transcript_size = $ts |
     .files[$fp] = {ranges: $ranges, hash: $hash, context_tokens: $ct}')

save_tracker "$tracker_file" "$tracker"

debug_log "RECORD ${file_path}:${new_start}-${new_end} (hash=${file_hash}, tokens=${context_tokens})"

exit 0
