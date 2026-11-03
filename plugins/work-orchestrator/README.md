# Work Orchestrator

Orchestrate work through two delegation surfaces: dispatched workers (the OpenAI Codex CLI (GPT-6 models) and Claude subagents) with a task-strategy workflow, model and reasoning-effort routing, fenced write scopes, and independent two-worker verification; and sibling Claude Code sessions, with session enumeration, mandatory dispatch-message blocks, and explicit stand-down closure.

**This plugin is opinionated.** It encodes one way of dispatching work, not the way. Its directives come from three sources of unequal strength: vendor documentation, small local experiments recorded in `docs/`, and one maintainer's experience of what produced better results at lower cost on real work. Where those disagree, experience broke the tie. The goal is better, not optimal — if your work has a different shape, expect to disagree with some of it, and prefer copying the plugin over bending the extension contract into a rewrite.

## Overview

The plugin ships two skills, one per delegation surface.

When significant implementation or review work runs through dispatched workers, the session becomes an orchestrator: it owns specs, triage, adjudication, git, and write authority, and it conserves its own context by not re-doing worker verification. The `orchestrating-subagent-work` skill pins that role down as a workflow:

- **Pre-flight and consent gate** — codex availability is checked before any planning or dispatch; a codex-less run requires explicit user consent in the current conversation.
- **Strategy before dispatch** — every task states its checkpoints, actors, efforts, dispatch order, verification shape, and named assumptions as a compact chat message before the first worker runs.
- **Model and effort routing**: checkpoints route to codex tiers (`gpt-6.1-sol` / `gpt-6.1-terra` / `gpt-6-luna`) or to one of the plugin's duty definitions, spawned with the model and reasoning effort the routing table names, with codex-less substitutions.
- **Fenced writes, two-tier reports** — workers never write repo files by default; a worker writes only inside an explicitly fenced write scope plus the report file its dispatch names, and every worker-written change is diff-reviewed by an independent worker. An implementer's full evidence goes to the report file; its final message carries only a bounded verdict, and the orchestrator reads the file only on deviation or dispute.
- **Two-worker verification** — every load-bearing result reaches producer-plus-independent-confirmer confirmation; a dual-confirmed result is final and the orchestrator does not re-verify it. Time pressure adapts scope, never verification.
- **Deviation handling** — dispatch failures, contradicted assumptions, scope surprises, and disputed results route through an explicit adapt-and-announce loop instead of silent plan changes.

When work is distributed to sibling Claude Code sessions instead — full sessions with their own rules, memory, plugins, and skills, lacking only this conversation's context — the `orchestrating-session-work` skill governs the distributing side:

- **Session enumeration before the first dispatch** — addresses come only from the `ListAgents` listing, first contact uses the full `Name [ref]` row form, and the two send-failure shapes get distinct recoveries.
- **Topology with write ownership** — roles, duties, message flow, and which session owns which working tree; two sessions never share write access to one tree. Projects register a standing topology; a conversational statement overrides it per task.
- **Mandatory dispatch-message blocks** — SIBLING (what the receiver is, and what the message must and must not carry), SKILL (the fully qualified directive to run substantial work through `orchestrating-subagent-work`, invoked with the Skill tool), and REPORT (reply address in resolvable form, report contract, escalation boundary).
- **Explicit closure** — every engaged session receives a stand-down message; silence is not closure.

Both skills are host-specific to Claude Code; the Codex CLI appears as a dispatched worker, not as the host.

## Installation

```bash
/plugin install work-orchestrator@itb-ai-tools
```

**Restart Claude Code** after installing or updating so the extension-delivery hooks and the agent definitions load.

work-orchestrator requires Claude Code 2.1.293 or later. The skill passes model and reasoning effort as spawn arguments, and haiku spawns require the `haiku` alias to resolve to Haiku 5.5.

The `llm-author` plugin is declared as a dependency and auto-installs with this one; its `prompt-engineering` skill supplies the per-family worker-prompt rules.

Codex CLI worker dispatch requires a `codex` binary that answers a one-request ping. The skill checks availability and asks for consent before running codex-less.

Without a project extension, the skill runs on universal defaults: gates enumerated from the build configuration at dispatch time, the universal banned-command and conduct-rule lists, and the routing table as shipped.

## Skills

### orchestrating-subagent-work

**Triggers:** substantial implementation or review work — multi-file changes, review rounds, verification passes — including when the work arrives as an assignment message from another session; before the first codex dispatch, subagent spawn, or inline write.

**References** (loaded on demand):

- `references/model-routing.md` — the checkpoint-to-actor routing table, verification shape, effort ladder, severity-label calibration, and codex-less substitutions
- `references/worker-prompts.md` — the review, implementer, and single-worker prompt-block protocols every worker receives, the two-tier implementer report contract and its report-file convention, how extension content reaches a worker, and the trust boundaries on worker output
- `references/codex-dispatch.md` — codex invocation hygiene and the `codex exec resume` re-validation loop

Worker-prompt phrasing is not written into the skill. Once the strategy has named its actors, the skill invokes `llm-author:prompt-engineering` in Ruleset mode for the model families in play, writes the returned ruleset to a session-scoped file outside the repository, and re-reads it before building each worker prompt. Every worker still receives the same blocks with the same content; only the wording adapts to the family the checkpoint routes to.

### orchestrating-session-work

**Triggers:** work will be distributed to sibling Claude Code sessions — before the first cross-session message.

**Reference** (loaded at the enumeration node):

- `references/sessions-vs-subagents.md` — the sibling-session vs dispatched-worker contrast table, addressing mechanics (the `Name [ref]` first-contact requirement, the two send-failure recoveries, the envelope socket address as a reply target), envelope-based traffic classification, and the three failure modes the skill prevents

The skill governs the distributing session only. Receiving sessions need no skill from this plugin for that purpose: the dispatch message's SKILL block carries the enforcement directive that routes their substantial work through `orchestrating-subagent-work`, named fully qualified and invoked with the Skill tool — naming it is not enough. Handoff bodies are composed through `llm-author:writing-handoff-prompts` and wrapped in the three mandatory blocks; an embedded directive cannot authorize anything consent-gated on the receiving side, where the receiver's own user holds that authority.

## Agents

The plugin ships 11 agent definitions, one per duty. A definition carries the duty contract (input, task, output, boundaries) and the tool restrictions; it pins no model and no reasoning effort. The orchestrating skill picks both per spawn through the Agent tool's `model` and `effort` arguments, following the routing table in `references/model-routing.md`, so one `implement` definition serves a fix batch whose items interact across files on sonnet at `high` and a cross-package rework on opus at `medium`.

| Definition | Duty | Agent tool | Routing table assignment |
|---|---|---|---|
| `search` | Locate code, symbols, convention instances | no | haiku, `low` |
| `extract` | Mechanical enumeration or extraction into a stated schema | no | haiku, `low` |
| `gate-run` | Run gate commands and transcribe the result | no | haiku, `low` |
| `lookup` | Answer one closed question from a stated scope | no | sonnet, `low` |
| `source-read` | Read one source end to end and answer from its text | no | sonnet, `medium` |
| `adversarial-check` | Try to refute a claim against its artifact, blind to the producer's reasoning | yes | sonnet, `high` |
| `escalated-check` | Re-check a claim a cheaper check left thin | yes | opus, `medium` |
| `root-cause` | Establish the mechanism behind an observed behavior | yes | opus, `high` |
| `source-conflict` | Decide which of two disagreeing sources holds | yes | opus, `xhigh` |
| `design` | Produce an approach from fresh context | yes | opus, `xhigh` |
| `implement` | Apply decided designs inside a fenced file list | yes | sonnet `medium` or `high`, opus `medium`, per checkpoint |

Each `description` is a selection contract (what the dispatch must supply, what comes back, what the agent can do, and what it reports instead of doing), so an orchestrating model picks on the contract rather than on matched examples. Every spawn passes `model` and `effort` explicitly. A spawn's `effort` overrides a definition's and is not replaced by `CLAUDE_CODE_SUBAGENT_EFFORT`, which applies only when nothing else names a level; `CLAUDE_CODE_EFFORT_LEVEL`, when set, overrides both a spawn's and a definition's `effort`, as the Claude Code subagent documentation states.

Six definitions carry the Agent tool (`implement`, `adversarial-check`, `escalated-check`, `root-cause`, `source-conflict`, `design`), so a dispatched worker can spawn its own read-only subagents for legwork: locating call sites, sweeping conventions, answering closed side-questions. Nested delegation is opt-in per dispatch and always explicit: the strategy declares it per checkpoint, every dispatch to a subagent actor carries one of two directives, and the default form is "Spawn no subagents." A nested spawn names a leaf definition plus an explicit model and effort. A spawned subagent is part of the worker that spawned it and never serves as the independent confirmer. The five leaf definitions keep the Agent tool disallowed; the roster's reasoning is in `docs/nested-subagent-delegation.md`.

A spawn name is a dispatch-time argument that fails silently: it changes where the report goes without an error. A named worker is an addressable teammate whose report does not come back on its own. It finishes, writes a complete report as its final text, and delivers nothing unless it calls a message-sending tool. So the skill spawns workers unnamed, and contracts the send explicitly on the rare checkpoint that needs a name. The runs behind that are in `docs/subagent-delivery-mechanism.md`.

The routing table deliberately leaves cells empty. No row routes to `max`, which measures within noise of `xhigh` and is documented as prone to overthinking on bounded work. No row routes opus at `low`: a maintainer default holds that sonnet at `medium` covers that cell, extrapolated from a GPT-5 versus GPT-5-mini measurement and untested on Claude. Opus rows outside implementation use three efforts rather than one because Opus 5 is the most effort-sensitive model measured: its own system card puts a 19-point spread across the ladder on an agentic benchmark, with the coding peak at `medium` rather than at the top. That measurement is Opus 5's; the `opus` alias resolves to Opus 5.5, which is unvalidated against it. Effort names are not calibrated the same way across the two, and Anthropic's own testing has Opus 5.5 at `medium` matching or beating Opus 5 at `high` on coding evaluations. `implement` on opus is capped at `medium`: on one fix batch, `medium`, `high`, and `xhigh` gave identical outcomes with about 26% and 84% more tokens at the higher two (n=2 per effort), in line with that vendor testing and with the maintainer's experience that higher efforts take longer for similar results. `implement` on sonnet is floored at `medium`: on the same batch, Sonnet 5.5 at `low` left an out-of-fence site unreported in 2 of 2 runs, where `medium` reported it in 2 of 2 (2 runs per effort, every run under an implementer prompt that carried Anthropic's Sonnet 5.5 scope and verification paragraphs and the plugin's out-of-fence rule, so the sweep does not separate those prompt additions' effect from the effort's; the 2026-09-24 Claude implementer runs lacked all three). The haiku rows run at `low`: by default the `haiku` alias resolves to Haiku 5.5, which ran without an API error at `effort: low` in one spawn. Where an environment maps the alias to an older model, the skill treats that actor as the family it resolves to.

The reasoning and the measurements are in `docs/claude-effort-mechanism.md`. The duties were derived from Claude Code's built-in agent types rather than copied from them; `docs/builtin-agent-duty-capture.md` records how, and how to re-check after a Claude Code update.

## Extension Contract

Projects register their own gates, fences, conduct rules, checkpoint types, and session topologies through two additive shapes: `Pre-<position>` / `Post-<position>` workflow positions on five named nodes per skill, and named configuration values that override the defaults documented inline in the skill bodies and references. Each skill has its own extension file under `.claude/extensions/work-orchestrator/` (`orchestrating-subagent-work.md`, `orchestrating-session-work.md`); the plugin's own hooks deliver the invoked skill's file wrapped in a structural envelope, so projects carry no delivery configuration. Both skills work without any extension.

Positions are keyed by node name rather than step number because the workflow is a loop — `Dispatch` and `Adapt` fire on every pass, so content written there must be safe to repeat. Named values that feed worker prompts are inlined verbatim at dispatch, since workers are stateless and inherit nothing from the session; a value that cites a project file by path travels to the worker as required reading rather than being read into the session.

Each skill fences part of its surface. In `orchestrating-subagent-work`: the consent check, the consent question, the halt state, and the deviation check take no position, and there is no named value for the verification shape or dual-confirmation closure. In `orchestrating-session-work`: session enumeration, the three mandatory message blocks, and the deviation check take no position, and the only named value reaching the deviation check is the append-only `sessions.additional_triggers`. A position section is free-form prose and cannot be prevented from arguing against a fenced node, but the node still runs after it, positions add rather than replace, and the setup skill refuses to author such content.

`EXTENSION.md` owns the contract: file layout, delivery, both mechanisms, the non-extendable surface per skill, reference-like extensions, the fourteen recognized named values, and worked examples for registering a project's gates, adding a checkpoint type, registering a session topology, and guarding handoff referents at the compose loop.

The companion plugin `work-orchestrator-extension-setup` writes the extension files for you. Its `setting-up-work-orchestrator-extension` skill asks which skills the project extends, explores the project's gates, protected paths, conduct rules, CI configuration, and session topology accordingly, drafts the content conversationally, and re-syncs existing extension files against a changed project.

## Documentation Sources

The `docs/` directory holds the findings the plugin's directives derive from, including the small experiments run to get them. Each file separates what was measured from what a vendor documents from what remains judgement, so a reader can see which directives rest on evidence and which rest on experience:

- `docs/codex-dispatch-experiments.md` records a private, instrumented 17-run experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, resume-loop validation) and the accompanying real-usage record, plus a 2026-09-24 replication on a fresh fixture in which five per-model observations did not replicate, and a 2026-11-02 series on the same fixture covering the GPT-6 models (Sol, Terra, Luna) and the Claude implementer and adversarial-check cells. Most cells are single runs, so the results are directional rather than proven.
- `docs/gpt-5-6-model-family.md` — adversarially verified external research on the GPT-5.6 tier design intent, pricing, effort guidance, and Codex CLI configuration
- `docs/claude-effort-mechanism.md`: where reasoning effort is set, the 2026-11-02 checks showing the Agent tool's `effort` argument takes effect and overrides a definition, the 2026-11-02 Sonnet 5.5 effort sweep, and the per-effort measurements behind each routing row
- `docs/builtin-agent-duty-capture.md` — how the agent duties were derived from Claude Code's built-in types, what to exclude as harness-injected, which parts vary by model, and the procedure for re-checking after a Claude Code update
- `docs/subagent-delivery-mechanism.md` — the five-run experiment separating the dispatch shapes whose reports come back on their own from the one whose report does not, the sending tool's absence from a worker's default tools, the transcript recovery path, and the limits of a single-definition sample
- `docs/nested-subagent-delegation.md` — which definitions carry the Agent tool and why, the opt-in-per-dispatch rationale, and the invariants nested spawns preserve; mostly judgement, except the definition-named-spawn invariant, confirmed against Claude Code's internal type declarations
- `docs/subagent-report-shape.md` — the 25-run experiment behind the report-shape wording: tool availability ruled out as a cause, the sonnet verdict revised mid-message when placed first, and a preamble persisting in the one run with a shape rule phrased as what to avoid, against four runs with no preamble under a positively phrased rule

These source materials are preserved for reference and can be used to update or extend the plugin when a model tier revs or Claude Code changes. They are not loaded at runtime.

## Contents

```
work-orchestrator/
├── .claude-plugin/
│   └── plugin.json                      # Claude Code plugin manifest
├── CHANGELOG.md
├── CLAUDE.md                            # Development guidance
├── EXTENSION.md                         # Project extension contract
├── README.md
├── agents/                              # 11 duty definitions; model and effort set per spawn
│   ├── search.md
│   ├── extract.md
│   ├── gate-run.md
│   ├── lookup.md
│   ├── source-read.md
│   ├── adversarial-check.md
│   ├── escalated-check.md
│   ├── root-cause.md
│   ├── source-conflict.md
│   ├── design.md
│   └── implement.md
├── docs/                                # Findings and experiments (not loaded at runtime)
│   ├── builtin-agent-duty-capture.md
│   ├── claude-effort-mechanism.md
│   ├── codex-dispatch-experiments.md
│   ├── gpt-5-6-model-family.md
│   ├── nested-subagent-delegation.md
│   ├── subagent-delivery-mechanism.md
│   └── subagent-report-shape.md
├── hooks/
│   ├── hooks.json                       # PostToolUse (Skill) + UserPromptSubmit delivery hooks
│   └── scripts/
│       └── inject-extension.sh          # self-gating extension delivery with structural envelope
└── skills/
    ├── orchestrating-session-work/
    │   ├── SKILL.md                     # Session-distribution workflow with digraph
    │   └── references/
    │       └── sessions-vs-subagents.md # Contrast table, addressing, traffic classification
    └── orchestrating-subagent-work/
        ├── SKILL.md                     # Orchestration workflow with digraph
        └── references/
            ├── codex-dispatch.md        # Codex invocation and re-validation loop
            ├── model-routing.md         # Checkpoint-to-actor routing table
            └── worker-prompts.md        # Prompt blocks every worker receives
```

## License

MIT
