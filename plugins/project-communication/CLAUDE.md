@README.md

## Directory & File Structure

```
plugins/project-communication/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── changelog-summarizing/
        └── SKILL.md
```

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify skill workflow or triggers | `skills/changelog-summarizing/SKILL.md` |
| Update anti-slop rules (vocabulary, patterns, tone) | The `human-author:ai-slop-writing-fixer` agent. Phase 6 dispatches it via the Agent tool. |
| Update plugin metadata | `.claude-plugin/plugin.json` |
| Log a new release | `CHANGELOG.md` |

## Authoring Rules

1. **Triggers live only in frontmatter.** The skill body must not restate when the skill activates. If a body section starts to describe triggers, rewrite it to describe behavior.
2. **Project-agnostic by default.** The skill must operate in any repository that uses Conventional Commits. Do not bake repository-shape assumptions into the skill (no implicit `plugins/<scope>/` or other default mappings). Linked headers require an explicit user-supplied mapping; otherwise headers are plain bold text.
3. **Anti-slop is delegated to the `human-author:ai-slop-writing-fixer` subagent.** Phase 6 dispatches it via the Agent tool. Do not duplicate anti-slop rules inline; if the ruleset needs to evolve, update the agent in the `human-author` plugin.
