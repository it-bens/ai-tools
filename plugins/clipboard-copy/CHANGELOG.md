# Changelog

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
