# Work Orchestrator Extension Setup

Setup skill that wires up a project to extend the `work-orchestrator` plugin's skills — `orchestrating-subagent-work` and `orchestrating-session-work`. It asks which skills the project extends, explores the project's gates, protected paths, conduct rules, recurring checkpoint types, and session topology accordingly, drafts the extension content conversationally with you, and writes one file per skill under `.claude/extensions/work-orchestrator/`. Delivery ships with the `work-orchestrator` plugin (4.0.0 or later), so no project delivery configuration is written. A re-sync mode audits existing extension files for drift against the current project.

Renamed from `subagent-orchestrator-extension-setup`, which remains in the marketplace frozen and deprecated.

The plugin name and the skill name are intentionally long so neither activates by accident; invoke the skill explicitly when you want to set the extension up in a project.

## Quick Start

```bash
/plugin install work-orchestrator-extension-setup@itb-ai-tools
```

Then invoke the skill from the project root:

```
/work-orchestrator-extension-setup:setting-up-work-orchestrator-extension
```

Claude Code only, matching the parent plugin — `work-orchestrator` orchestrates Claude subagent spawns, and the Codex CLI appears as a dispatched worker rather than as the host.

## Skills

### Setting Up the Extension

**Triggers:** "set up the work-orchestrator extension", "wire up the orchestrating-subagent-work extension", "re-sync the work-orchestrator extension".

**Produces in the target project:**

- `.claude/extensions/work-orchestrator/orchestrating-subagent-work.md` — named-value assignments (gates, fences, rules, lenses, routing) and `## Pre-<position>` / `## Post-<position>` sections across the five workflow positions that skill exposes.
- `.claude/extensions/work-orchestrator/orchestrating-session-work.md` (when selected) — the project's standing session topology (`sessions.topology`: roles, duties, message flow, write ownership per working tree), session deviation triggers, and position sections across that skill's five positions.
- No delivery configuration — the `work-orchestrator` plugin delivers the files itself.

The setup skill translates free-form intent into these formal options and refuses to encode observed shortcuts (those become an improvement-candidates report instead).

**What it explores.** Gate commands as actually declared in Makefiles, package scripts, and CI workflows, with their sandbox behavior; generated trees, lockfiles, and migration history for the write fence; command classes that touch shared infrastructure or cost money; conduct rules and project skill files a worker must receive; recurring defect classes that become review lenses; work types the universal routing table has no profile for; and — for the session skill — the working-tree and branch facts behind write ownership, while roles and duties come from you conversationally, plus whether receiving sessions read authoritative persistent artifacts end to end, which makes it propose the parent plugin's `Post-Compose` handoff referent guard.

**What it refuses.** The extension contract is append-only and fences its invariants, and the setup skill enforces both. A finding that would shorten a universal banned-command or conduct-rule list, or soften the consent gate, a deviation check, the verification shape, dual-confirmation closure, session enumeration, or the mandatory dispatch-message blocks, is surfaced as a disagreement with the plugin rather than written into a file. It also does not run gate commands to verify them — it confirms each exists in its declaring file and takes sandbox behavior from you.

**Re-sync mode:** when extension files already exist, the skill diffs every claim against fresh exploration findings — gate commands that changed or vanished, protected paths that moved, stale file citations, routing additions for work the project no longer does, topology rows naming trees or branches nobody works on — and proposes updates. A stale gate command is reported as the highest-value diff, since it is the one drift that silently breaks every implementer dispatch. An unchanged project produces no proposals. Re-sync reads nothing under `.claude/extensions/subagent-orchestrator/` — a project moving from the deprecated plugin moves its file by hand or re-runs this skill fresh.

## License

MIT
