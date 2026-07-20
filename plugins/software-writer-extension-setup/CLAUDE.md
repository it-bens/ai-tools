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

- **Skill** (`skills/setting-up-software-writer-extension/`): explores the target project, drafts evidence-backed extension proposals (inline and reference-like), refines them conversationally, writes the per-skill extension files under `.claude/extensions/software-writer/`, and provisions the Codex `AGENTS.override.md` delivery. Re-sync mode audits existing extension files for drift and migrates v1 (`.claude/hook-contexts/` plus settings hook entries) setups.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin.

## Relationship to software-writer

The `software-writer` plugin owns the extension contract in its `EXTENSION.md` (extension file layout, both mechanisms, reference-like extensions, one Recognized Named Values table per skill) and, from 2.0.0, ships the Claude Code delivery itself. This plugin executes the *exploration, drafting, and writing* of extension content, plus the Codex delivery and the v1 migration. The two plugins are independent; install both when a project wants extension content authored for it.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the setup workflow | `skills/setting-up-software-writer-extension/SKILL.md` | Fresh vs re-sync mode, probe checklists, prescriptive guard, reference-like entries, conversational refinement, v1 migration |
| Modify canonical paths or delivery | `skills/setting-up-software-writer-extension/SKILL.md` | `.claude/extensions/software-writer/<skill>.md`, root `AGENTS.override.md`, v1 artifact detection and removal |

## Testing

No automated tests. The skill's effects are validated by re-running it on an already-configured project (idempotent no-op), running re-sync on an unchanged project (no proposals), running re-sync on a v1-provisioned project (migration proposals), and inspecting the resulting extension files and `AGENTS.override.md`.
