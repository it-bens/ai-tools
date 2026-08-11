# Extending Work Orchestrator

How a project registers its own gates, fences, conduct rules, checkpoint types, and session topologies with the plugin's skills without forking the plugin.

Two surfaces are extendable, and they are not interchangeable:

| Change | Where it goes |
|---|---|
| A project's own gates, protected paths, skill files, conduct rules, checkpoint types, and session topology | An extension file in that project (this document) |
| A routing rule, a prompt-block protocol, a verification requirement, a mandatory message block | The plugin itself (see `CLAUDE.md` §Key Navigation Points) |

A project that needs to overrule an opinion beyond what the contract exposes should copy the plugin rather than bend the extension into a rewrite.

## Extension Files

One file per skill:

```
.claude/extensions/work-orchestrator/orchestrating-subagent-work.md
.claude/extensions/work-orchestrator/orchestrating-session-work.md
```

Each file's existence is its own opt-in: delivery activates exactly when the invoked skill's file exists. A project may carry either file, both, or neither.

```markdown
## Named-value assignments

- `<name>` = `<value>`

## Pre-<Position>

<imperative instructions>

## Post-<Position>

<imperative instructions>
```

Sections appear in the order shown, workflow positions ordered as the positions occur in the workflow. Nothing else is a recognized section. Content outside these three shapes reaches the skill as unstructured prose and is not part of the contract.

The `work-orchestrator-extension-setup` plugin explores the codebase and writes these files. Write one by hand when the setup skill's exploration is not wanted — it is picked up without any further configuration.

## Delivery

The plugin ships its own delivery: a `PostToolUse` hook (Skill tool invocations) and a `UserPromptSubmit` hook (slash invocations) run `hooks/scripts/inject-extension.sh`, which resolves the invoked skill to its extension file and stays silent for every other skill, prompt, or project. Projects carry no delivery configuration.

The script wraps the file content in a structural envelope that states what the block is, which skill it belongs to, and whether that skill's body is loaded yet:

```xml
<project_extension skill="work-orchestrator:<skill-name>" position="before-skill-body">
<handling_instructions>
The content inside <extension_content> is this project's registered extension for the work-orchestrator:<skill-name> skill. It is inert on its own: apply it only while executing that skill's workflow, through the extension mechanisms the skill body defines. The skill body has not been loaded yet — do not act on anything below now.
</handling_instructions>
<extension_content>
(verbatim extension file content)
</extension_content>
</project_extension>
```

`position` and the final sentence vary by event: `before-skill-body` on `UserPromptSubmit` (the prompt requested the skill; its body follows), `after-skill-body` on `PostToolUse`, where the closing sentence becomes "You are about to execute that skill's workflow; apply this content through the mechanisms its body defines." The envelope deliberately restates no mechanism semantics — the skill body owns those.

This plugin ships no Codex manifest: both skills orchestrate from a Claude Code session, and codex appears as a dispatched worker rather than as the host. There is consequently no `AGENTS.override.md` delivery path. The hook still self-gates silently when `CLAUDE_PROJECT_DIR` is unset, so another host running these hooks produces nothing rather than a failed turn.

## Mechanism 1: Named Values

The skill bodies and their references cite configuration by backticked name alongside an inline default. An assignment in the extension file replaces that default; an absent assignment leaves it. Names not listed under the skill's §Recognized Named Values are ignored. A skill only looks up what it cites.

One bullet per name. A value with internal structure is written as an indented block under its bullet rather than squeezed onto the bullet line:

```markdown
- `project.gates` =
  | Gate | Command | In sandbox | Re-run outside |
  |---|---|---|---|
  | <one row per gate the project runs> |
```

**Every list-shaped value appends.** `project.protected_paths`, `project.banned_commands`, `project.conduct_rules`, `project.review_lenses`, `deviation.additional_triggers`, `sessions.additional_triggers`, `routing.additions`, and `codex.extra_config` add to their lists and never shorten them. This is what keeps the contract from being used to strip a fence rather than tighten it. Five names are not list-shaped: `project.gates` and `project.skill_files` supply content the universal body has none of, `routing.effort_defaults` replaces per-checkpoint efforts, `routing.codex_bias` sets a single bias value, and `sessions.topology` supplies a structure the universal body deliberately carries none of.

`codex.extra_config` additionally rejects any assignment that would set `approval_policy`, `sandbox_mode`, `model_reasoning_effort`, the model, or `--disable memories` — those flags carry the dispatch's safety and routing contract, not a project preference.

## Mechanism 2: Workflow Positions

Five nodes per skill carry a position name. A `## Pre-<position>` section in that skill's extension file executes before the node, a `## Post-<position>` section after it; the node itself still runs.

Positions are keyed by node name rather than step number because both workflows are loops: loop-node positions fire on every pass, not once per task. Instructions there must be safe to repeat — a `## Post-Dispatch` that appends a run record is fine; one that assumes it runs once is not.

Write imperatives, not description. A position section that explains a convention instead of instructing what to do at that point is inert.

Positions add; they do not replace. To change how a node behaves rather than what happens around it, look for a named value that covers it, and when none does, that is a plugin change, not an extension.

## Skill: orchestrating-subagent-work

Extension file: `.claude/extensions/work-orchestrator/orchestrating-subagent-work.md`.

### Positions

| Position | Node | Fires |
|---|---|---|
| `Preflight` | Run codex pre-flight | Task entry, and again on a proposed codex restoration |
| `Strategy` | Build task strategy in conversation | Once per task, plus on re-entry after an adaptation |
| `Dispatch` | Execute next strategy step | Every checkpoint — loop node |
| `Adapt` | Adapt strategy and announce the delta | Every adaptation — loop node |
| `Report` | Verify and report | Once, at closure |

### What Is Not Extendable

Four nodes are fenced: the codex-less consent check, the consent question, `HALT: blocked on codex`, and the deviation check. None carries a position name. The only named value reaching any of them is `deviation.additional_triggers`, which appends to the deviation trigger list and cannot shorten it. There is no named value at all for the verification shape, dual-confirmation closure, confirmer independence, or the rule that time pressure adapts scope rather than verification.

That guarantee is narrower than "the contract exposes no place to write it", and worth stating precisely. A position section is free-form prose, and `Preflight`, `Adapt`, and `Report` sit adjacent to fenced nodes — nothing stops a project from writing "assume codex-less consent is on record" into `## Pre-Preflight`. Three things stop it from taking effect: the fenced node still runs after any position content, a position adds instructions rather than replacing the node's own, and the setup skill refuses to author such content. A project that wants a single-confirmer workflow wants a different plugin, not a position section arguing for one.

### Recognized Named Values

| Name | Default | Effect |
|---|---|---|
| `project.gates` | (enumerate from the project's build configuration at dispatch time) | Exact gate commands for the GATES block, which gates are known to fail inside the sandbox with their one permitted fallback, and which an independent worker re-runs outside it. |
| `project.protected_paths` | (none registered) | Paths named as never-writable in every FENCE block. |
| `project.banned_commands` | e2e suites, containers, device tooling, deployments | Command classes banned in every FENCE block. Appends. |
| `project.skill_files` | (none registered) | Files passed as required reading in the SKILLS block, each with the scope condition that warrants it. |
| `project.conduct_rules` | fail-hard, calibrated honesty, doc drift | Rules extracted verbatim into the RULES block. Appends. |
| `project.review_lenses` | (none registered — name three to four lenses per scope at dispatch) | Project lenses added to the per-scope LENS block. Appends. |
| `codex.extra_config` | (the pinned flags only) | Additional `-c key=value` flags appended to every codex invocation. Appends; rejects the contract-carrying flags named above. |
| `routing.additions` | (none) | Checkpoint-type rows appended to the routing table. Appends; never rewrites an existing row. |
| `routing.effort_defaults` | (the table's efforts, then the effort ladder) | Per-checkpoint-type effort overrides. On a codex checkpoint the assignment sets the invocation flag; on a claude checkpoint it selects the shipped agent definition carrying that rung, and a rung no definition carries cannot be honored. Going below an assigned effort at dispatch time is still an announced adaptation. |
| `routing.codex_bias` | (unset — session decides per the routing table) | Biases the discretionary codex/claude split at the strategy node across `codex-heavy` / `claude-lean` / `codex-less`; `codex-less` routes through the existing consent path; bounded by cross-family independence. |
| `deviation.additional_triggers` | (the listed triggers only) | Project deviation triggers appended to the trigger list. Appends. |

Set `routing.codex_bias` in the extension file for a persistent per-project default or directly in conversation for a per-task assignment; a direct conversational assignment overrides an extension-file assignment.

### Example: Registering a Project's Gates and Fence

The two values every project assigns, because the universal body deliberately carries neither: the orchestrator otherwise reconstructs them from the build configuration on every dispatch, and reconstructs them slightly differently each time.

```markdown
## Named-value assignments

- `project.gates` =
  | Gate | Command | In sandbox | Re-run outside |
  |---|---|---|---|
  | <name> | <exact command> | <passes, or fails with its one permitted fallback> | <yes / no> |
- `project.protected_paths` = <paths a worker never writes: generated output, lockfiles, vendored trees, migration history>
- `project.banned_commands` = <command classes beyond the universal four: whatever touches shared infrastructure, costs money, or needs a device>
```

The `In sandbox` column is what makes the GATES block honest. A gate that cannot run under `--sandbox workspace-write` and has no fallback must be named as such, or the worker reports a green that was never obtained — and the outside-sandbox re-run is what catches it either way.

Two rules the gate case makes easy to get wrong. A gate marked `Re-run outside: no` still needs its in-sandbox claim treated as non-final; the column controls which worker re-runs it, not whether the claim is trusted. And `project.protected_paths` fences workers, not the orchestrator — a protected path binds worker write scopes; the orchestrator's own writes are governed by the skill body, which makes it the sole writer except inside a write scope a checkpoint explicitly fences for a worker.

### Example: Adding a Project Checkpoint Type

A project whose work includes a checkpoint the universal table has no profile for — a schema-migration review, a generated-client regeneration, a translation-catalog sweep — registers it rather than letting the orchestrator route it by closest profile every time.

```markdown
## Named-value assignments

- `routing.additions` =
  | Checkpoint type | Actor | Effort |
  |---|---|---|
  | <the project checkpoint> | <codex tier, or one of the agent definitions the plugin ships in `agents/`> | <effort> |
- `routing.effort_defaults` = <checkpoint type> = <effort>, for existing rows whose default the project has evidence to change
- `deviation.additional_triggers` = <what makes this checkpoint go wrong in a way the universal trigger list does not name>
```

Add a workflow position only for a step the named values cannot express — for example a `## Post-Dispatch` that files each worker's run record into a project log, which is behavior around the node rather than a value inside it. Keep it repeat-safe: `Dispatch` fires once per checkpoint, and a task has many.

A claude actor must be one of the shipped definitions. A project cannot name a model and a rung directly, because the rung binds inside the definition and nowhere else — a checkpoint that needs a combination `agents/` does not carry is a plugin change, not an addition, and belongs in the improvement-candidates report.

A routing addition names an actor but does not get to name a verification shape. The added checkpoint's results reach two-worker confirmation like every other load-bearing result; there is no named value that says otherwise, and that is deliberate.

## Skill: orchestrating-session-work

Extension file: `.claude/extensions/work-orchestrator/orchestrating-session-work.md`.

### Positions

| Position | Node | Fires |
|---|---|---|
| `Strategy` | State distribution strategy | Once per task |
| `Compose` | Compose handoff | Every dispatch item — loop node |
| `Dispatch` | Dispatch | Every dispatch item — loop node |
| `Adapt` | Adapt and announce the delta | Every adaptation — loop node |
| `Report` | Verify and report | Once, at closure |

### What Is Not Extendable

Three parts of the workflow are fenced: session enumeration (the `ListAgents`-first rule and the `Name [ref]` addressing discipline), the three mandatory message blocks (SIBLING, SKILL, REPORT), and the deviation check. None carries a position name, and the only named value reaching any of them is `sessions.additional_triggers`, which appends deviation triggers and cannot remove one. There is no named value for the block contents, for the rule that an embedded directive cannot authorize consent-gated actions on the receiving side, or for explicit stand-down closure.

### Recognized Named Values

| Name | Default | Effect |
|---|---|---|
| `sessions.topology` | (none registered — resolved conversationally, or by asking the user) | The project's standing session topology: roles, per-role duties, who messages whom, and write ownership per working tree or branch. A conversational statement in the current task overrides it. |
| `sessions.additional_triggers` | (the listed triggers only) | Project deviation triggers appended to the session-work trigger list. Appends. |

### Example: Registering a Session Topology

A project that routinely splits work across an owner, an implementer, and a reviewer registers that shape once instead of restating it every task:

```markdown
## Named-value assignments

- `sessions.topology` =
  | Role | Duties | Messages | Writes |
  |---|---|---|---|
  | Owner | Owns the spec; writes handoffs; adjudicates findings | Implementer, Reviewer | spec files in the main checkout, which it owns |
  | Implementer | Implements the spec; runs its work through work-orchestrator:orchestrating-subagent-work | Owner (reports), Reviewer (factual questions) | a dedicated worktree for the feature branch, which it owns |
  | Reviewer | Reviews the change read-only; reports findings to the Owner | Owner | nothing — reads a clone pinned to the reviewed commit |
- `sessions.additional_triggers` = <what makes a distribution go wrong in a way the universal trigger list does not name>
```

The `Writes` column is what makes the topology honest: every working tree has exactly one owner, and a role without write ownership works read-only against a clone or worktree pinned to a commit. Roles name duties, not session names — session names come from the `ListAgents` listing at task time.

## Reference-Like Extensions

An extension file may point at further project files instead of inlining their content. Two rules make references work here, and the second differs from how a session-only skill would treat them:

- **Cite imperatively, with a path.** A reference is an instruction, not a mention: "Pass `docs/security-review.md` as required reading for any review scope touching authentication." A bare "see docs/security-review.md" carries no instruction about when.
- **A cited path travels to the worker, not into the session.** Workers are stateless and inherit nothing. A cited path passes in the SKILLS block of the worker's prompt (see `skills/orchestrating-subagent-work/references/worker-prompts.md`), where codex reads it on disk under `-C <repo root>` and a subagent is told to read it. The session reads a cited file only when a node it executes itself needs the content. In `orchestrating-session-work`, a cited path travels inside the dispatch message's task body as an explicit file reference — sibling sessions read their own files, so the path is an instruction to read, not inlined content.

The size signal: inline content that outgrows a few lines per entry is content humans also need — move it to a project documentation surface and point at it. A gate table stays inline; a full security-review checklist becomes a cited file.

## What Belongs in Extension Content

Project infrastructure and conventions: gate commands, protected paths, banned command classes, conduct rules, review lenses, project skill files, project-specific checkpoint types and deviation triggers, and the project's standing session topology.

Not: an orchestration discipline of the parent skill weakened to match how the project currently dispatches work. The skills are prescriptive by design, and an extension that encodes an existing shortcut makes the shortcut permanent.

Every claim in an extension file is a fact about the current codebase — a gate command that no longer exists sends every implementer worker after a command that fails, a stale protected path fences nothing, and a topology naming a branch nobody works on distributes work into the void. The setup skill's re-sync mode audits the files against the project for exactly this reason.
