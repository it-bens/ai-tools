# Web Fetching with PullMD

Fetch web pages, documents (PDF/Office/EPUB), and YouTube transcripts as clean, structured Markdown through a PullMD instance. The shared skill supports Claude Code and Codex. Claude Code additionally gets an enforced `WebFetch` redirect; Codex gets a `SessionStart` directive that prefers PullMD over native web research because Codex hooks cannot intercept that built-in tool.

## Installation

### Claude Code

```bash
/plugin install web-fetching-with-pullmd@itb-ai-tools
```

Create the redirect-hook configuration, register the MCP server, and restart Claude Code:

```bash
# ~/.claude/pullmd.json
{ "instance": "https://pullmd.example.com" }

claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user
```

### Codex

From a clone of this repository, add the repository marketplace once:

```bash
codex plugin marketplace add <repo-root>
```

Install `web-fetching-with-pullmd` from the Codex plugin browser, then register the PullMD MCP server:

```bash
codex mcp add pullmd --url https://pullmd.example.com/mcp
codex mcp login pullmd
```

Review and trust the plugin hooks (`/hooks` in the Codex CLI), then start a new session. Codex does not require `pullmd.json`; its MCP registration already stores the instance URL.

## MCP Server Setup

The plugin reads web content through a PullMD instance's MCP `read_url` tool. It does **not** bundle or register that server because the endpoint and authentication are user-specific.

### Claude Code

```bash
claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user
```

`--scope user` makes it available in every project (recommended when you have one instance). The default scope is `local` (current project only); use `--scope project` to share it with a repo through a checked-in `.mcp.json`.

The server **name** must match the server segment of `mcp_tool` — the default `mcp__pullmd__read_url` implies a server named `pullmd`. Register it under a different name and you must set `mcp_tool` in `pullmd.json` to match.

For OAuth, run `/mcp` after registration. Claude Code opens the login flow and manages the resulting token. For a bearer token, generate an API key on the PullMD instance and pass it as a registration header:

```bash
claude mcp add --transport http pullmd https://pullmd.example.com/mcp --scope user \
  --header "Authorization: Bearer pmd_..."
```

Run `/mcp` to verify that `pullmd` is connected and exposes `read_url`, `get_share`, and `list_recent`.

### Codex

Register a streamable HTTP server and authenticate with OAuth:

```bash
codex mcp add pullmd --url https://pullmd.example.com/mcp
codex mcp login pullmd
```

For bearer-token authentication, provide the name of an environment variable that Codex can read:

```bash
codex mcp add pullmd --url https://pullmd.example.com/mcp \
  --bearer-token-env-var PULLMD_TOKEN
```

Run `codex mcp list` to verify registration, then start a new session so the MCP tools and plugin skill are available.

### Server-side setup

Running and configuring the PullMD instance itself — Docker deployment, the `PULLMD_AUTH_MODE` modes, and enabling OAuth (`OAUTH_JWT_SECRET`, `PUBLIC_URL`) — depends on your server. See the PullMD project for the authoritative guide: **<https://github.com/AeternaLabsHQ/pullmd>** (its *Authentication* and *AI-agent integration* sections).

## Claude Code Hook Configuration

The Claude Code `WebFetch` redirect reads `pullmd.json` from two levels and merges them per key, with the project level overriding the user level:

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
| `enabled`      | boolean | `true`                  | Master switch for the Claude Code redirect hook.                                                                                                                                  |
| `mcp_tool`     | string  | `mcp__pullmd__read_url` | MCP tool name recommended in the deny message. Override to match your server's tool name.                                                                                         |
| `escape_after` | integer | `2`                     | Allow the Nth WebFetch attempt of the same URL through. Default `2`: first attempt blocked, retry allowed.                                                                        |
| `allow_hosts`  | array   | `[]`                    | Extra hosts always allowed through WebFetch. Matches the exact host or any subdomain.                                                                                             |
| `debug`        | boolean | `false`                 | Log allow/deny decisions to stderr with a `[pullmd]` prefix.                                                                                                                      |

## Host Behavior

### Claude Code WebFetch Hook

A `PreToolUse` hook on the `WebFetch` tool decides, for every call:

| Target                                          | Action                                                         |
|-------------------------------------------------|----------------------------------------------------------------|
| `enabled: false`                                | Allow (no-op — explicit opt-out)                               |
| Enabled but no instance configured              | Block and tell the user to configure `pullmd.json`             |
| The configured instance host                    | Allow (share links and direct PullMD pages)                    |
| Built-in allow list, or a host in `allow_hosts` | Allow (PullMD is the wrong tool for these)                     |
| Built-in block list                             | Deny with a host-specific message and no escape hatch          |
| Anything else                                   | Deny and tell Claude Code to use the PullMD MCP tool           |

### Built-in host rules

Two hardcoded lists ship with the plugin. They are opinionated on purpose and need no configuration.

**Always allowed** — PullMD is the wrong tool, so these stay on WebFetch:

| Host | Why |
|---|---|
| `github.com`, `www.github.com`, `raw.githubusercontent.com`, `gist.github.com` | Belongs on `gh` / WebFetch |
| `registry.npmjs.org` | Serves JSON, not a page |
| `localhost`, `127.0.0.1` | A remote PullMD instance has no route to the caller's loopback |

**Denied by default** — PullMD cannot serve them and WebFetch cannot reach them either, so the deny carries a host-specific message and the escape hatch does not apply:

| Host | Why |
|---|---|
| `reddit.com`, `redd.it` | PullMD returns no comment tree, and Reddit answers direct fetches with 403 |

Both lists match the exact host or any subdomain, so `reddit.com` also covers `www.`, `old.`, and `np.reddit.com`. An `allow_hosts` entry is checked first and therefore overrides a built-in block, which keeps the opinionated defaults from becoming a trap.

Under Codex, where a `PreToolUse` hook cannot intercept the native web tool, the block list is rendered into the `SessionStart` directive from the same table.

### Escape hatch

PullMD cannot handle every URL — JSON APIs, or the rare site it fails on. The hook counts attempts per URL within a session. Once attempts reach `escape_after` (default `2`), the same WebFetch is allowed through, so a retry always works. Counters reset on session start and compaction. The pattern mirrors the [`redundant-read-blocker`](../redundant-read-blocker/) plugin.

Hosts on the built-in block list are exempt: they are denied before the counter is touched, because letting the retry through would only hit the upstream block.

### Codex Native Web Research

Codex loads the shared skill and receives a concise `SessionStart` directive to prefer PullMD for ordinary pages, documents, and YouTube transcripts, followed by the built-in block list rendered from the same table the Claude Code hook reads. This is model guidance, not enforcement: Codex `PreToolUse` hooks cannot currently intercept its built-in web research tool. GitHub URLs and JSON APIs stay on Codex's native web tooling, and failed PullMD calls can fall back there when the format is supported.

Codex requires users to review and trust the plugin hooks. Changed hook definitions are skipped until trusted again.

## Requirements

- `jq`
- Bash
- A PullMD MCP server exposing a `read_url` tool, registered in the active host (see [MCP Server Setup](#mcp-server-setup))

## Layout

```
plugins/web-fetching-with-pullmd/
├── README.md
├── CHANGELOG.md
├── AGENTS.md
├── CLAUDE.md                      # Loads AGENTS.md for Claude Code
├── .claude-plugin/
│   └── plugin.json                 # Claude Code manifest
├── .codex-plugin/
│   └── plugin.json                 # Codex manifest
├── hooks/
│   ├── hooks.json                  # SessionStart + PreToolUse(WebFetch) registration
│   ├── prompts/
│   │   └── mcp-tool-directives.md  # Codex native-web routing guidance
│   └── scripts/
│       ├── lib.sh                  # Config merge, host parsing, built-in host rules, escape-hatch state I/O
│       ├── pre-webfetch.sh         # Allow/deny decision + redirect message
│       └── session-start.sh        # Resets state, injects guidance, checks MCP registration
└── skills/
    └── fetching-web-with-pullmd/
        └── SKILL.md                # When and how to use the PullMD MCP tool
```

## Credits

PullMD is a self-hosted web-to-Markdown service by **Aeterna Labs** (<https://github.com/AeternaLabsHQ/pullmd>), licensed AGPL-3.0. All the heavy lifting — headless-Chromium rendering, document and YouTube extraction — happens in PullMD itself; full credit for that work goes to its authors.

This plugin is an independent, third-party piece of work, not affiliated with Aeterna Labs. Its skill was adapted from PullMD's own bundled Claude Code skill; the redirect hook is an independent reimplementation. The plugin talks to a PullMD instance through its MCP tool and bundles none of PullMD's code.

## License

MIT
