@README.md

# Development Guide

## Compatibility Contract

This plugin must remain compatible with Claude Code and Codex.

- Claude Code uses `.claude-plugin/plugin.json` and enforces PullMD routing through the `PreToolUse` hook on `WebFetch`.
- Codex uses `.codex-plugin/plugin.json` and the repository marketplace at `.agents/plugins/marketplace.json`.
- Codex cannot intercept its built-in web research tool through `PreToolUse`; its `SessionStart` hook injects routing guidance instead. Never describe that guidance as mechanical enforcement.
- Keep skill instructions and the Codex directive prompt host-neutral except where setup commands necessarily differ.
- Keep the PullMD MCP server external. Its endpoint and authentication are user-specific, so the plugin must not bundle a fixed `.mcp.json`.
- Synchronize the Claude manifest, Codex manifest, skill frontmatter, and changelog whenever the plugin version changes.

## Directory and File Structure

```text
plugins/web-fetching-with-pullmd/
|-- .claude-plugin/plugin.json
|-- .codex-plugin/plugin.json
|-- AGENTS.md
|-- CLAUDE.md
|-- README.md
|-- CHANGELOG.md
|-- hooks/
|   |-- hooks.json
|   |-- prompts/mcp-tool-directives.md
|   `-- scripts/
|       |-- lib.sh
|       |-- pre-webfetch.sh
|       `-- session-start.sh
`-- skills/
    `-- fetching-web-with-pullmd/SKILL.md
```

## File Navigation

| Task | File |
|------|------|
| Update Claude Code plugin metadata | `.claude-plugin/plugin.json` |
| Update Codex plugin metadata | `.codex-plugin/plugin.json` |
| Update Codex marketplace registration | `.agents/plugins/marketplace.json` at the repository root |
| Change skill triggers or PullMD usage | `skills/fetching-web-with-pullmd/SKILL.md` |
| Change Codex routing guidance | `hooks/prompts/mcp-tool-directives.md` |
| Change hook registration or launch paths | `hooks/hooks.json` |
| Change config, host detection, or state helpers | `hooks/scripts/lib.sh` |
| Change Claude Code WebFetch routing | `hooks/scripts/pre-webfetch.sh` |
| Change state reset or MCP setup diagnostics | `hooks/scripts/session-start.sh` |

## Behavioral Rules

1. Treat PullMD as a black box. Document the MCP tool contract, not PullMD's extraction internals.
2. Refer to the `read_url` tool descriptively in skill and prompt content. The MCP server may be registered under a different name.
3. Keep `pullmd.json` focused on the Claude Code redirect and shared setup diagnostics. Do not require duplicate Codex configuration for an endpoint already stored in Codex's MCP registry.
4. Preserve the Claude Code escape hatch. If plugin state cannot be written, the `WebFetch` hook must fail open.
5. Keep MCP registration checks best-effort. Claude Code checks its JSON registries; Codex checks `codex mcp list --json`. Neither check proves connection or authentication.
6. Keep the Codex directive concise. It compensates for a missing hook interception point and must not duplicate the full skill.

## Validation

```bash
jq empty plugins/web-fetching-with-pullmd/.claude-plugin/plugin.json \
  plugins/web-fetching-with-pullmd/.codex-plugin/plugin.json \
  plugins/web-fetching-with-pullmd/hooks/hooks.json
shellcheck -x -P plugins/web-fetching-with-pullmd/hooks/scripts \
  plugins/web-fetching-with-pullmd/hooks/scripts/*.sh
.bats/bats-core/bin/bats plugin-tests/web-fetching-with-pullmd/*.bats
```
