@README.md

## Directory & File Structure

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
        └── SKILL.md                # When and how to call the PullMD read_url tool
```

## Key Functions

### `hooks/scripts/lib.sh`

Sourced by both hook scripts; sets the `PULLMD_*` globals and provides the shared helpers.

- `load_config(project_dir)` — resolves config from `~/.claude/pullmd.json` (user) and `<project_dir>/.claude/pullmd.json` then `<project_dir>/pullmd.json` (project), merged with `jq` as `defaults * user * project` so project keys win. Sets `PULLMD_INSTANCE`, `PULLMD_ENABLED`, `PULLMD_MCP_TOOL`, `PULLMD_ESCAPE_AFTER`, `PULLMD_ALLOW_HOSTS`, `PULLMD_DEBUG`. Coerces a non-positive `escape_after` back to 2.
- `read_json_or_empty(path)` — emits a file's JSON, or `{}` when missing/unreadable/invalid (validated with `jq empty`). This is what makes a corrupt config fall back instead of breaking the merge.
- `extract_host(url)` — lowercased host, stripped of scheme, userinfo, path, query, fragment, and port. Tolerates a missing scheme.
- `host_allowed(host)` — true for the builtin GitHub hosts (`PULLMD_BUILTIN_ALLOW`) or any `PULLMD_ALLOW_HOSTS` entry, matching the exact host or any subdomain.
- `load_state` / `save_state` / `state_path` / `session_dir` — per-session escape-hatch state at `${CLAUDE_PLUGIN_DATA}/<session_id>/webfetch-attempts.json`, shape `{"urls":{"<url>":<count>}}`. `save_state` writes atomically via tmp + `mv`.
- `mcp_server_from_tool(tool)` — derives the server name from a `mcp__<server>__<tool>` wire name (e.g. `mcp__pullmd__read_url` → `pullmd`); empty for a non-wire name.
- `mcp_server_configured(server, project_dir)` — best-effort check whether a server of that name is registered in `~/.claude.json` (top-level `mcpServers` and every `projects[].mcpServers`) or `<project_dir>/.mcp.json`. Detects configured-ness only, not connection/auth.

### `hooks/scripts/pre-webfetch.sh`

`PreToolUse` on `WebFetch`. Allows and exits 0 when disabled (`enabled: false`), the target host is the instance host, or `host_allowed` passes. Fails hard (exit 2) when enabled but no instance is configured anywhere, telling the user to set `instance` in `pullmd.json`. Otherwise increments the per-URL attempt count: once it reaches `PULLMD_ESCAPE_AFTER` it allows (escape hatch), else it writes the count and exits 2 with a message naming `PULLMD_MCP_TOOL`. Fails open (exit 0) when `CLAUDE_PLUGIN_DATA` is unset, so the escape hatch can never deadlock.

### `hooks/scripts/session-start.sh`

`SessionStart` (startup, compact). On every run, removes the current session's `webfetch-attempts.json` and stale temp files. On `startup` only, when an instance is configured and enabled but no server matching `PULLMD_MCP_TOOL` is registered (`mcp_server_configured`), emits a `hookSpecificOutput.additionalContext` nudge to register and authenticate the server. Gated to `startup` so it does not re-fire on compaction. Detects configured-ness, not connection/auth. Never blocks.

## Navigation

| Task                                           | File                                                            |
|------------------------------------------------|-----------------------------------------------------------------|
| Change config fields, defaults, or merge order | `hooks/scripts/lib.sh` — `load_config`                          |
| Change which hosts bypass the redirect         | `hooks/scripts/lib.sh` — `PULLMD_BUILTIN_ALLOW`, `host_allowed` |
| Change the allow/deny decision or escape hatch | `hooks/scripts/pre-webfetch.sh`                                 |
| Change the deny message wording                | `hooks/scripts/pre-webfetch.sh`                                 |
| Change when escape-hatch state resets          | `hooks/scripts/session-start.sh`, `hooks/hooks.json`            |
| Change the MCP-registration nudge or detection | `hooks/scripts/session-start.sh`, `hooks/scripts/lib.sh` — `mcp_server_configured` |
| Change hook registration or timeouts           | `hooks/hooks.json`                                              |
| Change when/how the skill calls the MCP tool   | `skills/fetching-web-with-pullmd/SKILL.md`                      |

## Authoring Rules

1. **The skill treats PullMD as a black box.** `SKILL.md` documents the `read_url` tool's parameters and when to reach for it — never PullMD's internal extraction mechanics.
2. **The skill never names the hook.** Redirection, the escape hatch, and `pullmd.json` are hook/config concerns. The skill runs a pre-flight (is the `read_url` tool available?), prefers it, and falls back to WebFetch — it never mentions the redirect.
3. **No hardcoded instance.** The instance lives in `pullmd.json`, so the plugin ships unscoped to any one server. When enabled but no instance is configured anywhere, the WebFetch hook fails hard (exit 2) — the hook only runs once the plugin is deliberately activated, so a missing instance is a setup error, not a silent fall-through. The only no-op is `enabled: false` (an explicit opt-out).
4. **Escape-hatch tracking fails open.** The per-URL *redirect* block must never be reachable without a working escape hatch; when escape-hatch state cannot be tracked (`CLAUDE_PLUGIN_DATA` unset), allow. This is distinct from the deliberate fail-hard on a missing instance (rule 3), which has no escape hatch — the fix there is to configure the instance or set `enabled: false`.
5. **Refer to tools descriptively in the skill.** Use "the `read_url` tool of the PullMD MCP server", never the wire name `mcp__pullmd__read_url` — the server may be registered under another name. A concrete tool name belongs only in the hook, which reads it from `mcp_tool`.

## Testing

BATS tests live in `plugin-tests/web-fetching-with-pullmd/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all web-fetching-with-pullmd tests
.bats/bats-core/bin/bats plugin-tests/web-fetching-with-pullmd/*.bats

# Filter by tag
.bats/bats-core/bin/bats --filter-tags config        plugin-tests/web-fetching-with-pullmd/*.bats
.bats/bats-core/bin/bats --filter-tags escape        plugin-tests/web-fetching-with-pullmd/*.bats
.bats/bats-core/bin/bats --filter-tags deny          plugin-tests/web-fetching-with-pullmd/*.bats
.bats/bats-core/bin/bats --filter-tags session-start plugin-tests/web-fetching-with-pullmd/*.bats
```

Files:

- `lib.bats` — `extract_host`, `host_allowed`, `load_config` (defaults, user/project sources, per-key precedence, invalid-JSON fallback, `escape_after` coercion), `mcp_server_from_tool` (server-name derivation), and `mcp_server_configured` (user/local/project-scope detection, absent/missing/invalid-JSON cases).
- `pre_webfetch.bats` — the allow/deny matrix (the no-instance fail-hard, the `enabled: false` no-op, instance host, GitHub, `allow_hosts`, normal pages), the escape hatch, and the deny messages.
- `session_start.bats` — state wipe on startup/compact, session isolation, the no-state path, and the registration nudge (startup-only, silent when registered/disabled/no-instance, custom `mcp_tool` server name).

The helper (`test_helper/common_setup.bash`) isolates `HOME`, `CLAUDE_PROJECT_DIR`, and `CLAUDE_PLUGIN_DATA` per test so the developer's real `~/.claude/pullmd.json` never leaks into a run.
