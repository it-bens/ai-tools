# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.9.0] - 2026-08-04

Added OpenAI model support to the `prompt-engineering` skill, with explicit guidance for the GPT-5.6 family (Sol, Terra, Luna) and the GPT-5 family baseline (GPT-5 through GPT-5.5). GPT-5.6 prompting is outcome-first: define the outcome, constraints, evidence, and completion bar, then leave the path to the model — leaner prompts outperform, contradictions destabilize more than gaps, and proactivity is steered through autonomy/approval boundaries rather than repeated "ask first" rules. Sourced from OpenAI's official GPT-5.6 prompting guidance, the "Using GPT-5.6" developer guide, the GPT-5.6 Sol migration guide, the launch announcement, and the original GPT-5 prompting guide from the OpenAI Cookbook; verbatim copies are archived under `docs/`.

### Added

- `skills/prompt-engineering/references/gpt-56-guide.md` — GPT-5.6 optimizations: model family and selection (Sol/Terra/Luna), core prompting posture, API parameters (`reasoning.effort` incl. the new `max`, `reasoning.mode: "pro"`, `reasoning.context`, `text.verbosity`, prompt-caching changes), behavioral guidance (conciseness, autonomy boundaries, retrieval budgets), tool use incl. Programmatic Tool Calling and multi-agent beta, a Claude-to-GPT-5.6 adaptation table, GPT-5.x migration steps and hazards, a pre-5.6 GPT-5 family baseline, and quick-reference templates
- `skills/prompt-engineering/examples/gpt-56-adaptation.md` — before/after transformations (step-prescriptive → outcome-first, approval-heavy → autonomy policy, vague thoroughness → retrieval budget) plus an adaptation checklist
- `references/output-formats.md` sections 11 "GPT-5.6 Prompts" (API Configuration) and 12 "Claude-to-GPT-5.6 Adaptations" (Before/After comparison), with matching rows in the SKILL.md output-format table
- `docs/gpt-5-6-prompting-guidance.md`, `docs/using-gpt-5-6.md`, `docs/upgrading-to-gpt-5-6-sol.md`, `docs/introducing-gpt-5-6.md`, `docs/gpt-5-prompting-guide.md` — verbatim raw source pages

### Changed

- `skills/prompt-engineering/SKILL.md` — frontmatter description gained GPT-5.6 (OpenAI) adaptation and GPT-5.x migration triggers; workflow digraph gained a "GPT-5.6 (OpenAI) -> gpt-56-guide" target-model branch; Phase 1 target-model question lists GPT-5.6; new "GPT-5.6 (OpenAI) Adaptation (When Requested)" section with compact triggers plus pointers
- `README.md` (plugin) — GPT-5.6 in the tagline, overview, Prompt Engineering triggers, capabilities, usage examples, and documentation sources
- `AGENTS.md` (plugin) — file-navigation row for the GPT-5.6 guide
- Repository `README.md` — llm-author plugin description includes GPT-5.6 (OpenAI)
- `project/system-prompt.md`, `project/description.txt` — Claude Web project recognizes GPT-5.6 as a requested target
- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` — version `3.9.0`; added the `gpt-5.6` and `openai` keywords; Claude Code manifest description includes GPT-5.6

## [3.8.0] - 2026-08-03

Removed self-description and self-justification prose across every skill. A reference or example file becomes inlined content the moment its skill loads it, so a heading or subtitle that describes the file — a `## Purpose` block, a "what this guide covers" subtitle, a "Loaded before Pass N" note — is ballast that adds nothing the loaded content does not already show, and it pushes the executable instructions further from the model's attention. This release cuts that prose and keeps the imperative instructions, the substantive reference content, and the deliverable templates.

### Changed

- `skills/prompt-engineering/SKILL.md` — frontmatter description reduced to trigger-only (dropped the capability-summary preamble that overrides the workflow digraph); removed the "Expert prompt engineering service…" mission blurb, the `## Core Mission` capabilities list, the post-digraph workflow-summary paragraph, and the `## Success Metrics` section, leaving the `**Deliverable**` constraint and the imperative phases
- `skills/content-editing/SKILL.md` — cut the "adding more instructions increases complexity" design-justification and the "Balance is key" platitude; trimmed the post-digraph narration to "Walk the checks in order."
- `skills/rule-file-writing/SKILL.md` — removed the post-digraph workflow-summary line; its three references (`essential-vs-ballast.md`, `techniques.md`, `three-angle-pattern.md`) dropped their "Loaded before Pass N" timing narration for a direct opening statement
- `skills/writing-handoff-prompts/SKILL.md` — removed the "a fresh session with a complete handoff outperforms a stale one" design-justification
- `skills/prompt-engineering/references/` — removed the descriptor subtitle under the H1 of `claude-4-guide.md`, `gemini-3-guide.md`, `glm-47-guide.md`, `output-formats.md`, and `prompt-patterns/README.md`; rewrote the `claude-5-guide.md` and `gemini-3-deep-research-guide.md` openers to keep their routing/definition and drop the self-description framing; removed the "For X" one-line descriptor from the ten prompt-pattern template files
- `skills/prompt-engineering/examples/` — removed the `## Purpose` and `## Best Used For` framing blocks from all seven example files, and restated the mid-file Example 5 intro in `glm-47-adaptation.md` as the scenario itself
- `project/system-prompt.md` — same cleanup for the Claude Web project prompt: removed the "these files contain everything you need" file-list summary, the "transform requirements into high-performing…" mission blurb, the "authoritative reference — consult them before responding" restatement, and the "adding more instructions increases complexity" design-justification

## [3.7.0] - 2026-08-03

Added a first-class Claude 4 → Claude 5 migration path to `prompt-engineering`, mirroring the GLM and Gemini adaptation treatment: a named workflow branch, a before/after output format, and a worked example. Existing Claude 4 content that targets Claude 5 was previously reachable only through the generic "optimize LLM-targeted content" path; migration is now its own mode that diagnoses and removes carried-over Claude 4 scaffolding and delivers a reviewable before/after.

### Added

- `skills/prompt-engineering/examples/claude-4-to-5-migration.md` — before/after transformations for a system prompt, an LLM-targeted comment-writing skill, and a subagent-orchestration prompt, plus a migration checklist
- Migration mode in the `prompt-engineering` workflow digraph — a "Migrating existing Claude 4 content to Claude 5?" branch that routes to a before/after delivery — and a matching "Claude 4 → Claude 5 Migration (When Requested)" section
- `references/output-formats.md` section 10, "Claude 4 to Claude 5 Migrations" (Before/After comparison), with a matching row in the SKILL.md output-format table

### Changed

- `skills/prompt-engineering/SKILL.md` — frontmatter description gained a Claude 4 → 5 migration trigger
- `README.md` (plugin) — Prompt Engineering triggers, capabilities, and usage examples now include Claude 4 → 5 migration
- `project/system-prompt.md` — the Claude Web project recognizes the migration prompt type

## [3.6.0] - 2026-08-03

Plugin hygiene plus a progressive-disclosure refactor of `prompt-engineering`: added workflow digraphs to the three skills that lacked one; aligned the `allowed-tools` frontmatter with what the field actually does (verified against the official skills docs at `code.claude.com/docs/en/skills`) and corrected the docs that mislabeled it; and reorganized the skill so each reference loads at its point of use, slimming SKILL.md from 517 to 349 lines and splitting the two largest reference files into per-section files.

### Added

- Workflow digraphs (Graphviz `dot`) to the three skills that lacked one: `prompt-engineering` (recognition / refinement / phase / target-model routing), `rule-file-writing` (Create-vs-Optimize routing and the two-pass loop pinned by a "no third pass" terminal), and `content-editing` (the correct-over-add decision gate). `writing-handoff-prompts` and `writing-session-feedback` already had one.
- Per-section reference files for on-demand loading: `references/techniques/` (nine technique files plus an index, from the former `techniques-detailed.md`) and `references/prompt-patterns/` (fifteen pattern files plus an index, from the former `prompt-patterns.md`). Citations point to the specific file so only the needed section loads.

### Changed

- `allowed-tools` now reflects that it pre-approves rather than restricts tools: removed it from `prompt-engineering` and `rule-file-writing`, and narrowed `writing-handoff-prompts` / `writing-session-feedback` to `Skill(llm-author:prompt-engineering)` alone. Every tool stays callable; unlisted tools are simply prompted for.
- Repository `README.md` and `AGENTS.md` — corrected the claim that `allowed-tools` "restricts tool access"; it pre-approves the listed tools for the invoking turn and does not restrict which tools are available (`disallowed-tools` is the removal field).
- `prompt-engineering` SKILL.md slimmed from 517 to 349 lines: the GLM 4.7, Gemini 3, and Claude 4 adaptation sections reduced to compact triggers plus pointers (full detail already lives in their guides); references named at their point of use, with `examples/system-prompt-template.md`, `examples/prompt-chain-template.md`, and `examples/optimization-report.md` wired into the phases that use them; and the redundant bottom "Additional Resources" list removed.
- Repointed technique and pattern citations from section anchors in the old monolith files to the new per-section files.

### Removed

- `references/techniques-detailed.md` and `references/prompt-patterns.md` — replaced by the per-section directories above.

## [3.5.0] - 2026-08-03

Added Claude 5 (Opus 5, Sonnet 5, Fable 5) support to the `prompt-engineering` skill and made Claude 5 the default target generation, with Claude 4 retained as a selectable path. Claude 5 shifts prompting from constraint toward judgment: the `effort` parameter and adaptive thinking replace manual thinking budgets and sampling parameters; assistant prefill, `budget_tokens`, and non-default `temperature`/`top_p`/`top_k` now return a 400 error; and the models self-verify, self-correct, and delegate to subagents more readily, so carried-over verification and aggressive tool-triggering prompts are removed rather than rewritten. Sourced from Anthropic's official prompting docs for Opus 5, Sonnet 5, and Fable 5, the prompting best-practices page, the model migration guide (`/docs/en/about-claude/models/migration-guide`), and the "new rules of context engineering for Claude 5 generation models" post on claude.com; verbatim copies are archived under `docs/`.

### Added

- `skills/prompt-engineering/references/claude-5-guide.md` — Claude 5 optimizations: an `effort`-parameter and adaptive-thinking primer, a breaking-changes table, per-model guidance (Opus 5, Sonnet 5, Fable 5), a Claude 5 model-selection table, and a "less is more" section for optimizing LLM-targeted content that targets Claude 5
- `docs/prompting-claude-opus-5.md`, `docs/prompting-claude-sonnet-5.md`, `docs/prompting-claude-fable-5.md`, `docs/claude-5-best-practices.md`, `docs/claude-5-migration-guide.md`, `docs/context-engineering-claude-5-generation.md` — verbatim raw source pages

### Changed

- `skills/prompt-engineering/SKILL.md` — Claude 5 set as the default target (frontmatter description, intro, core mission, Phase 1 model selection); "Claude 4 Specific Optimizations" reworked into a generation-aware "Model-Generation Optimizations" section with Claude 5 primary and Claude 4 retained; prefilling and chain-of-thought entries flagged Claude 4 / earlier with Claude 5 replacements; the LLM-targeted-content optimization principle gained a Claude 5 "less is more" note; GLM/Gemini comparison columns relabeled generation-neutral, with the Gemini temperature and prefill cells corrected for Claude 5
- `skills/prompt-engineering/references/techniques-detailed.md` — §6 Prefilling marked Claude 4 / earlier, noting the Claude 5 400 error and its replacements
- `project/system-prompt.md`, `project/description.txt` — Claude Web project updated to Claude 5 default with Claude 4 selectable
- `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json` — version `3.5.0`; added the `claude-5` keyword; Claude Code manifest description now includes Claude 5
- `README.md` (plugin) and repository `README.md`, and the plugin's `AGENTS.md` — document Claude 5 support and add a file-navigation entry for the new guide

## [3.4.0] - 2026-07-12

Generalized the plugin's runtime instructions for use by multiple AI coding assistants while preserving Claude-specific frontmatter and Claude Web assets.

### Added

- Codex plugin manifest and repository marketplace registration

### Changed

- Generalized rule-file authoring around the shared rule-file concept and the active assistant's discovery conventions
- Replaced named tool calls in skill bodies with host-neutral actions while retaining the helpful Claude Code frontmatter
- Moved shared development guidance to `AGENTS.md`, with `CLAUDE.md` loading it through `@AGENTS.md`

### Removed

- `writing-subagent-descriptions`, which will be superseded by a tool-neutral description-writing skill

## [3.3.0] - 2026-06-26

Added two skills that author session-to-session prompts, derived from recurring request patterns in the shopware/shopware sessions: `writing-handoff-prompts` (forward — package a unit of work for a fresh, zero-context session) and `writing-session-feedback` (backward — a calibration note to the upstream session that defined the work, so it can confirm correctness and sharpen future specs/reviews). Both stay abstract over the kind of work and deduce branch, commit/verification policy, scope, and recipient from context. They are `model: sonnet` and `user-invocable: false` (invoked only on an explicit user request, never proactively), craft their output via the nested `llm-author:prompt-engineering` skill, and ask whether to save it to a file or copy it to the clipboard. The section templates and gates were sharpened against external research on session handoffs.

### Added

- `skills/writing-handoff-prompts/SKILL.md` — contextual-requirements deduction table, a handoff section template (mission, first action, required reading, settled-vs-open, trust-the-code, scope, escalation boundary, evidence-based done), zero-context-completeness and concrete-real-values gates, and an ask-then-deliver step, pinned by a decision digraph
- `skills/writing-session-feedback/SKILL.md` — recipient/anchor deduction table, a feedback section template (verdict, divergences-with-reasons, under-specified, judgment calls with confidence tags, before/after verification), a self-evaluation-leniency counter, and an ask-then-deliver step, with a matching digraph

## [3.2.0] - 2026-06-12

Banned persona/role prompting and "You are …" identity openers in the prompt-engineering skill. Zheng et al. 2024 (arXiv:2311.10054) showed personas in system prompts do not improve factual correctness (162 personas, 4 model families, 2,410 factual questions; per-question effects unpredictable); identity openers restate the task without adding constraints. The skill now teaches explicit task and output requirements instead, actively removes personas and identity openers when optimizing existing prompts, and keeps a single exception: character roleplay, where the persona is the requested output. Citations stay out of skill content; provenance lives in this changelog and `docs/`. This deliberately diverges from Anthropic's legacy role-prompting guidance.

### Changed

- `skills/prompt-engineering/SKILL.md` — "Role Prompting" essential technique replaced by "Roles (Do Not Use)"; fixed broken deep-dive anchor (`#5-give-claude-a-role` → `#5-system-prompts-and-role-prompting`)
- `skills/prompt-engineering/SKILL.md` — optimization now actively removes personas and identity openers from existing prompts and LLM-targeted content: Phase 2 optimization step converts what they implied (tone/depth/audience) into explicit requirements, the LLM-targeted-content preservation principle excludes them from "substantive content", and the quality checklist gates delivery on their absence (character roleplay excepted)
- `references/techniques-detailed.md` §5 — removed "Enhanced accuracy" claims, role-specificity ladder, and the General Counsel example; replaced with a do-not-use directive, persona-vs-explicit-requirements example, domain-performance alternatives, and the character-roleplay exception
- `references/techniques-detailed.md` — technique-selection table routes "Domain expertise" to context/domain material/grounding instead of role prompting
- `examples/system-prompt-template.md` — Role section replaced by a Task section (no identity opener); customer-support example updated accordingly
- `references/glm-47-guide.md` / `examples/glm-47-adaptation.md` — "Role + Constraint Opener" reduced to "Constraint Opener"; identity openers stripped from all adapted example prompts (before-examples keep them as input being corrected)
- `examples/gemini-3-adaptation.md` / `references/gemini-3-guide.md` — identity openers stripped from adapted example prompts and the system-instruction API example
- `references/claude-4-guide.md` — safety template opens with directives instead of "You are a helpful, harmless, and honest AI assistant"
- `project/system-prompt.md` — Claude Web project prompt opens with the task statement instead of "You are an expert prompt engineer …"
- `docs/system-prompts.md` — editorial note marking the source doc's accuracy claims as superseded, to prevent regression in future skill updates

## [3.1.0] - 2026-05-28

Added Writing Subagent Descriptions skill for authoring the `description` field on Claude Code agent definitions. A single `[invocation-style]` argument (`broad` | `narrow` | `specialist`) controls trigger phrasing and routing breadth. The skill treats descriptions as LLM-routing artifacts, not human prose: no anti-slop validation runs, and router-recognized tokens such as `PROACTIVELY` and `MUST BE USED` are explicitly preserved.

### Added

- `skills/writing-subagent-descriptions/SKILL.md` — digraph workflow, broad / narrow / specialist drafting templates, router-vs-expert separation audit that preserves routing-critical tokens

## [3.0.0] - 2026-04-14

Renamed plugin from `prompt-engineering` to `llm-author`. The previous name collided with the inner `prompt-engineering` skill during invocation — phrases like "use the prompt-engineering plugin" frequently routed to the wrong skill. The new name reflects the plugin's actual scope: authoring LLM-targeted content (prompts, skills, agents, rules files) rather than prompt engineering alone. Skill names are unchanged.

### Changed

- Plugin directory: `plugins/prompt-engineering/` → `plugins/llm-author/`
- `plugin.json` name, description, and keywords updated to `llm-author`
- Marketplace entry and main README table updated to the new name
- Skill versions bumped to 3.0.0 to track the plugin major version
- Cross-plugin references (`behavior-diagnostics`) updated to `llm-author:prompt-engineering`

## [2.4.0] - 2026-04-14

Added Rule-File Writing skill for authoring and optimizing auto-loaded Claude Code rules files in `~/.claude/rules/` and project `.claude/rules/`.

### Added

- `skills/rule-file-writing/SKILL.md` - Create/optimize branching, interview flow, two-pass optimization loop
- `skills/rule-file-writing/assets/templates/rules-file-skeleton.md` - Canonical CRITICAL → Decision Test → body → Red Flags shell
- `skills/rule-file-writing/references/` - Pass 1 essential-vs-ballast, Pass 2 techniques and three-angle pattern

## [2.3.0] - 2026-02-04

Added Content Editing skill for LLM-targeted content optimization.

### Added

- `skills/content-editing/SKILL.md` - Decision framework for evaluating additions vs corrections
- Auto-invokes when editing SKILL.md, agent markdown, or command markdown files
- Enforces "prefer corrections over additions" principle

## [2.2.0] - 2026-02-04

Added Gemini 3 (Flash/Pro) as target model with specialized Deep Research prompting. Gemini 3 defaults to minimal output and processes long context differently than Claude; this update provides adaptation techniques for both standard prompts and the autonomous Deep Research feature.

### Added

- `references/gemini-3-guide.md` - Adaptation techniques, API config, multimodal/agentic patterns
- `references/gemini-3-deep-research-guide.md` - Deep Research prompting (scope definition, temporal constraints, source preferences, handling unknowns)
- `examples/gemini-3-adaptation.md` - Before/after transformation examples
- `examples/gemini-3-deep-research.md` - Deep Research prompt templates (academic, technical, market, exploratory)
- Target model clarification in Phase 1 (when user mentions Gemini)
- Gemini 3 output format with API configuration and adaptation rationale
- Deep Research output format with execution notes and iteration suggestions
- Deep Research Mode subsection under Gemini 3 Adaptation with detection signals

### Changed

- Skill description and triggers updated for Gemini 3 and Deep Research
- Claude Web project files support all three models

## [2.1.0] - 2026-01-23

Expanded scope to recognize and optimize LLM-targeted content (skills, agents, instructions) alongside traditional prompts. Added explicit workflow branching to prevent mixing contrary instructions.

### Added

- Prompt Recognition section defining traditional prompts vs LLM-targeted content
- Recognition signals for identifying LLM-targeted content (frontmatter, imperative language, etc.)
- Workflow selection with explicit branching based on prompt type
- `references/output-formats.md` with TOC linking to 6 format templates

### Changed

- Phase 1 now marked "(Traditional Prompts Only)" with skip instruction for LLM-targeted content
- Output Format section replaced with summary table referencing `output-formats.md`
- "When to Ask for Clarification" qualified for traditional prompts only
- Skill description updated to include LLM-targeted content optimization

## [2.0.4] - 2026-01-16

Embedded contextual references throughout workflow phases for progressive disclosure instead of consolidating all references at the end.

### Changed

- Phase 2: Design Strategy now links to specific technique sections
- Essential Techniques Reference sections include deep dive references
- Claude 4 Specific Optimizations links to full guide
- Specialized Domains links to relevant prompt patterns
- Simplified Additional Resources section (removed sub-lists)

## [2.0.3] - 2026-01-16

Added table of contents to all reference files and section-specific links in SKILL.md for easier navigation.

### Added

- Table of contents in techniques-detailed.md, claude-4-guide.md, prompt-patterns.md, glm-47-guide.md
- Section-specific references in SKILL.md Additional Resources section

## [2.0.2] - 2026-01-16

Research revealed GLM-4.7's architecture separates hidden reasoning from visible output. Added patterns to force justification surfacing in decision prompts.

### Added

- Reasoning architecture explanation in Decision-Making section intro
- Pattern 11: Decision + Because + Evidence Template
- Pattern 12: Labeled Input for Citation
- Pattern 13: Rule Priority Levels
- Troubleshooting entry "Missing Justifications / Generic Reasoning"

## [2.0.1] - 2026-01-15

Testing revealed standard GLM 4.7 techniques caused over-blocking in decision-making prompts (allow/block evaluations). Added patterns specifically for prompts requiring binary decisions.

### Added

- "Decision-Making Prompts" section with 5 new patterns (Patterns 6-10):
  - Critical Rule Isolation, Explicit Comparison Algorithms, Positive/Negative Rule Pairing, Decision Chain Examples, Critical Rule Repetition
- Troubleshooting entry "Over-Blocking / Misapplied Rules"
- Example 5: TDD Guard decision prompt with failed v1 and successful v2 comparison

## [2.0.0] - 2026-01-15

Added GLM 4.7 (Z.ai) as target model. Claude-optimized prompts produce generic responses on GLM 4.7 due to instruction processing differences; this update provides adaptation techniques.

### Added

- `references/glm-47-guide.md` - Adaptation techniques, API config, troubleshooting
- `examples/glm-47-adaptation.md` - Before/after transformation examples
- Target model clarification in Phase 1 (when user mentions GLM/Z.ai)
- GLM 4.7 output format with API configuration and adaptation rationale

### Changed

- Skill description and triggers updated for GLM 4.7
- Claude Web project files support both models

## [1.2.0] - 2025-12-21

Testing in Claude Web revealed the skill wasn't auto-activating. Root causes: skill description used meta-language instead of action-first pattern, and project system prompt's comprehensive inline content made Claude treat it as self-sufficient guidance, bypassing skill file reading entirely.

### Changed

- Rewrote skill description following Anthropic's official pattern to fix auto-activation
- Reduced project system prompt from 248 to 18 lines, delegating all content to SKILL.md

## [1.1.0] - 2025-12-21

Testing revealed the skill would start executing the described task (e.g., gathering Reddit tooling requirements) instead of generating a reusable prompt artifact. Root cause: Phase 1 used generic software engineering terminology that primed Claude to analyze subject matter rather than scope the prompt.

### Changed

- Renamed "Phase 1: Requirements Analysis" to "Phase 1: Prompt Scoping" to avoid software engineering terminology confusion
- Reframed all clarification questions to explicitly anchor to "the prompt" being created
- Added boundary guidance: "stay at the prompt level, don't dive into subject matter"

### Added

- Explicit meta-level statement in Core Mission: deliverable is always a prompt artifact, never task execution

### Fixed

- Resolved issue where skill would gather requirements for subject matter instead of for the prompt itself

## [1.0.0] - 2024-12-21

### Added

- Core `prompt-engineering` skill with 3-phase workflow (Requirements, Design, Delivery)
- Reference docs: prompting techniques, Claude 4 guide, prompt patterns
- Example templates: system prompts, prompt chains, optimization reports
- Claude Web project files for cross-platform compatibility
- Refinement mode for iterative prompt modifications
