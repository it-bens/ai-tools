# Native Tools Enforcer

Enforces use of Claude Code's native search tools — the `Grep`/`Glob` tools on classic builds, and `ugrep`/`bfs` on native macOS/Linux builds — via a PreToolUse hook. Adapts to the detected build and passes through silently when neither toolchain is available.

## Quick Start

```bash
/plugin install native-tools-enforcer@itb-ai-tools
```

**Restart Claude Code** after installation for the hook to take effect. Then optionally run the setup skill:

> Set up native-tools-enforcer

The skill detects your OS, checks if `bfs` / `ugrep` are installed, and offers to install them if missing.

## Modes

| Mode | When | Blocking behavior |
|---|---|---|
| `new` | macOS/Linux with `bfs` + `ugrep` on PATH, **or** env var forced | Block `find`/`grep` family; suggest `bfs`/`ugrep` in Bash |
| `classic` | Windows (Cygwin / MinGW / MSYS) | Block `find`/`grep` family; suggest `Glob`/`Grep` tools |
| `pass` | macOS/Linux without `bfs`+`ugrep`; unknown OS | Hook exits 0, no block, no warning |

## Blocked Commands

| Bash Command | New-mode redirect | Classic-mode redirect |
|---|---|---|
| `cat`, `head`, `tail`, `less`, `more` | **Read** tool | **Read** tool |
| `find`, `locate` | **`bfs`** in Bash | **Glob** tool |
| `grep`, `rg`, `ag`, `ack` | **`ugrep`** in Bash | **Grep** tool |
| `echo >`, `printf >`, `cat >`, `| tee` | **Write** tool | **Write** tool |
| `sed`, `awk`, `perl -i` | **Edit** tool | **Edit** tool |

Heredocs piped to commands (`cat << EOF | pbcopy`) are allowed.

### Piped grep/rg Behavior

Piped grep is **selectively blocked** based on whether the source command reads file contents:

| Source | Example | Blocked? |
|---|---|---|
| File viewers | `cat file.txt \| grep pattern` | ✅ Yes (Read caught first) |
| Binary inspectors | `strings bin \| grep pattern` | ✅ Yes |
| Compressed viewers | `zcat file.gz \| grep pattern` | ✅ Yes |
| Archive listings | `unzip -l \| grep pattern` | ❌ No |
| Command output | `git log \| grep feat`, `ps \| grep node` | ❌ No |

## Warned Commands

| Bash Command | New mode | Classic mode |
|---|---|---|
| `ls`, `ls -a`, `ls -R` | No warning (no tool to suggest) | Warn: suggest Glob |
| `ls -l`, `ls -la` | No warning | No warning (needs metadata) |

## Configuration

### Environment variables

| Name | Value | Effect |
|---|---|---|
| `NATIVE_TOOLS_ENFORCER_FORCE_NEW` | any non-empty value | Forces `new` mode regardless of OS or binary availability. User is responsible for ensuring `bfs`/`ugrep` are installed — otherwise the hook will suggest tools that do not exist. Values like `"false"` or `"0"` are treated as **set** (any non-empty string); use the empty string or unset the variable to turn the override off. |
| `NATIVE_TOOLS_ENFORCER_DEBUG` | any non-empty value | Enables debug logging to `$CLAUDE_PLUGIN_DATA/debug.log`. TSV lines: `<timestamp> <session_id or "-"> <mode> <decision> <command truncated to 200 chars>`. Commands are logged verbatim — remove the log file if privacy is a concern. |

Set them in `~/.claude/settings.json`:

```json
{
  "env": {
    "NATIVE_TOOLS_ENFORCER_FORCE_NEW": "1"
  }
}
```

The `setting-up` skill automates this.

## Requirements

- `jq` (pre-installed on most systems).
- `bfs` and `ugrep` only needed for `new` mode. Not bundled with Claude Code.
  The setup skill can install them via `brew` (macOS) or print the right
  `sudo <pkg-mgr> install` line (Linux).

## Developer Guide

See `CLAUDE.md`.

## License

MIT
