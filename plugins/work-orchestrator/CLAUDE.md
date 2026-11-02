@README.md

## Component Overview

This plugin provides:

- **Skills** — `skills/orchestrating-subagent-work/` (orchestrating implementation and review work through dispatched workers: codex CLI, Claude subagents) and `skills/orchestrating-session-work/` (distributing work to sibling Claude Code sessions: enumeration, topology, mandatory dispatch-message blocks, stand-down closure)
- **Agents** (`agents/`) — 11 duty definitions that pin no model and no reasoning effort; the routing table names a definition, a model, and an effort per checkpoint type, and the skill passes the model and effort as spawn arguments. Six definitions carry the Agent tool for dispatch-directed nested subagent spawns; the roster and its reasoning live in `docs/nested-subagent-delegation.md`
- **Hooks** (`hooks/`) — extension delivery: a `PostToolUse` hook (matcher `Skill`) and a `UserPromptSubmit` hook run `inject-extension.sh`, which resolves the invoked skill to its file under `.claude/extensions/work-orchestrator/` (one per skill), delivers it wrapped in the `<project_extension>` envelope, and stays silent for every other skill, prompt, or project

**No commands or MCP servers.** Claude Code only; there is no Codex manifest because the skill orchestrates Claude subagent spawns (Codex appears as a dispatched worker, not as the host). The companion `work-orchestrator-extension-setup` plugin writes project extension files.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the workflow shape (nodes, gates, terminal states) | `skills/orchestrating-subagent-work/SKILL.md` | Pre-flight, consent gate, strategy message, deviation loop, dual-confirmation closure |
| Modify the session-distribution workflow (enumeration, topology, blocks, closure) | `skills/orchestrating-session-work/SKILL.md` | ListAgents-first addressing, `sessions.topology`, SIBLING/SKILL/REPORT blocks, stand-down closure |
| Modify the sibling-session model or addressing/classification guidance | `skills/orchestrating-session-work/references/sessions-vs-subagents.md` | Contrast table, `Name [ref]` first contact, send-failure recoveries, envelope classification |
| Modify the extension mechanisms or the position table | `skills/orchestrating-subagent-work/SKILL.md` §Workflow and `skills/orchestrating-session-work/SKILL.md` §Workflow | Node-keyed positions, named-value lookup, append-only rule |
| Modify checkpoint-to-actor routing or effort defaults | `skills/orchestrating-subagent-work/references/model-routing.md` | Routing table, verification shape, severity-label calibration, codex-less substitutions |
| Change what a dispatched claude worker is contracted to do | `agents/<duty>.md` | Description as selection contract (takes / returns / can / does not), body as input-task-output-boundaries, no role |
| Change the model or effort a checkpoint runs on | `skills/orchestrating-subagent-work/references/model-routing.md` routing table + `docs/claude-effort-mechanism.md` §Routing-table basis (claude rows) | Model and effort are spawn arguments, not definition fields; `max` is deliberately not routed to |
| Change which definitions may spawn nested subagents, or the directive they receive | `agents/<name>.md` frontmatter + `skills/orchestrating-subagent-work/references/worker-prompts.md` §Nested subagents + `docs/nested-subagent-delegation.md` | Opt-in per dispatch, two directive forms with spawn-none default, spawned subagents read-only and never confirmers |
| Re-derive the built-in agent duties after a Claude Code update | `docs/builtin-agent-duty-capture.md` | Capture prompt, exclusion list, per-model check, duties table, update mode |
| Consult the effort evidence behind an effort choice | `docs/claude-effort-mechanism.md` | Where effort is set, the spawn-argument checks and per-effort measurements |
| Consult the evidence behind spawning workers unnamed | `docs/subagent-delivery-mechanism.md` | The three dispatch shapes, per-run results, the send contract, transcript recovery, the idle signal |
| Modify what any worker receives in its prompt | `skills/orchestrating-subagent-work/references/worker-prompts.md` | Review/implementer/single-worker blocks, two-tier report files, trust boundaries, extension propagation into worker prompts |
| Change what a worker's final message must contain or how it is shaped | `agents/<name>.md` §Output + `docs/subagent-report-shape.md` | Final message as the report channel, verdict-last from the sonnet runs, positively phrased first-token rules for haiku |
| Change how worker-prompt phrasing is derived per model family | `skills/orchestrating-subagent-work/SKILL.md` §Derive worker-prompt rules for the assigned families | Ruleset-mode invocation of `llm-author:prompt-engineering`, the three stated inputs, the session-scoped ruleset file re-read per dispatch |
| Modify codex invocation flags or the re-validation loop | `skills/orchestrating-subagent-work/references/codex-dispatch.md` | Invocation hygiene, `exec resume`, codex-less re-validation |
| Add, rename, or retire a named value or position | `EXTENSION.md` + the file that cites it | The recognized-values table and position table must match the names and inline defaults cited in `SKILL.md` and both references |
| Document how projects extend the skill | `EXTENSION.md` | File layout, delivery, both mechanisms, the non-extendable surface, reference-like extensions, worked examples |
| Change the delivery envelope, gating, skill-to-file mapping, or failure behavior | `hooks/scripts/inject-extension.sh` | `<project_extension>` envelope, per-skill extension files, position variants, silent gates vs loud failures |
| Change delivery events or timeout | `hooks/hooks.json` | `PostToolUse` matcher `Skill`, `UserPromptSubmit` |
| Consult the evidence behind a directive | `docs/codex-dispatch-experiments.md`, `docs/gpt-5-6-model-family.md`, `docs/claude-effort-mechanism.md` | Experiment findings, tier design intent, effort mechanics and measurements; the per-row basis of the routing table in `docs/codex-dispatch-experiments.md` §Routing-table basis (codex rows) and `docs/claude-effort-mechanism.md` §Routing-table basis (claude rows) |

## Maintenance Rules

- Keep provenance (experiment citations, source URLs) out of `SKILL.md` and `references/` — it lives in `docs/` and `CHANGELOG.md`.
- A per-model capability statement in `docs/` states its sample size and conditions; `references/` and `SKILL.md` phrase per-model behavior as working defaults, not traits. A rule resting on one run is re-checked before it is tightened.
- The worker-prompt ruleset is derived, never authored here. Family-specific prompt wording comes from `llm-author:prompt-engineering` at task time; adding such wording to `SKILL.md` or `references/` duplicates a source that revs independently. What the plugin states is what the ruleset must cover — the lever order per family, leanness as deduplication rather than block removal, and that verification duties survive it.
- The GPT-5.6 tier names in `references/model-routing.md` are durable tiers that rev independently; when a tier revs, re-validate the routing table against fresh evidence and record the change here and in `docs/`.
- The skill body stays host-neutral about delivery mechanics and project specifics: project gates, protected paths, and banned command classes are named generically, cite their named values, and are filled in per project by the orchestrator at dispatch time.
- The extension contract's fence is structural, not prose: in `orchestrating-subagent-work` the consent nodes, the halt state, and the deviation check carry no position name, and the verification shape and dual-confirmation closure have no named value; in `orchestrating-session-work` session enumeration, the mandatory message blocks, and the deviation check carry no position name, and the block contents have no named value. A change that gives any of them one removes the guarantee the plugin exists for.
- A named value is cited at the point that consumes it, not hoisted into a skill body. Adding one means editing three places: the citing file, the `EXTENSION.md` table, and the `CHANGELOG.md` entry.
- Agent definitions carry no role and no worked examples. The `description` is the selection contract an orchestrating model reads when choosing — what the dispatch supplies, what comes back, what the agent can do, and what it reports instead of doing. The body states input, task, output, and boundaries. Where a description would enumerate use cases, it states the contract and gives at most two instances.
- The definition holds what is standing; the dispatch prompt holds what is specific. Scope, quoted contracts, adjudicated decisions, and gate commands come from `worker-prompts.md` at dispatch time. Restating any of them in a definition creates a contradiction the worker pays to reconcile.
- One definition per duty contract. A definition never pins `model` or `effort`; those belong to the routing table. No instruction in a definition may require the agent to determine or assess its own model, effort, or capability. Wording tuned from measurements on a model is allowed, such as the verdict-last contract or the positively phrased first-token rules recorded in `docs/subagent-report-shape.md`. Add a definition only for a new duty contract, not for a new model or effort.
- The routing table covers combinations with a reason, not the cross product: no `max` anywhere, no opus `low`, no fable. Routing a new combination means naming the evidence for it in `docs/claude-effort-mechanism.md`.

## Testing

BATS tests for the delivery script in `plugin-tests/work-orchestrator/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run
.bats/bats-core/bin/bats plugin-tests/work-orchestrator/*.bats
```

Skill-body changes have no automated tests. Validate them by invoking the skill in a scratch project without an extension file (universal defaults) and in a project with one (extension contract, envelope delivery).

Agent definitions have no automated tests either. Validate a changed definition by dispatching it on a task its contract covers and checking the returned shape against what the description promises, and by dispatching it on a task the contract excludes to confirm it reports rather than proceeds. Frontmatter parses as YAML, so a colon followed by a space inside an unquoted `description` breaks the file — use an em-dash. A new definition needs a Claude Code restart before it resolves.

This plugin is opinionated. Its routing, its effort choices, and its verification shape come from a mix of measurement, vendor guidance, and one maintainer's experience of what produced better results at lower cost. A change that trades an opinion for a different opinion needs a reason recorded in `docs/`, not just a preference.
