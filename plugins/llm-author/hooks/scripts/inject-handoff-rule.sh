#!/bin/bash
set -euo pipefail

fail() {
    printf 'inject-handoff-rule: %s\n' "$1" >&2
    exit 1
}

SKILL="llm-author:writing-handoff-prompts"

MODE="${1:-}"
case "$MODE" in
    post-tool-use|user-prompt) ;;
    *) fail "unknown or missing mode argument: '${MODE}' (expected post-tool-use or user-prompt)" ;;
esac

# CLAUDE_PROJECT_DIR marks the Claude Code delivery path; another host may
# still run these hooks. Self-gate silently rather than failing the turn.
[[ -n "${CLAUDE_PROJECT_DIR:-}" ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULE_FILE="${SCRIPT_DIR}/../../rules/referent-verification.md"

INPUT=$(cat)

if [[ "$MODE" == "post-tool-use" ]]; then
    if ! FIELD=$(printf '%s' "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null); then
        fail "stdin is not valid JSON"
    fi
    [[ "$FIELD" == "$SKILL" ]] || exit 0
    EVENT="PostToolUse"
    PREAMBLE="Apply this rule to every referent the handoff prompt cites."
else
    if ! FIELD=$(printf '%s' "$INPUT" | jq -r '.prompt // empty' 2>/dev/null); then
        fail "stdin is not valid JSON"
    fi
    FIELD_LC=$(printf '%s' "$FIELD" | tr '[:upper:]' '[:lower:]')
    HANDOFF_RE='hand[- ]?off'
    [[ "$FIELD_LC" =~ $HANDOFF_RE ]] || exit 0
    EVENT="UserPromptSubmit"
    PREAMBLE="If this request asks for a handoff prompt, invoke the ${SKILL} skill with the Skill tool, and apply this rule to every referent the handoff cites."
fi

[[ -f "$RULE_FILE" && -r "$RULE_FILE" ]] || fail "rule file missing or unreadable: ${RULE_FILE}"

CONTENT=$(cat -- "$RULE_FILE")

CTX="<handoff_referent_rule>
${PREAMBLE}
${CONTENT}
</handoff_referent_rule>"

jq -n --arg event "$EVENT" --arg ctx "$CTX" \
    '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
