# Subagent Orchestrator

Orchestrate implementation and review work through dispatched workers — the OpenAI Codex CLI (GPT-5.6 models) and Claude subagents — with a task-strategy workflow, model and reasoning-effort routing, fenced write scopes, and independent two-worker verification.

**This plugin is opinionated.** It encodes one way of dispatching work, not the way. Its directives come from three sources of unequal strength: vendor documentation, small local experiments recorded in `docs/`, and one maintainer's experience of what produced better results at lower cost on real work. Where those disagree, experience broke the tie. The goal is better, not optimal — if your work has a different shape, expect to disagree with some of it, and prefer copying the plugin over bending the extension contract into a rewrite.

## Overview

When significant implementation or review work runs through dispatched workers, the session becomes an orchestrator: it owns specs, triage, adjudication, git, and write authority, and it conserves its own context by not re-doing worker verification. This plugin ships the `orchestrating-subagent-work` skill, which pins that role down as a workflow:

- **Pre-flight and consent gate** — codex availability is checked before any planning or dispatch; a codex-less run requires explicit user consent in the current conversation.
- **Strategy before dispatch** — every task states its checkpoints, actors, efforts, dispatch order, verification shape, and named assumptions as a compact chat message before the first worker runs.
- **Model and effort routing** — checkpoints route to codex tiers (`gpt-5.6-sol` / `terra` / `luna`) or to one of the plugin's agent definitions, each pinning a model and a reasoning effort, with codex-less substitutions.
- **Fenced writes** — workers never write by default; a worker writes only inside an explicitly fenced write scope, and every worker-written change is diff-reviewed by an independent worker.
- **Two-worker verification** — every load-bearing result reaches producer-plus-independent-confirmer confirmation; a dual-confirmed result is final and the orchestrator does not re-verify it. Time pressure adapts scope, never verification.
- **Deviation handling** — dispatch failures, contradicted assumptions, scope surprises, and disputed results route through an explicit adapt-and-announce loop instead of silent plan changes.

The skill is host-specific to Claude Code (it orchestrates Claude subagent spawns); the Codex CLI appears as a dispatched worker, not as the host.

## Installation

```bash
/plugin install subagent-orchestrator@itb-ai-tools
```

**Restart Claude Code** after installing or updating so the extension-delivery hooks and the agent definitions load.

The `llm-author` plugin is declared as a dependency and auto-installs with this one; its `prompt-engineering` skill supplies the per-family worker-prompt rules.

Codex CLI worker dispatch additionally requires an installed, authenticated `codex` binary. The skill detects its absence and asks for consent before running codex-less.

Without a project extension, the skill runs on universal defaults: gates enumerated from the build configuration at dispatch time, the universal banned-command and conduct-rule lists, and the routing table as shipped.

## Skill

### orchestrating-subagent-work

**Triggers:** implementation or review work will run through dispatched workers — before the first codex dispatch or subagent spawn.

**References** (loaded on demand):

- `references/model-routing.md` — the checkpoint-to-actor routing table, verification shape, effort ladder, severity-label calibration, and codex-less substitutions
- `references/worker-prompts.md` — the review and implementer prompt-block protocols every worker receives, how extension content reaches a worker, and the trust boundaries on worker output
- `references/codex-dispatch.md` — codex invocation hygiene and the `codex exec resume` re-validation loop

Worker-prompt phrasing is not written into the skill. Once the strategy has named its actors, the skill invokes `llm-author:prompt-engineering` in Ruleset mode for the model families in play, writes the returned ruleset to a session-scoped file outside the repository, and re-reads it before building each worker prompt. Every worker still receives the same blocks with the same content; only the wording adapts to the family the checkpoint routes to.

## Agents

Claude Code does not let a reasoning effort be set when a subagent is spawned. The Agent tool accepts an `effort` argument and silently discards it — no error, no effect — so the worker runs at whatever the session happens to be set to. Effort binds in one place only: an agent definition. These 15 definitions exist for that reason, and most of them become unnecessary if the open upstream issues are fixed.

| Duty | haiku | sonnet | opus |
|---|---|---|---|
| `search` — locate code, symbols, convention instances | `search-haiku` | — | — |
| `investigate` — answer a question from sources, or check a claim | `investigate-haiku` | `low`, `medium`, `high` | `medium`, `high`, `xhigh` |
| `implement` — apply decided designs inside a fenced file list | — | `medium`, `high` | `medium`, `high`, `xhigh` |
| `design` — produce an approach from fresh context | — | — | `xhigh` |
| `gate-run` — run gate commands and transcribe the result | `gate-run-haiku` | — | — |

Names state the model and the rung because neither can be chosen at dispatch time. Each `description` is a selection contract — what the dispatch must supply, what comes back, what the agent can do, and what it reports instead of doing — so an orchestrating model picks on the contract rather than on matched examples.

The set is deliberately incomplete. Haiku takes no effort at all (it rejects the parameter, and its only depth lever is a process-wide thinking budget). No definition uses `max`, which measures within noise of `xhigh` and is documented as prone to overthinking on bounded work. There is no opus `low`, because sonnet at `medium` dominates that cell. Opus carries three rungs rather than one because it is the most effort-sensitive model measured — its own system card puts a 19-point spread across the ladder on an agentic benchmark, with the coding peak at `medium` rather than at the top.

The reasoning and the measurements are in `docs/claude-effort-mechanism.md`. The duties were derived from Claude Code's built-in agent types rather than copied from them; `docs/builtin-agent-duty-capture.md` records how, and how to re-check after a Claude Code update.

## Extension Contract

Projects register their own gates, fences, conduct rules, and checkpoint types through two additive shapes: `Pre-<position>` / `Post-<position>` workflow positions on five named nodes, and named configuration values that override the defaults documented inline in the skill body and its references. The extension file lives at `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md`; the plugin's own hooks deliver it wrapped in a structural envelope whenever the skill runs, so projects carry no delivery configuration. The skill works without any extension.

Positions are keyed by node name rather than step number because the workflow is a loop — `Dispatch` and `Adapt` fire on every pass, so content written there must be safe to repeat. Named values that feed worker prompts are inlined verbatim at dispatch, since workers are stateless and inherit nothing from the session; a value that cites a project file by path travels to the worker as required reading rather than being read into the session.

Four nodes are fenced — the consent check, the consent question, the halt state, and the deviation check. None takes a position, and the only named value reaching any of them is `deviation.additional_triggers`, which appends triggers and cannot remove one. There is no named value at all for the verification shape or dual-confirmation closure. A position section is free-form prose and cannot be prevented from arguing against a fenced node, but the node still runs after it, positions add rather than replace, and the setup skill refuses to author such content.

`EXTENSION.md` owns the contract: file layout, delivery, both mechanisms, the non-extendable surface, reference-like extensions, the eleven recognized named values, and worked examples for registering a project's gates and adding a checkpoint type.

The companion plugin `subagent-orchestrator-extension-setup` writes the extension file for you. Its `setting-up-subagent-orchestrator-extension` skill explores the project's gates, protected paths, conduct rules, and CI configuration, drafts the content conversationally, and re-syncs an existing file against a changed project.

## Documentation Sources

The `docs/` directory holds the findings the plugin's directives derive from, including the small experiments run to get them. Each file separates what was measured from what a vendor documents from what remains judgement, so a reader can see which directives rest on evidence and which rest on experience:

- `docs/codex-dispatch-experiments.md` — a private, instrumented 17-run experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, resume-loop validation) and the accompanying real-usage record. Single-run cells at one effort level, so directional rather than proven
- `docs/gpt-5-6-model-family.md` — adversarially verified external research on the GPT-5.6 tier design intent, pricing, effort guidance, and Codex CLI configuration
- `docs/claude-effort-mechanism.md` — where reasoning effort binds and where it silently does not, the six-run experiment establishing that a spawn-time `effort` argument has no effect, haiku's exclusion from the parameter, and the per-rung measurements behind each definition's rung
- `docs/builtin-agent-duty-capture.md` — how the agent duties were derived from Claude Code's built-in types, what to exclude as harness-injected, which parts vary by model, and the procedure for re-checking after a Claude Code update

These source materials are preserved for reference and can be used to update or extend the plugin when a model tier revs or Claude Code changes. They are not loaded at runtime.

## Contents

```
subagent-orchestrator/
├── .claude-plugin/
│   └── plugin.json                      # Claude Code plugin manifest
├── CHANGELOG.md
├── CLAUDE.md                            # Development guidance
├── EXTENSION.md                         # Project extension contract
├── README.md
├── agents/                              # 15 definitions pinning model + reasoning effort
│   ├── search-haiku.md
│   ├── investigate-haiku.md
│   ├── investigate-sonnet-low.md
│   ├── investigate-sonnet-medium.md
│   ├── investigate-sonnet-high.md
│   ├── investigate-opus-medium.md
│   ├── investigate-opus-high.md
│   ├── investigate-opus-xhigh.md
│   ├── implement-sonnet-medium.md
│   ├── implement-sonnet-high.md
│   ├── implement-opus-medium.md
│   ├── implement-opus-high.md
│   ├── implement-opus-xhigh.md
│   ├── design-opus-xhigh.md
│   └── gate-run-haiku.md
├── docs/                                # Findings and experiments (not loaded at runtime)
│   ├── builtin-agent-duty-capture.md
│   ├── claude-effort-mechanism.md
│   ├── codex-dispatch-experiments.md
│   └── gpt-5-6-model-family.md
├── hooks/
│   ├── hooks.json                       # PostToolUse (Skill) + UserPromptSubmit delivery hooks
│   └── scripts/
│       └── inject-extension.sh          # self-gating extension delivery with structural envelope
└── skills/
    └── orchestrating-subagent-work/
        ├── SKILL.md                     # Orchestration workflow with digraph
        └── references/
            ├── codex-dispatch.md        # Codex invocation and re-validation loop
            ├── model-routing.md         # Checkpoint-to-actor routing table
            └── worker-prompts.md        # Prompt blocks every worker receives
```

## License

MIT
