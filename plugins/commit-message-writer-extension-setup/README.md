# Commit Message Writer Extension Setup

One-time setup skill that wires up a project to extend the `commit-message-writer:writing-commit-messages` skill in Claude Code or Codex. It provisions the overlay content file and host-specific hook entries that deliver it to the agent.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install commit-message-writer-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/commit-message-writer-extension-setup:setting-up-commit-message-writer-extension
```

The skill detects the active host, gathers the overlay content, and writes the host-specific hook configuration. Claude Code uses `.claude/hook-contexts/` plus project settings. Codex uses `.codex/hook-contexts/` plus `.codex/hooks.json`; the overlay takes effect in a new Codex session.

## Skills

### Setting Up the Extension

**Triggers:** "set up the commit-message-writer extension", "wire up the writing-commit-messages overlay", "install the commit-message-writer hook plumbing".

**Produces in the target project:**
- `.claude/hook-contexts/writing-commit-messages.md` — overlay content. Holds the named-value assignments and `## Pre-Step-N` / `## Post-Step-N` sections that the parent skill formally exposes as extension points. The setup skill translates free-form user intent into these formal options.
- `.claude/settings.json` (or `.claude/settings.local.json`) entries:
  - `PostToolUse` with matcher `Skill`, gated on `tool_input.skill == "commit-message-writer:writing-commit-messages"`.
  - `UserPromptSubmit`, gated on a prompt that begins with `/commit-message-writer:writing-commit-messages`.
- For Codex, `.codex/hook-contexts/writing-commit-messages.md` and a `.codex/hooks.json` `SessionStart` entry that injects the overlay as additional developer context.

## License

MIT
