# Commit Message Writer Extension Setup

One-time setup skill that wires up a project to extend the `commit-message-writer:writing-commit-messages` skill in Claude Code or Codex. It provisions a shared overlay content file and the host-specific project configuration that exposes it to the agent.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install commit-message-writer-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/commit-message-writer-extension-setup:setting-up-commit-message-writer-extension
```

The skill detects the active host and gathers the overlay content in `.claude/hook-contexts/writing-commit-messages.md`. Claude Code delivers it through project hooks. Codex uses a committed root `AGENTS.override.md` that instructs the agent to read the same file whenever the writing skill is used.

## Skills

### Setting Up the Extension

**Triggers:** "set up the commit-message-writer extension", "wire up the writing-commit-messages overlay", "install the commit-message-writer hook plumbing".

**Produces in the target project:**
- `.claude/hook-contexts/writing-commit-messages.md` — overlay content. Holds the named-value assignments and `## Pre-Step-N` / `## Post-Step-N` sections that the parent skill formally exposes as extension points. The setup skill translates free-form user intent into these formal options.
- `.claude/settings.json` (or `.claude/settings.local.json`) entries:
  - `PostToolUse` with matcher `Skill`, gated on `tool_input.skill == "commit-message-writer:writing-commit-messages"`.
  - `UserPromptSubmit`, gated on a prompt that begins with `/commit-message-writer:writing-commit-messages`.
- For Codex, a committed root `AGENTS.override.md` section that instructs the agent to read `.claude/hook-contexts/writing-commit-messages.md` whenever the writing skill is used. Existing root `AGENTS.md` guidance is retained through an explicit read instruction — Codex replaces, not stacks, AGENTS files and resolves no `@path` references inside them.

## License

MIT
