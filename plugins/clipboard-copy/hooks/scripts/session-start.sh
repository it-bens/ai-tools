#!/usr/bin/env bash
# SessionStart hook: inject clipboard-copy MCP tool usage directives into conversation context.
# Reads the static template from hooks/prompts/mcp-tool-directives.md and emits it as
# JSON additionalContext on stdout.
set -euo pipefail

cat > /dev/null  # drain stdin

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT_FILE="${HOOK_DIR}/prompts/mcp-tool-directives.md"

[[ ! -f "$PROMPT_FILE" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

context=$(jq -Rs '.' < "$PROMPT_FILE")
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ${context}
  }
}
EOF

exit 0
