#!/bin/bash
# Enforces Sonnet model for Explore subagent.
# Haiku produces lossy summaries that lose important context.
#
# Exit codes:
#   0 - Allow (not Explore, or using Sonnet)
#   2 - Block (Explore without Sonnet)

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract subagent_type (empty if not a subagent call)
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

# Only check Explore subagent calls
if [[ "$SUBAGENT_TYPE" != "Explore" ]]; then
  exit 0
fi

# Extract model (defaults to empty which means Haiku is used)
MODEL=$(echo "$INPUT" | jq -r '.tool_input.model // empty')

# Allow only Sonnet
if [[ "$MODEL" == "sonnet" ]]; then
  exit 0
fi

# Block all other models
cat >&2 << 'EOF'
Blocked: Explore subagent requires Sonnet model.

The default Haiku model produces lossy summaries that lose important context
the main model needs for accurate reasoning.

Alternatives:
1. Retry with model: "sonnet" in the Task call
2. Use tools directly: Glob, Grep, and Read provide full context
EOF

exit 2
