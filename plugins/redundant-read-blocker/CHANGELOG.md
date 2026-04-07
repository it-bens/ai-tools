# Changelog

## [1.0.1] - 2026-04-07

### Fixed

- Pipeline crash in `get_latest_context_tokens` when transcript contains truncated JSON lines (`set -euo pipefail` + `pipefail` interaction)
- Non-atomic tracker file writes that could corrupt JSON on timeout or signal interruption (now uses `mktemp` + `mv`)
- `post-edit-write.sh` bypassing shared `load_tracker`/`save_tracker` functions
- Range calculation asymmetry between `pre-read.sh` and `post-read.sh` when only offset or limit is provided
- Missing POSIX trailing newlines on all files

### Changed

- Consolidated per-script jq input parsing from 5-8 separate invocations to a single call (reduced subprocess spawns per hook execution)
- Applied lowercase variable naming convention for script-local variables (UPPERCASE reserved for env vars and config constants)
- Replaced `echo` with `printf '%s\n'` for data output safety
- Session cleanup now also removes stale atomic-write temp files (`.rrb-tmp.*`)

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