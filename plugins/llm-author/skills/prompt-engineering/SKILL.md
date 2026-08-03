---
name: prompt-engineering
version: 3.6.0
description: Create, optimize, and debug high-performing prompts for Claude 5 and Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3 with production-ready templates and evidence-based techniques. Also optimize LLM-targeted content (skills, agents, instructions, documentation). Use this skill when the user asks to create a prompt, write a prompt, improve a prompt, build a prompt chain, design a system prompt, adapt a prompt for GLM 4.7, adapt a prompt for Gemini, create a Gemini deep research prompt, or needs prompt engineering guidance. Also handles prompt refinement and follow-up modifications.
---

# Prompt Engineering Lab

Expert prompt engineering service for Claude 5 and Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3. Transform requirements into high-performing, production-ready prompts through evidence-based techniques and systematic optimization.

## Core Mission

Create, optimize, and debug prompts by:
- Applying Claude 5 and Claude 4 best practices and advanced prompting techniques
- Creating reusable prompt patterns and templates
- Optimizing existing prompts for better accuracy, consistency, and efficiency
- Providing actionable guidance for prompt debugging and iteration

**Deliverable**: The output is always a prompt artifact—a ready-to-use prompt that users copy and use elsewhere. Never execute what the prompt describes; only deliver the prompt itself.

## Prompt Recognition

A prompt is any content containing information, context, or directives intended for LLM consumption. This includes:

**Traditional prompts:**
- System prompts, user prompts, prompt templates
- Few-shot examples, prompt chains

**LLM-targeted content:**
- Skills, agents, commands (Claude Code, Cursor, etc.)
- Project instructions and rules files
- Documentation consumed by LLMs during tasks
- Any file with imperative instructions for an LLM

**Recognition signals:**
- Frontmatter with fields like `description`, `tools`, `allowed-tools`
- Imperative language: "You must", "Always", "Never"
- Workflow steps, constraints, decision trees
- References to LLM tools or capabilities
- Content structured to guide LLM behavior

**Optimization principle for LLM-targeted content:**

These documents are created with clear scope and intention—often by an LLM—and contain everything required for their purpose. Optimization improves clarity, structure, and effectiveness WITHOUT removing information, context, or directives.

Apply reasoning to understand:
- What information is essential to the document's purpose
- Which directives shape LLM behavior
- What context enables correct interpretation

Then optimize for clarity and impact while preserving all substantive content. Personas and "You are …" identity openers are not substantive content.

Because Claude 5 is the default target, apply "less is more" by default: Claude 5 exercises judgment, so cutting over-constraint (absolute rules, repetition, worked examples that narrow exploration) improves output. This relaxes the preserve-everything default above — keep substantive directives, but drop scaffolding that compensated for weaker instruction-following. For Claude 4 or earlier targets, keep the preserve-everything default. See `references/claude-5-guide.md#optimizing-llm-targeted-content-for-claude-5`.

## Workflow

```dot
digraph prompt_engineering {
    "Prompt request" [shape=doublecircle];
    "Refining a prompt already generated this conversation?" [shape=diamond];
    "Refinement mode: ask what changes, deliver the full refined prompt" [shape=box];
    "Traditional prompt or LLM-targeted content?" [shape=diamond];
    "Phase 1: scope the prompt (purpose, audience, success criteria, platform, target model)" [shape=box];
    "Phase 2: design strategy (techniques by complexity + target-model adaptation)" [shape=box];
    "Target model?" [shape=diamond];
    "Claude 5 default -> claude-5-guide" [shape=box];
    "Claude 4 -> claude-4-guide" [shape=box];
    "GLM 4.7 -> glm-47-guide" [shape=box];
    "Gemini 3 -> gemini-3-guide (Deep Research -> gemini-3-deep-research-guide)" [shape=box];
    "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)" [shape=doublecircle];

    "Prompt request" -> "Refining a prompt already generated this conversation?";
    "Refining a prompt already generated this conversation?" -> "Refinement mode: ask what changes, deliver the full refined prompt" [label="yes"];
    "Refinement mode: ask what changes, deliver the full refined prompt" -> "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)";
    "Refining a prompt already generated this conversation?" -> "Traditional prompt or LLM-targeted content?" [label="no"];
    "Traditional prompt or LLM-targeted content?" -> "Phase 1: scope the prompt (purpose, audience, success criteria, platform, target model)" [label="traditional"];
    "Traditional prompt or LLM-targeted content?" -> "Phase 2: design strategy (techniques by complexity + target-model adaptation)" [label="LLM-targeted (skip Phase 1)"];
    "Phase 1: scope the prompt (purpose, audience, success criteria, platform, target model)" -> "Phase 2: design strategy (techniques by complexity + target-model adaptation)";
    "Phase 2: design strategy (techniques by complexity + target-model adaptation)" -> "Target model?";
    "Target model?" -> "Claude 5 default -> claude-5-guide";
    "Target model?" -> "Claude 4 -> claude-4-guide";
    "Target model?" -> "GLM 4.7 -> glm-47-guide";
    "Target model?" -> "Gemini 3 -> gemini-3-guide (Deep Research -> gemini-3-deep-research-guide)";
    "Claude 5 default -> claude-5-guide" -> "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)";
    "Claude 4 -> claude-4-guide" -> "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)";
    "GLM 4.7 -> glm-47-guide" -> "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)";
    "Gemini 3 -> gemini-3-guide (Deep Research -> gemini-3-deep-research-guide)" -> "Phase 3: deliver ready-to-copy prompt artifact (format by type and platform)";
}
```

LLM-targeted content skips Phase 1 and enters at Phase 2 with the streamlined output format. Refinement mode is a shortcut for a prompt already produced this conversation. Each node is elaborated below.

### Phase 1: Prompt Scoping (Traditional Prompts Only)

Before generating the prompt, understand its intended purpose. Gather information about what the prompt should accomplish—not implementation details of the subject matter it addresses.

**Required clarifications about the prompt:**
- What should users accomplish with this prompt? (high-level goal, not implementation details)
- Who will use this prompt (technical level, domain expertise)?
- What makes the prompt successful (output quality, format, completeness)?
- Target platform: Claude Web, Claude Desktop, or API?
- Target model: Claude 5 (default), Claude 4, GLM 4.7, or Gemini 3? (only ask if user mentions Claude 4, GLM, Z.ai, Gemini, or model adaptation)

**Clarify prompt ambiguities (stay at the prompt level, don't dive into subject matter):**
- If variations might be beneficial, ask if user wants alternative prompt approaches
- If the prompt's scope is unclear, confirm what it should and shouldn't address
- If success criteria are vague, propose concrete metrics for the prompt's output

### Refinement Mode

When the user is modifying a prompt that was previously generated in this conversation:

**Detection signals:**
- References to "the prompt", "that prompt", "the previous prompt"
- Modification requests: "make it more...", "adjust...", "change the...", "add..."
- Feedback on results: "it didn't work because...", "the output was too..."

**Streamlined workflow:**
- Skip full requirements gathering - the context is already established
- Ask a targeted question: "What specifically should change?"
- Focus on the delta, not full re-specification
- Preserve unchanged aspects of the original prompt
- Deliver the complete refined prompt (not just the changes)

### Phase 2: Design Strategy

Select appropriate techniques based on task complexity:

**For simple tasks:**
- Clear, direct instructions
- Explicit output format specification
- Relevant examples if format is critical

**For complex tasks:**
- Chain of thought prompting with XML structure
  → See `references/techniques/chain-of-thought.md`
- Multi-shot examples for consistency
  → See `references/techniques/multishot-prompting.md`
- Prompt chaining for multi-step workflows
  → Technique: `references/techniques/prompt-chaining.md`; ready template: `examples/prompt-chain-template.md`

**For optimization:**
- Analyze current prompt structure and gaps
- Identify specific failure modes
- Remove personas and "You are …" identity openers: state the task directly and convert whatever they implied (tone, depth, audience) into explicit requirements — keep a persona only where it is the requested output (character roleplay)
- Apply targeted improvements with documented rationale; document the before/after with `examples/optimization-report.md`

### Phase 3: Prompt Delivery

Deliver prompts as ready-to-copy markdown blocks optimized for the target platform. Choose the structure from the [Output Format](#output-format) table below (details in `references/output-formats.md`); for a system prompt, adapt `examples/system-prompt-template.md`.

**Default (Claude Web / Claude Desktop):**
- Complete prompt in a single code block
- No API parameters unless requested
- Include usage instructions and testing suggestions

**API format (only when explicitly requested):**
- Include max_tokens and effort recommendations; temperature only for Claude 4 / earlier (Claude 5 rejects non-default temperature)
- Separate system and user message components
- Provide JSON structure if needed

## Essential Techniques Reference

### Be Clear and Direct
- Provide contextual information (purpose, audience, workflow)
- Use numbered steps for sequential instructions
- Specify exact output format requirements
- Tell Claude what TO do, not what NOT to do
→ Deep dive: `references/techniques/be-clear-and-direct.md`

### Use XML Tags
- Separate prompt components: `<instructions>`, `<context>`, `<examples>`
- Structure outputs: `<thinking>`, `<answer>`, `<analysis>`
- Nest tags for hierarchical content
- Be consistent with tag naming
→ Deep dive: `references/techniques/xml-tags.md`

### Chain of Thought
- Basic: "Think step-by-step"
- Guided: Outline specific thinking steps
- Structured: Use `<thinking>` and `<answer>` tags
- Use for complex reasoning, analysis, or multi-step tasks
- Claude 5: thinking is adaptive and on by default; the `<thinking>`/`<answer>` scaffolding and manual `budget_tokens` are Claude 4 / earlier patterns (see `references/claude-5-guide.md#adaptive-thinking`)
→ Deep dive: `references/techniques/chain-of-thought.md`

### Multishot Prompting
- Include 3-5 diverse, relevant examples
- Wrap in `<examples>` tags with nested `<example>` tags
- Cover edge cases and variations
- Ensure examples match desired output format exactly
→ Deep dive: `references/techniques/multishot-prompting.md`

### Roles (Do Not Use)
- Do not write roles or personas into prompts
- "You are …" identity openers add nothing — state the task and constraints directly
- State tone, format, length, and audience as explicit output requirements instead
- For domain accuracy, provide domain context and reference material
- Sole exception: character roleplay, where the persona is the requested output
→ Deep dive: `references/techniques/system-prompts-and-roles.md`

### Prefilling (API only — Claude 4 and earlier)
- Start assistant response to enforce format
- Skip preambles by prefilling `{` for JSON
- Maintain character in roleplay scenarios
- Cannot end with trailing whitespace
- Claude 5: prefill returns a 400 error — use Structured Outputs or a direct "respond without preamble" instruction instead
→ Deep dive: `references/techniques/prefilling.md`

## Model-Generation Optimizations

Claude 5 (Opus 5, Sonnet 5, Fable 5) is the default target. Claude 4 (Opus 4.x, Sonnet 4.x) and Haiku 4.5 prompts often over-steer Claude 5 — re-tune when migrating.

### Claude 5 (default)

Claude 5 exercises more judgment and needs less scaffolding. Steer with the `effort` parameter and targeted, positive instructions.

**Control length on Opus 5** — Opus 5 runs longer by default and effort doesn't reliably change visible length, so prompt for concision (Sonnet 5 is already concise; Fable 5 can over-elaborate at high effort):
```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

**Remove carried-over verification** — Claude 5 self-verifies and self-corrects, so "double-check your answer", "add a verification step", and "use a subagent to verify" cause over-verification. Delete them.

**Guide subagent delegation** — Claude 5 delegates readily; give explicit criteria. Cap spawn counts for cost-sensitive Opus 5 work; Fable 5 is built to delegate freely (see the guide):
```
Delegate to a subagent only for large, genuinely independent, parallelizable tasks.
Keep spawn counts low.
```

**Soften aggressive language** — `CRITICAL: You MUST...` over-triggers; use "Use ... when ...".

**Breaking changes** — assistant prefill, `budget_tokens`, and non-default `temperature`/`top_p`/`top_k` return a 400 error. Use adaptive thinking with `effort`, and Structured Outputs instead of prefill.

→ Full guide, per-model specifics (Opus 5 / Sonnet 5 / Fable 5), and Claude 4 → 5 migration: `references/claude-5-guide.md`

### Claude 4 and earlier

Claude 4 needs "above and beyond" behavior requested explicitly:
- Request thoroughness ("Include as many relevant features and interactions as possible. Go beyond the basics.").
- Explain *why* an instruction matters — Claude 4 generalizes from the reason.
- Add anti-reward-hacking wording for coding ("high-quality, general-purpose solution; don't hard-code test cases; say so if the task is unreasonable").
- Prompt reflection on tool results before the next step.

→ Full guide: `references/claude-4-guide.md`

## GLM 4.7 Adaptation (When Requested)

When the user explicitly targets GLM 4.7: it treats polite, buried instructions as optional, so make directives firm and front-loaded.

- Front-load all mandatory rules in the first 200 words.
- Convert soft language to hard directives (MUST / ALWAYS / NEVER).
- Add explicit output templates and a FORBIDDEN-patterns block to block generic responses.
- Add a self-verification block; force language with `ALWAYS respond in English`.
- API: enable thinking, temperature 0.6–0.7, and GLM stop tokens.

→ Full adaptations, patterns, and API config: `references/glm-47-guide.md`; transformation examples: `examples/glm-47-adaptation.md`

## Gemini 3 Adaptation (When Requested)

When the user explicitly targets Gemini 3: it defaults to minimal output and handles long context differently than Claude.

**Deep Research mode** — if the user mentions "deep research", citation-backed literature reviews, or extended autonomous web research, use `references/gemini-3-deep-research-guide.md` and `examples/gemini-3-deep-research.md` (autonomous 5–60 min runs, plan review, ~10% citation-error, explicit scope/temporal/source constraints). Otherwise apply standard adaptations:

- Keep temperature at 1.0 — changing it causes looping or degraded output.
- Place instructions after long context; put constraints at the prompt end.
- Request verbosity explicitly and always include 2–3 few-shot examples.
- Control format with response-prefix strings; add a self-verification block.
- Flash (routine, high-volume) vs Pro (complex) — identical prompting.

→ Full adaptations, model selection, and API config: `references/gemini-3-guide.md`; transformation examples: `examples/gemini-3-adaptation.md`

## Output Format

Select the appropriate format based on prompt type:

| Type | Format | Reference |
|------|--------|-----------|
| Traditional prompts | Full wrapper (Purpose, Best Used For, etc.) | `references/output-formats.md#1-traditional-prompts` |
| LLM-targeted content | Optimized content only, no wrapper | `references/output-formats.md#2-llm-targeted-content` |
| Refinements | Add "Changes Made" section | `references/output-formats.md#3-refinements` |
| Prompt chains | Chain Overview with steps | `references/output-formats.md#4-prompt-chains` |
| GLM 4.7 prompts | Add API Configuration | `references/output-formats.md#5-glm-47-prompts` |
| Claude-to-GLM adaptations | Before/After comparison | `references/output-formats.md#6-claude-to-glm-adaptations` |
| Gemini 3 prompts | Add API Configuration | `references/output-formats.md#7-gemini-3-prompts` |
| Claude-to-Gemini adaptations | Before/After comparison | `references/output-formats.md#8-claude-to-gemini-adaptations` |
| Gemini Deep Research prompts | Add Deep Research Notes + Iteration Suggestions | `references/output-formats.md#9-gemini-deep-research-prompts` |

## Quality Checklist

Before delivering any prompt, verify:
- [ ] Instructions are unambiguous and complete
- [ ] Proper use of XML tags and formatting
- [ ] Relevant examples included where helpful
- [ ] Clear success criteria provided
- [ ] Handles edge cases appropriately
- [ ] No personas and no "You are …" identity openers — task, tone, depth, and audience stated as explicit requirements (exception: character roleplay)

## When to Ask for Clarification

For **traditional prompts**, ask the user for clarification when:
- Use case is ambiguous or too broad
- Multiple valid approaches exist
- Output format preferences are unclear
- User might benefit from prompt variations
- Success criteria need definition
- Target platform is not specified

Example clarification:
```
Before I create this prompt, I have a few questions:
- Should this prompt handle [specific edge case]?
- Do you want the output in [format A] or [format B]?
- Would you like me to provide alternative variations?
```

## Specialized Domains

### Software Development
- Code generation: completeness, error handling, best practices
  → See `references/prompt-patterns/code-generation.md`
- Code review: structured criteria, actionable feedback
  → See `references/prompt-patterns/code-review.md`
- Architecture: systematic exploration, trade-off analysis
  → See `references/prompt-patterns/comparative-analysis.md`
- Debugging: methodical problem-solving, hypothesis testing
  → See `references/prompt-patterns/root-cause-analysis.md`

### Business & Analysis
- Data analysis: clear insights, visualization recommendations
  → See `references/prompt-patterns/structured-analysis.md`
- Report generation: professional formatting, executive summaries
  → See `references/prompt-patterns/chain-patterns.md`
- Decision support: structured options, risk assessment
  → See `references/prompt-patterns/comparative-analysis.md`

### Creative & Content
- Writing: tone consistency, audience adaptation
  → See `references/prompt-patterns/structured-content-generation.md`
- Documentation: technical accuracy, user-friendliness
  → See `references/prompt-patterns/documentation-generation.md`
- Marketing: brand voice, conversion optimization
  → See `references/prompt-patterns/text-rewriting.md`

## Success Metrics

Prompt engineering succeeds when:
- Users receive production-ready prompts immediately usable
- Prompts achieve their intended task effectively
- Prompts are self-documenting and professionally formatted
