# Software Writer Extension Setup

Setup skill that wires up a project to extend the `software-writer` skills (`writing-code`, `writing-tests`, `writing-docs`) in Claude Code or Codex. It explores the codebase, drafts the per-skill overlay content conversationally with the user, provisions a shared overlay file per skill, and merges the host-specific configuration that exposes the overlays to the agent. A re-sync mode audits existing overlays for drift against the current code.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install software-writer-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/software-writer-extension-setup:setting-up-software-writer-extension
```

The skill detects the active host, explores the project (stacks, test infrastructure, in-repo helpers, documentation surfaces), and gathers evidence-backed overlay proposals it refines with you one skill family at a time. Claude Code delivers the overlays through project hooks. Codex uses a committed root `AGENTS.override.md` that conditionally references the same files whenever a writing skill is used.

## Skills

### Setting Up the Extension

**Triggers:** "set up the software-writer extension", "wire up the writing-code/writing-tests/writing-docs overlays", "re-sync the software-writer overlays".

**Produces in the target project:**

- `.claude/hook-contexts/writing-code.md`, `writing-tests.md`, `writing-docs.md` — overlay content (one file per skill with a non-empty overlay). Each holds the named-value assignments and `## Pre-Step-N` / `## Post-Step-N` sections the parent skills formally expose as extension points. The setup skill translates free-form intent into these formal options and refuses to encode observed bad practices (those become an improvement-candidates report instead).
- `.claude/settings.json` (or `.claude/settings.local.json`) entries per overlaid skill:
  - `PostToolUse` with matcher `Skill`, gated on `tool_input.skill == "software-writer:<skill>"`.
  - `UserPromptSubmit`, gated on a prompt that begins with `/software-writer:<skill>`.
- For Codex, a committed root `AGENTS.override.md` section that references the overlay files whenever the matching writing skill is used. Existing root `AGENTS.md` guidance is retained through `@AGENTS.md`.

**Re-sync mode:** when overlays already exist, the skill diffs every overlay claim against fresh exploration findings — moved symbols, deleted helpers, changed parallelism or CI facts, drifted surface taxonomies — and proposes updates. An unchanged project produces no proposals.

## License

MIT
