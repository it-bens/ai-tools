#!/bin/bash
# SessionStart hook: wipe tracking files on startup or compaction.
# Matcher: startup, compact
#
# Exit codes:
#   0 - Always (SessionStart hooks should not block)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

input=$(cat)

# Parse all input fields in a single jq invocation
{
    IFS= read -r session_id
    IFS= read -r cwd
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.cwd // "")
')

if [[ -z "$session_id" ]]; then
    exit 0
fi

load_config "$cwd"

session_path=$(session_dir "$CLAUDE_PLUGIN_DATA" "$session_id")

debug_log "SessionStart: wiping tracking files in ${session_path}"

# Delete all tracking files and stale temp files for this session
if [[ -d "$session_path" ]]; then
    rm -f "${session_path}"/read-tracker-*.json "${session_path}"/.rrb-tmp.*
fi

exit 0
