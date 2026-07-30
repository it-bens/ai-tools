# Changelog

## [1.0.0] - 2026-07-31

### Added

- `triaging-a-dependency-update` skill: a read-only, single-purpose assessment of one dependency update; a grouped update is assessed per-package under one report with per-package verdicts and one group disposition.
- Three-pronged assessment: (a) does it require changes, grounded in host-codebase call sites; (b) does it enable an improvement, including a testability axis, gated on a concrete before-to-after; (c) latent-bug watch, flagging when an upstream bug fix may still affect the application.
- Structured investigation engine that bounds a large changeset into three inventories (changed surface — every changed contract, not only symbols — plus added surface and fixed-bug list), searches the visible code (call sites plus imports, config, and framework registration), ranks by criticality, verifies the top-ranked candidates in depth, dispositions every candidate, resolves direct versus transitive dependencies including undeclared direct use, and flags a non-enumerating changelog as a limitation.
- Final quality gate that verifies grounding, before-to-after, disposition, and sources before composing the report, looping back to the offending step on failure.
- Host-neutral model tiers (cheap fan-out, mid reading, strong driver) that dispatch subagents where the host supports per-worker model routing and degrade to inline work where it does not.
- Runtime detection of ecosystem, dependency directness, type system, and release-notes location, with a version-tag-diff fallback when no changelog exists; no package manager, forge, or updater bot is hardcoded.
- Single output: an assessment delivered to the clipboard for the user to post, with soft companion integration (git-forge tooling, web reader, clipboard) that degrades with an explicit note when a companion is absent.
- Claude Code and Codex manifests plus marketplace registration for both hosts.
