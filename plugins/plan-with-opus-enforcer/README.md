# Plan with Opus Enforcer

Enforces Opus model for the Plan subagent.

## Quick Start

```bash
/plugin install plan-with-opus-enforcer@it-bens
```

**Restart Claude Code** after installation for hooks to take effect.

## Why This Plugin

The built-in Plan subagent uses **inherit by default**, which means it uses whatever model the parent conversation uses. When the parent uses Haiku or Sonnet, the Plan agent also uses that model, which may not provide optimal reasoning depth for complex architectural decisions.

This plugin enforces Opus for Plan, ensuring maximum reasoning capability for:

- **Deep architectural analysis** - Thorough evaluation of system design
- **Comprehensive edge case coverage** - Better anticipation of failure modes
- **Detailed implementation planning** - More complete step-by-step guidance
- **Nuanced trade-off evaluation** - Sophisticated cost-benefit analysis

## Behavior

| Model           | Allowed? |
|-----------------|----------|
| `opus`          | Allowed  |
| Everything else | Blocked  |

When blocked, Claude receives guidance to retry with Opus.

## How It Works

PreToolUse hook intercepts `Task` tool calls and checks:
1. Is `subagent_type` equal to `"Plan"`?
2. Is `model` set to `"opus"`?

If not Opus, exits with code 2 (block) and helpful message.

## Requirements

- `jq` (usually pre-installed)

## Related

- [plan-with-sonnet-enforcer](../plan-with-sonnet-enforcer/) - Alternative: enforces Sonnet instead
- [explore-with-opus-enforcer](../explore-with-opus-enforcer/) - Similar plugin for Explore agent
- [Claude Code Subagents Docs](https://code.claude.com/docs/en/sub-agents)

## License

MIT
