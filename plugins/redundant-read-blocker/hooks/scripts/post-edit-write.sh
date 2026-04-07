#!/bin/bash
# PostToolUse Edit/Write hook: invalidate tracking for modified file.
# Removes the file entry from ALL agent trackers in the current session.
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
    IFS= read -r cwd
    IFS= read -r file_path
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.cwd // ""),
    (.tool_input.file_path // "")
')

if [[ -z "$session_id" || -z "$file_path" ]]; then
    exit 0
fi

load_config "$cwd"

session_path=$(session_dir "$CLAUDE_PLUGIN_DATA" "$session_id")

if [[ ! -d "$session_path" ]]; then
    exit 0
fi

# Remove file entry from all agent trackers in this session
for tracker_file in "${session_path}"/read-tracker-*.json; do
    [[ -f "$tracker_file" ]] || continue

    tracker=$(load_tracker "$tracker_file")

    # Check if file is tracked before writing
    has_file=$(printf '%s\n' "$tracker" | jq --arg fp "$file_path" '.files | has($fp)')
    if [[ "$has_file" == "true" ]]; then
        updated=$(printf '%s\n' "$tracker" | jq -c --arg fp "$file_path" 'del(.files[$fp])')
        save_tracker "$tracker_file" "$updated"
        debug_log "INVALIDATE ${file_path} (Edit/Write) in $(basename "$tracker_file")"
    fi
done

exit 0
