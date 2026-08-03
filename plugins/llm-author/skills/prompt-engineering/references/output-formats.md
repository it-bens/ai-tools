# Output Formats

Templates for delivering prompts based on type and target.

## Contents

1. [Traditional Prompts](#1-traditional-prompts)
2. [LLM-Targeted Content](#2-llm-targeted-content)
3. [Refinements](#3-refinements)
4. [Prompt Chains](#4-prompt-chains)
5. [GLM 4.7 Prompts](#5-glm-47-prompts)
6. [Claude-to-GLM Adaptations](#6-claude-to-glm-adaptations)
7. [Gemini 3 Prompts](#7-gemini-3-prompts)
8. [Claude-to-Gemini Adaptations](#8-claude-to-gemini-adaptations)
9. [Gemini Deep Research Prompts](#9-gemini-deep-research-prompts)
10. [Claude 4 to Claude 5 Migrations](#10-claude-4-to-claude-5-migrations)

---

## 1. Traditional Prompts

Full wrapper format for user-facing prompts:

```markdown
# [Prompt Title]

## Purpose
[Clear description of what this prompt accomplishes]

## Best Used For
[Specific scenarios and use cases]

## Prompt

[Complete, ready-to-copy prompt in code block]

## Usage Notes
- Target model: [Claude 5 (Opus 5 / Sonnet 5 / Fable 5) / Claude 4 / GLM 4.7 / Gemini 3]
- [Platform-specific notes if applicable]

## Testing Guide
[How to validate the prompt works correctly with example inputs]
```

---

## 2. LLM-Targeted Content

Streamlined format for skills, agents, and instructions:

- Output only the optimized content in a code block
- Preserve the original document structure (frontmatter, sections, etc.)
- No wrapper sections (Purpose, Best Used For, Usage Notes, Testing Guide)

---

## 3. Refinements

When refining a previously generated prompt, add after `## Prompt`:

```markdown
## Changes Made
- [What was modified and the rationale]
- [Key differences from previous version]
```

---

## 4. Prompt Chains

For multi-step workflows:

```markdown
## Chain Overview
### Step 1: [Purpose]
[Prompt with clear output format]

### Step 2: [Purpose]
[Prompt consuming Step 1 output]

## Integration Notes
[How to connect the chain in practice]
```

---

## 5. GLM 4.7 Prompts

For prompts targeting GLM 4.7, add:

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

---

## 6. Claude-to-GLM Adaptations

For converting existing Claude prompts to GLM 4.7:

```markdown
## Before (Claude)
[Original prompt]

## After (GLM 4.7)
[Adapted prompt]

## Adaptation Rationale
- [Change 1]: [Reason]
- [Change 2]: [Reason]
```

---

## 7. Gemini 3 Prompts

For prompts targeting Gemini 3, add:

```markdown
## API Configuration
- Model: `gemini-2.0-flash` or `gemini-2.0-pro`
- Temperature: 1.0 (always keep at default)
- For JSON: `response_mime_type="application/json"` with schema

## Adaptation Notes
- [Key changes made from Claude-style prompting]
- [Why specific patterns were applied]
```

---

## 8. Claude-to-Gemini Adaptations

For converting existing Claude prompts to Gemini 3:

```markdown
## Before (Claude)
[Original prompt]

## After (Gemini 3)
[Adapted prompt]

## Adaptation Rationale
- [Change 1]: [Reason]
- [Change 2]: [Reason]
```

---

## 9. Gemini Deep Research Prompts

For prompts targeting Gemini's Deep Research feature (autonomous multi-step research):

```markdown
# [Research Prompt Title]

## Purpose
[What research question this prompt addresses]

## Best Used For
[Research types: literature review, market analysis, technical comparison, etc.]

## Prompt

[Complete deep research prompt with:
- Clear research objective
- Explicit scope definition
- Temporal constraints
- Source preferences
- Output format specification
- Handling instructions for unknowns]

## Deep Research Notes
- Execution time: 5-20 minutes typical (up to 60 for complex topics)
- Review the research plan before execution and adjust scope as needed
- Verify citations—approximately 10% may contain errors
- Follow up to drill into specific sections after initial report

## Iteration Suggestions
- [Potential follow-up question to expand findings]
- [Potential follow-up to drill into specific section]
- [Potential follow-up to verify specific claims]
```

**Key additions vs. standard Gemini prompts:**
- Deep Research Notes section (execution expectations, verification reminders)
- Iteration Suggestions section (prepared follow-up questions)
- Prompt must include scope, temporal, source, and handling instructions

---

## 10. Claude 4 to Claude 5 Migrations

For re-tuning an existing Claude 4 prompt or LLM-targeted content for Claude 5:

```markdown
## Before (Claude 4)
[Original content]

## After (Claude 5)
[Re-tuned content]

## Migration Rationale
- [Change 1]: [Reason — which Claude 5 behavior it addresses]
- [Change 2]: [Reason]
```

For LLM-targeted content (skills, agents, rules files), preserve the original document structure in the "After" block and report only the re-tuning changes in the rationale. Diagnose and remove carried-over Claude 4 scaffolding rather than rewriting from scratch.
