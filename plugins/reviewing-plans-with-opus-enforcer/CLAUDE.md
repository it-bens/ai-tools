@README.md

## Directory & File Structure

```
plugins/reviewing-plans-with-opus-enforcer/
├── README.md
├── CLAUDE.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/
        └── enforce-opus-skill.sh
```

## Component Overview

This plugin provides:
- **PreToolUse Hook** (`hooks/hooks.json`) — intercepts Skill tool calls
- **Validation Script** (`hooks/scripts/enforce-opus-skill.sh`) — blocks `reviewing-plans` invocation when not on Opus

**No commands, agents, skills, or MCP servers** — hooks-only plugin.

## Key Logic

The script:

1. Parses `tool_input.skill` and `transcript_path` from the hook input.
2. Returns immediately (`exit 0`) if the invoked skill name does not end with `reviewing-plans`.
3. Tails the transcript JSONL and extracts the most recent `.message.model` value.
4. Allows the call if the model contains `opus`; blocks otherwise.

### Why transcript parsing

Skill invocations do not carry a `tool_input.model` field the way Task subagent calls do. The current model is not exposed directly in PreToolUse input. The transcript at `transcript_path` is the only reliable signal available within hook constraints — every assistant turn writes its `message.model`, and `tail` keeps the read bounded for large sessions.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Change allowed models | `enforce-opus-skill.sh` | Edit the `*opus*` glob match |
| Modify block message | `enforce-opus-skill.sh` | Edit heredoc after `cat >&2` |
| Adjust hook timeout | `hooks.json` | `timeout` field (default: 5s) |
| Change which skill is enforced | `enforce-opus-skill.sh` | Edit the regex matching `tool_input.skill` |

## Manual Testing

```bash
# Should allow (not the targeted skill)
echo '{"tool_input": {"skill": "some-other-skill"}, "transcript_path": "/dev/null"}' \
  | ./hooks/scripts/enforce-opus-skill.sh
echo $?  # 0

# Should block (no transcript, can't determine model)
echo '{"tool_input": {"skill": "superpowers-additions:reviewing-plans"}, "transcript_path": "/dev/null"}' \
  | ./hooks/scripts/enforce-opus-skill.sh
echo $?  # 2

# Should allow (transcript shows opus)
TF=$(mktemp); printf '%s\n' '{"type":"assistant","message":{"model":"claude-opus-4-7"}}' > "$TF"
echo "{\"tool_input\": {\"skill\": \"reviewing-plans\"}, \"transcript_path\": \"$TF\"}" \
  | ./hooks/scripts/enforce-opus-skill.sh
echo $?  # 0
rm -f "$TF"

# Should block (transcript shows sonnet)
TF=$(mktemp); printf '%s\n' '{"type":"assistant","message":{"model":"claude-sonnet-4-6"}}' > "$TF"
echo "{\"tool_input\": {\"skill\": \"reviewing-plans\"}, \"transcript_path\": \"$TF\"}" \
  | ./hooks/scripts/enforce-opus-skill.sh
echo $?  # 2
rm -f "$TF"
```

## Integration Points

- `jq` dependency for JSON parsing
- Affects only Skill tool calls naming `reviewing-plans`
- Requires Claude Code restart after installation
- Hook reads only the last 500 lines of the transcript to stay within the 5-second timeout
