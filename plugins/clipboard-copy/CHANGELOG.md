# Changelog

## [1.3.0] - 2026-08-21

### Added

- **No-echo directive** in `hooks/prompts/mcp-tool-directives.md` — after a clipboard copy the agent reports the tool result (byte count, backend, path) and does not reprint the copied content, overriding an instruction to output that same content. Covered by `plugin-tests/clipboard-copy/session_start.bats`.
- **No-echo clause in both tool descriptions** (`mcp-server-clipboard/tools.json`) — carries the same rule on the channel that survives context summarization and reaches hosts that register the MCP server without the hooks.

## [1.2.1] - 2026-07-13

### Fixed

- Codex now launches the MCP server from the plugin root, and shared hook launchers require host-provided plugin-root variables instead of probing repo-local paths.

## [1.2.0] - 2026-07-09

### Added

- Codex plugin metadata (`.codex-plugin/plugin.json`) and repo marketplace metadata (`.agents/plugins/marketplace.json`) while keeping the existing Claude Code manifest and `.mcp.json` path.
- Shared `AGENTS.md` development guidance with `CLAUDE.md` reduced to an `@AGENTS.md` compatibility wrapper.

### Changed

- Hook launcher commands now resolve either Codex or Claude Code plugin-root environments before falling back to repo-local paths.
- Block-message wording is host-neutral so the shared hook prompt works in both Claude Code and Codex.
- Plugin and MCP server metadata now report version `1.2.0`.

## [1.1.0] - 2026-05-10

### Added

- **SessionStart hook** (`hooks/scripts/session-start.sh`) — injects clipboard-copy MCP tool directives into the conversation context at session start so the model prefers `clipboard_copy` / `clipboard_copy_file` from the first turn, instead of relying solely on the reactive `PreToolUse` block message. The directive is held in `hooks/prompts/mcp-tool-directives.md` and emitted via the standard `hookSpecificOutput.additionalContext` channel. Pattern adapted from the gh-tooling plugin.
- **BATS coverage** for the SessionStart hook (`plugin-tests/clipboard-copy/session_start.bats`) — asserts JSON shape (`hookEventName`, non-empty `additionalContext`), directive content (ALWAYS/NEVER framing, both tool names, every blocked Bash command, paste-mode escape hatch), and the silent-success no-op when the prompt template is absent.

## [1.0.0] - 2026-05-08

Initial release.

### Added

- **`clipboard-copy` MCP server** (`mcp-server-clipboard/server.sh`) — bash-based JSON-RPC 2.0 stdio server, registered via `.mcp.json`. Reuses the generic protocol handler in `shared/mcpserver_core.sh`.
- **`clipboard_copy` tool** — copies inline text to the system clipboard. Returns `Copied N bytes to clipboard via <backend>`.
- **`clipboard_copy_file` tool** — copies the contents of a file at an absolute path. Validates that the path is non-empty, absolute, exists, is a regular file, and is readable; rejects everything else with a specific error message.
- **Auto-detected backend cascade** in `_clipboard_detect_backend`:
  - macOS → `pbcopy` → `osc52`
  - Linux → `clip.exe` (WSL) → `wl-copy` (Wayland) → `xclip` / `xsel` (X11) → headless fallback → `osc52`
  - Cygwin / MinGW / MSYS → `clip` → `osc52`
  - everything else → `osc52`
- **OSC 52 fallback** writes a base64-encoded escape sequence to `/dev/tty` (wrapped in a tmux DCS pass-through when `$TMUX` is set), so the server still copies over SSH and in headless environments.
- **PreToolUse(Bash) enforcement hook** (`hooks/scripts/check-clipboard.sh`) — blocks native clipboard-write commands and routes the model to the MCP tools. Recognizes `pbcopy`, `wl-copy`, `clip.exe`, `clip`, and copy-mode `xclip` / `xsel`. Allows paste-mode invocations (`pbpaste`, `wl-paste`, `xclip -o`, `xsel -o`/`--output`). Block message follows the friendly `🤖 Down, model!` voice used by the rest of the marketplace.
