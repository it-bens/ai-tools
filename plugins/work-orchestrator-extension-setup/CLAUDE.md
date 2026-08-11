@README.md

## Directory & File Structure

```
plugins/work-orchestrator-extension-setup/
├── .claude-plugin/plugin.json
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── setting-up-work-orchestrator-extension/
        └── SKILL.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/setting-up-work-orchestrator-extension/`): asks which of the parent plugin's skills the project extends, explores the target project, drafts evidence-backed extension proposals (including the session topology, which comes from the user conversationally), refines them conversationally, and writes one extension file per selected skill under `.claude/extensions/work-orchestrator/`. Re-sync mode audits existing files for drift.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin. Claude Code only, matching the parent plugin.

## Relationship to work-orchestrator

The `work-orchestrator` plugin owns the extension contract in its `EXTENSION.md` (file layout, both mechanisms, the per-skill position tables and recognized-values tables, the non-extendable surfaces) and ships the delivery hooks. This plugin executes the *exploration, drafting, and writing* of extension content. The two plugins are independent; install both when a project wants extension content authored for it.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the setup workflow | `skills/setting-up-work-orchestrator-extension/SKILL.md` | Fresh vs re-sync mode, probe checklists, the four guards, conversational refinement |
| Modify the canonical paths | `skills/setting-up-work-orchestrator-extension/SKILL.md` | `.claude/extensions/work-orchestrator/orchestrating-subagent-work.md`, `.claude/extensions/work-orchestrator/orchestrating-session-work.md` |

## Maintenance Rules

- The Step 4 mechanism list and the Step 6 position names mirror `work-orchestrator`'s `EXTENSION.md`. When the parent adds, renames, or retires a named value or a position, update both here and there in the same change.
- The four guards in Step 4 are the reason this skill exists rather than a free-form "write me an extension" prompt. A change that relaxes one needs a corresponding change to the parent contract, not a local edit.

## Testing

No automated tests. The skill's effects are validated by re-running it on an already-configured project (idempotent no-op), running re-sync on an unchanged project (no proposals), and inspecting the resulting extension file against the parent plugin's template.
