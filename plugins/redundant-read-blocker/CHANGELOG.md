# Changelog

## [1.0.0] - 2026-04-07

Initial release.

### Added

- PreToolUse hook blocking redundant Read calls for unchanged files
- PostToolUse hook recording allowed reads with sorted/merged line ranges
- PostToolUse hook invalidating tracking on Edit/Write
- SessionStart hook wiping tracking on startup and compaction
- Per-agent tracking files (parallel subagent safe)
- Session-scoped state in $CLAUDE_PLUGIN_DATA/{session_id}/
- External file change detection via mtime comparison
- Context decay invalidation based on transcript token growth
- Rewind detection via transcript size decrease
- Unbounded ranges (end: null) for full-file reads
- Project-level configuration via .claude/redundant-read-blocker.json
- Debug logging with [RRB] prefix
- Verbose deny messages with context decay stats
- BATS test suite