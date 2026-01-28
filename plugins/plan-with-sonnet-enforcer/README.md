# Plan with Sonnet Enforcer

Enforces Sonnet model for the Plan subagent.

## Quick Start

```bash
/plugin install plan-with-sonnet-enforcer@it-bens
```

**Restart Claude Code** after installation for hooks to take effect.

## Why This Plugin

The built-in Plan subagent uses **inherit by default**, which means it uses whatever model the parent conversation uses. When the parent uses Haiku (for cost optimization), the Plan agent also uses Haiku, which can cause:

- **Shallower reasoning** - Less thorough architectural analysis
- **Missed edge cases** - Weaker at anticipating failure modes
- **Incomplete plans** - May skip important implementation details
- **Weaker trade-off analysis** - Less nuanced evaluation of options

This plugin enforces Sonnet for Plan, ensuring consistent planning quality.

## Behavior

| Model           | Allowed? |
|-----------------|----------|
| `sonnet`        | Allowed  |
| Everything else | Blocked  |

When blocked, Claude receives guidance to retry with Sonnet.

## How It Works

PreToolUse hook intercepts `Task` tool calls and checks:
1. Is `subagent_type` equal to `"Plan"`?
2. Is `model` set to `"sonnet"`?

If not Sonnet, exits with code 2 (block) and helpful message.

## Requirements

- `jq` (usually pre-installed)

## Related

- [plan-with-opus-enforcer](../plan-with-opus-enforcer/) - Alternative: enforces Opus instead
- [explore-with-sonnet-enforcer](../explore-with-sonnet-enforcer/) - Similar plugin for Explore agent
- [Claude Code Subagents Docs](https://code.claude.com/docs/en/sub-agents)

## License

MIT
