# File Read Plugin Guidance

This is a portable MCP plugin. Keep the core server and tool contract independent of any specific agent host.

- Keep `.codex-plugin/plugin.json` aligned with the portable MCP server contract.
- Host-specific manifests may adapt launch paths, but must not change `read_file` behavior.
- Keep the MCP tool arguments `file_path`, `offset`, `limit`, `max_bytes`, and `cwd`.
- Keep the implementation in Bash.
- Preserve relative path support through the optional `cwd` argument and the MCP server working-directory fallback.
- Keep output line-numbered so responses are easy to cite and guardrail hooks can reason about returned ranges.
- Preserve text-reader safeguards: reject likely binary files, strip a UTF-8 BOM, normalize CRLF to LF, and cap returned content through byte and token limits.
- Keep the `SessionStart` directive host-neutral apart from the MCP tool name. File-reading command enforcement belongs in a separate guardrail plugin.

## Layout

```text
file-read/
|-- .codex-plugin/plugin.json
|-- hooks/
|   |-- hooks.json
|   |-- prompts/mcp-tool-directives.md
|   `-- scripts/session-start.sh
|-- mcp-server-read/
|   |-- config.json
|   |-- tools.json
|   |-- server.sh
|   `-- lib/read_file.sh
|-- shared/mcpserver_core.sh
|-- README.md
`-- CHANGELOG.md
```

## Validation

Run these checks after edits:

```bash
jq empty plugins/file-read/.codex-plugin/plugin.json plugins/file-read/mcp-server-read/config.json plugins/file-read/mcp-server-read/tools.json
python3 /Users/martinbens/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py plugins/file-read
.bats/bats-core/bin/bats plugin-tests/file-read/*.bats
```
