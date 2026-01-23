# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
