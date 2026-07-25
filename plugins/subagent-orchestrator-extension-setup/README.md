# Subagent Orchestrator Extension Setup

Setup skill that wires up a project to extend the `subagent-orchestrator` plugin's `orchestrating-subagent-work` skill. It explores the project's gates, protected paths, conduct rules, and recurring checkpoint types, drafts the extension content conversationally with you, and writes `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md`. Delivery ships with the `subagent-orchestrator` plugin (2.0.0 or later), so no project delivery configuration is written. A re-sync mode audits an existing extension file for drift against the current project.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install subagent-orchestrator-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/subagent-orchestrator-extension-setup:setting-up-subagent-orchestrator-extension
```

Claude Code only, matching the parent plugin — `subagent-orchestrator` orchestrates Claude subagent spawns, and the Codex CLI appears as a dispatched worker rather than as the host.

## Skills

### Setting Up the Extension

**Triggers:** "set up the subagent-orchestrator extension", "wire up the orchestrating-subagent-work extension", "re-sync the subagent-orchestrator extension".

**Produces in the target project:**

- `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md` — the extension content: named-value assignments and `## Pre-<position>` / `## Post-<position>` sections across the five workflow positions the parent skill exposes. The setup skill translates free-form intent into these formal options and refuses to encode observed shortcuts (those become an improvement-candidates report instead).
- No delivery configuration — the `subagent-orchestrator` plugin delivers the file itself.

**What it explores.** Gate commands as actually declared in Makefiles, package scripts, and CI workflows, with their sandbox behavior; generated trees, lockfiles, and migration history for the write fence; command classes that touch shared infrastructure or cost money; conduct rules and project skill files a worker must receive; recurring defect classes that become review lenses; and work types the universal routing table has no profile for.

**What it refuses.** The extension contract is append-only and fences its invariants, and the setup skill enforces both. A finding that would shorten a universal banned-command or conduct-rule list, or soften the consent gate, the deviation check, the verification shape, or dual-confirmation closure, is surfaced as a disagreement with the plugin rather than written into the file. It also does not run gate commands to verify them — it confirms each exists in its declaring file and takes sandbox behavior from you.

**Re-sync mode:** when an extension file already exists, the skill diffs every claim against fresh exploration findings — gate commands that changed or vanished, protected paths that moved, stale file citations, routing additions for work the project no longer does — and proposes updates. A stale gate command is reported as the highest-value diff, since it is the one drift that silently breaks every implementer dispatch. An unchanged project produces no proposals.

## License

MIT
