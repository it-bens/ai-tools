#!/bin/bash
# Enforces Opus model for Plan subagent.
# Requires maximum model capability for architectural planning.
#
# Exit codes:
#   0 - Allow (not Plan, or using Opus)
#   2 - Block (Plan without Opus)

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract subagent_type (empty if not a subagent call)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Only check Plan subagent calls
if [[ "$SUBAGENT_TYPE" != "Plan" ]]; then
  exit 0
fi

# Extract model (defaults to empty which means inherit is used)
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // empty')

# Allow only Opus
if [[ "$MODEL" == "opus" ]]; then
  exit 0
fi

# Block all other models
cat >&2 << 'EOF'
Blocked: Plan subagent requires Opus model.

The Plan agent inherits the parent model by default, which may be Haiku or Sonnet.
Complex architectural planning benefits from maximum reasoning depth.

Retry with model: "opus" in the Task call.
EOF

exit 2
