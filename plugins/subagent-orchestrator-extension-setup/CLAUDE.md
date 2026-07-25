@README.md

## Directory & File Structure

```
plugins/subagent-orchestrator-extension-setup/
├── .claude-plugin/plugin.json
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── setting-up-subagent-orchestrator-extension/
        └── SKILL.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/setting-up-subagent-orchestrator-extension/`): explores the target project, drafts evidence-backed extension proposals, refines them conversationally, and writes the extension file under `.claude/extensions/subagent-orchestrator/`. Re-sync mode audits an existing file for drift.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin. Claude Code only, matching the parent plugin.

## Relationship to subagent-orchestrator

The `subagent-orchestrator` plugin owns the extension contract in its `EXTENSION.md` (file layout, both mechanisms, the position table, the recognized-values table, the non-extendable surface) and, from 2.0.0, ships the delivery hooks. This plugin executes the *exploration, drafting, and writing* of extension content. The two plugins are independent; install both when a project wants extension content authored for it.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the setup workflow | `skills/setting-up-subagent-orchestrator-extension/SKILL.md` | Fresh vs re-sync mode, probe checklists, the four guards, conversational refinement |
| Modify the canonical path | `skills/setting-up-subagent-orchestrator-extension/SKILL.md` | `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md` |

## Maintenance Rules

- The Step 4 mechanism list and the Step 6 position names mirror `subagent-orchestrator`'s `EXTENSION.md`. When the parent adds, renames, or retires a named value or a position, update both here and there in the same change.
- The four guards in Step 4 are the reason this skill exists rather than a free-form "write me an extension" prompt. A change that relaxes one needs a corresponding change to the parent contract, not a local edit.

## Testing

No automated tests. The skill's effects are validated by re-running it on an already-configured project (idempotent no-op), running re-sync on an unchanged project (no proposals), and inspecting the resulting extension file against the parent plugin's template.
