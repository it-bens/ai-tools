# Changelog

All notable changes to the `web-fetching-with-pullmd` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-24

Initial release of `web-fetching-with-pullmd`, an independent plugin that fetches web content through a PullMD instance via its MCP tool. The skill was adapted from PullMD's own bundled Claude Code skill (PullMD by Aeterna Labs, licensed AGPL-3.0).

### Added

- Skill that drives the PullMD MCP server's `read_url` tool to read web pages, documents, and YouTube transcripts as clean Markdown (with the tool's real parameters documented), runs a pre-flight availability check, surfaces prior results via `list_recent` / `get_share`, and falls back to WebFetch when PullMD is unavailable. Tools are referred to descriptively, so a server registered under any name works.
- `pullmd.json` configuration resolved from user level (`~/.claude/pullmd.json`) and project level (`<project>/.claude/pullmd.json` or `<project>/pullmd.json`), merged per key with project values overriding user values. Fields: `instance`, `enabled`, `mcp_tool`, `escape_after`, `allow_hosts`, `debug`. Schema at `pullmd.schema.json`.
- `PreToolUse` hook on `WebFetch` that allows the configured instance host, GitHub, and configured `allow_hosts`, redirects every other page to the PullMD MCP tool, and is a no-op when no instance is configured.
- Per-URL escape hatch: a repeated `WebFetch` of the same URL is allowed once attempts reach `escape_after` (default 2), covering JSON APIs and URLs PullMD cannot handle.
- `SessionStart` hook that wipes the escape-hatch state on startup and compaction, and on startup nudges the user to register and authenticate the MCP server when an instance is configured but no matching server is registered (it detects registration only — not connection or auth state). Backed by `lib.sh` helpers `mcp_server_from_tool` and `mcp_server_configured`.
- README **MCP Server Setup** guide: registering the server in Claude Code (`claude mcp add --transport http`), OAuth and Bearer-token authentication, and a pointer to the PullMD project for server-side setup.
