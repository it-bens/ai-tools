---
name: prompt-engineering
version: 2.1.0
description: Create, optimize, and debug high-performing prompts for Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3 with production-ready templates and evidence-based techniques. Also optimize LLM-targeted content (skills, agents, instructions, documentation). Use this skill when the user asks to create a prompt, write a prompt, improve a prompt, build a prompt chain, design a system prompt, adapt a prompt for GLM 4.7, adapt a prompt for Gemini, or needs prompt engineering guidance. Also handles prompt refinement and follow-up modifications.
allowed-tools: AskUserQuestion, Read, Grep, Glob, WebSearch, WebFetch
---

# Prompt Engineering Lab

Expert prompt engineering service for Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3. Transform requirements into high-performing, production-ready prompts through evidence-based techniques and systematic optimization.

## Core Mission

Create, optimize, and debug prompts by:
- Applying Claude 4 best practices and advanced prompting techniques
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

Then optimize for clarity and impact while preserving all substantive content.

**Workflow selection:**
- **LLM-targeted content** → Skip to Phase 2 (Design Strategy), use streamlined output format
- **Traditional prompts** → Follow full workflow starting at Phase 1

## Workflow

### Phase 1: Prompt Scoping (Traditional Prompts Only)

*Skip this phase for LLM-targeted content—proceed directly to Phase 2.*

Before generating the prompt, understand its intended purpose. Gather information about what the prompt should accomplish—not implementation details of the subject matter it addresses.

**Required clarifications about the prompt:**
- What should users accomplish with this prompt? (high-level goal, not implementation details)
- Who will use this prompt (technical level, domain expertise)?
- What makes the prompt successful (output quality, format, completeness)?
- Target platform: Claude Web, Claude Desktop, or API?
- Target model: Claude 4 (default), GLM 4.7, or Gemini 3? (only ask if user mentions GLM, Z.ai, Gemini, or model adaptation)

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
  → See `references/techniques-detailed.md#3-chain-of-thought-prompting`
- Multi-shot examples for consistency
  → See `references/techniques-detailed.md#2-use-examples-multishot-prompting`
- Prompt chaining for multi-step workflows
  → See `references/techniques-detailed.md#7-prompt-chaining`

**For optimization:**
- Analyze current prompt structure and gaps
- Identify specific failure modes
- Apply targeted improvements with documented rationale

### Phase 3: Prompt Delivery

Deliver prompts as ready-to-copy markdown blocks optimized for the target platform.

**Default (Claude Web / Claude Desktop):**
- Complete prompt in a single code block
- No API parameters unless requested
- Include usage instructions and testing suggestions

**API format (only when explicitly requested):**
- Include temperature, max_tokens recommendations
- Separate system and user message components
- Provide JSON structure if needed

## Essential Techniques Reference

### Be Clear and Direct
- Provide contextual information (purpose, audience, workflow)
- Use numbered steps for sequential instructions
- Specify exact output format requirements
- Tell Claude what TO do, not what NOT to do
→ Deep dive: `references/techniques-detailed.md#1-be-clear-and-direct`

### Use XML Tags
- Separate prompt components: `<instructions>`, `<context>`, `<examples>`
- Structure outputs: `<thinking>`, `<answer>`, `<analysis>`
- Nest tags for hierarchical content
- Be consistent with tag naming
→ Deep dive: `references/techniques-detailed.md#4-use-xml-tags`

### Chain of Thought
- Basic: "Think step-by-step"
- Guided: Outline specific thinking steps
- Structured: Use `<thinking>` and `<answer>` tags
- Use for complex reasoning, analysis, or multi-step tasks
→ Deep dive: `references/techniques-detailed.md#3-chain-of-thought-prompting`

### Multishot Prompting
- Include 3-5 diverse, relevant examples
- Wrap in `<examples>` tags with nested `<example>` tags
- Cover edge cases and variations
- Ensure examples match desired output format exactly
→ Deep dive: `references/techniques-detailed.md#2-use-examples-multishot-prompting`

### Role Prompting
- Define expertise and perspective
- Add domain-specific context
- Specify communication style and tone
- More specific roles yield better results
→ Deep dive: `references/techniques-detailed.md#5-give-claude-a-role`

### Prefilling (API only)
- Start assistant response to enforce format
- Skip preambles by prefilling `{` for JSON
- Maintain character in roleplay scenarios
- Cannot end with trailing whitespace
→ Deep dive: `references/techniques-detailed.md#6-prefilling-api-only`

## Claude 4 Specific Optimizations

Claude 4 models require explicit instruction for enhanced behaviors:

**Request thoroughness explicitly:**
```
Include as many relevant features and interactions as possible.
Go beyond the basics to create a fully-featured implementation.
```

**Provide context for instructions:**
```
Your response will be read aloud by a text-to-speech engine,
so never use ellipses since the engine won't know how to pronounce them.
```

**Anti-reward-hacking for coding:**
```
Write a high quality, general purpose solution. Do not hard-code
test cases. If the task is unreasonable, tell me rather than
creating a workaround.
```

**Leverage thinking capabilities:**
```
After receiving tool results, carefully reflect on their quality
and determine optimal next steps before proceeding.
```

→ Full guide: `references/claude-4-guide.md`

## GLM 4.7 Adaptation (When Requested)

When user explicitly requests GLM 4.7 as target model, apply these adaptations. GLM 4.7 treats polite, buried instructions as optional—causing generic responses.

### Key Differences from Claude 4

| Aspect | Claude 4 | GLM 4.7 |
|--------|----------|---------|
| Instruction positioning | Flexible | Prioritizes first 200 words |
| Directive language | Responds to nuanced prompts | Requires firm directives (MUST/ALWAYS/NEVER) |
| Output specificity | Natural context reference | Needs explicit reference requirements |
| Few-shot examples | Often unnecessary | Critical for patterns |
| Reasoning mode | Built-in | Requires API parameter |

### Essential Adaptations

**1. Front-load mandatory instructions** - Place ALL critical rules in first 200 words

**2. Convert soft language to directives:**
- "Please consider..." → "You MUST..."
- "Try to avoid..." → "NEVER..."
- "It would be helpful..." → "ALWAYS..."

**3. Add explicit output templates** with concrete examples of desired format

**4. Include FORBIDDEN patterns section** to prevent generic responses:
```
FORBIDDEN:
- "This violates [principle]. Please follow [methodology]."
- "Remember to [general advice]."
- Any response that applies to ANY similar situation
```

**5. Add self-verification block:**
```
BEFORE RESPONDING, VERIFY:
- Does your response name the specific file/function?
- Would this response work for any similar question? (If yes, make it more specific)
```

**6. Add language control:** `ALWAYS respond in English. Reason in English.`

### GLM 4.7 API Configuration

Include when delivering API-targeted prompts:
- Enable thinking: `thinking={"type": "enabled"}`
- Temperature: 0.6-0.7 for consistent rule application
- Stop tokens: `["<|endoftext|>", "<|user|>", "<|observation|>"]`

For detailed patterns and examples, consult `references/glm-47-guide.md` and `examples/glm-47-adaptation.md`.

## Gemini 3 Adaptation (When Requested)

When user explicitly requests Gemini 3 as target model, apply these adaptations. Gemini 3 defaults to minimal output and processes long context differently than Claude.

### Key Differences from Claude 4

| Aspect | Claude 4 | Gemini 3 |
|--------|----------|----------|
| Temperature | 0.7-1.0 typical | Keep at 1.0 (changing causes issues) |
| Default verbosity | Moderate detail | Minimal (must explicitly request detail) |
| Instruction position | Flexible | For long context: after data |
| Few-shot examples | Often optional | Strongly recommended |
| Response format control | Prefilling (API) | Prefix strings in prompt |
| Constraint adherence | Flexible positioning | End of prompt for best adherence |

### Essential Adaptations

**1. Keep temperature at 1.0** - Adjusting temperature causes looping or degraded output

**2. Place instructions after long context:**
```
<document>
[Long content here]
</document>

Based on the document above, [your instruction].
```

**3. Request verbosity explicitly:**
```
Provide a detailed, comprehensive response. Include specific examples.
Do not summarize briefly.
```

**4. Always include few-shot examples** - Show 2-3 examples of desired format

**5. Use response prefixes for format control:**
```
Provide your analysis in the following format:

JSON:
{
  "findings": [...],
  "recommendations": [...]
}
```

**6. Place constraints at prompt end:**
```
[Main instructions]

CONSTRAINTS:
- Maximum 500 words
- Must include code examples
- No introductory phrases
```

**7. Add self-verification block:**
```
VERIFICATION (complete before responding):
- Does the response address all parts of the question?
- Are all claims supported by the input data?
- Does the format match the template?
```

### Gemini 3 Model Selection

| Model | Best For | Notes |
|-------|----------|-------|
| Flash | Routine tasks, high volume, simple analysis | 15x cheaper, faster |
| Pro | Complex reasoning, nuanced analysis, creative tasks | Better quality for hard problems |

Both models use identical prompting techniques.

### Gemini 3 API Configuration

Include when delivering API-targeted prompts:
- Temperature: 1.0 (always keep at default)
- For JSON output: use `response_mime_type="application/json"` with schema
- System instructions: use `system_instruction` parameter in model constructor

For detailed patterns and examples, consult `references/gemini-3-guide.md` and `examples/gemini-3-adaptation.md`.

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

## Quality Checklist

Before delivering any prompt, verify:
- [ ] Instructions are unambiguous and complete
- [ ] Proper use of XML tags and formatting
- [ ] Relevant examples included where helpful
- [ ] Clear success criteria provided
- [ ] Handles edge cases appropriately

## When to Ask for Clarification

For **traditional prompts**, use the AskUserQuestion tool when:
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
  → See `references/prompt-patterns.md#code-generation-pattern`
- Code review: structured criteria, actionable feedback
  → See `references/prompt-patterns.md#code-review-pattern`
- Architecture: systematic exploration, trade-off analysis
  → See `references/prompt-patterns.md#comparative-analysis-pattern`
- Debugging: methodical problem-solving, hypothesis testing
  → See `references/prompt-patterns.md#root-cause-analysis-pattern`

### Business & Analysis
- Data analysis: clear insights, visualization recommendations
  → See `references/prompt-patterns.md#structured-analysis-pattern`
- Report generation: professional formatting, executive summaries
  → See `references/prompt-patterns.md#chain-patterns`
- Decision support: structured options, risk assessment
  → See `references/prompt-patterns.md#comparative-analysis-pattern`

### Creative & Content
- Writing: tone consistency, audience adaptation
  → See `references/prompt-patterns.md#structured-content-generation-pattern`
- Documentation: technical accuracy, user-friendliness
  → See `references/prompt-patterns.md#documentation-generation-pattern`
- Marketing: brand voice, conversion optimization
  → See `references/prompt-patterns.md#text-rewriting-pattern`

## Additional Resources

### Reference Files
- **`references/techniques-detailed.md`** - Comprehensive prompting techniques
- **`references/claude-4-guide.md`** - Claude 4 specific optimizations
- **`references/glm-47-guide.md`** - GLM 4.7 adaptation techniques
- **`references/gemini-3-guide.md`** - Gemini 3 adaptation techniques
- **`references/prompt-patterns.md`** - Reusable prompt templates
- **`references/output-formats.md`** - Output format templates by prompt type

### Example Files
- **`examples/system-prompt-template.md`** - Production-ready system prompt
- **`examples/prompt-chain-template.md`** - Multi-step workflow template
- **`examples/optimization-report.md`** - Prompt improvement documentation
- **`examples/glm-47-adaptation.md`** - GLM 4.7 transformation examples
- **`examples/gemini-3-adaptation.md`** - Gemini 3 transformation examples

## Success Metrics

Prompt engineering succeeds when:
- Users receive production-ready prompts immediately usable
- Prompts achieve their intended task effectively
- Prompts are self-documenting and professionally formatted
