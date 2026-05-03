#!/bin/bash
# Enforces Opus model for the reviewing-plans skill.
# Plan review depends on reasoning depth that Sonnet/Haiku do not reliably deliver.
#
# Skill invocations do not carry a tool_input.model field, so the hook detects the
# active model by parsing the most recent message.model entry from the session
# transcript at transcript_path.
#
# Exit codes:
#   0 - Allow (skill is not reviewing-plans, or session is on Opus)
#   2 - Block (reviewing-plans on non-Opus, or model could not be determined)

set -euo pipefail

INPUT=$(cat)

# Parse all fields in one jq call
IFS=$'\t' read -r SKILL TRANSCRIPT_PATH < <(
    printf '%s' "$INPUT" | jq -r '[
        (.tool_input.skill // empty),
        (.transcript_path // empty)
    ] | @tsv'
)

# Only check reviewing-plans invocations (matches both bare and plugin-namespaced names).
if [[ ! "$SKILL" =~ ^([^:]+:)?reviewing-plans$ ]]; then
    exit 0
fi

# Read the most recent assistant model from the transcript tail.
# tail bounds the read so large transcripts do not blow the 5s hook timeout.
MODEL=""
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
    MODEL=$(tail -500 -- "$TRANSCRIPT_PATH" 2>/dev/null \
        | jq -r 'select(.message.model) | .message.model' 2>/dev/null \
        | tail -1 \
        || true)
fi

# Allow Opus (matches claude-opus-4-7, opus, etc.)
if [[ "$MODEL" == *opus* ]]; then
    exit 0
fi

# Block all other models, including the could-not-determine case.
cat >&2 << EOF
Blocked: reviewing-plans skill requires the Opus model.

Detected session model: ${MODEL:-(unknown)}

Plan review depends on reasoning depth that lower-tier models do not
reliably deliver — multi-claim audits, scope-skepticism heuristics, and
finding-classification gates lose accuracy on Sonnet/Haiku.

Switch with /model opus, then re-invoke the skill.

To run reviewing-plans without enforcement, uninstall the
reviewing-plans-with-opus-enforcer plugin.
EOF

exit 2
