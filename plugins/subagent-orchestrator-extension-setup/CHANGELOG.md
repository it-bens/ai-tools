# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-08-04

Mirrors the `routing.effort_defaults` contract change in `subagent-orchestrator` 3.0.0. Claude checkpoints now take their reasoning effort from an agent definition the parent plugin ships, so an effort override on one selects among those definitions rather than setting a free-form level. Step 5 states both resolutions and routes an inexpressible rung to the improvement-candidates report instead of writing it into the extension file.

## [1.1.0] - 2026-08-03

The setup skill now records the `routing.codex_bias` project preference (`codex-heavy` / `claude-lean` / none) in Step 5, treats it as a preference exempt from the evidence requirement, and refuses to author a persistent `codex-less` bias; it surfaces codex-less as a per-session consent decision instead.

## [1.0.0] - 2026-07-26

Initial release, companion to `subagent-orchestrator` 2.0.0, which introduced the extension contract this skill authors content for.

### Added

- `skills/setting-up-subagent-orchestrator-extension/SKILL.md` — fresh and re-sync modes, evidence-backed exploration of gates, fences, conduct rules, review lenses, and checkpoint types, conversational refinement per family, and the write plus verification of `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md`

Four guards constrain what the skill will write: the append-only guard (a list-shaped value never shortens its universal list), the fence guard (nothing that softens the consent gate, deviation check, verification shape, or dual-confirmation closure), the loop-node guard (content at `Dispatch` and `Adapt` must be repeat-safe), and the prescriptive guard (observed shortcuts become an improvement-candidates report, not extension content). Gate commands are confirmed to exist in their declaring file and never run to verify them.
