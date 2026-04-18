@README.md

# Development Guide

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify skill behavior or triggers | `skills/reddit-researching/SKILL.md` |
| Update tool truncation/field/rate-limit details | `skills/reddit-researching/references/tool-constraints.md` |
| Update MCP server launch config | `.mcp.json` |
| Update plugin metadata | `.claude-plugin/plugin.json` |
| Log a new release | `CHANGELOG.md` |

## Skill Structure

`SKILL.md` contains the decision-driven workflow (prerequisite check, mode detection, four phases, deliverable). Tool-specific constraints (truncation behavior, field semantics, rate limits) live in `references/tool-constraints.md` — loaded on demand when Claude needs interpretation context.

When updating the skill, prefer correcting existing content over adding new instructions.

## Authoring Rules (binding)

1. **Triggers live only in frontmatter.** The skill body must not restate when the skill activates. If a body section starts to describe triggers, rewrite it to describe behavior.
2. **Tool names use the plugin-scoped prefix** `mcp__plugin_reddit-research_reddit-buddy__<tool>` in all examples and frontmatter. If Claude Code ever changes this convention, update `SKILL.md`, `references/tool-constraints.md`, and `README.md` together.

## MCP Server

The plugin auto-starts the `reddit-buddy` MCP server via `.mcp.json` using `npx -y reddit-mcp-buddy`. Anonymous access only; rate limit ~10 calls/minute, which is why the skill enforces a 3 to 6 call budget.

Resulting tool prefix: `mcp__plugin_reddit-research_reddit-buddy__<tool>`.

## Testing Changes

After modifying the skill:

1. Restart Claude Code so the MCP server reloads.
2. Confirm the tool list shows `mcp__plugin_reddit-research_reddit-buddy__*`.
3. Trigger the skill three ways and verify behavior:
   - Mention Reddit explicitly → skill activates and proceeds without asking.
   - Ask for generic web research without mentioning Reddit → skill asks the user once before any reddit-buddy call.
   - About to call a reddit-buddy tool directly → skill activates and the decision gate applies.
