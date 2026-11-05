# Changelog

## [1.0.0] - 2026-11-05

Initial release.

### Added

- Stop prompt hook that turns a decision asked in prose into an `AskUserQuestion` call
- PreToolUse agent hook on `AskUserQuestion` that denies questions the agent can derive, with the derived answer and its source
- Optional project checklist at `.claude/extensions/decision-handback-guard/checklist.md` with `## The agent decides` and `## The user decides` lists
