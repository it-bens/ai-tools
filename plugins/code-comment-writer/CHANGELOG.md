# Changelog

## [2.0.0] - 2026-06-24

Renamed and repositioned to match the structure and feature set of the `commit-message-writer` plugin. **Breaking:** the plugin, skill, and configuration model all changed.

### Changed
- **Renamed** the plugin `comment-review` → `code-comment-writer` and the skill `comment-reviewing` → `writing-code-comments`. The "writer" framing covers both reading and editing.
- Frontmatter `description` rewritten as a trigger-only phrase (was a feature summary that competed with the workflow digraph).
- The workflow is now a numbered eight-step sequence with a Graphviz digraph; the prose "Review Approach" narration and the duplicated progressive-disclosure list were cut. SKILL.md dropped from 439 to ~165 lines.
- Configuration moved from a `.reviewrc.md` file to in-context named values plus a `Pre-Step-N` / `Post-Step-N` extension contract: `paths.ignore`, `paths.conservative`, `comments.preserve_patterns`, `comments.exemption_markers`, `todo.ticket_format`, `domain.terms`.
- The `--git` / working-tree scope now diffs against `HEAD` by default (uncommitted changes); pass an explicit base such as "vs main" to compare against a branch. The prior `comment-review` always compared against the main branch.

### Added
- `model: sonnet` and `effort: high` in the skill frontmatter, pinning Sonnet at high effort for the failure-sensitive judgments (redundant vs load-bearing comment, contract vs implementation docblock, content-signal loss on condensation). Replaces the determinism-focused self-validation apparatus.
- `scripts/scope.sh`: deterministic scope resolution for path / git-worktree / commit / commit-range / commit-list scopes, emitting a `FILE <path> <ranges>` manifest with a built-in skip set and per-file changed-line ranges for git scopes. Strict exit codes (0/1/2).
- Read-only mode detected from "check", "analyze", "audit" verbs, mirroring how `commit-message-writer` layers validation mode.
- First-class documentation-surface support: the `docs.surface` named value lets a project declare an invariant documentation surface (where each kind of knowledge lives), and a new `Relocate` action enforces it — referencing comments whose content a surface already documents, and flagging for migration those the surface owns but does not yet cover. Detailed in `references/documentation-surface.md`.
- BATS coverage for `scope.sh` in `plugin-tests/code-comment-writer/`.
- Companion plugin `code-comment-writer-extension-setup` that provisions overlay content and hook entries for projects that want to extend the skill.
- Registered the plugin in `marketplace.json` and the root README (the prior `comment-review` plugin was never registered).

### Removed
- Slash commands `/comment-review` and `/comment-check`; mode and scope detection now happen inside the skill from arguments and verbs.
- `scripts/git-helpers.sh` (replaced by `scope.sh`) and `scripts/validate-edit.sh` (the Edit tool already enforces existence and unique-match).
- The `.reviewrc.md` config system and its references (`config-overview.md`, `config-options-reference.md`, `config-recipes.md`, `reviewrc-template.md`).
- `self-validation-checks.md`, `workflow-examples.md`, and `output-formats.md` (report format now lives inline in SKILL.md).
- Consolidated `api-docs-core-principles.md`, `api-docs-parameters-and-returns.md`, and `api-docs-contracts.md` into a single `api-docs.md`.
- The shipped `STABILITY-IMPROVEMENT-PLAN.md` (a design document, not skill content).

## [1.2.0] - 2025-11-02

### Added
- Self-validation system that validates categorizations against configuration rules, detects inconsistencies, and auto-corrects safe violations before applying changes

## [1.1.2] - 2025-11-02

### Changed
- Updated bash script invocation examples in SKILL.md to use {baseDir} placeholder instead of hardcoded /path/to/skill path for better maintainability and clarity

## [1.1.1] - 2025-11-01

### Fixed
- Fixed "BASH_SOURCE[0]: parameter not set" error in git-helpers.sh when sourcing script with set -u in complex command chains by using safe parameter expansion (${BASH_SOURCE[0]:-})

## [1.1.0] - 2025-10-30

### Added
- Uncertainty evaluation mechanism with HIGH/MEDIUM/LOW classification using content signal detection (examples, constraints, rationale, trade-offs) and progressive disclosure
- "Changes Requiring Verification" section in report output with actionable verification prompts
- uncertainty-patterns.md reference file with pattern definitions, content signal library, and verification templates

### Changed
- Integrated uncertainty evaluation into skill description, pre-edit review workflow, and change tracking
- Enhanced output format to include verification section with adaptive verbosity

### Performance
- Two-stage evaluation (lightweight heuristics, then full patterns only when HIGH/MEDIUM detected) reduces token overhead for simple reviews

## [1.0.1] - 2025-10-30

### Fixed
- Corrected broken internal documentation links that referenced non-existent files (configuration-guide.md → config-overview.md, api-documentation-guidelines.md → api-docs-core-principles.md)
- Fixed git command execution in wrong directory by using git -C with WORK_DIR variable in git-helpers.sh

## [1.0.0] - 2025-10-22

Initial release.

### Skill - Comment Reviewing
- Comment review following "why not what" principle with five-category action system (Remove, Improve, Keep, Flag, Condense)
- Intelligent comment type detection (implementation vs API documentation) with multi-language support
- Git integration with consistency checking and pre-edit validation
- Project-specific configuration via `.reviewrc.md` with adaptive output formats
- Special cases handling (legacy code, algorithms, generated code)

### Commands
- `/comment-review` - Review and improve comments with smart scope detection
- `/comment-check` - Analyze comment quality (read-only)
- Support for files, directories, --git flag, commits, ranges, and commit lists
