# Code Comment Writer Extension Setup

One-time setup skill that wires up a project to extend the `code-comment-writer:writing-code-comments` skill. Provisions the overlay content file and the hook entries that deliver it to the agent the moment the skill runs.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install code-comment-writer-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/code-comment-writer-extension-setup:setting-up-code-comment-writer-extension
```

The skill walks the project state, asks what to put in the overlay, writes `.claude/hook-contexts/writing-code-comments.md`, and merges the required hook entries into `.claude/settings.json` (or `.claude/settings.local.json` when preferred).

## Skills

### Setting Up the Extension

**Triggers:** "set up the code-comment-writer extension", "wire up the writing-code-comments overlay", "install the code-comment-writer hook plumbing".

**Produces in the target project:**
- `.claude/hook-contexts/writing-code-comments.md` — overlay content. Holds the named-value assignments and `## Pre-Step-N` / `## Post-Step-N` sections that the parent skill formally exposes as extension points. The setup skill translates free-form user intent into these formal options.
- `.claude/settings.json` (or `.claude/settings.local.json`) entries:
  - `PostToolUse` with matcher `Skill`, gated on `tool_input.skill == "code-comment-writer:writing-code-comments"`.
  - `UserPromptSubmit`, gated on a prompt that begins with `/code-comment-writer:writing-code-comments`.

## License

MIT
