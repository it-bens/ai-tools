# File Read

Portable MCP server that provides a `read_file` tool for local text files. It is packaged as a Codex plugin and can also be launched directly by other MCP clients that support stdio servers.

## Tool

### `read_file`

Reads a local file and returns line-numbered text.

| Field | Required | Description |
|-------|----------|-------------|
| `file_path` | Yes | Absolute path, or a path relative to `cwd` or the MCP server working directory. |
| `offset` | No | 1-based first line to return. Defaults to `1`. |
| `limit` | No | Number of lines to return. If omitted, reads through end of file. |
| `max_bytes` | No | Maximum normalized content bytes to return before truncating. |
| `cwd` | No | Absolute directory used to resolve relative `file_path` values. |

Example:

```json
{
  "file_path": "README.md",
  "offset": 1,
  "limit": 120
}
```

Output starts with file metadata, followed by tab-separated line numbers and text:

```text
File: /path/to/README.md
Lines: 1-2 of 40

     1	# Project
     2	Intro text
```

## Installation

The repository marketplace exposes `file-read` to Codex through `.codex-plugin/plugin.json`.

Other MCP clients can launch `mcp-server-read/server.sh` as a stdio server. The server requires Bash and resolves its support files relative to its own location.

## Design Notes

- `file_path`, `offset`, and `limit` follow the familiar range-reader argument shape used by coding-agent file tools.
- The reader is implemented in Bash.
- It strips a UTF-8 BOM from the first line and normalizes CRLF line endings to LF in returned output.
- Likely binary files are rejected by extension and by NUL-byte detection in the first 8 KiB.
- Returned content is capped by `max_bytes`, `FILE_READ_MAX_BYTES`, and `FILE_READ_MAX_OUTPUT_TOKENS`.
- `CODEX_READ_MAX_BYTES` and `CODEX_READ_MAX_OUTPUT_TOKENS` remain compatibility aliases.
- The plugin stays separate from guardrail plugins such as `redundant-read-blocker` and `native-tools-enforcer`.

## Requirements

- Bash
- `jq`
- `awk`
- `od`
- `grep`
- `head` or `dd`

## Version

Current version: `0.1.0`
