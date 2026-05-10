ALWAYS use the clipboard-copy MCP tools to write to the system clipboard. NEVER run native clipboard-write commands via Bash.

## Tools (clipboard-copy)

- `clipboard_copy(text)` — copy inline text to the clipboard.
- `clipboard_copy_file(path)` — copy the contents of a file at an absolute path. Prefer this when the content is already on disk; it avoids round-tripping the bytes through the MCP channel as an inline string.

## Blocked Bash equivalents

`pbcopy`, `wl-copy`, `xclip` (without `-o`/`-out`), `xsel` (without `-o`/`--output`), `clip.exe`, and `clip` are blocked by a PreToolUse hook. Use the MCP tools above instead.

Paste-mode reads (`pbpaste`, `wl-paste`, `xclip -o`, `xsel -o`/`--output`) are not affected and remain available via Bash.
