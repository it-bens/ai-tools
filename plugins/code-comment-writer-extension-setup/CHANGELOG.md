# Changelog

## [1.0.1] - 2026-06-24

### Fixed
- Hook `command` strings now read the overlay file via `$CLAUDE_PROJECT_DIR/.claude/hook-contexts/writing-code-comments.md` instead of a project-relative path. The relative path resolved against the hook's working directory, so once Claude changed directories mid-session the overlay file was no longer found, the hook errored, and `UserPromptSubmit`/`PostToolUse` delivery stopped.

## [1.0.0] - 2026-06-24

### Added
- `setting-up-code-comment-writer-extension` skill that provisions a project to extend `code-comment-writer:writing-code-comments`.
- Writes the overlay content file `.claude/hook-contexts/writing-code-comments.md` from named-value assignments and `Pre-Step-N` / `Post-Step-N` sections.
- Idempotent merge of the `PostToolUse` (matcher `Skill`) and `UserPromptSubmit` hook entries into the project's settings file, skipping entries whose `command` string already exists.
