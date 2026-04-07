#!/bin/bash
# SessionStart hook: wipe tracking files on startup or compaction.
# Matcher: startup, compact
#
# Exit codes:
#   0 - Always (SessionStart hooks should not block)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$SESSION_ID" ]]; then
    exit 0
fi

load_config "$CWD"

SESSION_PATH=$(session_dir "$CLAUDE_PLUGIN_DATA" "$SESSION_ID")

debug_log "SessionStart: wiping tracking files in ${SESSION_PATH}"

# Delete all tracking files for this session
if [[ -d "$SESSION_PATH" ]]; then
    rm -f "${SESSION_PATH}"/read-tracker-*.json
fi

exit 0