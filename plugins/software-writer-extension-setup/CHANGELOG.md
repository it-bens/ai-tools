# Changelog

## [2.0.0] - 2026-07-20

### Changed

- Extension files are written to `.claude/extensions/software-writer/<skill>.md` (was `.claude/hook-contexts/<skill>.md`); vocabulary unified on "extension content" / "extension file".
- Claude Code delivery provisioning removed: `software-writer` 2.x ships its own hooks, so the skill writes no settings entries. Step 7 now covers Codex `AGENTS.override.md` provisioning and v1 migration only.
- The canonical `AGENTS.override.md` section wraps each file reference in the `<project_extension>` envelope and always retains a root `AGENTS.md` through `@AGENTS.md`, stated with the reason: Codex replaces, not stacks, AGENTS files.
- Drafting supports reference-like entries: findings whose content lives in (or belongs in) a project documentation surface become an imperative citation plus a `docs.surfaces` registration instead of inlined content.
- Verification now confirms delivery by invoking an extended skill and checking for the `<project_extension>` envelope.

### Added

- v1 migration in re-sync mode: detects `.claude/hook-contexts/writing-*.md` files and the six v1 jq hook entries in project settings, rewrites the content at the new path, deletes the legacy files, and removes the legacy entries (with explicit user approval for the settings edit).

## [1.0.0] - 2026-07-20

### Added

- `setting-up-software-writer-extension` skill: codebase exploration with per-family probe checklists (stacks, tests, code, docs), evidence-backed overlay drafting mapped onto the parent skills' formal extension mechanisms only, a prescriptive guard that reports observed bad practices as improvement candidates instead of encoding them, conversational per-family refinement, overlay-file writing under `.claude/hook-contexts/`, idempotent delivery-entry merges for Claude Code settings and the Codex `AGENTS.override.md`, and a verify-and-report step.
- Re-sync mode: diffs existing overlay claims against fresh exploration findings and turns stale rows into update proposals; keeps shared named values (`project.stacks`) consistent across overlays.
- Claude Code and Codex manifests and marketplace registration.
