---
description: Verify Codex availability and configuration for codex-integration plugin
allowed-tools:
  - Bash
  - mcp__codex-cli__ping
---

You are checking if OpenAI Codex is properly configured and available for the codex-integration plugin.

Run these verification steps in sequence:

## Step 1: Check Codex CLI Installation

Use Bash to check if the Codex CLI is installed:
```bash
which codex
```

If not found, inform the user:
```bash
npm install -g @openai/codex
# or
brew install codex
```

## Step 2: Check Codex CLI Version

If installed, check the version:
```bash
codex --version
```

Minimum required: v0.75.0. Recommend updating if older:
```bash
npm update -g @openai/codex
```

## Step 3: Ping MCP Server

Call the `mcp__codex-cli__ping` tool to verify the MCP server is running:

```json
mcp__codex-cli__ping({})
```

If the tool is not available or fails:
- The MCP server is not registered (restart Claude Code)
- The Codex CLI is not authenticated
- The user's OpenAI account lacks Codex access

## Step 4: Authentication Check

If the ping failed with authentication errors:
```bash
codex login
```

Codex authentication requires an OpenAI account (typically ChatGPT Plus/Pro/Team).

## Step 5: Report Status

Provide a clear summary:

```
Codex Pre-Flight Check Results
==============================

✓ Codex CLI: Installed (version X.X.X)
✓ MCP Server: codex-cli responding
✓ Authentication: Valid

Status: Ready for use

The codex-integration plugin is fully operational.
```

Or if issues found:

```
Codex Pre-Flight Check Results
==============================

✗ Codex CLI: Not found
  → Run: npm install -g @openai/codex

⚠ Codex CLI: Version below v0.75.0
  → Run: npm update -g @openai/codex

⚠ MCP Server: Not responding
  → Restart Claude Code to load the MCP server

✗ Authentication: Not configured
  → Run: codex login

Status: Setup required

Follow the troubleshooting steps above, then run /codex-check again.
```

## Common Issues

- **"command not found: codex"** — Install the Codex CLI
- **"MCP server not found"** — Restart Claude Code after plugin installation
- **"Authentication failed"** — Run `codex login`
- **"Insufficient permissions"** — Upgrade to ChatGPT Plus/Pro/Team
