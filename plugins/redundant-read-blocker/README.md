# Redundant Read Blocker

Prevents wasteful re-reads of unchanged files by tracking what was already read and blocking redundant Read tool calls.

## How It Works

The plugin uses Claude Code hooks to track every file read, then blocks subsequent reads when the content hasn't changed. This reduces context bloat and wasted tool calls.

**Blocking conditions** (all must be true):
- File was previously read in this session
- File content has not changed (md5 hash unchanged)
- Context hasn't decayed past the threshold
- Requested line range is fully covered by previous reads

**Automatic unblocking:**
- File is edited (via Edit or Write tool)
- File content changes (detected via md5 hash)
- Context grows past the decay threshold
- Session compacts or restarts
- User rewinds conversation (Esc)
- Second read attempt after a block (escape hatch for Edit/Write deadlocks)

## Installation

```bash
/plugin install redundant-read-blocker
```

Requires `jq` to be installed.

## Configuration

Create `.claude/redundant-read-blocker.json` in your project (optional):

```json
{
  "decay_threshold": 80000,
  "debug": false,
  "verbose_deny": false
}
```

| Field | Default | Description |
|-------|---------|-------------|
| `decay_threshold` | `80000` | Tokens of context growth before a read is considered "forgotten" and allowed again. Increase for 1M context windows. |
| `debug` | `false` | Log all block/allow decisions to stderr with `[RRB]` prefix. |
| `verbose_deny` | `false` | Include context decay stats in the deny message shown to Claude. |

Without a config file, all defaults apply.

## Context Decay

Claude's recall degrades as context grows. The plugin tracks how many tokens have been added to the context since each file was read. When the growth exceeds `decay_threshold`, the read is considered "forgotten" and allowed again.

The default threshold (80,000 tokens) is conservative for 200K context windows (~40%). For 1M context windows, consider increasing to 300,000-400,000.

**Limitation:** The plugin cannot detect the active context window size. The `context_window.context_window_size` field is available to status line scripts but not to hooks. Users must configure `decay_threshold` manually based on their window size.

## Debug Mode

Set `"debug": true` to see all decisions:

```
[RRB] ALLOW /src/main.ts:1-100 — not tracked
[RRB] DENY /src/main.ts:1-50 — fully covered, hash unchanged
[RRB] ALLOW /src/main.ts:1-100 — content changed (hash d41d8cd9 -> a1b2c3d4)
[RRB] ALLOW /src/main.ts:1-100 — context decay exceeded (85000/80000)
```

## Future Improvements

- **Range-specific hashing:** Currently the entire file is hashed on each check. A future version could hash only the previously-read line ranges for more precise invalidation — a change outside the tracked ranges would not trigger a re-read. This would require extracting and hashing the same line ranges on each check, with complexity around range merging.