# Changelog

## [1.0.0] - 2026-07-20

### Added

- `setting-up-software-writer-extension` skill: codebase exploration with per-family probe checklists (stacks, tests, code, docs), evidence-backed overlay drafting mapped onto the parent skills' formal extension mechanisms only, a prescriptive guard that reports observed bad practices as improvement candidates instead of encoding them, conversational per-family refinement, overlay-file writing under `.claude/hook-contexts/`, idempotent delivery-entry merges for Claude Code settings and the Codex `AGENTS.override.md`, and a verify-and-report step.
- Re-sync mode: diffs existing overlay claims against fresh exploration findings and turns stale rows into update proposals; keeps shared named values (`project.stacks`) consistent across overlays.
- Claude Code and Codex manifests and marketplace registration.
