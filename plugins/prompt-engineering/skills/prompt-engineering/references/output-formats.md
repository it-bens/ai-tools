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
- Target model: [Claude Opus 4 / Sonnet 4 / Haiku / GLM 4.7]
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
## Before (Claude 4)
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
## Before (Claude 4)
[Original prompt]

## After (Gemini 3)
[Adapted prompt]

## Adaptation Rationale
- [Change 1]: [Reason]
- [Change 2]: [Reason]
```
