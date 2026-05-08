# Clipboard Copy

A bash-based MCP server that provides cross-platform clipboard tools: `clipboard_copy` (inline text) and `clipboard_copy_file` (contents of a file at an absolute path). Auto-detects the right backend (pbcopy / wl-copy / xclip / xsel / clip.exe / clip) and falls back to OSC 52 escape sequences when no native utility is available — so it still works over SSH and in headless environments.

## Quick Start

```bash
/plugin install clipboard-copy@itb-ai-tools
```

Restart Claude Code so the MCP server is registered. Then ask Claude to copy something:

> Copy the latest changelog entry to my clipboard.

Claude will call `clipboard_copy` with the text; the server picks the backend appropriate for your machine.

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

## Backend Detection

The server picks the first available backend in this order, scoped to the OS:

| OS                              | Detection order                                                           |
|---------------------------------|---------------------------------------------------------------------------|
| macOS (`Darwin`)                | `pbcopy` → `osc52`                                                        |
| Linux                           | `clip.exe` (WSL) → `wl-copy` (Wayland) → `xclip` → `xsel` (X11) → `osc52` |
| Cygwin / MinGW / MSYS (Windows) | `clip` → `osc52`                                                          |
| Other                           | `osc52`                                                                   |

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
├── .claude-plugin/
│   └── plugin.json
├── .mcp.json
├── README.md
├── shared/
│   └── mcpserver_core.sh           # JSON-RPC 2.0 stdio handler
├── hooks/
│   ├── hooks.json                  # PreToolUse(Bash) registration
│   └── scripts/
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

## License

MIT
