# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-07-26

Adds the project extension surface, modeled on the one `software-writer` 2.x ships. The mechanisms are the same — workflow positions plus named configuration values, delivered by plugin-owned hooks — with two adaptations the orchestration workflow forces: positions are keyed by node name rather than step number, because the workflow is cyclic and a linear step number would misdescribe it; and named values that feed worker prompts are inlined verbatim at dispatch, because workers are stateless and inherit nothing from the session.

### Added

- `EXTENSION.md` — the contract: extension file layout, delivery envelope, both mechanisms, the non-extendable surface, reference-like extensions, the recognized-values table, and worked examples for registering gates and a project checkpoint type
- `hooks/hooks.json`, `hooks/scripts/inject-extension.sh` — Claude Code delivery of `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md` on `PostToolUse` (matcher `Skill`) and `UserPromptSubmit`, wrapped in a `<project_extension>` envelope; silent for every other skill, prompt, and project
- Ten recognized named values: `project.gates`, `project.protected_paths`, `project.banned_commands`, `project.skill_files`, `project.conduct_rules`, `project.review_lenses`, `codex.extra_config`, `routing.additions`, `routing.effort_defaults`, `deviation.additional_triggers`
- Five workflow positions — `Preflight`, `Strategy`, `Dispatch`, `Adapt`, `Report` — each with a `Pre-` and `Post-` form
- `plugin-tests/subagent-orchestrator/inject_extension.bats` — gating, delivery, non-Claude-host, and failure coverage for the delivery script

### Changed

- `skills/orchestrating-subagent-work/SKILL.md` — new `## Workflow` section declaring both extension mechanisms and the position table, with node sections demoted to `###` beneath it; the deviation node cites `deviation.additional_triggers`
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — new §Extension content in worker prompts fixing propagation (values inlined verbatim into the citing block; cited paths travel as SKILLS required reading); GATES, FENCE, SKILLS, RULES, and LENS rows cite their named values with inline defaults; invocation hygiene cites `codex.extra_config`
- `skills/orchestrating-subagent-work/references/model-routing.md` — routing table cites `routing.additions`, effort ladder cites `routing.effort_defaults`

The consent gate, the deviation check, the halt state, the verification shape, and dual-confirmation closure are deliberately fenced: none carries a position name, and the only named value reaching any of them is `deviation.additional_triggers`, which appends triggers and cannot remove one. The verification shape and dual-confirmation closure have no named value at all.

## [1.0.0] - 2026-07-17

Initial release. The skill's directives derive from two evidence legs, both distilled into `docs/`: a private, instrumented 17-run codex experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, and a resume-loop validation — single-run cells, all at effort `max`, so directional rather than proven) and an adversarially verified deep-research pass over the official GPT-5.6 and Codex CLI documentation (2026-07-15; 23 of 24 top claims survived three refute-votes each).

### Added

- `skills/orchestrating-subagent-work/SKILL.md` — orchestration workflow (codex pre-flight, codex-less consent gate, strategy-before-dispatch, deviation-and-adaptation loop, dual-confirmation closure), pinned by a digraph
- `skills/orchestrating-subagent-work/references/model-routing.md` — checkpoint-to-actor routing table across `gpt-5.6-sol`/`terra`/`luna` and sonnet/haiku subagents, verification shape, effort ladder, severity-label calibration, codex-less substitutions
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — CLI-only invocation hygiene, review and implementer prompt-block protocols, the `codex exec resume` re-validation loop, trust boundaries
- `docs/codex-dispatch-experiments.md` — distilled local experiment findings (transport, model roles, prompt-block ablations, spec-writing lessons, cost, named confounds)
- `docs/gpt-5-6-model-family.md` — external research on tier design intent, pricing, effort guidance, and Codex CLI configuration, with sources
