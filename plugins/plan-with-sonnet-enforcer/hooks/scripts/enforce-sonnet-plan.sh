#!/bin/bash
# Enforces Sonnet model for Plan subagent.
# Ensures thorough architectural reasoning during planning.
#
# Exit codes:
#   0 - Allow (not Plan, or using Sonnet)
#   2 - Block (Plan without Sonnet)

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

# Allow only Sonnet
if [[ "$MODEL" == "sonnet" ]]; then
  exit 0
fi

# Block all other models
cat >&2 << 'EOF'
Blocked: Plan subagent requires Sonnet model.

The Plan agent inherits the parent model by default, which may be Haiku.
Haiku can produce shallower architectural reasoning and miss important details.

Retry with model: "sonnet" in the Task call.
EOF

exit 2
