@README.md

## Directory & File Structure

```
plugins/explore-with-opus-enforcer/
├── README.md
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/
        └── enforce-opus-explore.sh
```

## Component Overview

This plugin provides:
- **PreToolUse Hook** (`hooks/hooks.json`) - Intercepts Task tool calls
- **Validation Script** (`hooks/scripts/enforce-opus-explore.sh`) - Blocks Explore without Opus

**No commands, agents, skills, or MCP servers** - hooks-only plugin.

## Key Logic

The script checks two conditions:
1. `tool_input.subagent_type == "Explore"` - Only affects Explore agent
2. `tool_input.model` - Must be "opus" to pass

### Allowed Models
- `opus` - Pass

### Blocked Models
- `haiku` - Block (default when unspecified)
- `sonnet` - Block
- `inherit` - Block
- Empty/unset - Block (defaults to Haiku)

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Change allowed models | `enforce-opus-explore.sh` | Edit `if` condition |
| Modify block message | `enforce-opus-explore.sh` | Edit heredoc after `cat >&2` |
| Adjust hook timeout | `hooks.json` | `timeout` field (default: 5s) |

## Testing

BATS tests are located in `plugin-tests/explore-with-opus-enforcer/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all tests
.bats/bats-core/bin/bats plugin-tests/explore-with-opus-enforcer/

# Filter by tag
.bats/bats-core/bin/bats --filter-tags blocking plugin-tests/explore-with-opus-enforcer/
.bats/bats-core/bin/bats --filter-tags allow plugin-tests/explore-with-opus-enforcer/
```

### Manual Testing

```bash
# Should block (Haiku default)
echo '{"tool_input": {"subagent_type": "Explore"}}' | ./hooks/scripts/enforce-opus-explore.sh
echo $?  # Should be 2

# Should block (Sonnet)
echo '{"tool_input": {"subagent_type": "Explore", "model": "sonnet"}}' | ./hooks/scripts/enforce-opus-explore.sh
echo $?  # Should be 2

# Should allow (Opus)
echo '{"tool_input": {"subagent_type": "Explore", "model": "opus"}}' | ./hooks/scripts/enforce-opus-explore.sh
echo $?  # Should be 0

# Should allow (not Explore)
echo '{"tool_input": {"subagent_type": "Plan", "model": "haiku"}}' | ./hooks/scripts/enforce-opus-explore.sh
echo $?  # Should be 0
```

## Integration Points

- **jq** dependency for JSON parsing
- Affects Task tool calls (Explore subagent only)
- Requires Claude Code restart after installation
