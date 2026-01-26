@README.md

## Directory & File Structure

```
plugins/explore-with-sonnet-enforcer/
├── README.md
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/
        └── enforce-sonnet-explore.sh
```

## Component Overview

This plugin provides:
- **PreToolUse Hook** (`hooks/hooks.json`) - Intercepts Task tool calls
- **Validation Script** (`hooks/scripts/enforce-sonnet-explore.sh`) - Blocks Explore with weak models

**No commands, agents, skills, or MCP servers** - hooks-only plugin.

## Key Logic

The script checks two conditions:
1. `tool_input.subagent_type == "Explore"` - Only affects Explore agent
2. `tool_input.model == "sonnet"` - Must be exactly "sonnet" to pass

### Allowed Models
- `sonnet` - Pass

### Blocked Models
- Everything else (haiku, opus, inherit, empty)

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Change allowed model | `enforce-sonnet-explore.sh` | Edit `if` condition |
| Modify block message | `enforce-sonnet-explore.sh` | Edit heredoc after `cat >&2` |
| Adjust hook timeout | `hooks.json` | `timeout` field (default: 5s) |

## Testing

BATS tests are located in `plugin-tests/explore-with-sonnet-enforcer/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all tests
.bats/bats-core/bin/bats plugin-tests/explore-with-sonnet-enforcer/

# Filter by tag
.bats/bats-core/bin/bats --filter-tags blocking plugin-tests/explore-with-sonnet-enforcer/
.bats/bats-core/bin/bats --filter-tags allow plugin-tests/explore-with-sonnet-enforcer/
```

### Manual Testing

```bash
# Should block (Haiku default)
echo '{"tool_input": {"subagent_type": "Explore"}}' | ./hooks/scripts/enforce-sonnet-explore.sh
echo $?  # Should be 2

# Should block (Opus)
echo '{"tool_input": {"subagent_type": "Explore", "model": "opus"}}' | ./hooks/scripts/enforce-sonnet-explore.sh
echo $?  # Should be 2

# Should allow (Sonnet)
echo '{"tool_input": {"subagent_type": "Explore", "model": "sonnet"}}' | ./hooks/scripts/enforce-sonnet-explore.sh
echo $?  # Should be 0

# Should allow (not Explore)
echo '{"tool_input": {"subagent_type": "Plan", "model": "haiku"}}' | ./hooks/scripts/enforce-sonnet-explore.sh
echo $?  # Should be 0
```

## Integration Points

- **jq** dependency for JSON parsing
- Affects Task tool calls (Explore subagent only)
- Requires Claude Code restart after installation
