# Changelog

## [0.2.0] - 2026-07-12

### Added

- Session-start hook that directs compatible agent hosts to use `read_file` for local text reads.

## [0.1.0] - 2026-07-09

### Added

- Portable `file-read` MCP server with Codex plugin packaging and direct stdio support for other MCP clients.
- `read_file` MCP tool with `file_path`, `offset`, `limit`, `max_bytes`, and `cwd` arguments.
- Line-numbered file output for local text reads.
- Bash safeguards for likely binary files, UTF-8 BOM stripping, CRLF normalization, and output truncation.
