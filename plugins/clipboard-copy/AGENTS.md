@README.md

## Compatibility Contract

This plugin must remain dual-compatible with Claude Code and Codex.

- Claude Code uses `.claude-plugin/plugin.json` and `.mcp.json`.
- Codex uses `.codex-plugin/plugin.json` and the repo marketplace at `.agents/plugins/marketplace.json`.
- The MCP server implementation, hook scripts, and `hooks/prompts/mcp-tool-directives.md` are shared.
- Keep `hooks/hooks.json` compatible with both runtimes. Resolve the plugin root from Codex's `PLUGIN_ROOT` or Claude Code's `CLAUDE_PLUGIN_ROOT`, and fail when neither is available; do not probe cwd-relative fallback paths.
- Do not replace Claude-specific files while adding Codex support. Codex files are additive.

## Directory & File Structure

```
plugins/clipboard-copy/
├── README.md
├── AGENTS.md
├── CLAUDE.md                         # Claude Code wrapper: @AGENTS.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json                  # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json                  # Codex plugin manifest and MCP server declaration
├── .mcp.json                        # Claude Code MCP registration
├── shared/
│   └── mcpserver_core.sh            # Generic JSON-RPC 2.0 stdio handler
├── mcp-server-clipboard/
│   ├── server.sh                    # MCP entry point (referenced from .mcp.json)
│   ├── config.json                  # serverInfo + instructions returned by initialize
│   ├── tools.json                   # Tool schemas returned by tools/list
│   └── lib/
│       └── clipboard.sh             # Backend detection + tool implementations
└── hooks/
    ├── hooks.json                   # SessionStart + PreToolUse(Bash) registration
    ├── prompts/
    │   └── mcp-tool-directives.md   # Static directive injected at SessionStart
    └── scripts/
        ├── session-start.sh         # Emits the directive as additionalContext
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

### SessionStart hook (`hooks/`)

#### `session-start.sh` (entry point)
Drains stdin, locates `hooks/prompts/mcp-tool-directives.md` relative to its own path, JSON-encodes it via `jq -Rs '.'`, and emits a `hookSpecificOutput.additionalContext` object on stdout so the host agent can splice the directive into conversation context at session start. Exits 0 silently if the prompt file is missing or `jq` is unavailable — the SessionStart channel is optional and must never block the session. The directive itself (`hooks/prompts/mcp-tool-directives.md`) is static: clipboard-copy has no per-project config, so the gh-tooling template-assembly machinery (write/label sections, opt-out flag) was dropped in this adaptation.

### PreToolUse hook (`hooks/`)

#### `parse_hook_input()` (in `scripts/lib/common.sh`)
Reads the hook input JSON from stdin, extracts `.tool_input.command` into the `COMMAND` global, and exits 0 (allow) when the command is empty.

#### `block_clipboard(tool, hint)` (in `scripts/lib/common.sh`)
Writes a host-neutral block message to stderr and exits 2 (deny). The message includes the offending command, the suggested MCP tool, the supplied hint, and a generic explanation of why the MCP path is preferred. Keep this text free of Claude-only or Codex-only terminology.

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
| Adjust the SessionStart directive text | `hooks/prompts/mcp-tool-directives.md` |
| Change how the SessionStart directive is assembled or emitted | `hooks/scripts/session-start.sh` |
| Adjust which Bash patterns get blocked | `hooks/scripts/check-clipboard.sh` |
| Adjust the block message | `hooks/scripts/lib/common.sh` — `block_clipboard` |
| Adjust the hook timeout | `hooks/hooks.json` |
| Re-register the Claude Code MCP server entry point | `.mcp.json` |
| Re-register the Codex MCP server entry point | `.codex-plugin/plugin.json` |
| Update Codex marketplace metadata | `.agents/plugins/marketplace.json` at repo root |

## MCP Wire Flow

1. Claude Code spawns `mcp-server-clipboard/server.sh` per `.mcp.json`; Codex spawns the same server through `.codex-plugin/plugin.json`.
2. `server.sh` exports `MCP_CONFIG_FILE`, `MCP_TOOLS_LIST_FILE`, `MCP_LOG_FILE`, sources `mcpserver_core.sh` + `lib/clipboard.sh`, then calls `run_mcp_server`.
3. The loop reads JSON-RPC requests one per line on stdin and writes responses on stdout. The server log goes to `mcp-server-clipboard/server.log` (gitignored — log file rather than committed state).
4. `tools/call clipboard_copy` → `tool_clipboard_copy` → `_clipboard_send_stdin <backend>` → backend utility or OSC 52 escape to `/dev/tty`.

## Codex Smoke Test

After installing the Codex plugin and restarting Codex, the MCP tools should be discoverable as clipboard-copy tools. A verified local install exposed them under `mcp__clipboard_copy` and successfully returned `Copied N bytes to clipboard via pbcopy` for `clipboard_copy`.

## Testing

BATS tests live in `plugin-tests/clipboard-copy/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all clipboard-copy tests
.bats/bats-core/bin/bats plugin-tests/clipboard-copy/*.bats

# Filter by tag
.bats/bats-core/bin/bats --filter-tags hook          plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags detect        plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags tool          plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags block         plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags allow         plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags validate      plugin-tests/clipboard-copy/*.bats
.bats/bats-core/bin/bats --filter-tags session-start plugin-tests/clipboard-copy/*.bats
```

Files:

- `check_clipboard.bats` — block/allow matrix for the PreToolUse hook (pbcopy/wl-copy/clip/clip.exe/xclip/xsel × direct/piped/chained, plus paste-mode and false-positive guards).
- `detect_backend.bats` — `_clipboard_detect_backend` cascade across OS × installed-utility × WAYLAND_DISPLAY/DISPLAY combinations.
- `tool_clipboard_copy_file.bats` — every path-validation branch (missing/empty/relative/nonexistent/directory/unreadable) plus byte-exact dispatcher capture for the success path. Smoke-checks `tool_clipboard_copy` text validation too.
- `session_start.bats` — JSON shape (`hookEventName`, non-empty `additionalContext`), directive content (ALWAYS/NEVER framing, both tool names, every blocked Bash command, paste-mode escape hatch), plus the silent-success path when the prompt template is absent. Pattern adapted from `plugin-tests/gh-tooling/session_start.bats` in the shopware ai-coding-tools repo.

### Mocking

`plugin-tests/clipboard-copy/test_helper/backend_setup.bash` provides `backend_set os=... pbcopy=1 xclip=0 ...` for PATH-based mocking. It restricts PATH to the mock dir alone (so `command -v pbcopy` is deterministic on macOS where the real binary lives in `/usr/bin`) and captures absolute paths to `cat`/`chmod`/`rm`/`uname` for its own use. Call `backend_setup_init` in `setup()` and `backend_setup_cleanup` in `teardown()`.

The `tool_clipboard_copy_file.bats` suite stubs `_clipboard_send_stdin` to capture bytes to a tempfile rather than touching the real clipboard, so the success path is verified without depending on any platform utility being installed.

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
