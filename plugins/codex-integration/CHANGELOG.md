# Changelog

## [2.0.0] - 2026-04-08

### Changed

- **Plugin renamed**: `codex-debugger` -> `codex-integration`
- **MCP server**: Built-in `codex mcp-server` -> official `codex-mcp-server` npm package
- **Architecture**: Agent-first -> skill-first with `context: fork` + `agent:` delegation
- **Agent**: Full protocol -> thin frontmatter-only wrapper (skill owns protocol)
- **Tool names**: `mcp__codex__*` -> `mcp__codex-cli__*`
- **Session management**: `conversationId` + `codex-reply` -> `sessionId` parameter
- **Default model**: `gpt-5` -> `gpt-5.2-codex`
- **Pre-flight**: Test prompt -> `ping` tool

### Added

- `codex-consulting` skill: covers both auto-escalation and on-demand consultation
- Web search capability via `mcp__codex-cli__websearch`
- On-demand consultation mode (no 3-failure prerequisite)

### Removed

- `mcp__codex__codex-reply` tool (replaced by `sessionId`)
- Agent protocol content (moved to skill)

## [1.1.0] - 2025-12-17

### Changed

- Agent: model `sonnet` → `inherit`, added `color: yellow`, structured `<example>` blocks in description
- Command: added `allowed-tools` restriction, explicit JSON invocation format

### Added

- Agent: "Output Format" section, "Do NOT use this agent for" guidance
- Docs: Features section (README), Quick Reference table (AGENTS), removed fragile line numbers

## [1.0.0] - 2025-10-30

Initial release.

### Added

- `codex-escalation` agent for automatic consultation with OpenAI Codex (GPT-5) when stuck after three failed attempts
- `/codex-check` command for verifying Codex setup and troubleshooting issues
- MCP server configuration for native Codex CLI integration
- Progressive escalation protocol (Codex consultation → user notification)
- Multi-turn conversation support with single-turn fallback for compatibility
- Comprehensive context gathering (goal, attempts, errors, code snippets)
