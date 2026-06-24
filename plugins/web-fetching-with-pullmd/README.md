# Web Fetching with PullMD

Fetch web pages, documents (PDF/Office/EPUB), and YouTube transcripts as clean, structured Markdown through a PullMD instance instead of raw WebFetch HTML. The plugin ships a skill that explains when and how to call the PullMD MCP tool, plus a `PreToolUse` hook that redirects `WebFetch` of normal pages to that tool. Which PullMD instance to use is set in a `pullmd.json` config file — the plugin is not hardcoded to any one server.

## Quick Start

```bash
/plugin install web-fetching-with-pullmd@itb-ai-tools
```

Create a user-level config pointing at your instance:

```bash
# ~/.claude/pullmd.json
{ "instance": "https://pullmd.example.com" }
```

Register the PullMD MCP server in Claude Code so its `read_url` tool is available (auth details under [MCP Server Setup](#mcp-server-setup)), then restart Claude Code:

```bash
claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user
```

From then on, when Claude reaches for `WebFetch` on a normal page the hook redirects it to the PullMD MCP tool, which returns cleaner Markdown than raw HTML.

## MCP Server Setup

The plugin reads web content through a PullMD instance's MCP `read_url` tool. It does **not** bundle or register that server — set it up once in Claude Code.

### 1. Register the server

```bash
claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user
```

`--scope user` makes it available in every project (recommended when you have one instance). The default scope is `local` (current project only); use `--scope project` to share it with a repo through a checked-in `.mcp.json`.

The server **name** must match the server segment of `mcp_tool` — the default `mcp__pullmd__read_url` implies a server named `pullmd`. Register it under a different name and you must set `mcp_tool` in `pullmd.json` to match.

### 2. Authenticate

A PullMD instance with `PULLMD_AUTH_MODE` set to anything other than `disabled` requires authentication on `/mcp`. Claude Code supports two paths:

- **OAuth** — after adding the server, run `/mcp` in Claude Code. It detects that the server needs authentication and opens a browser for the login and consent flow; the token is then stored and refreshed automatically (in the OS keychain on macOS). Run `/mcp` again to clear authentication.
- **Bearer token** — generate an API key on your instance (`https://pullmd.example.com/settings`) and pass it as a header when registering:

  ```bash
  claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user \
    --header "Authorization: Bearer pmd_..."
  ```

### 3. Verify

Run `/mcp` — `pullmd` should be connected and expose `read_url` (alongside `get_share` and `list_recent`). With that in place and `instance` set in your `pullmd.json`, the redirect hook and the tool line up.

### Server-side setup

Running and configuring the PullMD instance itself — Docker deployment, the `PULLMD_AUTH_MODE` modes, and enabling OAuth (`OAUTH_JWT_SECRET`, `PUBLIC_URL`) — depends on your server. See the PullMD project for the authoritative guide: **<https://github.com/AeternaLabsHQ/pullmd>** (its *Authentication* and *AI-agent integration* sections).

## Configuration

The plugin reads `pullmd.json` from two levels and merges them per key, with the project level overriding the user level:

| Level   | Path                                                          |
|---------|---------------------------------------------------------------|
| User    | `~/.claude/pullmd.json`                                       |
| Project | `<project>/.claude/pullmd.json`, else `<project>/pullmd.json` |

A user-level config typically sets the instance once. A project can then override individual keys — for example raise the escape threshold or allow extra hosts — without restating the instance:

```jsonc
// ~/.claude/pullmd.json
{ "instance": "https://pullmd.example.com" }

// <project>/.claude/pullmd.json
{ "escape_after": 3, "allow_hosts": ["status.example.com"] }
```

| Field          | Type    | Default                 | Description                                                                                                                                                                       |
|----------------|---------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `instance`     | string  | —                       | Base URL of your PullMD service. When unset at every level while the plugin is enabled, the hook fails hard and blocks WebFetch until you configure it (or set `enabled: false`). |
| `enabled`      | boolean | `true`                  | Master switch for the redirect hook.                                                                                                                                              |
| `mcp_tool`     | string  | `mcp__pullmd__read_url` | MCP tool name recommended in the deny message. Override to match your server's tool name.                                                                                         |
| `escape_after` | integer | `2`                     | Allow the Nth WebFetch attempt of the same URL through. Default `2`: first attempt blocked, retry allowed.                                                                        |
| `allow_hosts`  | array   | `[]`                    | Extra hosts always allowed through WebFetch. Matches the exact host or any subdomain.                                                                                             |
| `debug`        | boolean | `false`                 | Log allow/deny decisions to stderr with a `[pullmd]` prefix.                                                                                                                      |

## WebFetch Hook

A `PreToolUse` hook on the `WebFetch` tool decides, for every call:

| Target                                          | Action                                                         |
|-------------------------------------------------|----------------------------------------------------------------|
| `enabled: false`                                | Allow (no-op — explicit opt-out)                               |
| Enabled but no instance configured              | Block and tell the user to configure `pullmd.json`             |
| The configured instance host                    | Allow (share links and direct PullMD pages)                    |
| `github.com` family, or a host in `allow_hosts` | Allow (PullMD is the wrong tool for these)                     |
| Anything else                                   | Deny and tell Claude to use the PullMD MCP tool                |

### Escape hatch

PullMD cannot handle every URL — JSON APIs, or the rare site it fails on. The hook counts attempts per URL within a session. Once attempts reach `escape_after` (default `2`), the same WebFetch is allowed through, so a retry always works. Counters reset on session start and compaction. The pattern mirrors the [`redundant-read-blocker`](../redundant-read-blocker/) plugin.

## Requirements

- `jq`
- A PullMD MCP server exposing a `read_url` tool, registered in Claude Code (see [MCP Server Setup](#mcp-server-setup))

## Layout

```
plugins/web-fetching-with-pullmd/
├── README.md
├── CHANGELOG.md
├── CLAUDE.md
├── .claude-plugin/
│   └── plugin.json                 # Plugin manifest
├── hooks/
│   ├── hooks.json                  # SessionStart + PreToolUse(WebFetch) registration
│   └── scripts/
│       ├── lib.sh                  # Config merge, host parsing, escape-hatch state I/O
│       ├── pre-webfetch.sh         # Allow/deny decision + redirect message
│       └── session-start.sh        # Wipes escape-hatch counters; nudges on missing MCP registration
└── skills/
    └── fetching-web-with-pullmd/
        └── SKILL.md                # When and how to use the PullMD MCP tool
```

## Credits

PullMD is a self-hosted web-to-Markdown service by **Aeterna Labs** (<https://github.com/AeternaLabsHQ/pullmd>), licensed AGPL-3.0. All the heavy lifting — Reddit comment trees, headless-Chromium rendering, document and YouTube extraction — happens in PullMD itself; full credit for that work goes to its authors.

This plugin is an independent, third-party piece of work, not affiliated with Aeterna Labs. Its skill was adapted from PullMD's own bundled Claude Code skill; the redirect hook is an independent reimplementation. The plugin talks to a PullMD instance through its MCP tool and bundles none of PullMD's code.

## License

MIT
