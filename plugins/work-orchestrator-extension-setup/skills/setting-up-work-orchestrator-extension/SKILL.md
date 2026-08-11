---
name: setting-up-work-orchestrator-extension
version: 2.0.0
description: Use when the user explicitly asks to set up, install, configure, wire up, or re-sync the work-orchestrator plugin's extensions for the current project. Do not activate as a side effect of an orchestration task.
---

# Setting Up the work-orchestrator Extensions

Create the extension files for the `work-orchestrator` plugin's skills in the current project — `orchestrating-subagent-work` (gates, fences, rules, routing) and `orchestrating-session-work` (session topology, session deviation triggers), one file per skill under `.claude/extensions/work-orchestrator/`. The `work-orchestrator` plugin delivers the files itself, so no delivery configuration is written. Re-sync mode audits existing files against the current project and turns stale claims into update proposals.

## Workflow

```dot
digraph setting_up {
    "Start" [shape=doublecircle];
    "Step 1: Confirm scope and select skills" [shape=box];
    "Per selected skill: extension file present?" [shape=diamond];
    "Step 2: Explore the project" [shape=box];
    "Step 3: Diff existing extension files against findings" [shape=box];
    "Step 4: Draft extension proposals" [shape=box];
    "Step 5: Refine conversationally" [shape=box];
    "User approves the plan?" [shape=diamond];
    "Step 6: Write one extension file per selected skill" [shape=box];
    "Step 7: Verify and report" [shape=box];
    "Done" [shape=doublecircle];

    "Start" -> "Step 1: Confirm scope and select skills" -> "Per selected skill: extension file present?";
    "Per selected skill: extension file present?" -> "Step 2: Explore the project" [label="absent — fresh mode for that skill"];
    "Per selected skill: extension file present?" -> "Step 2: Explore the project" [label="present — re-sync mode for that skill"];
    "Step 2: Explore the project" -> "Step 4: Draft extension proposals" [label="every selected skill fresh"];
    "Step 2: Explore the project" -> "Step 3: Diff existing extension files against findings" [label="any file in re-sync"];
    "Step 3: Diff existing extension files against findings" -> "Step 4: Draft extension proposals";
    "Step 4: Draft extension proposals" -> "Step 5: Refine conversationally" -> "User approves the plan?";
    "User approves the plan?" -> "Step 5: Refine conversationally" [label="no — amend or drop"];
    "User approves the plan?" -> "Step 6: Write one extension file per selected skill" [label="yes"];
    "Step 6: Write one extension file per selected skill" -> "Step 7: Verify and report" -> "Done";
}
```

### Step 1: Confirm scope and select skills

Confirm the current working directory is the project root that should receive the extensions. If unclear, ask the user before doing anything else.

Ask which skills the project extends: `orchestrating-subagent-work`, `orchestrating-session-work`, or both. Default to `orchestrating-subagent-work` alone when the user has no session-distribution workflow; propose the session skill only when the user distributes work across named sessions.

Per selected skill, run in **re-sync mode** when its file under `.claude/extensions/work-orchestrator/` exists; otherwise run in **fresh mode**. The two files are independent — one may re-sync while the other is created fresh.

This skill targets Claude Code. `work-orchestrator` ships no Codex manifest, so there is no host branch and no `AGENTS.override.md` to provision.

### Step 2: Explore the project

Dispatch read-only exploration — Explore subagents for breadth, direct reads for confirmation — with the probe checklists below. Every proposed row must carry evidence: the file and line the claim traces to. Never propose a gate command, a protected path, or a banned command class from memory or plausibility; a wrong gate command sends every implementer worker after a command that fails.

Probe checklists:

- **Gates:** build, format, typecheck, lint, and test commands as actually declared — Makefile targets, `package.json` scripts, `taskfile.yml`, `justfile`, `composer.json` scripts, tox/nox config, and the CI workflow files. The CI workflow is the strongest evidence of what the project considers a gate. For each, note whether it needs network, containers, a database, or a device.
- **Fence:** generated output directories and codegen markers, lockfiles, vendored trees, migration history, `.gitattributes` `linguist-generated` entries, and anything a `.gitignore` or build step rewrites. Separately: command classes that touch shared infrastructure, cost money, or need a device — e2e configs, `docker-compose` files, deploy scripts, seed or reset commands.
- **Conduct rules:** rule files and contributor guidance that state conduct a worker must follow beyond the universal three (fail-hard, calibrated honesty, doc drift) — `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `CONTRIBUTING.md`.
- **Skill files:** project skills the project expects to govern implementation or review, and which scopes warrant each.
- **Review lenses:** recurring defect classes visible in git history and issue labels; directories with a security or privacy flavor that route away from `gpt-5.6-sol` under the universal table.
- **Checkpoint types and deviation triggers:** recurring work types the routing table has no profile for (schema migrations, generated clients, translation catalogs), and project failure modes the universal trigger list does not name.
- **Session topology** (only when `orchestrating-session-work` is selected): the roles the project distributes work across, per-role duties, who messages whom, and write ownership — which role owns which working tree or branch, and which roles work read-only against a clone or pinned worktree. This checklist is conversational rather than probed: roles and duties come from the user; exploration contributes only the working-tree and branch facts (worktrees in use, long-lived branches, formatter or build steps that rewrite files).

### Step 3: Diff existing extension files against findings

Re-sync mode only; fresh mode proceeds directly to Step 4.

Diff each claim in every existing extension file against the current findings: gate commands that no longer exist or changed invocation, protected paths that moved or were deleted, cited files that no longer exist or no longer cover what the citation claims, routing additions for checkpoint types the project no longer runs, conduct rules whose source file was rewritten, and topology rows naming working trees or branches the project no longer uses. Turn every stale claim into an update proposal with its evidence. An unchanged project produces no proposals.

Report the gate table as the highest-value diff: a stale gate command is the one drift that silently breaks every implementer dispatch.

### Step 4: Draft extension proposals

Map every finding onto the parent skills' formal mechanisms only, into the file of the skill it belongs to:

1. **Named-value assignments** — the names in the `work-orchestrator` plugin's `EXTENSION.md` under the target skill's §Recognized Named Values. Each has a default and a documented effect. Session topology maps to `sessions.topology`; session failure modes map to `sessions.additional_triggers`.
2. **Workflow position extensions** — `## Pre-<position>` / `## Post-<position>` sections of imperative instructions, where the position is one of `Preflight`, `Strategy`, `Dispatch`, `Adapt`, `Report` for `orchestrating-subagent-work`, and one of `Strategy`, `Compose`, `Dispatch`, `Adapt`, `Report` for `orchestrating-session-work`.

If a finding cannot be mapped to either mechanism, surface it to the user and ask whether to drop or rephrase it. Do not write content that lies outside the two mechanisms.

**Append-only guard.** Every list-shaped value adds to its universal list and never shortens it. A finding that amounts to "this project does not need one of the universal banned command classes" or "these conduct rules do not apply here" is not expressible and must not be dressed up as an assignment. Surface it to the user as a disagreement with the plugin, not as a proposal.

**Fence guard.** The consent gate, the deviation checks, the halt state, the verification shape, dual-confirmation closure, session enumeration, and the three mandatory message blocks are outside the contract. A finding that would soften any of them — a project that "always runs codex-less", a checkpoint that "does not need a second confirmer", a fast path that skips the outside-sandbox gate re-run, a dispatch message that "does not need the SKILL block", a topology that shares one working tree between two writing roles — is refused, not encoded. Collect these with the improvement candidates below.

Do not author `routing.codex_bias = codex-less`. Treat a persistent from-file value as the refused "always runs codex-less" shape and as unable to serve as consent. Explain that codex-less is a per-session consent decision that the user must state directly, and record it among the surfaced decisions rather than in the file.

**Loop-node guard.** `Dispatch` and `Adapt` fire on every pass in both skills, and `Compose` fires on every dispatch item in `orchestrating-session-work`. Content proposed for any of them must be safe to repeat; a proposal that assumes it runs once per task belongs at `Strategy` or `Report`.

**Prescriptive guard.** Extension content is project *infrastructure and conventions*: gates, fences, rules, lenses, checkpoint types. Never weaken an orchestration discipline of the parent skill to match how the project currently dispatches work. Collect observed shortcuts into an "improvement candidates" report for the user instead of encoding them.

**Reference-like entries.** When a finding's content already lives in a project file, or outgrows a few inline lines, propose a citation instead of inlining it — and state where it travels. In an `orchestrating-subagent-work` extension, a cited path passes to a worker as required reading in the SKILLS block, not into the session; in an `orchestrating-session-work` extension, it travels inside the dispatch message's task body as an explicit file reference the sibling session reads itself. A gate table stays inline; a full security-review checklist becomes a cited file.

### Step 5: Refine conversationally

Work one family at a time, in the order gates → fence → rules and lenses → routing → topology (topology only when `orchestrating-session-work` is selected). For each, present the findings with their evidence and the proposed content, then ask targeted questions via AskUserQuestion:

- Confirm each gate's exact command, and whether it runs inside a `workspace-write` sandbox. For a gate that does not, get its one permitted fallback and whether an independent worker re-runs it outside.
- Accept or reject each protected path and each banned command class, with evidence.
- Confirm which conduct rules and project skill files a worker must receive, and the scope condition for each.
- Accept or reject each proposed routing addition and effort override — an effort override needs the project's own evidence, not a preference. An override on a codex checkpoint sets the invocation flag, so any level is expressible. An override on a claude checkpoint selects one of the agent definitions the parent plugin ships, so only the rungs those definitions carry are expressible — propose a rung none of them carries as an improvement candidate for the parent plugin, not as an assignment. Ask whether the project wants a persistent codex/claude bias; offer `codex-heavy`, `claude-lean`, or none, and record `routing.codex_bias` when selected. Treat this bias as a preference, not a Step 2 probe target, and exempt it from the effort-override evidence requirement.
- Confirm each proposed deviation trigger.
- For the topology: confirm the roles, per-role duties, and message flow with the user (they are the source, not exploration), and confirm write ownership against the explored working-tree facts — every tree has exactly one writing role, and read-only roles get the clone-or-pinned-worktree instruction.

Translate free-form intent into named values or positions before writing. Loop until the user approves each family; on rejection, amend or drop and re-present.

Do not run a gate command to verify it. Confirm it exists in its declaring file, and take sandbox behavior from the user rather than from a trial run.

### Step 6: Write one extension file per selected skill

Write one file per selected skill under `.claude/extensions/work-orchestrator/` — `orchestrating-subagent-work.md`, `orchestrating-session-work.md` — creating the directory if needed. Use this template per file, omitting any section with no entries:

````
## Named-value assignments

- `<name>` = `<value>`

## Pre-<Position>

<imperative instructions>

## Post-<Position>

<imperative instructions>
````

One bullet per assigned name under the single `## Named-value assignments` heading. A value with internal structure — the gate table, a routing-additions table, the topology table — is written as an indented block under its bullet rather than squeezed onto the bullet line. One section per workflow position, ordered as the positions occur in that skill's workflow: `Preflight`, `Strategy`, `Dispatch`, `Adapt`, `Report` for `orchestrating-subagent-work`; `Strategy`, `Compose`, `Dispatch`, `Adapt`, `Report` for `orchestrating-session-work`.

Verify after writing each file: every section is one of the three template sections above, every position name is one of that skill's five, every assigned name belongs to that skill's recognized set, and the sections appear in the order shown.

### Step 7: Verify and report

Confirm in this order, per written file:

1. The extension file exists and matches the Step 6 template.
2. Every assigned name appears in the parent plugin's §Recognized Named Values table for that skill.
3. Every cited file path exists.
4. The file is not ignored by version control. It is project configuration and must be committed. Do not create a commit without the user's explicit approval, but report untracked state as incomplete setup.

Report the files written, the evidence behind each gate row, and the improvement candidates and refused findings collected in Step 4. Confirm delivery by invoking each written skill and checking that a `<project_extension>` block for it appears; if none appears, report that the installed `work-orchestrator` plugin is older than 4.0.0 or the session needs a restart, and stop. In re-sync mode on an unchanged project, report that no changes were proposed.
