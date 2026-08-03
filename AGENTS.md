@README.md

# Development Guide

## Required: Use Assistant Authoring Tools

For all plugin and skill development, consult the active assistant's matching authoring workflow before manually creating plugin structures.

### Claude Code

| Task | Tool |
|---|---|
| Create new plugin | `/create-plugin` command |
| Plugin structure guidance | `plugin-dev:plugin-structure` skill |
| Create/edit skills | `plugin-dev:skill-development` skill |
| Create agents | `plugin-dev:agent-development` skill |
| Create commands | `plugin-dev:command-development` skill |
| Create hooks | `plugin-dev:hook-development` skill |
| MCP integration | `plugin-dev:mcp-integration` skill |
| Validate plugin | `plugin-dev:plugin-validator` agent |
| Review skill quality | `plugin-dev:skill-reviewer` agent |

### Codex

| Task | Skill |
|---|---|
| Create or update a plugin and its marketplace entry | `plugin-creator` |
| Create or update a skill | `skill-creator` |
| Verify current Codex conventions | `openai-docs` |

For agents, commands, hooks, and MCP integrations, use a matching installed authoring workflow when one is available. Otherwise, verify the active host's current conventions and inspect the nearest compatible plugin before editing.

## Compatibility Contract

Plugins may support Claude Code, Codex, or both. Claim support only when the plugin has the manifest, marketplace registration, required runtime wiring, and documentation for that host.

| Host | Plugin manifest | Marketplace registry |
|---|---|---|
| Claude Code | `.claude-plugin/plugin.json` | `.claude-plugin/marketplace.json` |
| Codex | `.codex-plugin/plugin.json` | `.agents/plugins/marketplace.json` |

- Keep shared skills, scripts, hooks, and guidance host-neutral where behavior is shared.
- Keep host-specific manifests, wrappers, and setup instructions additive.
- Do not infer Codex compatibility from a plugin name or shared skill body. Use `✅` only when both the Codex manifest and marketplace entry exist, add a parenthesized note for Codex-specific prerequisites or behavior differences, and use `❌` otherwise.

## Adding a New Plugin

1. Choose the hosts the plugin will support.
2. Create the plugin in `plugins/<plugin-name>/` with the active assistant's authoring workflow.
3. Add the manifest and marketplace entry for each supported host, following a current neighboring entry for that host's schema.
4. Keep shared implementation host-neutral and isolate unavoidable host-specific behavior.
5. Update the `README.md` plugin table, keep it alphabetized by plugin name, and set Codex compatibility from the checked-in Codex manifest and marketplace entry.

## Claude Web Compatibility

Skills use `allowed-tools` in frontmatter to pre-approve tools in Claude Code — it auto-approves the listed tools for the invoking turn so Claude is not prompted, and does **not** restrict which tools are available (`disallowed-tools` is the field that removes tools). This field does not work in Claude Web.

To create Claude Web-compatible ZIPs that strip `allowed-tools`:

```bash
./build-skill-for-web.sh ./plugins/<plugin>/skills/<skill>
```

## Directory Purposes

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared project guidance for Codex and Claude Code |
| `AGENTS.override.md` | Codex project override that instructs reading `AGENTS.md` before project-specific additions |
| `CLAUDE.md` | Claude Code wrapper that inlines `AGENTS.md` |
| `plugins/` | Plugin implementations (skills, agents, commands, hooks, and MCP servers) |
| `plugin-tests/` | BATS tests for hook scripts |
| `.agents/plugins/marketplace.json` | Codex marketplace registry |
| `.claude-plugin/marketplace.json` | Claude Code marketplace registry |
| `.github/scripts/setup-bats.sh` | BATS test framework setup |
| `build-skill-for-web.sh` | Creates Claude Web ZIPs |
