@README.md

## Directory & File Structure

```
plugins/commit-message-writer/
├── .claude-plugin/plugin.json
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── writing-commit-messages/
        ├── SKILL.md
        ├── scripts/gather.sh
        └── references/
            ├── type-detection.md
            └── validation-rules.md
```

## Component Overview

This plugin provides:
- **Skill** (`skills/writing-commit-messages/`): the workflow for generating and validating Conventional Commits with a generic `Pre-Step-N` / `Post-Step-N` extension contract and a small catalog of named configuration values.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape, mode detection, or step bodies | `skills/writing-commit-messages/SKILL.md` | Steps 1-14 + Step V, extension contract, named configuration values |
| Modify the universal type-detection decision tree | `skills/writing-commit-messages/references/type-detection.md` | Priority-ordered type rules, breaking-change detection |
| Modify the anti-slop ruleset | The `human-author:ai-slop-writing-fixer` agent | Em-dash ban, banned vocabulary, sentence patterns. Step 11 dispatches this agent via the Agent tool. |
| Modify validation-mode checks | `skills/writing-commit-messages/references/validation-rules.md` | Format / consistency / body-quality categories |
| Modify diff-gather script | `skills/writing-commit-messages/scripts/gather.sh` | TOC sections, exit codes, tmpfile prefix |

## Testing

BATS tests for `gather.sh` live in `plugin-tests/commit-message-writer/`. Run with:

```bash
.bats/bats-core/bin/bats plugin-tests/commit-message-writer/gather.bats
```
