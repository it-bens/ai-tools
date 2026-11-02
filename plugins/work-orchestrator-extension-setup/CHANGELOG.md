# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.2.0] - 2026-11-02

`work-orchestrator` 5.0.0 replaced its 15 model-and-effort agent definitions with 11 duty definitions that pin neither; the orchestrating skill passes model and effort per spawn. The setup skill follows: an effort override on a claude checkpoint can now name any level, and a routing addition's claude actor is a duty definition plus a model.

### Changed

- `skills/setting-up-work-orchestrator-extension/SKILL.md`: Step 5 no longer limits claude effort overrides to the rungs of shipped definitions; a routing addition names a duty definition plus a model, and a checkpoint whose duty no shipped definition covers becomes an improvement candidate for the parent plugin
- `skills/setting-up-work-orchestrator-extension/SKILL.md`: Step 3 (re-sync) carries the 4.x-to-5.x migration table and rewrites every retired definition name in an extension file to the duty definition, model, and effort the table gives, proposed like any other stale claim; haiku rows get `low`
- `skills/setting-up-work-orchestrator-extension/SKILL.md`: Step 5 offers `routing.model_defaults`, the parent's new per-checkpoint model override for claude checkpoints, under the same evidence requirement as effort overrides, and refuses one naming fable or a codex checkpoint
- `README.md`, `.claude-plugin/plugin.json`: state that routing additions target the `work-orchestrator` 5.0.0 duty definitions; the README states that re-sync rewrites 4.x definition names

The extension-file format is unchanged. Files that name a 4.x definition need the re-sync this version runs, because `work-orchestrator` 5.0.0 no longer ships those definitions.

## [2.1.0] - 2026-08-21

The setup skill knows the parent plugin's handoff referent guard. When receiving sessions read authoritative persistent artifacts end to end, a handoff composed from session recall can cite referents those artifacts do not hold; the parent's `EXTENSION.md` now carries a `Post-Compose` guard example for that setup, and this skill proposes it.

### Changed

- `skills/setting-up-work-orchestrator-extension/SKILL.md` — Step 2 gains a handoff-referent-guard probe (session-work only): detect authoritative persistent artifacts and propose the parent's `Post-Compose` guard example plus a citation-discipline `project.conduct_rules` entry; Step 5's family order and confirmation list carry the guard

## [2.0.0] - 2026-08-11

The plugin is renamed from `subagent-orchestrator-extension-setup` to `work-orchestrator-extension-setup`, following the parent plugin's rename, and the setup skill now covers both of the parent's skills. This directory is a copy of `plugins/subagent-orchestrator-extension-setup/`, which remains in the marketplace frozen and deprecated. There is no migration tooling: re-sync reads nothing under `.claude/extensions/subagent-orchestrator/`.

### Added

- Skill selection in Step 1: the user chooses which parent skills the project extends (`orchestrating-subagent-work`, `orchestrating-session-work`, or both); each selected skill gets its own file and its own fresh-vs-re-sync decision
- Session-topology drafting for `orchestrating-session-work`: roles, duties, and message flow come from the user conversationally; exploration contributes the working-tree and branch facts behind write ownership; Step 5 enforces exactly one writing role per tree
- `sessions.topology` and `sessions.additional_triggers` in the Step 4 mechanism mapping, with the session skill's position set (`Strategy`, `Compose`, `Dispatch`, `Adapt`, `Report`)

### Changed

- Plugin name: `subagent-orchestrator-extension-setup` → `work-orchestrator-extension-setup`; skill and canonical paths follow
- The fence guard extends to the session skill's fenced surface: session enumeration, the mandatory dispatch-message blocks, and a topology sharing one working tree between two writing roles are refused, not encoded
- Step 7 verifies per written file and confirms delivery by invoking each written skill against `work-orchestrator` 4.0.0 or later

## [1.2.0] - 2026-08-04


Mirrors the `routing.effort_defaults` contract change in `work-orchestrator` 3.0.0. Claude checkpoints now take their reasoning effort from an agent definition the parent plugin ships, so an effort override on one selects among those definitions rather than setting a free-form level. Step 5 states both resolutions and routes an inexpressible rung to the improvement-candidates report instead of writing it into the extension file.

## [1.1.0] - 2026-08-03

The setup skill now records the `routing.codex_bias` project preference (`codex-heavy` / `claude-lean` / none) in Step 5, treats it as a preference exempt from the evidence requirement, and refuses to author a persistent `codex-less` bias; it surfaces codex-less as a per-session consent decision instead.

## [1.0.0] - 2026-07-26

Initial release, companion to `work-orchestrator` 2.0.0, which introduced the extension contract this skill authors content for.

### Added

- `skills/setting-up-work-orchestrator-extension/SKILL.md` — fresh and re-sync modes, evidence-backed exploration of gates, fences, conduct rules, review lenses, and checkpoint types, conversational refinement per family, and the write plus verification of `.claude/extensions/work-orchestrator/orchestrating-subagent-work.md`

Four guards constrain what the skill will write: the append-only guard (a list-shaped value never shortens its universal list), the fence guard (nothing that softens the consent gate, deviation check, verification shape, or dual-confirmation closure), the loop-node guard (content at `Dispatch` and `Adapt` must be repeat-safe), and the prescriptive guard (observed shortcuts become an improvement-candidates report, not extension content). Gate commands are confirmed to exist in their declaring file and never run to verify them.
