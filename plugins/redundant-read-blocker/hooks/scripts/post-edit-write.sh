#!/bin/bash
# PostToolUse Edit/Write hook: invalidate tracking for modified file.
# Removes the file entry from ALL agent trackers in the current session.
#
# Exit codes:
#   0 - Always (PostToolUse hooks should not block)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$SESSION_ID" || -z "$FILE_PATH" ]]; then
    exit 0
fi

load_config "$CWD"

SESSION_PATH=$(session_dir "$CLAUDE_PLUGIN_DATA" "$SESSION_ID")

if [[ ! -d "$SESSION_PATH" ]]; then
    exit 0
fi

# Remove file entry from all agent trackers in this session
for tracker_file in "${SESSION_PATH}"/read-tracker-*.json; do
    [[ -f "$tracker_file" ]] || continue

    TRACKER=$(cat "$tracker_file")

    # Check if file is tracked before writing
    HAS_FILE=$(echo "$TRACKER" | jq --arg fp "$FILE_PATH" '.files | has($fp)')
    if [[ "$HAS_FILE" == "true" ]]; then
        UPDATED=$(echo "$TRACKER" | jq -c --arg fp "$FILE_PATH" 'del(.files[$fp])')
        echo "$UPDATED" > "$tracker_file"
        debug_log "INVALIDATE ${FILE_PATH} (Edit/Write) in $(basename "$tracker_file")"
    fi
done

exit 0