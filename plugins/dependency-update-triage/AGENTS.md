@README.md

## Directory & File Structure

```
plugins/dependency-update-triage/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── README.md
└── skills/
    └── triaging-a-dependency-update/
        ├── SKILL.md
        └── references/
            ├── detection.md
            ├── investigation.md
            └── output.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/triaging-a-dependency-update/`): the read-only triage workflow. SKILL.md carries the digraph, the five operating rules, and eleven steps; detection, the investigation engine with its three prongs, and the report shape live in the references, while gathering, the source gate, the conclusion, and the quality gate are inline.

**No commands, agents, hooks, scripts, or MCP servers.** Both companions (git-forge tooling, web reader) are soft: the skill checks for each and degrades with a note when it is absent rather than depending on it.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape, operating rules, or step bodies | `skills/triaging-a-dependency-update/SKILL.md` | Digraph, five operating rules, Steps 1-11, final quality gate with loop-back, read-only invariant |
| Modify how the host stack is detected | `skills/triaging-a-dependency-update/references/detection.md` | Ecosystem/lockfile, direct vs transitive, type system, release-notes location, update source; runtime detection, nothing hardcoded |
| Modify the investigation engine or the three prongs | `skills/triaging-a-dependency-update/references/investigation.md` | Three inventories (changed/added/fixed-bug), search/rank/disposition, model tiers, prong (a) grounding, prong (b) unlocking + testability, prong (c) latent-bug reachability |
| Modify the report shape or companion degradation | `skills/triaging-a-dependency-update/references/output.md` | Report sections, delivery, degrade-with-a-note table |

## Host Compatibility

Both hosts run the same SKILL.md and references. The skill body is host-neutral: it names no host-specific tool, expresses model routing as tiers rather than model names, and treats every companion as soft. The Claude Code frontmatter `model` field is not used, so the driver runs on the session model on both hosts; the Opus recommendation for the driver is documented in the README, not pinned.

## Testing

No scripts or hooks, so no BATS coverage. Validate skill-body changes by invoking the skill against a sample update in a scratch project: confirm it routes gather → detect → investigate → report, produces the three-pronged output shape, grounds every impact claim in a code reference, and presents the report without editing the repo.
