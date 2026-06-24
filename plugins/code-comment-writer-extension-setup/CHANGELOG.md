# Changelog

## [1.0.0] - 2026-06-24

### Added
- `setting-up-code-comment-writer-extension` skill that provisions a project to extend `code-comment-writer:writing-code-comments`.
- Writes the overlay content file `.claude/hook-contexts/writing-code-comments.md` from named-value assignments and `Pre-Step-N` / `Post-Step-N` sections.
- Idempotent merge of the `PostToolUse` (matcher `Skill`) and `UserPromptSubmit` hook entries into the project's settings file, skipping entries whose `command` string already exists.
