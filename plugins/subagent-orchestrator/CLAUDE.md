@README.md

## Component Overview

This plugin provides:

- **Skill** (`skills/orchestrating-subagent-work/`) — workflow for orchestrating implementation and review work through dispatched workers (codex CLI, Claude subagents)

**No commands, agents, hooks, or MCP servers** — skill-only plugin. Claude Code only; there is no Codex manifest because the skill orchestrates Claude subagent spawns (Codex appears as a dispatched worker, not as the host).

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape (nodes, gates, terminal states) | `skills/orchestrating-subagent-work/SKILL.md` | Pre-flight, consent gate, strategy message, deviation loop, dual-confirmation closure |
| Modify checkpoint-to-actor routing or effort defaults | `skills/orchestrating-subagent-work/references/model-routing.md` | Routing table, verification shape, severity-label calibration, codex-less substitutions |
| Modify codex invocation flags, prompt blocks, or the re-validation loop | `skills/orchestrating-subagent-work/references/codex-dispatch.md` | Invocation hygiene, review/implementer blocks, `exec resume`, trust boundaries |
| Consult the evidence behind a directive | `docs/codex-dispatch-experiments.md`, `docs/gpt-5-6-model-family.md` | Experiment findings, tier design intent |

## Maintenance Rules

- Keep provenance (experiment citations, source URLs) out of `SKILL.md` and `references/` — it lives in `docs/` and `CHANGELOG.md`.
- The GPT-5.6 tier names in `references/model-routing.md` are durable tiers that rev independently; when a tier revs, re-validate the routing table against fresh evidence and record the change here and in `docs/`.
- The skill body stays host-neutral about delivery mechanics and project specifics: project gates, protected paths, and banned command classes are named generically and filled in per project by the orchestrator at dispatch time.
