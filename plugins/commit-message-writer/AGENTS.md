@README.md

## Directory & File Structure

```
plugins/commit-message-writer/
├── .codex-plugin/plugin.json
├── .claude-plugin/plugin.json
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── writing-commit-messages/
        ├── SKILL.md
        ├── scripts/
        │   ├── cleanup.sh
        │   └── gather.sh
        └── references/
            ├── type-detection.md
            └── validation-rules.md
```

## Component Overview

This plugin provides:
- **Skill** (`skills/writing-commit-messages/`): the workflow for generating and validating Conventional Commits with a generic `Pre-Step-N` / `Post-Step-N` extension contract and a small catalog of named configuration values.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin. The Codex version of its required subagent is installed separately from `codex-subagents/`.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape, mode detection, or step bodies | `skills/writing-commit-messages/SKILL.md` | Steps 1-14 + Step V, extension contract, named configuration values |
| Modify the universal type-detection decision tree | `skills/writing-commit-messages/references/type-detection.md` | Priority-ordered type rules, breaking-change detection |
| Modify the anti-slop ruleset | The `human-author:ai-slop-writing-fixer` agent | Em-dash ban, banned vocabulary, sentence patterns. Step 11 dispatches this agent via the Agent tool. |
| Modify validation-mode checks | `skills/writing-commit-messages/references/validation-rules.md` | Format / consistency / body-quality categories |
| Modify diff-gather or cleanup scripts | `skills/writing-commit-messages/scripts/` | TOC sections, exit codes, tmpfile creation and constrained deletion |

## Testing

BATS tests for the scripts live in `plugin-tests/commit-message-writer/`. Run with:

```bash
.bats/bats-core/bin/bats plugin-tests/commit-message-writer/gather.bats plugin-tests/commit-message-writer/cleanup.bats
```
