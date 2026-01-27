# Changelog

## [1.0.1] - 2025-01-27

### Changed

- Removed native tools alternative from error message
- Claude now only receives guidance to retry with Opus model

## [1.0.0] - 2025-01-26

Initial release.

### Added

- PreToolUse hook intercepting Task tool calls for Explore subagent
- Blocks Explore when model is not `opus`
- Allows non-Explore subagents (Plan, general-purpose, Bash, etc.)
- Error message guiding Claude to retry with Opus
- BATS test suite with blocking, allow, and input validation tests

### References

- [Lossy compression issue](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Subagent documentation gaps](https://github.com/anthropics/claude-code/issues/10469)
