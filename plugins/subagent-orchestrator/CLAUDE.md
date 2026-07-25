@README.md

## Component Overview

This plugin provides:

- **Skill** (`skills/orchestrating-subagent-work/`) — workflow for orchestrating implementation and review work through dispatched workers (codex CLI, Claude subagents)
- **Hooks** (`hooks/`) — extension delivery: a `PostToolUse` hook (matcher `Skill`) and a `UserPromptSubmit` hook run `inject-extension.sh`, which delivers a project's `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md` wrapped in the `<project_extension>` envelope and stays silent for every other skill, prompt, or project

**No commands, agents, or MCP servers.** Claude Code only; there is no Codex manifest because the skill orchestrates Claude subagent spawns (Codex appears as a dispatched worker, not as the host). The companion `subagent-orchestrator-extension-setup` plugin writes project extension files.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape (nodes, gates, terminal states) | `skills/orchestrating-subagent-work/SKILL.md` | Pre-flight, consent gate, strategy message, deviation loop, dual-confirmation closure |
| Modify the extension mechanisms or the position table | `skills/orchestrating-subagent-work/SKILL.md` §Workflow | Node-keyed positions, named-value lookup, append-only rule |
| Modify checkpoint-to-actor routing or effort defaults | `skills/orchestrating-subagent-work/references/model-routing.md` | Routing table, verification shape, severity-label calibration, codex-less substitutions |
| Modify what any worker receives in its prompt | `skills/orchestrating-subagent-work/references/worker-prompts.md` | Review/implementer blocks, trust boundaries, extension propagation into worker prompts |
| Modify codex invocation flags or the re-validation loop | `skills/orchestrating-subagent-work/references/codex-dispatch.md` | Invocation hygiene, `exec resume`, codex-less re-validation |
| Add, rename, or retire a named value or position | `EXTENSION.md` + the file that cites it | The recognized-values table and position table must match the names and inline defaults cited in `SKILL.md` and both references |
| Document how projects extend the skill | `EXTENSION.md` | File layout, delivery, both mechanisms, the non-extendable surface, reference-like extensions, worked examples |
| Change the delivery envelope, gating, or failure behavior | `hooks/scripts/inject-extension.sh` | `<project_extension>` envelope, position variants, silent gates vs loud failures |
| Change delivery events or timeout | `hooks/hooks.json` | `PostToolUse` matcher `Skill`, `UserPromptSubmit` |
| Consult the evidence behind a directive | `docs/codex-dispatch-experiments.md`, `docs/gpt-5-6-model-family.md` | Experiment findings, tier design intent |

## Maintenance Rules

- Keep provenance (experiment citations, source URLs) out of `SKILL.md` and `references/` — it lives in `docs/` and `CHANGELOG.md`.
- The GPT-5.6 tier names in `references/model-routing.md` are durable tiers that rev independently; when a tier revs, re-validate the routing table against fresh evidence and record the change here and in `docs/`.
- The skill body stays host-neutral about delivery mechanics and project specifics: project gates, protected paths, and banned command classes are named generically, cite their named values, and are filled in per project by the orchestrator at dispatch time.
- The extension contract's fence is structural, not prose: the consent nodes, the halt state, and the deviation check carry no position name, and the verification shape and dual-confirmation closure have no named value. A change that gives any of them one removes the guarantee the plugin exists for.
- A named value is cited at the point that consumes it, not hoisted into `SKILL.md`. Adding one means editing three places: the citing file, the `EXTENSION.md` table, and the `CHANGELOG.md` entry.

## Testing

BATS tests for the delivery script in `plugin-tests/subagent-orchestrator/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run
.bats/bats-core/bin/bats plugin-tests/subagent-orchestrator/*.bats
```

Skill-body changes have no automated tests. Validate them by invoking the skill in a scratch project without an extension file (universal defaults) and in a project with one (extension contract, envelope delivery).
