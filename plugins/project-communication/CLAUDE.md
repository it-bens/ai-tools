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
        ├── SKILL.md
        └── references/
            └── writing-rules-anti-ai-slop.md
```

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify skill workflow or triggers | `skills/changelog-summarizing/SKILL.md` |
| Update anti-slop rules (vocabulary, patterns, tone) | `skills/changelog-summarizing/references/writing-rules-anti-ai-slop.md` |
| Update plugin metadata | `.claude-plugin/plugin.json` |
| Log a new release | `CHANGELOG.md` |

## Authoring Rules

1. **Triggers live only in frontmatter.** The skill body must not restate when the skill activates. If a body section starts to describe triggers, rewrite it to describe behavior.
2. **Project-agnostic by default.** The skill must operate in any repository that uses Conventional Commits. Do not bake repository-shape assumptions into the skill (no implicit `plugins/<scope>/` or other default mappings). Linked headers require an explicit user-supplied mapping; otherwise headers are plain bold text.
3. **Anti-slop reference is self-contained.** No cross-skill source-of-truth pointers. If the file is reused elsewhere, copy it; don't link.
