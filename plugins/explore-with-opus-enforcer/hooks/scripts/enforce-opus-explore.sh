#!/bin/bash
# Enforces Opus model for Explore subagent.
# Requires maximum model capability for codebase exploration.
#
# Exit codes:
#   0 - Allow (not Explore, or using Opus)
#   2 - Block (Explore without Opus)

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

# Allow only Opus
if [[ "$MODEL" == "opus" ]]; then
  exit 0
fi

# Block all other models
cat >&2 << 'EOF'
Blocked: Explore subagent requires Opus model.

The default Haiku model produces lossy summaries that lose important context.

Retry with model: "opus" in the Task call.
EOF

exit 2
