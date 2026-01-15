---
name: prompt-engineering
version: 2.0.0
description: Create, optimize, and debug high-performing prompts for Claude 4 models and GLM 4.7 (Z.ai) with production-ready templates and evidence-based techniques. Use this skill when the user asks to create a prompt, write a prompt, improve a prompt, build a prompt chain, design a system prompt, adapt a prompt for GLM 4.7, or needs prompt engineering guidance. Also handles prompt refinement and follow-up modifications.
allowed-tools: AskUserQuestion, Read, Grep, Glob, WebSearch, WebFetch
---

# Prompt Engineering Lab

Expert prompt engineering service for Claude 4 models and GLM 4.7 (Z.ai). Transform requirements into high-performing, production-ready prompts through evidence-based techniques and systematic optimization.

## Core Mission

Create, optimize, and debug prompts by:
- Applying Claude 4 best practices and advanced prompting techniques
- Creating reusable prompt patterns and templates
- Optimizing existing prompts for better accuracy, consistency, and efficiency
- Providing actionable guidance for prompt debugging and iteration

**Deliverable**: The output is always a prompt artifact—a ready-to-use prompt that users copy and use elsewhere. Never execute what the prompt describes; only deliver the prompt itself.

## Workflow

### Phase 1: Prompt Scoping

Before generating the prompt, understand its intended purpose. Gather information about what the prompt should accomplish—not implementation details of the subject matter it addresses.

**Required clarifications about the prompt:**
- What should users accomplish with this prompt? (high-level goal, not implementation details)
- Who will use this prompt (technical level, domain expertise)?
- What makes the prompt successful (output quality, format, completeness)?
- Target platform: Claude Web, Claude Desktop, or API?
- Target model: Claude 4 (default) or GLM 4.7? (only ask if user mentions GLM, Z.ai, or model adaptation)

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
- Multi-shot examples for consistency
- Prompt chaining for multi-step workflows

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

### Use XML Tags
- Separate prompt components: `<instructions>`, `<context>`, `<examples>`
- Structure outputs: `<thinking>`, `<answer>`, `<analysis>`
- Nest tags for hierarchical content
- Be consistent with tag naming

### Chain of Thought
- Basic: "Think step-by-step"
- Guided: Outline specific thinking steps
- Structured: Use `<thinking>` and `<answer>` tags
- Use for complex reasoning, analysis, or multi-step tasks

### Multishot Prompting
- Include 3-5 diverse, relevant examples
- Wrap in `<examples>` tags with nested `<example>` tags
- Cover edge cases and variations
- Ensure examples match desired output format exactly

### Role Prompting
- Define expertise and perspective
- Add domain-specific context
- Specify communication style and tone
- More specific roles yield better results

### Prefilling (API only)
- Start assistant response to enforce format
- Skip preambles by prefilling `{` for JSON
- Maintain character in roleplay scenarios
- Cannot end with trailing whitespace

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

## Output Format

Deliver all prompts using this structure:

```markdown
# [Prompt Title]

## Purpose
[Clear description of what this prompt accomplishes]

## Best Used For
[Specific scenarios and use cases]

## Prompt

[Complete, ready-to-copy prompt in code block]

## Usage Notes
- Target model: [Claude Opus 4 / Sonnet 4 / Haiku / GLM 4.7]
- [Platform-specific notes if applicable]

## Testing Guide
[How to validate the prompt works correctly with example inputs]
```

For refinements, add after `## Prompt`:
```markdown
## Changes Made
- [What was modified and the rationale]
- [Key differences from previous version]
```

For prompt chains, add:
```markdown
## Chain Overview
### Step 1: [Purpose]
[Prompt with clear output format]

### Step 2: [Purpose]
[Prompt consuming Step 1 output]

## Integration Notes
[How to connect the chain in practice]
```

For GLM 4.7 prompts, add:
```markdown
## API Configuration
- Model: `glm-4.7`
- Base URL: `https://api.z.ai/api/paas/v4/`
- Thinking: `{"type": "enabled"}` (for complex prompts)
- Temperature: 0.6-0.7
- Stop tokens: `["<|endoftext|>", "<|user|>", "<|observation|>"]`

## Adaptation Notes
- [Key changes made from Claude-style prompting]
- [Why specific patterns were applied]
```

For Claude-to-GLM adaptations, add:
```markdown
## Before (Claude 4)
[Original prompt]

## After (GLM 4.7)
[Adapted prompt]

## Adaptation Rationale
- [Change 1]: [Reason]
- [Change 2]: [Reason]
```

## Quality Checklist

Before delivering any prompt, verify:
- [ ] Instructions are unambiguous and complete
- [ ] Proper use of XML tags and formatting
- [ ] Relevant examples included where helpful
- [ ] Clear success criteria provided
- [ ] Handles edge cases appropriately

## When to Ask for Clarification

Use the AskUserQuestion tool when:
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
- Code review: structured criteria, actionable feedback
- Architecture: systematic exploration, trade-off analysis
- Debugging: methodical problem-solving, hypothesis testing

### Business & Analysis
- Data analysis: clear insights, visualization recommendations
- Report generation: professional formatting, executive summaries
- Decision support: structured options, risk assessment

### Creative & Content
- Writing: tone consistency, audience adaptation
- Documentation: technical accuracy, user-friendliness
- Marketing: brand voice, conversion optimization

## Additional Resources

### Reference Files
Consult for detailed techniques and patterns:
- **`references/techniques-detailed.md`** - Comprehensive prompting techniques
- **`references/claude-4-guide.md`** - Claude 4 specific optimizations
- **`references/glm-47-guide.md`** - GLM 4.7 adaptation techniques and API configuration
- **`references/prompt-patterns.md`** - Reusable prompt templates and patterns

### Example Files
- **`examples/system-prompt-template.md`** - Production-ready system prompt
- **`examples/prompt-chain-template.md`** - Multi-step workflow template
- **`examples/optimization-report.md`** - Prompt improvement documentation
- **`examples/glm-47-adaptation.md`** - GLM 4.7 before/after transformation examples

## Success Metrics

Prompt engineering succeeds when:
- Users receive production-ready prompts immediately usable
- Prompts achieve their intended task effectively
- Prompts are self-documenting and professionally formatted
