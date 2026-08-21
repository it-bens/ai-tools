# Clipboard Copy

A bash-based MCP server that provides cross-platform clipboard tools: `clipboard_copy` (inline text) and `clipboard_copy_file` (contents of a file at an absolute path). Auto-detects the right backend (pbcopy / wl-copy / xclip / xsel / clip.exe / clip) and falls back to OSC 52 escape sequences when no native utility is available — so it still works over SSH and in headless environments.

The plugin is intentionally compatible with both Claude Code and Codex. Claude Code uses `.claude-plugin/plugin.json` plus `.mcp.json`; Codex uses `.codex-plugin/plugin.json` and the repo marketplace at `.agents/plugins/marketplace.json`. The MCP server, hook scripts, and directive prompt are shared.

## Quick Start

### Claude Code

```bash
/plugin install clipboard-copy@itb-ai-tools
```

Restart Claude Code so the MCP server is registered. Then ask Claude to copy something:

> Copy the latest changelog entry to my clipboard.

Claude will call `clipboard_copy` with the text; the server picks the backend appropriate for your machine.

### Codex

From a clone of this repository, add the repo marketplace once:

```bash
codex plugin marketplace add <repo-root>
```

Then install `clipboard-copy` from Codex's plugin browser, restart Codex, and ask Codex to copy something:

> Copy the latest changelog entry to my clipboard.

Codex exposes the same MCP tools. In the tested local install, they appear under the `mcp__clipboard_copy` namespace as `clipboard_copy` and `clipboard_copy_file`.

## Tools

### `clipboard_copy`

Writes inline text to the system clipboard.

| Argument | Type   | Required | Description                                                     |
|----------|--------|----------|-----------------------------------------------------------------|
| `text`   | string | yes      | The text to copy. Sent verbatim — no trailing newline appended. |

On success returns `Copied N bytes to clipboard via <backend>`.

### `clipboard_copy_file`

Writes the contents of a file to the system clipboard. Useful when the content is already on disk — for example a temp file the model just wrote — and would be wasteful to send back through the MCP channel as inline text.

| Argument | Type   | Required | Description                                                                  |
|----------|--------|----------|------------------------------------------------------------------------------|
| `path`   | string | yes      | Absolute filesystem path to the file whose contents should be copied.        |

The path must be absolute, point to an existing regular file, and be readable. On success returns `Copied N bytes from <path> to clipboard via <backend>`.

Both tool descriptions carry the no-echo rule described under [SessionStart Hook](#sessionstart-hook), so it applies even on a host that registers the MCP server without the plugin's hooks.

## Backend Detection

The server picks the first available backend in this order, scoped to the OS:

| OS                              | Detection order                                                           |
|---------------------------------|---------------------------------------------------------------------------|
| macOS (`Darwin`)                | `pbcopy` → `osc52`                                                        |
| Linux                           | `clip.exe` (WSL) → `wl-copy` (Wayland) → `xclip` → `xsel` (X11) → `osc52` |
| Cygwin / MinGW / MSYS (Windows) | `clip` → `osc52`                                                          |
| Other                           | `osc52`                                                                   |

## SessionStart Hook

A `SessionStart` hook injects a short directive into the conversation context at the start of every session, naming `clipboard_copy` / `clipboard_copy_file` as the right way to write to the clipboard and listing the Bash commands that are blocked. This complements the reactive `PreToolUse` block message below: the model sees the directive *before* it ever reaches for `pbcopy`, instead of only being corrected after the fact.

The directive also bans reprinting copied content into the session. After a copy the model reports the tool result — byte count, backend, and the path for `clipboard_copy_file` — and stays silent about the content itself, even when the surrounding instruction asks for that content to be output. Printing it is correct only when the user asks for it after the copy has already happened.

The directive text lives in `hooks/prompts/mcp-tool-directives.md`. The hook script (`hooks/scripts/session-start.sh`) emits it via `hookSpecificOutput.additionalContext`.

The hook registration is shared between Claude Code and Codex. It resolves the plugin root from Codex's `PLUGIN_ROOT` or Claude Code's `CLAUDE_PLUGIN_ROOT` and fails explicitly when neither host-provided variable is available.

## Bash Enforcement Hook

A `PreToolUse` hook on the `Bash` tool blocks native clipboard-write commands and routes them to the MCP tools, mirroring the gh-tooling approach. Blocked invocations exit with code 2 and a hint pointing to `clipboard_copy` / `clipboard_copy_file`.

| Command | Action |
|---|---|
| `pbcopy` (anywhere in segment) | Block |
| `wl-copy` (anywhere in segment) | Block |
| `clip.exe` (anywhere in segment) | Block |
| `clip` (at start of segment) | Block |
| `xclip` without `-o` / `-out` | Block |
| `xsel` without `-o` / `--output` | Block |
| `pbpaste`, `wl-paste`, `xclip -o`, `xsel -o` | Allow (clipboard reads are not the target) |

Pipes, `;`, `&&`, and `\|\|` are recognized as command separators so chained invocations are caught:

```bash
echo "secret" | pbcopy            # blocked
date && wl-copy < file            # blocked
xclip -selection clipboard < f    # blocked
xclip -o > out.txt                # allowed (paste)
```

## OSC 52 Fallback

When no native utility is available — over SSH, in containers, in restricted environments — the server falls back to writing an [OSC 52](https://www.xfree86.org/current/ctlseqs.html) terminal escape sequence to `/dev/tty`. The escape is wrapped in a tmux DCS pass-through when `$TMUX` is set.

OSC 52 is supported by most modern terminal emulators, including:

- iTerm2
- kitty
- Alacritty
- WezTerm
- Windows Terminal
- foot
- tmux (with the wrapping the server applies automatically)

If your terminal does not honor OSC 52 the copy will silently no-op as far as the system clipboard is concerned — there is no way for the server to detect that.

## Requirements

- `bash` 4+
- `jq`
- `base64` or `openssl` (only used by the OSC 52 fallback)
- A clipboard utility for your platform if you want to skip OSC 52:
  - macOS: `pbcopy` (preinstalled)
  - Linux Wayland: `wl-clipboard` (`wl-copy`)
  - Linux X11: `xclip` or `xsel`
  - WSL: `clip.exe` (preinstalled on Windows)
  - Cygwin/MSYS: `clip`

## Layout

```
plugins/clipboard-copy/
├── AGENTS.md                      # Shared development guidance for Codex and Claude Code
├── CLAUDE.md                      # Claude Code wrapper: @AGENTS.md
├── .claude-plugin/
│   └── plugin.json                 # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json                 # Codex plugin manifest
├── .mcp.json                       # Claude Code MCP registration
├── README.md
├── shared/
│   └── mcpserver_core.sh           # JSON-RPC 2.0 stdio handler
├── hooks/
│   ├── hooks.json                  # SessionStart + PreToolUse(Bash) registration
│   ├── prompts/
│   │   └── mcp-tool-directives.md  # Static template injected at SessionStart
│   └── scripts/
│       ├── session-start.sh        # Emits the directive as additionalContext
│       ├── check-clipboard.sh      # Pattern-matches and blocks native writes
│       └── lib/
│           └── common.sh           # parse_hook_input + block_clipboard
└── mcp-server-clipboard/
    ├── server.sh                    # Entry point (registered in .mcp.json)
    ├── config.json                  # MCP serverInfo + instructions
    ├── tools.json                   # Tool schemas (clipboard_copy, clipboard_copy_file)
    └── lib/
        └── clipboard.sh             # Backend detection + tool implementations
```

Codex marketplace metadata lives outside the plugin directory at `.agents/plugins/marketplace.json`, with `source.path` pointing back to `./plugins/clipboard-copy`.

## License

MIT
