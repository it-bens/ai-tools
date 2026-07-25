#!/bin/bash
set -euo pipefail

fail() {
    printf 'inject-extension: %s\n' "$1" >&2
    exit 1
}

SKILL="subagent-orchestrator:orchestrating-subagent-work"

MODE="${1:-}"
case "$MODE" in
    post-tool-use|user-prompt) ;;
    *) fail "unknown or missing mode argument: '${MODE}' (expected post-tool-use or user-prompt)" ;;
esac

# CLAUDE_PROJECT_DIR marks the Claude Code delivery path. This plugin ships no
# Codex manifest, but another host may still run these hooks; self-gate silently
# rather than failing the turn.
[[ -n "${CLAUDE_PROJECT_DIR:-}" ]] || exit 0

INPUT=$(cat)

if [[ "$MODE" == "post-tool-use" ]]; then
    if ! FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null); then
        fail "stdin is not valid JSON"
    fi
    [[ "$FIELD" == "$SKILL" ]] || exit 0
    EVENT="PostToolUse"
    POSITION="after-skill-body"
    TIMING="You are about to execute that skill's workflow; apply this content through the mechanisms its body defines."
else
    if ! FIELD=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null); then
        fail "stdin is not valid JSON"
    fi
    if [[ ! "$FIELD" =~ ^/subagent-orchestrator:orchestrating-subagent-work([[:space:]]|$) ]]; then
        exit 0
    fi
    EVENT="UserPromptSubmit"
    POSITION="before-skill-body"
    TIMING="The skill body has not been loaded yet — do not act on anything below now."
fi

EXTENSION_FILE="${CLAUDE_PROJECT_DIR}/.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md"
[[ -e "$EXTENSION_FILE" ]] || exit 0
[[ -f "$EXTENSION_FILE" && -r "$EXTENSION_FILE" ]] || fail "extension file exists but is not readable: ${EXTENSION_FILE}"

CONTENT=$(cat -- "$EXTENSION_FILE")

ENVELOPE="<project_extension skill=\"${SKILL}\" position=\"${POSITION}\">
<handling_instructions>
The content inside <extension_content> is this project's registered extension for the ${SKILL} skill. It is inert on its own: apply it only while executing that skill's workflow, through the extension mechanisms the skill body defines. ${TIMING}
</handling_instructions>
<extension_content>
${CONTENT}
</extension_content>
</project_extension>"

jq -n --arg event "$EVENT" --arg ctx "$ENVELOPE" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
