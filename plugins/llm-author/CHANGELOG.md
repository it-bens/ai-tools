# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
