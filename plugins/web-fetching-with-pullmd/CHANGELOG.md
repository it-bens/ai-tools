# Changelog

All notable changes to the `web-fetching-with-pullmd` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-07-25

### Added

- Built-in host rules (`PULLMD_HOST_RULES` in `lib.sh`). Hosts that PullMD cannot serve and that WebFetch cannot reach either are denied with a host-specific message instead of the generic PullMD redirect, and are exempt from the escape hatch — letting the retry through would only hit the upstream block. Ships opinionated and unconfigurable, with one rule covering `reddit.com` and `redd.it`. A user `allow_hosts` entry is checked first and therefore overrides a built-in block, so the defaults can never trap a user.
- `registry.npmjs.org`, `localhost`, and `127.0.0.1` on the built-in allow list. The npm registry serves JSON rather than a page, and a remote PullMD instance has no route to the caller's loopback; both were previously redirected to PullMD and had to burn the escape hatch to get through.
- Codex `SessionStart` guidance now renders the block list from the same table the Claude Code hook reads, so the enforced rules and the injected directive cannot drift apart.
- `query` and `max_tokens` in the skill's parameter table. The `read_url` tool has always accepted them; they return only the sections relevant to a query, which the skill never surfaced.

### Changed

- Under Codex, a missing `mcp-tool-directives.md` no longer suppresses the whole `SessionStart` injection. The static prompt file and the rendered block list are now independent, so the block rules are delivered even when the prompt file is absent.

### Removed

- The skill's `comments`, `comment_depth`, `comment_limit`, and `lang` parameters, the Reddit `read_url` example, and every claim of Reddit support across the skill, both manifests, the Codex directive, and the READMEs. Testing against a live instance showed thread fetches return title and metadata but an empty comment tree at depths 3 and 5, with and without a comment cap and with the cache bypassed, while subreddit listings answer 403 on both `www.` and `old.reddit.com`. `lang` only ever set the comments-section header, so it went with them.

## [1.2.0] - 2026-07-12

### Added

- Codex plugin manifest and repository marketplace registration
- Codex `SessionStart` guidance that prefers PullMD over native web research

### Changed

- Generalized the skill's setup and fallback instructions for Claude Code and Codex
- Made MCP registration diagnostics use the active host's registry
- Moved shared development guidance to `AGENTS.md`, with `CLAUDE.md` loading it through `@AGENTS.md`

## [1.1.0] - 2026-06-24

### Changed

- The `PreToolUse` WebFetch hook now fails hard (blocks the WebFetch, exit 2) when the plugin is enabled but no PullMD instance is configured at any level, instead of silently passing the WebFetch through. The hook only runs once the plugin is deliberately activated, so a missing instance is a setup error — the deny message tells the user to set `instance` in `pullmd.json` and register the MCP server. `enabled: false` remains an explicit no-op opt-out. The registration check stays in the non-blocking `SessionStart` nudge: it is best-effort (registration only, and can miss a server registered under another name), so gating a blocking hook on it could break a working setup.

### Removed

- `pullmd.schema.json`. Nothing consumed it at runtime — `load_config` parses `pullmd.json` directly with its own defaults and coercion, and editor validation via the schema was opt-in and never wired up. The configuration table in the plugin README is now the single source of truth for the `pullmd.json` fields.

## [1.0.0] - 2026-06-24

Initial release of `web-fetching-with-pullmd`, an independent plugin that fetches web content through a PullMD instance via its MCP tool. The skill was adapted from PullMD's own bundled Claude Code skill (PullMD by Aeterna Labs, licensed AGPL-3.0).

### Added

- Skill that drives the PullMD MCP server's `read_url` tool to read web pages, documents, and YouTube transcripts as clean Markdown (with the tool's real parameters documented), runs a pre-flight availability check, surfaces prior results via `list_recent` / `get_share`, and falls back to WebFetch when PullMD is unavailable. Tools are referred to descriptively, so a server registered under any name works.
- `pullmd.json` configuration resolved from user level (`~/.claude/pullmd.json`) and project level (`<project>/.claude/pullmd.json` or `<project>/pullmd.json`), merged per key with project values overriding user values. Fields: `instance`, `enabled`, `mcp_tool`, `escape_after`, `allow_hosts`, `debug`. Schema at `pullmd.schema.json`.
- `PreToolUse` hook on `WebFetch` that allows the configured instance host, GitHub, and configured `allow_hosts`, redirects every other page to the PullMD MCP tool, and is a no-op when no instance is configured.
- Per-URL escape hatch: a repeated `WebFetch` of the same URL is allowed once attempts reach `escape_after` (default 2), covering JSON APIs and URLs PullMD cannot handle.
- `SessionStart` hook that wipes the escape-hatch state on startup and compaction, and on startup nudges the user to register and authenticate the MCP server when an instance is configured but no matching server is registered (it detects registration only — not connection or auth state). Backed by `lib.sh` helpers `mcp_server_from_tool` and `mcp_server_configured`.
- README **MCP Server Setup** guide: registering the server in Claude Code (`claude mcp add --transport http`), OAuth and Bearer-token authentication, and a pointer to the PullMD project for server-side setup.
