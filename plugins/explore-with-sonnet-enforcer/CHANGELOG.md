# Changelog

## [1.0.0] - 2025-01-26

Initial release.

### Added

- PreToolUse hook intercepting Task tool calls for Explore subagent
- Blocks Explore when model is not `sonnet`
- Allows non-Explore subagents (Plan, general-purpose, Bash, etc.)
- Helpful error message guiding Claude to retry with Sonnet or use native tools
- BATS test suite with blocking, allow, and input validation tests

### References

- [Lossy compression issue](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Subagent documentation gaps](https://github.com/anthropics/claude-code/issues/10469)
