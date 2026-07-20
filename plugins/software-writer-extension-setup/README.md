# Software Writer Extension Setup

Setup skill that wires up a project to extend the `software-writer` skills (`writing-code`, `writing-tests`, `writing-docs`) in Claude Code or Codex. It explores the codebase, drafts the per-skill extension content conversationally with the user, and writes one shared extension file per skill under `.claude/extensions/software-writer/`. On Claude Code, delivery ships with the `software-writer` plugin (2.0.0 or later), so no project delivery configuration is written; on Codex, a committed root `AGENTS.override.md` references the same files. A re-sync mode audits existing extension files for drift against the current code and migrates v1 setups.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install software-writer-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/software-writer-extension-setup:setting-up-software-writer-extension
```

The skill detects the active host, explores the project (stacks, test infrastructure, in-repo helpers, documentation surfaces), and gathers evidence-backed extension proposals it refines with you one skill family at a time.

## Skills

### Setting Up the Extension

**Triggers:** "set up the software-writer extension", "wire up the writing-code/writing-tests/writing-docs extension", "re-sync the software-writer extension", "migrate the software-writer extension".

**Produces in the target project:**

- `.claude/extensions/software-writer/writing-code.md`, `writing-tests.md`, `writing-docs.md` — extension content (one file per skill with a non-empty extension). Each holds the named-value assignments and `## Pre-Step-N` / `## Post-Step-N` sections the parent skills formally expose as extension points, including reference-like entries that cite project documentation surfaces read on demand. The setup skill translates free-form intent into these formal options and refuses to encode observed bad practices (those become an improvement-candidates report instead).
- No Claude Code delivery configuration — the `software-writer` plugin delivers the files itself.
- For Codex, a committed root `AGENTS.override.md` section with one `<project_extension>` envelope per extended skill, wrapping the file reference in the same handling instructions Claude Code delivers. Existing root `AGENTS.md` guidance is retained through `@AGENTS.md` — Codex replaces, not stacks, AGENTS files.

**Re-sync mode:** when extension files (or a v1 setup) already exist, the skill diffs every claim against fresh exploration findings — moved symbols, deleted helpers, changed parallelism or CI facts, drifted surface taxonomies, stale reference citations — and proposes updates. It also migrates v1 setups: content under `.claude/hook-contexts/` moves to the new path, and the v1 hook entries are removed from the project settings with your approval. An unchanged project with no v1 artifacts produces no proposals.

## License

MIT
