# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-08

### Added
- Overlay-extension convention in `reviewing-plans` workflow. Project overlays may insert digraph nodes at named positions (`Pre-Step-N`, `Post-Step-N`); overlay-supplied fragments are treated as authoritative additions to the workflow shape, not as advisory commentary, and the full execution path is the composition of the skill's digraph with any overlay fragments at their named positions.

## [1.0.0] - 2026-05-03

### Added
- Initial release
- `reviewing-plans` skill: critical, multi-lens audit of an implementation plan against its spec, project posture, and current code
- Companion enforcer plugin available as `reviewing-plans-with-opus-enforcer`
