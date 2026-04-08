@README.md

## Quick Reference

| Component | Purpose | File |
|-----------|---------|------|
| Skill | Consultation protocol | `skills/codex-consulting/SKILL.md` |
| Agent | Skill executor (thin wrapper) | `agents/codex-escalation.md` |
| Command | Setup verification | `commands/codex-check.md` |
| MCP Server | Codex integration | `.mcp.json` |

## When to Modify

| Want to change... | Modify |
|-------------------|--------|
| Consultation protocol | `skills/codex-consulting/SKILL.md` |
| MCP tools available | `agents/codex-escalation.md` (tools field) + `skills/codex-consulting/SKILL.md` (allowed-tools) |
| MCP server config | `.mcp.json` |
| Pre-flight checks | `commands/codex-check.md` |
| Plugin metadata | `.claude-plugin/plugin.json` |

## Integration Points

- **MCP Server**: `codex-cli` via `npx -y codex-mcp-server`
- **Tools**: `mcp__codex-cli__codex`, `mcp__codex-cli__websearch`, `mcp__codex-cli__ping`
- **External Dependency**: Codex CLI v0.75.0+ with OpenAI authentication
