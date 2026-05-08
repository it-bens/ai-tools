@README.md

## Directory & File Structure

```
plugins/clipboard-copy/
├── README.md
├── CLAUDE.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json                  # Plugin manifest
├── .mcp.json                        # Registers the clipboard-copy MCP server
├── shared/
│   └── mcpserver_core.sh            # Generic JSON-RPC 2.0 stdio handler
├── mcp-server-clipboard/
│   ├── server.sh                    # MCP entry point (referenced from .mcp.json)
│   ├── config.json                  # serverInfo + instructions returned by initialize
│   ├── tools.json                   # Tool schemas returned by tools/list
│   └── lib/
│       └── clipboard.sh             # Backend detection + tool implementations
└── hooks/
    ├── hooks.json                   # PreToolUse(Bash) registration
    └── scripts/
        ├── check-clipboard.sh       # Pattern-matches and blocks native writes
        └── lib/
            └── common.sh            # parse_hook_input + block_clipboard helpers
```

## Key Functions

### MCP server (`mcp-server-clipboard/`)

#### `_clipboard_detect_backend()` (in `lib/clipboard.sh`)
Echoes the backend name for the current environment. Resolution order, scoped to `uname -s`:

- **Darwin** → `pbcopy` → `osc52`
- **Linux** → `clip.exe` (WSL) → `wl-copy` (Wayland) → `xclip` / `xsel` (X11) → `wl-copy`/`xclip`/`xsel` again as a headless fallback → `osc52`
- **CYGWIN/MINGW/MSYS** → `clip` → `osc52`
- everything else → `osc52`

Pure function; no side effects.

#### `_clipboard_b64()` (in `lib/clipboard.sh`)
Base64-encodes stdin without line wraps. Uses `base64 -w 0` when GNU base64 is available, falls back to `base64 | tr -d '\r\n'` for BSD/macOS, and to `openssl base64 -A` if neither is present. Returns 1 if neither is reachable.

#### `_clipboard_send_stdin(backend)` (in `lib/clipboard.sh`)
Reads stdin and dispatches to the right utility (`pbcopy`, `wl-copy`, `xclip -selection clipboard`, `xsel --clipboard --input`, `clip.exe`, `clip`). For `osc52` it buffers stdin, base64-encodes, wraps in a tmux DCS pass-through when `$TMUX` is set, and writes the escape sequence to `/dev/tty` so it stays out of the JSON-RPC channel. Returns 1 if `/dev/tty` is not writable in OSC 52 mode.

#### `tool_clipboard_copy(args)` (in `lib/clipboard.sh`)
Reads `.text` from the JSON args, validates it is non-empty, picks a backend, pipes the text via `printf '%s'` into `_clipboard_send_stdin`, and emits `Copied N bytes to clipboard via <backend>`.

#### `tool_clipboard_copy_file(args)` (in `lib/clipboard.sh`)
Reads `.path` from the JSON args. Validates that the path is non-empty, absolute (starts with `/`), exists, is a regular file (rejects directories and special files), and is readable. Picks a backend, redirects the file directly into `_clipboard_send_stdin`, and emits `Copied N bytes from <path> to clipboard via <backend>`. Size is read with `wc -c < "$path" | tr -d ' '` for portability between BSD and GNU `wc`.

#### `run_mcp_server` (in `shared/mcpserver_core.sh`)
JSON-RPC 2.0 stdio loop. Dispatches `initialize`, `tools/list`, `tools/call`, `notifications/initialized`, and `ping`. Tool calls invoke `tool_<name>` functions; missing functions return JSON-RPC error -32601.

### PreToolUse hook (`hooks/`)

#### `parse_hook_input()` (in `scripts/lib/common.sh`)
Reads the hook input JSON from stdin, extracts `.tool_input.command` into the `COMMAND` global, and exits 0 (allow) when the command is empty.

#### `block_clipboard(tool, hint)` (in `scripts/lib/common.sh`)
Writes the friendly `🤖 Down, model!` message to stderr and exits 2 (deny). The message includes the offending command, the suggested MCP tool, the supplied hint, and a generic explanation of why the MCP path is preferred.

#### `check-clipboard.sh` (entry point)
Sources `lib/common.sh`, calls `parse_hook_input`, then runs a series of grep -E checks against `$COMMAND`. Blocks `pbcopy`, `wl-copy`, `clip.exe`, and `clip` at the start of any command segment (`^|;|&&|\|`). Blocks `xclip` / `xsel` only when no paste flag (`-o` / `-out` / `--output`) is present in the same segment — `[^|;&]*` keeps the lookup scoped so a later `xsel -o` cannot excuse an earlier `xclip -i`.

## Navigation

| Task | File |
|---|---|
| Change backend detection cascade | `mcp-server-clipboard/lib/clipboard.sh` — `_clipboard_detect_backend` |
| Add a new clipboard backend | `mcp-server-clipboard/lib/clipboard.sh` — extend `_clipboard_detect_backend` and `_clipboard_send_stdin` |
| Change OSC 52 wrapping (e.g. screen support) | `mcp-server-clipboard/lib/clipboard.sh` — `osc52` branch in `_clipboard_send_stdin` |
| Add a new MCP tool | Add `tool_<name>` to `lib/clipboard.sh` and a schema entry to `mcp-server-clipboard/tools.json` |
| Update tool descriptions / schemas | `mcp-server-clipboard/tools.json` |
| Update server-level `instructions` text | `mcp-server-clipboard/config.json` |
| Adjust which Bash patterns get blocked | `hooks/scripts/check-clipboard.sh` |
| Adjust the block message | `hooks/scripts/lib/common.sh` — `block_clipboard` |
| Adjust the hook timeout | `hooks/hooks.json` |
| Re-register the MCP server entry point | `.mcp.json` |

## MCP Wire Flow

1. Claude Code spawns `mcp-server-clipboard/server.sh` per `.mcp.json`.
2. `server.sh` exports `MCP_CONFIG_FILE`, `MCP_TOOLS_LIST_FILE`, `MCP_LOG_FILE`, sources `mcpserver_core.sh` + `lib/clipboard.sh`, then calls `run_mcp_server`.
3. The loop reads JSON-RPC requests one per line on stdin and writes responses on stdout. The server log goes to `mcp-server-clipboard/server.log` (gitignored — log file rather than committed state).
4. `tools/call clipboard_copy` → `tool_clipboard_copy` → `_clipboard_send_stdin <backend>` → backend utility or OSC 52 escape to `/dev/tty`.

## Manual Smoke Test

The MCP server is just a stdio process — drive it with hand-crafted JSON-RPC:

```bash
SERVER=./mcp-server-clipboard/server.sh

# Initialize + list + copy
{
  jq -c -n '{jsonrpc:"2.0",id:1,method:"initialize",params:{}}'
  jq -c -n '{jsonrpc:"2.0",id:2,method:"tools/list",params:{}}'
  jq -c -n '{jsonrpc:"2.0",id:3,method:"tools/call",params:{name:"clipboard_copy",arguments:{text:"hello"}}}'
} | "$SERVER" | jq -c .

pbpaste   # macOS: should show "hello"

# clipboard_copy_file end-to-end
echo "from disk" > /tmp/cliptest.txt
jq -c -n --arg p /tmp/cliptest.txt \
  '{jsonrpc:"2.0",id:1,method:"tools/call",params:{name:"clipboard_copy_file",arguments:{path:$p}}}' \
  | "$SERVER" | jq -c .
pbpaste
rm /tmp/cliptest.txt
```

Drive the hook with synthetic PreToolUse JSON:

```bash
HOOK=./hooks/scripts/check-clipboard.sh

# Expect exit 2 + block message on stderr
printf '%s' '{"tool_input":{"command":"echo hi | pbcopy"}}' | bash "$HOOK"

# Expect exit 0 (allow) for paste reads and unrelated commands
printf '%s' '{"tool_input":{"command":"xclip -o > out.txt"}}' | bash "$HOOK"
printf '%s' '{"tool_input":{"command":"git status"}}'         | bash "$HOOK"
```
