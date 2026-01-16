# Native Tools Enforcer

Enforces use of Claude Code native tools instead of bash equivalents via PreToolUse hook.

## Quick Start

```bash
/plugin install native-tools-enforcer@it-bens
```

**Restart Claude Code** after installation for hooks to take effect.

## Features

- **PreToolUse Hook** - Intercepts Bash tool calls before execution
- **Pattern Matching** - Blocks commands that should use native tools
- **Helpful Messages** - Suggests correct native tool with explanation

## Blocked Commands

| Bash Command | Native Alternative |
|--------------|-------------------|
| `cat`, `head`, `tail`, `less`, `more` | **Read** tool |
| `find`, `locate` | **Glob** tool |
| `grep`, `rg`, `ag`, `ack` | **Grep** tool |
| `echo >`, `printf >`, `cat >`, `tee` | **Write** tool |
| `sed`, `awk`, `perl -i` | **Edit** tool |

> **Note:** Heredocs piped to commands (`cat << EOF | pbcopy`) are allowed since they don't write to files.

### Piped grep/rg Behavior

Piped grep is **selectively blocked** based on whether the source command reads file contents:

| Source Command | Example | Blocked? | Reason |
|----------------|---------|----------|--------|
| File viewers | `cat file.txt \| grep pattern` | ✅ Yes | Use Grep tool |
| Binary inspectors | `strings binary \| grep pattern` | ✅ Yes | Use Grep tool |
| Compressed viewers | `zcat file.gz \| grep pattern` | ✅ Yes | Use Grep tool |
| Archive listings | `unzip -l \| grep pattern` | ❌ No | Metadata, not file content |
| Git commands | `git log \| grep feat` | ❌ No | Command output |
| Process lists | `ps aux \| grep node` | ❌ No | System metadata |
| Package managers | `npm ls \| grep lodash` | ❌ No | Command output |

This distinction exists because the Grep tool searches files on disk—it cannot filter command output.

## Warned Commands (Not Blocked)

| Bash Command | Suggestion | Why Not Blocked |
|--------------|------------|-----------------|
| `ls`, `ls -a`, `ls -R` | **Glob** tool | Claude Code docs recommend `ls` for directories |
| `ls -l`, `ls -la` | (none) | Native tools can't provide file metadata |

Simple `ls` commands trigger a tip suggesting Glob, but are allowed because Claude Code's own documentation recommends `ls` for directory operations.

## Why This Plugin

- Native tools don't require approval; bash commands do
- Native tools integrate better with Claude Code context
- Agents via Task tool respect hooks but may ignore CLAUDE.md rules ([#10056](https://github.com/anthropics/claude-code/issues/10056))

## Requirements

- `jq` (usually pre-installed)

## Developer Guide

See `CLAUDE.md` for plugin architecture and modification guidance.

## License

MIT
