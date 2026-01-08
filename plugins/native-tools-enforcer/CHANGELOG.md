# Changelog

## [1.1.1] - 2025-01-08

### Fixed

- Heredocs piped to commands (`cat << EOF | pbcopy`) are no longer blocked
- Previously, all heredoc usage was blocked; now only heredocs writing to files are blocked

## [1.1.0] - 2024-12-22

### Added

- `warn_about_native()` function for non-blocking suggestions
- Warning for simple `ls` commands suggesting Glob tool as alternative
- Documentation distinguishing blocked vs warned commands

### Notes

- `ls` commands are warned but not blocked because:
  - Claude Code docs explicitly recommend `ls` for directory operations
  - Native tools (Glob, Read) cannot provide file metadata (permissions, sizes, ownership)
  - `ls -l`, `ls -la` and other metadata-needing variants are allowed without warning

## [1.0.0] - 2024-12-19

Initial release.

### Added

- PreToolUse hook intercepting Bash commands that should use native Claude Code tools
- Blocks file reading commands (`cat`, `head`, `tail`, `less`, `more`) → Read tool
- Blocks file finding commands (`find`, `locate`) → Glob tool
- Blocks content searching commands (`grep`, `rg`, `ag`, `ack`, piped variants) → Grep tool
- Blocks file writing commands (`echo >`, `printf >`, `cat >`, heredocs, `tee`) → Write tool
- Blocks file editing commands (`sed`, `awk`, `perl -i`, piped variants) → Edit tool
- Helpful error messages with native tool suggestions

### References

- [#10056](https://github.com/anthropics/claude-code/issues/10056) - Agents ignoring CLAUDE.md tool rules
- [#5892](https://github.com/anthropics/claude-code/issues/5892) - Bash commands bypassing file restrictions
