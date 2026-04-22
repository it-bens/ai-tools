# Changelog

## [2.1.1] - 2026-04-22

### Changed

- `setting-up` skill now runs on Haiku (`model: haiku` in frontmatter). The skill is deterministic — run the probe, branch on JSON fields, run the matching case — so the smaller model is sufficient and cheaper for the configuration workflow.

## [2.1.0] - 2026-04-22

### Added

- **SessionStart hook** (`hooks/scripts/session-start.sh`) injects a short directive block into every new session, listing which native tools or Bash helpers Claude should use for the detected mode. Primes the model before the first tool call, reducing the number of commands that would otherwise hit the PreToolUse blocker.
- **Per-mode prompts** in `hooks/prompts/`:
  - `native-tools-new.md` — directs Claude to Read/Write/Edit tools and `bfs`/`ugrep` in Bash.
  - `native-tools-classic.md` — directs Claude to Read/Write/Edit, Glob, and Grep tools.
- **Pass mode stays silent** — no injection when neither toolchain is available, matching the PreToolUse pass-through behavior.

### Changed

- `hooks/hooks.json` description updated to cover both hook stages.

## [2.0.0] - 2026-04-22

### Breaking

- On macOS/Linux **without** `bfs`/`ugrep` installed, the hook now **passes through** (no block, no warning) instead of redirecting to the `Glob`/`Grep` tools. This avoids a block loop on native Claude Code builds that no longer ship the `Glob`/`Grep` tools. Users who still want enforcement in this state should install `bfs` + `ugrep` (the new `setting-up` skill assists with this).

### Added

- **Mode detection** in `hooks/scripts/lib/detect-mode.sh`. Resolves to `new`, `classic`, or `pass` based on:
  1. `NATIVE_TOOLS_ENFORCER_FORCE_NEW` env var (binary override),
  2. OS (`uname -s`),
  3. `command -v bfs && command -v ugrep` probe.
- **`native-tools-enforcer:setting-up` skill** — detects OS + package manager + binary state, offers install assistance (`brew install` on macOS; prints the`sudo` command on Linux), and writes `NATIVE_TOOLS_ENFORCER_FORCE_NEW` to `~/.claude/settings.json` when the user wants to pin behavior.
- **Opt-in debug logging** via `NATIVE_TOOLS_ENFORCER_DEBUG=1`. Writes one TSV line per hook invocation to `$CLAUDE_PLUGIN_DATA/debug.log`. Unset = zero I/O.

### Changed

- Block messages for the `find`/`locate` family now suggest `bfs` in Bash when the resolved mode is `new`; otherwise they suggest the Glob tool as before.
- Block messages for the `grep`/`rg`/`ag`/`ack` family and piped-grep variants now suggest `ugrep` in Bash in `new` mode; Grep tool in `classic`.
- The `ls` warning is suppressed in `new` mode (no `Glob` tool to suggest).

### Unchanged

- `Read`/`Edit`/`Write` tool redirects for `cat`, `head`, `tail`, `sed`, `awk`, `echo >`, `tee`, etc. These tools exist on every build.
- Allow-list for piped grep from command-output sources (`git log | grep`, `ps aux | grep`, etc.).

## [1.2.0] - 2025-01-16

### Changed

- Piped grep/rg is now selectively blocked based on source command
- Commands reading file contents (cat, head, tail, strings, zcat, etc.) piped to grep/rg are blocked
- Commands outputting metadata/results (unzip -l, git log, ps, npm ls, etc.) piped to grep/rg are allowed

### Added

- `is_file_content_command()` function to distinguish file content commands from metadata/output commands
- BATS tests for piped grep behavior covering allowed and blocked patterns
- Documentation in README explaining piped grep behavior

### Fixed

- False positive: `unzip -l *.whl | grep dockerfile` was incorrectly blocked
- The Grep tool can only search files on disk, not filter command output

## [1.1.3] - 2025-01-08

### Fixed

- Redirect patterns (`echo >`, `printf >`, `cat >`) no longer trigger on `>` inside quoted arguments
- Changed filename detection from `[^&]` to `["'a-zA-Z0-9/~._$]` to match valid filename starters
- Previously, commit messages containing `>` characters would cause false positives

## [1.1.2] - 2025-01-08

### Fixed

- Heredoc detection no longer triggers on `<<` appearing in command arguments or quoted strings
- Added command boundary prefix `(^|;|&&)` to heredoc pattern to match other blocking rules

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
