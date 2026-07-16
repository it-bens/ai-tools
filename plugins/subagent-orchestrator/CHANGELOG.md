# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-07-17

Initial release. The skill's directives derive from two evidence legs, both distilled into `docs/`: a private, instrumented 17-run codex experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, and a resume-loop validation — single-run cells, all at effort `max`, so directional rather than proven) and an adversarially verified deep-research pass over the official GPT-5.6 and Codex CLI documentation (2026-07-15; 23 of 24 top claims survived three refute-votes each).

### Added

- `skills/orchestrating-subagent-work/SKILL.md` — orchestration workflow (codex pre-flight, codex-less consent gate, strategy-before-dispatch, deviation-and-adaptation loop, dual-confirmation closure), pinned by a digraph
- `skills/orchestrating-subagent-work/references/model-routing.md` — checkpoint-to-actor routing table across `gpt-5.6-sol`/`terra`/`luna` and sonnet/haiku subagents, verification shape, effort ladder, severity-label calibration, codex-less substitutions
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — CLI-only invocation hygiene, review and implementer prompt-block protocols, the `codex exec resume` re-validation loop, trust boundaries
- `docs/codex-dispatch-experiments.md` — distilled local experiment findings (transport, model roles, prompt-block ablations, spec-writing lessons, cost, named confounds)
- `docs/gpt-5-6-model-family.md` — external research on tier design intent, pricing, effort guidance, and Codex CLI configuration, with sources
