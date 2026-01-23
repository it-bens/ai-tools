# Gemini 3 Prompt Adaptation Guide

Techniques for adapting Claude 4 prompts to achieve quality parity on Gemini 3 models.

## Table of Contents

- [Core Differences: Claude 4 vs Gemini 3](#core-differences-claude-4-vs-gemini-3)
- [Adaptation Techniques](#adaptation-techniques)
- [Model Selection: Flash vs Pro](#model-selection-flash-vs-pro)
- [Multimodal Input Handling](#multimodal-input-handling)
- [Agentic Workflow Configuration](#agentic-workflow-configuration)
- [API Configuration](#api-configuration)
- [Reusable Patterns](#reusable-patterns)
- [Troubleshooting](#troubleshooting)
- [Adaptation Quick Checklist](#adaptation-quick-checklist)

## Core Differences: Claude 4 vs Gemini 3

| Aspect | Claude 4 | Gemini 3 | Adaptation Required |
|--------|----------|----------|---------------------|
| **Temperature** | 0.7-1.0 typical | Keep at 1.0 (changing causes issues) | Never lower temperature |
| **Default verbosity** | Moderate detail | Minimal output | Explicitly request detail |
| **Instruction position** | Flexible | For long context: after data | Move instructions post-context |
| **Few-shot examples** | Often optional | Strongly recommended | Always include examples |
| **Response format control** | Prefilling (API) | Prefix strings in prompt | Use response prefixes |
| **Constraint adherence** | Flexible positioning | End of prompt for best adherence | Move constraints to end |
| **XML tags** | Supported | Supported (use consistently) | Keep consistent naming |
| **Self-verification** | Useful but optional | Critical for reliability | Add verification blocks |

## Adaptation Techniques

### 1. Keep Temperature at 1.0

Gemini 3 behaves unpredictably with adjusted temperature. Lower values can cause looping or degraded output quality.

**Claude-style (fails on Gemini 3):**
```python
temperature=0.3  # For consistent, focused output
```

**Gemini 3-optimized:**
```python
temperature=1.0  # Always keep at default
# Use prompt structure, not temperature, for consistency
```

### 2. Place Instructions After Long Context

For documents over ~2000 tokens, Gemini 3 prioritizes content near the end. Place instructions after data.

**Claude-style (suboptimal on Gemini 3):**
```
Analyze this document for security vulnerabilities.
Focus on SQL injection and XSS patterns.

<document>
[10,000 lines of code]
</document>
```

**Gemini 3-optimized:**
```
<document>
[10,000 lines of code]
</document>

Based on the code above, analyze for security vulnerabilities.
Focus on SQL injection and XSS patterns.
```

### 3. Use Context Bridging Phrases

Connect post-context instructions to the data explicitly:

```
Based on the information above...
Using the document provided...
From the code listing above...
Referring to the previous content...
```

### 4. Request Verbosity Explicitly

Gemini 3 defaults to minimal responses. Request detail when needed:

**Claude-style (produces terse output on Gemini 3):**
```
Explain how the authentication system works.
```

**Gemini 3-optimized:**
```
Explain how the authentication system works in detail.
Include specific code examples, edge cases, and potential failure modes.
Provide a comprehensive explanation rather than a summary.
```

### 5. Always Include Few-Shot Examples

Gemini documentation states: "Always include few-shot examples in your prompts."

**Claude-style (often sufficient):**
```
Classify the sentiment of this review as positive, negative, or neutral.
```

**Gemini 3-optimized:**
```
Classify the sentiment of reviews as positive, negative, or neutral.

Examples:
Review: "This product exceeded my expectations!"
Sentiment: positive

Review: "Terrible quality, broke after one week."
Sentiment: negative

Review: "It works as expected, nothing special."
Sentiment: neutral

Now classify:
Review: "{{user_review}}"
Sentiment:
```

### 6. Use Response Prefixes for Format Control

Instead of API prefilling, add prefix strings that signal expected format:

```
Provide your analysis in the following format:

JSON:
{
  "findings": [...],
  "severity": "...",
  "recommendations": [...]
}
```

### 7. Place Constraints at Prompt End

Constraints placed at the end have stronger adherence:

**Claude-style (flexible placement):**
```
IMPORTANT: Keep response under 100 words.

Summarize this article about climate change impacts.
```

**Gemini 3-optimized:**
```
Summarize this article about climate change impacts.

CONSTRAINTS:
- Maximum 100 words
- Use bullet points only
- No introductory phrases
```

### 8. Add Self-Verification Blocks

Request explicit verification against requirements:

```
BEFORE FINALIZING YOUR RESPONSE:
1. Verify all code examples are syntactically correct
2. Check that every claim references the source document
3. Confirm the response addresses all three questions asked
4. Ensure the output format matches the template provided
```

## Model Selection: Flash vs Pro

Both Flash and Pro use the same prompting techniques. Choose based on task requirements:

| Factor | Flash | Pro |
|--------|-------|-----|
| **Speed** | Faster | Slower |
| **Cost** | 15x cheaper | Higher |
| **Context window** | Large | Large |
| **Best for** | Routine tasks, high volume, simple analysis | Complex reasoning, nuanced analysis, creative tasks |
| **Prompting differences** | None | None |

**When to use Flash:**
- Classification tasks
- Simple extractions
- High-volume processing
- Latency-sensitive applications
- Cost-constrained projects

**When to use Pro:**
- Multi-step reasoning
- Complex code generation
- Nuanced content creation
- Tasks requiring deep analysis
- Quality-critical outputs

## Multimodal Input Handling

When working with images, video, or audio alongside text:

### Reference Each Modality Explicitly

```
I'm providing you with:
1. An image of the error screen
2. The relevant log file text
3. User's description of the steps taken

Analyze ALL THREE inputs to diagnose the issue:
- From the IMAGE: identify the error code and UI state
- From the LOGS: find the corresponding error trace
- From the DESCRIPTION: understand the user's workflow

Synthesize these into a diagnosis.
```

### Position Multimodal Content Strategically

For long textual context with images:
```
[Image of architecture diagram]

The diagram above shows our current system architecture.

<documentation>
[Extended technical documentation]
</documentation>

Using BOTH the architecture diagram AND the documentation above,
identify potential scalability bottlenecks.
```

## Agentic Workflow Configuration

When using Gemini 3 for agentic tasks with tool use:

### Explicit Decomposition Instructions

```
TASK DECOMPOSITION APPROACH:
1. Break complex requests into subtasks
2. Execute ONE tool call per reasoning step
3. After each tool result, evaluate before proceeding
4. If a tool fails, attempt an alternative approach
5. Summarize findings after completing all subtasks
```

### Adaptability Parameters

```
HANDLING UNEXPECTED SITUATIONS:
- If a required file is missing: note it and continue with available data
- If a tool returns an error: describe the error and try alternative
- If results are ambiguous: ask for clarification before proceeding
- If the task scope expands: confirm before taking additional actions
```

### Persistence Patterns

```
RETRY STRATEGY:
- First failure: retry with same parameters
- Second failure: try alternative tool or approach
- Third failure: report blocker and request guidance

Never abandon a task silently. Always report status.
```

## API Configuration

### Basic Configuration

```python
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")

model = genai.GenerativeModel("gemini-2.0-flash")

response = model.generate_content(
    prompt,
    generation_config=genai.GenerationConfig(
        temperature=1.0,      # Always keep at 1.0
        top_p=0.95,
        top_k=40,
        max_output_tokens=8192
    )
)
```

### With System Instructions

```python
model = genai.GenerativeModel(
    "gemini-2.0-flash",
    system_instruction="You are a code review assistant. Provide specific, actionable feedback."
)

response = model.generate_content(user_prompt)
```

### Structured Output (JSON Mode)

```python
response = model.generate_content(
    prompt,
    generation_config=genai.GenerationConfig(
        response_mime_type="application/json",
        response_schema={
            "type": "object",
            "properties": {
                "analysis": {"type": "string"},
                "score": {"type": "number"},
                "recommendations": {"type": "array", "items": {"type": "string"}}
            }
        }
    )
)
```

### Recommended Parameters by Task

| Use Case | Temperature | top_p | Notes |
|----------|-------------|-------|-------|
| Code generation | 1.0 | 0.95 | Use structured output for JSON |
| Creative writing | 1.0 | 0.95 | Request verbosity explicitly |
| Analysis/reasoning | 1.0 | 0.95 | Include self-verification |
| Classification | 1.0 | 0.95 | Few-shot examples critical |

## Reusable Patterns

### Pattern 1: Post-Context Instruction Block

```
<data>
[Long document or code]
</data>

Based on the data above:
1. [First instruction]
2. [Second instruction]
3. [Third instruction]

Output format:
[Template]
```

### Pattern 2: Verbosity Control

```
Provide a [DETAILED/COMPREHENSIVE/THOROUGH] response that includes:
- Specific examples from the input
- Step-by-step reasoning
- Edge cases and exceptions
- Actionable recommendations

Do not provide a brief summary. Expand on each point.
```

### Pattern 3: Few-Shot Template

```
Task: [Description]

<examples>
<example>
Input: [Sample input 1]
Output: [Expected output 1]
</example>

<example>
Input: [Sample input 2]
Output: [Expected output 2]
</example>

<example>
Input: [Sample input 3 - edge case]
Output: [Expected output 3]
</example>
</examples>

Now process:
Input: {{user_input}}
Output:
```

### Pattern 4: Self-Verification Block

```
VERIFICATION CHECKLIST (complete before responding):
[ ] Response directly addresses the user's question
[ ] All code examples have been tested mentally for correctness
[ ] Output format matches the requested template exactly
[ ] No assumptions made without explicit documentation
[ ] Response length meets the specified requirements
```

### Pattern 5: Constraint Footer

```
[Main prompt content above]

CONSTRAINTS (strictly enforce):
- Maximum [N] words/sentences/items
- Must include [required element]
- Must NOT include [forbidden element]
- Format: [specific format requirement]
```

## Troubleshooting

### Terse/Minimal Responses

**Symptom:** Gemini 3 provides brief answers when detailed analysis expected.

**Solution:**
1. Add explicit verbosity request: "Provide a detailed, comprehensive response"
2. Specify minimum content: "Include at least 5 specific examples"
3. Ask for elaboration: "Explain your reasoning thoroughly"

### Format Non-Compliance

**Symptom:** Output doesn't match requested structure.

**Solution:**
1. Add few-shot examples showing exact format
2. Use response prefix pattern
3. Move format instructions to end of prompt
4. Use JSON mode for structured data

### Instruction Skipping (Long Context)

**Symptom:** Instructions at prompt start are ignored with long documents.

**Solution:**
1. Move instructions AFTER the data
2. Use context bridging: "Based on the document above..."
3. Repeat critical instructions at end

### Inconsistent Output

**Symptom:** Same prompt produces varying quality results.

**Solution:**
1. Keep temperature at 1.0 (don't try to lower it)
2. Add more few-shot examples
3. Add self-verification block
4. Use structured output mode for JSON

### Looping or Repetitive Output

**Symptom:** Model repeats content or gets stuck.

**Solution:**
1. Verify temperature is 1.0
2. Add explicit "Do not repeat" instruction
3. Set appropriate max_output_tokens
4. Break complex tasks into smaller prompts

### Multimodal Confusion

**Symptom:** Model ignores or misinterprets image/audio input.

**Solution:**
1. Explicitly reference each modality
2. Describe what each input contains
3. Specify which input to use for each part of the task

## Adaptation Quick Checklist

When converting any Claude prompt for Gemini 3:

- [ ] Keep temperature at 1.0 (do not adjust)
- [ ] For long context: move instructions AFTER the data
- [ ] Add context bridging phrases when referencing prior content
- [ ] Explicitly request detail if comprehensive output needed
- [ ] Include 2-3 few-shot examples showing desired format
- [ ] Use response prefixes instead of API prefilling
- [ ] Move constraints to end of prompt
- [ ] Add self-verification block for complex tasks
- [ ] For multimodal: explicitly reference each input type
- [ ] For agentic tasks: add explicit decomposition and retry patterns
