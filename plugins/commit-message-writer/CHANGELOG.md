# Changelog

## [1.0.3] - 2026-05-28

### Fixed
- Step 2 now directs running `gather.sh` by its absolute path while keeping the working directory inside the repository being summarized. The script detects its target repository from the current working directory, so the previous relative-path invocation led sessions to `cd` into the skill's own directory (a different repository when the skill is plugin-installed), targeting the wrong repository.
- `gather.sh` root-commit detection now requires `<sha>` itself to resolve before treating `<sha>^..<sha>` as a root commit. An unknown ref (e.g. invoked against the wrong repository) previously matched the same "parent does not resolve" test, was rewritten to git's empty-tree object, and surfaced a misleading `invalid git range: 4b825dc6...` error. It now falls through to report `invalid git range: <sha>^..<sha>`, naming the actual input.
- Step 2 exit-code `2` handling now names both causes (invalid range, not inside a git repository) and directs reporting the script's stderr message verbatim.

### Added
- BATS regression test for a rewrite range whose commit does not resolve in the current repository.

## [1.0.2] - 2026-05-22

### Fixed
- Step 2 now invokes `gather.sh` via the skill-relative path `scripts/gather.sh`. The previous path (`.claude/skills/commit-message-generating/scripts/gather.sh`) pointed at a non-existent location, causing sessions to abandon the gather workflow and orient with raw git commands instead.
- Step 1 mode detection now states that the argument is authoritative and must not be re-interpreted against conversation context, preventing the skill from falling back to staged mode when uncommitted changes are present alongside a SHA or range argument.

## [1.0.1] - 2026-05-22

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
