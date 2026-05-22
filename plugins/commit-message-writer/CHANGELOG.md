# Changelog

## [1.1.0] - 2026-05-22

### Fixed
- `gather.sh` now handles a rewrite-mode range against a root (parentless) commit. The script detects `<sha>^..<sha>` where `<sha>^` does not resolve and substitutes git's empty-tree object for the diff side and `-1 <sha>` for the log side, so `git diff` and `git log` both succeed on a repository's initial commit.

### Added
- BATS regression test for the root-commit case in `plugin-tests/commit-message-writer/gather.bats`.

## [1.0.0] - 2026-05-18

### Added
- `writing-commit-messages` skill.
- Mode detection (staged / squash / rewrite) from arguments and message context.
- `gather.sh` script that emits a deterministic TOC of git diff sections for targeted Read and Grep against a tmpfile.
- Generic `Pre-Step-N` / `Post-Step-N` extension contract at every workflow step.
- Recognized named configuration values: `modes.squash.default_base`, `scope.naming_convention`, `subject.max_length`, `body.breaking_change_handoff`, `footer.template`, `footer.extra_lines`.
- Type-detection decision tree.
- Anti-slop ruleset (em-dash ban, banned vocabulary, sentence patterns, sentence rhythm).
- Validation mode covering format compliance, consistency, and body quality.
- BATS coverage for `gather.sh` (exit codes, TOC structure, staged vs working-tree fallback, log-section presence for ranges, tmpfile prefix).
