@README.md

## Directory & File Structure

```
codex-subagents/
├── README.md
├── CLAUDE.md
└── ai-slop-writing-fixer.toml
```

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand installation scopes and available agents | `README.md` |
| Modify the Codex agent metadata or instructions | `ai-slop-writing-fixer.toml` |
| Modify the canonical anti-slop rules, inputs, output contract, or scope guardrails | `plugins/human-author/agents/ai-slop-writing-fixer.md` |

## Authoring Rules

1. **Claude Code is the canonical source.** Keep `ai-slop-writing-fixer.toml` behavior aligned with `plugins/human-author/agents/ai-slop-writing-fixer.md`. Adapt only host-specific metadata and instruction syntax.
2. **Agent names are compatibility contracts.** Preserve `human-author:ai-slop-writing-fixer` so shared skills can request the same subagent name in Claude Code and Codex.
3. **Installation instructions must be portable.** Do not include user-specific absolute paths, checkout-specific source paths, shell-only copy commands, or dependencies on optional runtimes.
4. **Codex agents remain separate from plugins.** Do not move these files into plugin bundles until Codex supports distributing custom agents through plugins.
5. **Installed copies are outputs.** Edit the source files in `codex-subagents/`; users replace their personal or project-scoped installed copies afterward.
