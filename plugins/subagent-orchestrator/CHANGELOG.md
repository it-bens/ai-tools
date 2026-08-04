# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.1.0] - 2026-08-05

Worker prompts were phrased for one audience and dispatched to three. A codex worker reads everything it will ever know from its dispatch prompt; a claude worker arrives carrying its agent definition, and the two families respond to opposite tuning. So the rules are now derived rather than encoded: a node between the strategy and the first dispatch invokes `llm-author:prompt-engineering` in Ruleset mode for the families the strategy assigned, once per task, and the ruleset is re-read before each prompt is built. Blocks and content are unchanged; only wording adapts.

Three requirements the plugin states itself, because none follows from a prompting guide. The lever order is inverted between families — Claude actors get the rung set first; GPT-5.6 actors get the prompt checked for a missing success criterion, dependency rule, tool-routing rule, or verification loop before the rung rises (`docs/claude-effort-mechanism.md` §Cross-vendor note). Leanness means deduplication, not block removal: OpenAI reports leaner system prompts scoring roughly 10–15% better at 41–66% fewer tokens, directional internal eval runs rather than a benchmark, and this plugin's FENCE-block ablation cut a two-fix implementer run from 405k to 186–192k tokens (`docs/codex-dispatch-experiments.md`). Verification duties survive the ruleset, since the Claude 5 guidance to strip verification scaffolding is scoped to Opus 5.

Mapping haiku definitions to the Claude 4 generation is this repository's judgement, not a citation: Anthropic publishes no Haiku 4.5 prompting page, and its general best-practices page lists the model with no generation carve-out.

### Added

- `skills/orchestrating-subagent-work/SKILL.md` — the `Derive worker-prompt rules for the assigned families` node, in the digraph between `Build task strategy in conversation` and `Execute next strategy step`. It states the families in play, the dispatch path per family (a piped string for codex, a subagent spawn for claude — neither takes API parameters), and the two artifact types the plugin authors, so the skill resolves its three inputs without stopping to ask. The ruleset lands in a non-permanent file outside the repository: never committed, never under a project path, never reused across tasks
- `allowed-tools: Skill(llm-author:prompt-engineering)` in the skill frontmatter, and `dependencies: ["llm-author"]` in the manifest, matching how `commit-message-writer`, `project-communication`, and `software-writer` declare `human-author`

### Changed

- `skills/orchestrating-subagent-work/SKILL.md` — `Execute next strategy step` reads the ruleset file before building each worker prompt and phrases it for the family the checkpoint's actor belongs to
- `skills/orchestrating-subagent-work/references/worker-prompts.md` — the opening paragraph no longer claims a codex worker and a subagent get the same prompt. They get the same blocks and the same content; the phrasing adapts, and the ruleset is named as where the adaptation comes from

The derivation node carries no position name and no named value configures it. The position table stays at five entries, the recognized-values table at eleven, and project-specific prompt content still reaches workers through the named values `worker-prompts.md` already cites. Projects with an extension file need no action.

## [3.0.0] - 2026-08-04

The routing table assigned every claude checkpoint an effort of `—`, because there was no way to give a subagent one. Testing showed why: the Agent tool accepts an `effort` argument and silently discards it. Six sonnet dispatches, three declaring `low` and three declaring `max`, returned byte-identical answers to an eight-problem battery, with the `low` runs averaging *more* tokens (78.1k against 74.4k) and longer wall-clock (241s against 207s); `effort: "banana"` was accepted without complaint; and `CLAUDE_EFFORT` read the session's `xhigh` inside both. Reasoning effort binds in one place only — an agent definition — so the plugin now ships them.

This is a workaround for open Claude Code issues, not a design preference. If per-spawn effort lands upstream, most of `agents/` becomes unnecessary.

### Added

- `agents/` — 15 definitions across four duties and three models, each pinning a model and a reasoning effort. `search-haiku`, `investigate-haiku`, `gate-run-haiku`; `investigate-sonnet-{low,medium,high}`, `implement-sonnet-{medium,high}`; `investigate-opus-{medium,high,xhigh}`, `implement-opus-{medium,high,xhigh}`, `design-opus-xhigh`. Names state model and rung because neither is settable at dispatch. Read-only duties enforce that with `disallowedTools` rather than with a prohibition paragraph, and every definition blocks re-delegation
- `docs/claude-effort-mechanism.md` — where effort binds and where it silently does not, the spawn-argument experiment with its sample sizes and its limits, haiku's unconditional exclusion from the parameter and the `thinking_mode` directives it receives instead, and the per-rung measurements behind each choice: Opus 5's 19-point spread across the ladder with its coding peak at `medium`, sonnet's documented under-thinking risk at `low`, and the evidence that a stronger model at a lower rung beats a weaker model at a higher one
- `docs/builtin-agent-duty-capture.md` — how the duties were derived from Claude Code's built-in agent types, the capture prompt and its boundary marker, the harness-injected content to exclude, the per-model check (duty prose is byte-identical between sonnet and opus; haiku recites unreliably), and the update procedure for a Claude Code upgrade

### Changed

- `skills/orchestrating-subagent-work/references/model-routing.md` — every claude row names an agent definition and its rung instead of `—`; new rows for self-contained substantial batches, cross-file fix batches, mechanism-reworking batches, escalated verification, root-cause reads, and source contradictions; the escalation criterion is now stated (skipped scope or stopped early needs a higher rung, had everything and still got it wrong needs a stronger model); `max` is documented as deliberately unrouted; `routing.effort_defaults` resolves to an invocation flag on codex checkpoints and to a definition selection on claude ones; where a substantial self-contained batch matches both the codex and the opus implementer row, that pair is named as one discretionary choice `routing.codex_bias` arbitrates, with the strategy declaring which side it took
- `skills/orchestrating-subagent-work/SKILL.md` — the description is a contract rather than a trigger list, stating what the skill takes, returns, can do, and refuses; the dispatch node routes to the named definition instead of spawning with an explicit model, and forbids setting an effort on the spawn
- `EXTENSION.md` — `routing.effort_defaults` documents its two resolutions, and that a rung no shipped definition carries cannot be honored; the `routing.additions` example names a shipped definition as its claude actor rather than a bare model, since a project cannot pair a model with a rung directly
- `README.md` and `CLAUDE.md` — the plugin states plainly that it is opinionated and partly grounded in one maintainer's experience; the false "no agents" claim is corrected; agent-authoring rules are recorded (contract descriptions, no roles, no worked examples, standing content in the definition and specific content in the dispatch prompt)

### Breaking

- A claude checkpoint is no longer dispatched by naming a model. It routes to an agent definition, which requires a Claude Code restart after install or update before it resolves
- Projects assigning `routing.effort_defaults` for a claude checkpoint type now select among shipped definitions. An assignment naming a rung none of them carries is reported rather than approximated
- No extension-file format, position name, or other named value changed. Projects with an extension file need no action beyond the restart

## [2.2.0] - 2026-08-03

Adds `routing.codex_bias`, the eleventh recognized named value: an override-shaped codex/claude calibration read at the strategy node. It accepts `codex-heavy`, `claude-lean`, or `codex-less`; unset preserves current behavior. Cross-family independence bounds every bias, and `codex-less` routes through the existing consent gate. The digraph adds that route, and the consent-question halt wording now also covers dropping the bias.

## [2.1.0] - 2026-07-26

The prompt-block protocols were reachable only through a file named for codex, so the branch that dispatches a subagent never opened them. 2.0.0 fixed the pointer; this release fixes the placement.

### Added

- `skills/orchestrating-subagent-work/references/worker-prompts.md` — the review and implementer prompt-block protocols, extension-content propagation into worker prompts, and the trust boundaries on worker output, all moved here from `codex-dispatch.md` and stated worker-generally

### Changed

- `skills/orchestrating-subagent-work/SKILL.md` — the dispatch node reads `references/worker-prompts.md` before the first dispatch of any checkpoint, ahead of the actor-specific bullets, so the blocks no longer hang off the codex branch
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — reduced to codex mechanics (invocation hygiene, the `exec resume` loop) and gains the codex-less re-validation rule the resume loop previously left implicit
- Trust boundaries and the GATES row are stated per worker rather than per codex run: a gate claim is non-final whatever produced it, the sandbox is named as the codex case rather than the rule, and diff review covers every worker-written change

No named value, position, or extension-file format changed. Projects with an extension file need no action.

## [2.0.0] - 2026-07-26

Adds the project extension surface, modeled on the one `software-writer` 2.x ships. The mechanisms are the same — workflow positions plus named configuration values, delivered by plugin-owned hooks — with two adaptations the orchestration workflow forces: positions are keyed by node name rather than step number, because the workflow is cyclic and a linear step number would misdescribe it; and named values that feed worker prompts are inlined verbatim at dispatch, because workers are stateless and inherit nothing from the session.

### Added

- `EXTENSION.md` — the contract: extension file layout, delivery envelope, both mechanisms, the non-extendable surface, reference-like extensions, the recognized-values table, and worked examples for registering gates and a project checkpoint type
- `hooks/hooks.json`, `hooks/scripts/inject-extension.sh` — Claude Code delivery of `.claude/extensions/subagent-orchestrator/orchestrating-subagent-work.md` on `PostToolUse` (matcher `Skill`) and `UserPromptSubmit`, wrapped in a `<project_extension>` envelope; silent for every other skill, prompt, and project
- Ten recognized named values: `project.gates`, `project.protected_paths`, `project.banned_commands`, `project.skill_files`, `project.conduct_rules`, `project.review_lenses`, `codex.extra_config`, `routing.additions`, `routing.effort_defaults`, `deviation.additional_triggers`
- Five workflow positions — `Preflight`, `Strategy`, `Dispatch`, `Adapt`, `Report` — each with a `Pre-` and `Post-` form
- `plugin-tests/subagent-orchestrator/inject_extension.bats` — gating, delivery, non-Claude-host, and failure coverage for the delivery script

### Changed

- `skills/orchestrating-subagent-work/SKILL.md` — new `## Workflow` section declaring both extension mechanisms and the position table, with node sections demoted to `###` beneath it; the deviation node cites `deviation.additional_triggers`
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — new §Extension content in worker prompts fixing propagation (values inlined verbatim into the citing block; cited paths travel as SKILLS required reading); GATES, FENCE, SKILLS, RULES, and LENS rows cite their named values with inline defaults; invocation hygiene cites `codex.extra_config`
- `skills/orchestrating-subagent-work/references/model-routing.md` — routing table cites `routing.additions`, effort ladder cites `routing.effort_defaults`

The consent gate, the deviation check, the halt state, the verification shape, and dual-confirmation closure are deliberately fenced: none carries a position name, and the only named value reaching any of them is `deviation.additional_triggers`, which appends triggers and cannot remove one. The verification shape and dual-confirmation closure have no named value at all.

## [1.0.0] - 2026-07-17

Initial release. The skill's directives derive from two evidence legs, both distilled into `docs/`: a private, instrumented 17-run codex experiment series (review and implementer runs across all three GPT-5.6 models against a known defect state, prompt-block ablations, and a resume-loop validation — single-run cells, all at effort `max`, so directional rather than proven) and an adversarially verified deep-research pass over the official GPT-5.6 and Codex CLI documentation (2026-07-15; 23 of 24 top claims survived three refute-votes each).

### Added

- `skills/orchestrating-subagent-work/SKILL.md` — orchestration workflow (codex pre-flight, codex-less consent gate, strategy-before-dispatch, deviation-and-adaptation loop, dual-confirmation closure), pinned by a digraph
- `skills/orchestrating-subagent-work/references/model-routing.md` — checkpoint-to-actor routing table across `gpt-5.6-sol`/`terra`/`luna` and sonnet/haiku subagents, verification shape, effort ladder, severity-label calibration, codex-less substitutions
- `skills/orchestrating-subagent-work/references/codex-dispatch.md` — CLI-only invocation hygiene, review and implementer prompt-block protocols, the `codex exec resume` re-validation loop, trust boundaries
- `docs/codex-dispatch-experiments.md` — distilled local experiment findings (transport, model roles, prompt-block ablations, spec-writing lessons, cost, named confounds)
- `docs/gpt-5-6-model-family.md` — external research on tier design intent, pricing, effort guidance, and Codex CLI configuration, with sources
