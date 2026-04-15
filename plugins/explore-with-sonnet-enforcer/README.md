# Explore with Sonnet Enforcer

Enforces Sonnet model for the Explore subagent.

## Quick Start

```bash
/plugin install explore-with-sonnet-enforcer@itb-ai-tools
```

**Restart Claude Code** after installation for hooks to take effect.

## Why This Plugin

The built-in Explore subagent uses **Haiku by default**, which causes:

- **Lossy compression** - Summaries lose important context
- **Reduced accuracy** - Weaker model misses nuances
- **Research loops** - Can cause endless compact-and-research cycles

This plugin enforces Sonnet for Explore, ensuring better results.

## Behavior

| Model           | Allowed? |
|-----------------|----------|
| `sonnet`        | Allowed  |
| Everything else | Blocked  |

When blocked, Claude receives guidance to retry with Sonnet.

## How It Works

PreToolUse hook intercepts `Task` tool calls and checks:
1. Is `subagent_type` equal to `"Explore"`?
2. Is `model` set to `"sonnet"`?

If not Sonnet, exits with code 2 (block) and helpful message.

## Requirements

- `jq` (usually pre-installed)

## Related

- [explore-with-opus-enforcer](../explore-with-opus-enforcer/) - Alternative: enforces Opus instead
- [Claude Code Subagents Docs](https://code.claude.com/docs/en/sub-agents)

## References

- [Lossy compression issue](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Subagent documentation gaps](https://github.com/anthropics/claude-code/issues/10469)

## License

MIT
