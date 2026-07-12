@README.md

## Directory & File Structure

```
plugins/commit-message-writer-extension-setup/
├── .codex-plugin/plugin.json
├── .claude-plugin/plugin.json
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── setting-up-commit-message-writer-extension/
        └── SKILL.md
```

## Component Overview

This plugin provides:
- **Skill** (`skills/setting-up-commit-message-writer-extension/`): provisions the overlay content file and the hook entries that deliver overlay content to `commit-message-writer:writing-commit-messages` at runtime.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin.

## Relationship to commit-message-writer

The `commit-message-writer` plugin documents the *content shape* of an overlay (Extension Contract, Recognized Named Values). This plugin documents and executes the *delivery* of that content. The two plugins are independent; install both when a project wants extension content to reach the parent skill.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the setup workflow | `skills/setting-up-commit-message-writer-extension/SKILL.md` | Settings target choice, overlay content rules, idempotent settings merge |
| Modify canonical paths | `skills/setting-up-commit-message-writer-extension/SKILL.md` | `.claude/hook-contexts/`, root `AGENTS.override.md`, Claude hook templates |

## Testing

No automated tests. The skill's effects are validated by re-running it on an already-configured project (idempotent no-op) and by inspecting the resulting `settings.json` and overlay file.
