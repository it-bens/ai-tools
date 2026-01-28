@README.md

## Directory & File Structure

```
plugins/plan-with-opus-enforcer/
├── README.md
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/
        └── enforce-opus-plan.sh
```

## Component Overview

This plugin provides:
- **PreToolUse Hook** (`hooks/hooks.json`) - Intercepts Task tool calls
- **Validation Script** (`hooks/scripts/enforce-opus-plan.sh`) - Blocks Plan without Opus

**No commands, agents, skills, or MCP servers** - hooks-only plugin.

## Key Logic

The script checks two conditions:
1. `tool_input.subagent_type == "Plan"` - Only affects Plan agent
2. `tool_input.model` - Must be "opus" to pass

### Allowed Models
- `opus` - Pass

### Blocked Models
- `haiku` - Block
- `sonnet` - Block
- `inherit` - Block
- Empty/unset - Block (defaults to inherit)

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Change allowed models | `enforce-opus-plan.sh` | Edit `if` condition |
| Modify block message | `enforce-opus-plan.sh` | Edit heredoc after `cat >&2` |
| Adjust hook timeout | `hooks.json` | `timeout` field (default: 5s) |

## Testing

BATS tests are located in `plugin-tests/plan-with-opus-enforcer/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all tests
.bats/bats-core/bin/bats plugin-tests/plan-with-opus-enforcer/

# Filter by tag
.bats/bats-core/bin/bats --filter-tags blocking plugin-tests/plan-with-opus-enforcer/
.bats/bats-core/bin/bats --filter-tags allow plugin-tests/plan-with-opus-enforcer/
```

### Manual Testing

```bash
# Should block (inherit default - no model specified)
echo '{"tool_input": {"subagent_type": "Plan"}}' | ./hooks/scripts/enforce-opus-plan.sh
echo $?  # Should be 2

# Should block (Sonnet)
echo '{"tool_input": {"subagent_type": "Plan", "model": "sonnet"}}' | ./hooks/scripts/enforce-opus-plan.sh
echo $?  # Should be 2

# Should block (Haiku)
echo '{"tool_input": {"subagent_type": "Plan", "model": "haiku"}}' | ./hooks/scripts/enforce-opus-plan.sh
echo $?  # Should be 2

# Should allow (Opus)
echo '{"tool_input": {"subagent_type": "Plan", "model": "opus"}}' | ./hooks/scripts/enforce-opus-plan.sh
echo $?  # Should be 0

# Should allow (not Plan)
echo '{"tool_input": {"subagent_type": "Explore", "model": "haiku"}}' | ./hooks/scripts/enforce-opus-plan.sh
echo $?  # Should be 0
```

## Integration Points

- **jq** dependency for JSON parsing
- Affects Task tool calls (Plan subagent only)
- Requires Claude Code restart after installation
