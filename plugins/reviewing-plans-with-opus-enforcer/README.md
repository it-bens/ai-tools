# Reviewing Plans with Opus Enforcer

Enforces Opus model for the `reviewing-plans` skill from [`superpowers-additions`](../superpowers-additions/).

## Quick Start

```bash
/plugin install superpowers-additions@itb-ai-tools
/plugin install reviewing-plans-with-opus-enforcer@itb-ai-tools
```

**Restart Claude Code** after installation for hooks to take effect.

## Why This Plugin

Plan review depends on reasoning depth that lower-tier models do not reliably deliver. The skill walks four lenses, classifies findings into five labels, and routes between silent fixes, mechanical corrections, and decisions — all of which degrade noticeably on Sonnet or Haiku, especially the scope-skepticism lens and the citable-source test.

The skill itself does not pin a model in its frontmatter — model selection lives outside the skill so that users who manage `/model` themselves are not forced into Opus. This plugin is the opt-in companion that adds enforcement.

Install this plugin if you want enforcement; skip it if you prefer to manage model selection yourself.

## Behavior

| Active session model | Allowed? |
|----------------------|----------|
| `opus` (any variant) | Allowed  |
| Everything else      | Blocked  |
| Cannot be determined | Blocked  |

When blocked, the user receives a message guiding them to switch via `/model opus` and re-invoke the skill.

## How It Works

PreToolUse hook intercepts `Skill` tool calls and:

1. Checks whether the invoked skill name ends with `reviewing-plans` (matches both bare and plugin-namespaced forms).
2. Reads the most recent `message.model` entry from the session transcript (`transcript_path` in the hook input).
3. Allows if the model name contains `opus`; blocks otherwise.

The transcript-based detection is necessary because Skill invocations — unlike Task subagent calls — do not carry a `tool_input.model` field. The hook reads only the tail of the transcript to stay within the 5-second hook timeout.

## Requirements

- `jq` (usually pre-installed)
- The skill from `superpowers-additions` (the enforcer is a no-op without it)

## Related

- [superpowers-additions](../superpowers-additions/) — the plugin shipping the `reviewing-plans` skill this enforcer targets
- [plan-with-opus-enforcer](../plan-with-opus-enforcer/) — analogous enforcer for the Plan subagent (different mechanism: subagent-call `model` field)
- [explore-with-opus-enforcer](../explore-with-opus-enforcer/) — analogous enforcer for the Explore subagent

## License

MIT
