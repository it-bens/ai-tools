@README.md

## Directory & File Structure

```
plugins/human-author/
├── README.md
├── CHANGELOG.md
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json
└── agents/
    └── ai-slop-writing-fixer.md
```

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify the agent's rules, inputs, output contract, or scope guardrails | `agents/ai-slop-writing-fixer.md` |
| Update plugin metadata | `.claude-plugin/plugin.json` |
| Log a new release | `CHANGELOG.md` |

## Authoring Rules

1. **Agent ruleset is project-agnostic.** Examples in the agent body must not reference vendor-specific symbols, classes, or product names. Use generic identifiers (`Context`, `quantityStart`, "user profile", "payment") so the agent applies cleanly in any repository.
2. **No frequency budgets in the agent.** Counting and rate-limiting belong to the caller. The agent fixes violations; it does not police how many of each pattern the input had.
3. **Rule additions must come with a `Bad:` / `Better:` pair.** Rules without an example are interpreted unevenly across runs. If a rule cannot be illustrated with a short before/after, the rule is probably too abstract to keep.
4. **The self-check is load-bearing.** Every rule addition must pass the "second pass returns `no_changes: true`" test. If a corrected output can trigger the new rule, the rule and its replacement guidance need to be revised together.
