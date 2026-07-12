#!/usr/bin/env bash
# Inject file-read MCP usage directives into the session context.
set -euo pipefail

cat > /dev/null

HOOK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="${HOOK_DIR}/prompts/mcp-tool-directives.md"

[[ ! -f "${PROMPT_FILE}" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

context=$(jq -Rs '.' < "${PROMPT_FILE}")
printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": %s\n  }\n}\n' "${context}"
