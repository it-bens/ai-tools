# Changelog

## [1.0.1] - 2026-04-19

### Changed

- Skill description rewritten for more reliable triggering: leads with an imperative `MUST invoke` before any `mcp__plugin_reddit-research_reddit-buddy__*` tool call, enumerates canonical user-facing trigger phrases, and reframes the call budget as a methodology signal rather than a restriction. Addresses a failure mode where the skill was bypassed in favor of direct MCP calls.

## [1.0.0] - 2026-04-18

Initial release.

### Added

- `reddit-researching` skill with decision-driven workflow (Scope, Search, Drill, Synthesize).
- Mode detection for three trigger paths: explicit Reddit requests, generic web research with user consent, and tool-call guardrail.
- `.mcp.json` that auto-starts the `reddit-buddy` MCP server via `npx -y reddit-mcp-buddy`.
- Tool permissions via `allowed-tools` for the four usable reddit-buddy tools plus AskUserQuestion.
- `references/tool-constraints.md` for truncation behavior, field semantics, and rate limits.
- Deliverable definition requiring attributed claims, truncation flags, and call count disclosure.
- README, CLAUDE.md, and plugin manifest.
