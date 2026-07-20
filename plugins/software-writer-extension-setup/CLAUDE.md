@README.md

## Directory & File Structure

```
plugins/software-writer-extension-setup/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── setting-up-software-writer-extension/
        └── SKILL.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/setting-up-software-writer-extension/`): explores the target project, drafts evidence-backed overlay proposals, refines them conversationally, writes the per-skill overlay content files, and merges the delivery entries that expose them to the `software-writer` skills at runtime. Re-sync mode audits existing overlays for drift.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin.

## Relationship to software-writer

The `software-writer` plugin documents the *content shape* of an overlay in its `EXTENSION.md` (both extension mechanisms, one Recognized Named Values table per skill). This plugin executes the *exploration, drafting, and delivery* of that content. The two plugins are independent; install both when a project wants extension content to reach the parent skills.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the setup workflow | `skills/setting-up-software-writer-extension/SKILL.md` | Fresh vs re-sync mode, probe checklists, prescriptive guard, conversational refinement, idempotent settings merge |
| Modify canonical paths or delivery entries | `skills/setting-up-software-writer-extension/SKILL.md` | `.claude/hook-contexts/<skill>.md`, root `AGENTS.override.md`, per-skill hook command templates |

## Testing

No automated tests. The skill's effects are validated by re-running it on an already-configured project (idempotent no-op), running re-sync on an unchanged project (no proposals), and inspecting the resulting settings and overlay files.
