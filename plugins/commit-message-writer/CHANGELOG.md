# Changelog

## Unreleased

### Added

- Codex plugin metadata and repository marketplace registration.
- Manual Codex custom-agent package for the existing `human-author:ai-slop-writing-fixer` prerequisite.

## [1.2.0] - 2026-06-04

### Added
- `model: sonnet` and `effort: high` in the skill frontmatter. The skill now pins Sonnet 4.6 with high effort for its turn regardless of the session model. Rationale: the workflow classifies the commit type, summarizes a diff, and orchestrates a multi-step tool flow (gather.sh, ranged Read, Grep, subagent dispatch) where intent inference from an ambiguous diff and edge-case fidelity (traceability, breaking-change detection, multi-concern squash) are the failure-sensitive parts. Haiku 4.5 has no effort parameter, so it cannot carry the setting; Sonnet's adaptive reasoning at high effort spends thinking on the ambiguous diffs and stays cheap on trivial ones.

## [1.1.0] - 2026-05-28

### Changed
- Step 11 now dispatches the `human-author:ai-slop-writing-fixer` subagent via the Agent tool instead of re-reading an inline anti-slop reference. The agent applies the corrections and returns the fixed message text. This shifts anti-slop maintenance to the `human-author` plugin and picks up its broader ruleset (pre-empted concession, hedge openers, balanced hedging, parallelism in compound predicates, label-not-explanation, plus the existing em-dash ban, banned vocabulary, sentence patterns, rhythm, and concreteness rules).

### Added
- `dependencies` entry on `human-author` in `.claude-plugin/plugin.json`. Installing this plugin now auto-installs `human-author`.

### Removed
- `skills/writing-commit-messages/references/writing-rules-anti-ai-slop.md`. The ruleset lives in the `human-author:ai-slop-writing-fixer` agent.

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
