#!/usr/bin/env bash
# SessionStart hook: inject native-tool usage directives into conversation context.
# Mode is resolved via the same library as the PreToolUse hook, so the injected
# directives always match what the enforcement will actually do:
#   new    → directs Claude to Read/Write/Edit tools and bfs/ugrep in Bash
#   classic → directs Claude to Read/Write/Edit, Glob, and Grep tools
#   pass   → no injection (the PreToolUse hook passes through anyway)
set -euo pipefail

cat > /dev/null  # drain stdin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=./lib/detect-mode.sh
source "${SCRIPT_DIR}/lib/detect-mode.sh"
NTE_MODE=""
nte_resolve_mode

[[ "${NTE_MODE}" == "pass" ]] && exit 0

PROMPT_FILE="${HOOK_DIR}/prompts/native-tools-${NTE_MODE}.md"
[[ -f "${PROMPT_FILE}" ]] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

context=$(cat -- "${PROMPT_FILE}")
json_context=$(printf '%s' "${context}" | jq -Rs '.')

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ${json_context}
  }
}
EOF

exit 0
