# Changelog

## [1.0.1] - 2026-06-24

### Fixed
- Hook `command` strings now read the overlay file via `$CLAUDE_PROJECT_DIR/.claude/hook-contexts/writing-commit-messages.md` instead of a project-relative path. The relative path resolved against the hook's working directory, so once Claude changed directories mid-session the overlay file was no longer found, the hook errored, and `UserPromptSubmit`/`PostToolUse` delivery stopped.

## [1.0.0] - 2026-05-19

### Added
- `setting-up-commit-message-writer-extension` skill.
- Workflow that provisions `.claude/hook-contexts/writing-commit-messages.md` as the overlay content file and adds matching `PostToolUse:Skill` + `UserPromptSubmit` hook entries to the target settings file.
