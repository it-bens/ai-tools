# Subagent Orchestrator

Orchestrate implementation and review work through dispatched workers — the OpenAI Codex CLI (GPT-5.6 models) and Claude subagents — with a task-strategy workflow, evidence-based model routing, fenced write scopes, and independent two-worker verification.

## Overview

When significant implementation or review work runs through dispatched workers, the session becomes an orchestrator: it owns specs, triage, adjudication, git, and write authority, and it conserves its own context by not re-doing worker verification. This plugin ships the `orchestrating-subagent-work` skill, which pins that role down as a workflow:

- **Pre-flight and consent gate** — codex availability is checked before any planning or dispatch; a codex-less run requires explicit user consent in the current conversation.
- **Strategy before dispatch** — every task states its checkpoints, actors, efforts, dispatch order, verification shape, and named assumptions as a compact chat message before the first worker runs.
- **Model routing** — checkpoints route to codex tiers (`gpt-5.6-sol` / `terra` / `luna`) or Claude subagents (sonnet / haiku) by task profile, with effort defaults and codex-less substitutions.
- **Fenced writes** — workers never write by default; a worker writes only inside an explicitly fenced write scope, and every worker-written change is diff-reviewed by an independent worker.
- **Two-worker verification** — every load-bearing result reaches producer-plus-independent-confirmer confirmation; a dual-confirmed result is final and the orchestrator does not re-verify it. Time pressure adapts scope, never verification.
- **Deviation handling** — dispatch failures, contradicted assumptions, scope surprises, and disputed results route through an explicit adapt-and-announce loop instead of silent plan changes.

The skill is host-specific to Claude Code (it orchestrates Claude subagent spawns); the Codex CLI appears as a dispatched worker, not as the host.

## Installation

```bash
/plugin install subagent-orchestrator@itb-ai-tools
```

**Restart Claude Code** after installing or updating so the extension-delivery hooks load.

Codex CLI worker dispatch additionally requires an installed, authenticated `codex` binary. The skill detects its absence and asks for consent before running codex-less.

Without a project extension, the skill runs on universal defaults: gates enumerated from the build configuration at dispatch time, the universal banned-command and conduct-rule lists, and the routing table as shipped.

## Skill

### orchestrating-subagent-work

**Triggers:** a task will be executed or reviewed through dispatched workers — before the first codex dispatch, subagent spawn, or workflow run of any implementation or review task.

**References** (loaded on demand):

- `references/model-routing.md` — the checkpoint-to-actor routing table, verification shape, effort ladder, severity-label calibration, and codex-less substitutions
- `references/worker-prompts.md` — the review and implementer prompt-block protocols every worker receives, how extension content reaches a worker, and the trust boundaries on worker output
- `references/codex-dispatch.md` — codex invocation hygiene and the `codex exec resume` re-validation loop

## Extension Contract

Projects register their own gates, fences, conduct rules, and checkpoint types through two additive shapes: `Pre-<position>` / `Post-<position>` workflow positions on five named nodes, and named configuration values that override the defaults documented inline in the skill body and its references. The extension file lives at `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md`; the plugin's own hooks deliver it wrapped in a structural envelope whenever the skill runs, so projects carry no delivery configuration. The skill works without any extension.

Positions are keyed by node name rather than step number because the workflow is a loop — `Dispatch` and `Adapt` fire on every pass, so content written there must be safe to repeat. Named values that feed worker prompts are inlined verbatim at dispatch, since workers are stateless and inherit nothing from the session; a value that cites a project file by path travels to the worker as required reading rather than being read into the session.

Four nodes are fenced — the consent check, the consent question, the halt state, and the deviation check. None takes a position, and the only named value reaching any of them is `deviation.additional_triggers`, which appends triggers and cannot remove one. There is no named value at all for the verification shape or dual-confirmation closure. A position section is free-form prose and cannot be prevented from arguing against a fenced node, but the node still runs after it, positions add rather than replace, and the setup skill refuses to author such content.

`EXTENSION.md` owns the contract: file layout, delivery, both mechanisms, the non-extendable surface, reference-like extensions, the ten recognized named values, and worked examples for registering a project's gates and adding a checkpoint type.

The companion plugin `subagent-orchestrator-extension-setup` writes the extension file for you. Its `setting-up-subagent-orchestrator-extension` skill explores the project's gates, protected paths, conduct rules, and CI configuration, drafts the content conversationally, and re-syncs an existing file against a changed project.

## Documentation Sources

The `docs/` directory contains the distilled research findings the skill's directives derive from:

- `docs/codex-dispatch-experiments.md` — a private, instrumented 17-run experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, resume-loop validation) and the accompanying real-usage record
- `docs/gpt-5-6-model-family.md` — adversarially verified external research on the GPT-5.6 tier design intent, pricing, effort guidance, and Codex CLI configuration

These source materials are preserved for reference and can be used to update or extend the skill when a model tier revs. They are not loaded at runtime.

## Contents

```
subagent-orchestrator/
├── .claude-plugin/
│   └── plugin.json                      # Claude Code plugin manifest
├── CHANGELOG.md
├── CLAUDE.md                            # Development guidance
├── EXTENSION.md                         # Project extension contract
├── README.md
├── docs/                                # Distilled research findings (not loaded at runtime)
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
