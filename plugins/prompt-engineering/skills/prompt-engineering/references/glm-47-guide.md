# GLM 4.7 Prompt Adaptation Guide

Techniques for adapting Claude 4 prompts to achieve reasoning and response parity on GLM 4.7 (Z.ai).

## Table of Contents

- [Core Differences: Claude 4 vs GLM 4.7](#core-differences-claude-4-vs-glm-47)
- [Adaptation Techniques](#adaptation-techniques)
- [Decision-Making Prompts](#decision-making-prompts)
- [API Configuration](#api-configuration)
- [Reusable Patterns](#reusable-patterns)
- [Troubleshooting](#troubleshooting)
- [Adaptation Quick Checklist](#adaptation-quick-checklist)
- [Cost Comparison](#cost-comparison)

## Core Differences: Claude 4 vs GLM 4.7

| Aspect | Claude 4 | GLM 4.7 | Adaptation Required |
|--------|----------|---------|---------------------|
| **Instruction positioning** | Flexible—synthesizes full prompt | Strong start-bias—prioritizes first 200 words | Front-load all constraints |
| **Directive language** | Responds to nuanced, polite prompts | Responds best to firm directives | Convert suggestions to commands |
| **Output specificity** | Naturally references context | Defaults to abstract principle statements | Add explicit reference requirements |
| **Conditional logic** | Handles nested if/then implicitly | Benefits from explicit step decomposition | Break conditionals into numbered steps |
| **Few-shot examples** | Often unnecessary for tone/style | Critical for achieving specific patterns | Add 1-2 examples of desired output |
| **Reasoning mode** | Built-in, always active | Requires explicit API parameter | Enable `thinking.type: "enabled"` |
| **Language output** | Stable English | May switch to Chinese mid-response | Add explicit language instructions |

## Adaptation Techniques

### 1. Front-Load Mandatory Instructions

GLM 4.7 has a strong recency bias toward prompt beginnings. Place every critical instruction in the first 200 words.

**Claude-style (fails on GLM 4.7):**
```
You are a helpful code review assistant. When reviewing code, please
consider readability, performance, and security. It would be nice if
you could reference our architecture.md file...

[several paragraphs later]

Important: Always provide specific, actionable feedback that references
the exact code being modified.
```

**GLM 4.7-optimized:**
```
MANDATORY OUTPUT RULES:
1. ALWAYS reference the specific code/file the user modified
2. ALWAYS name the exact line number and function
3. NEVER give generic advice like "follow best practices"

You are a code review assistant. Your reviews MUST include:
1. Specific line references (e.g., "Line 47:")
2. Direct code suggestions, not just descriptions
3. Priority labels: [CRITICAL], [IMPORTANT], [SUGGESTION]

[rest of context follows...]
```

### 2. Replace Soft Language with Directives

| Claude Accepts | GLM 4.7 Requires |
|----------------|------------------|
| "Please consider..." | "You MUST..." |
| "It would be helpful to..." | "ALWAYS..." |
| "Try to avoid..." | "NEVER..." |
| "You might want to..." | "STRICTLY..." |
| "Remember to..." | "REQUIRED:..." |

**Before:**
```
When blocking, try to be specific about what test the user should write.
Consider referencing the actual code they're modifying.
```

**After:**
```
When blocking, you MUST:
- State the EXACT test the user should write
- Reference the SPECIFIC code they are modifying
- NEVER use phrases like "follow TDD" without specifics
```

### 3. Use the CATS Framework

Structure prompts using **Context, Action, Tone, Structure**:

```
Context: You are reviewing a pull request for a Python FastAPI backend.

Action: Identify ALL violations of our REST naming conventions. For EACH
violation, provide the line number, the problematic code, and corrected code.

Tone: Be direct and technical. Do not soften criticism.

Structure: Format as:
## [SEVERITY] Issue Title
- **Line**: [number]
- **Problem**: [specific code]
- **Fix**: [corrected code]
- **Reason**: [one sentence]
```

### 4. Add Explicit Output Templates

GLM 4.7 adheres more reliably when given explicit templates with examples.

```
OUTPUT FORMAT FOR BLOCKING:
"You're [verb]ing [specific thing]. Write a test for [specific behavior] first, then [specific next step]."

EXAMPLE - User adds calculateTax function without test:
CORRECT: "You're adding calculateTax without a failing test. Write a test that calls calculateTax(100) and expects 7.5 for the default tax rate, then run it to see it fail."
WRONG: "This violates TDD principles. Please follow the Red-Green-Refactor cycle."
```

### 5. Add Self-Verification Requirements

Force the model to check its own response for specificity:

```
BEFORE RESPONDING, VERIFY:
- Does your response name the specific file/function?
- Does your response specify what test to write?
- Would this exact response work for any violation? (If yes, make it more specific)
```

### 6. Use Context-Referencing Instructions

GLM 4.7 will reference specific context only when explicitly instructed:

```
CONTEXT TO REFERENCE:
- User action: [description]
- File modified: [filename]
- Function added: [function name]
- Missing coverage: [what lacks tests]

Your response MUST mention at least 2 items from CONTEXT verbatim.
If a detail is missing, say "Not provided" instead of generalizing.
```

### 7. Include Forbidden Patterns

Explicitly state what NOT to do:

```
FORBIDDEN RESPONSE PATTERNS:
- "This violates [principle]. Please follow [methodology]."
- "Remember to [general advice]."
- "Best practice is to [abstract guidance]."
- Any response that could apply to ANY similar situation

REQUIRED RESPONSE PATTERN:
- "You're [specific action]. [Specific instruction for THIS exact case]."
```

### 8. Add Language Control

Prevent language switching:

```
ALWAYS respond in English. Reason in English. Output in English.
```

## Decision-Making Prompts

Standard adaptation techniques work for **output generation** prompts (code review, feedback, explanations). Decision-making prompts—where the model must make allow/block, yes/no, or categorical judgments—require additional patterns to prevent over-blocking or misapplied rules.

### Why Decision Prompts Need Extra Scaffolding

GLM-4.7's architecture separates reasoning (`reasoning_content`) from visible output (`content`). Thinking mode improves decision quality but doesn't automatically surface justifications—you must explicitly instruct the model to include reasoning in its response. Without this scaffolding, GLM-4.7 defaults to generic outputs like "This violates TDD principles" rather than specific directives like "You're adding `calculateDiscount()` without a failing test. Write a test first."

### When to Use These Patterns

Apply these patterns when the prompt requires:
- Binary decisions (allow/block, valid/invalid, pass/fail)
- Rule evaluation against input data
- Categorical classification with edge cases
- Enforcement or gating logic

### Pattern 6: Critical Rule Isolation

Place the single most important rule in its own top-level section BEFORE all other content. This rule should override or take precedence.

```
<critical_rule>
ADDING EXACTLY ONE NEW TEST IS ALWAYS ALLOWED.
This is the most important rule. Do not block single test additions.
</critical_rule>

[Rest of prompt follows...]
```

**Why it works:** GLM 4.7's start-bias means the first rule encountered has outsized influence. Isolating the critical rule ensures it isn't diluted by surrounding content.

### Pattern 7: Explicit Comparison Algorithms

When rules involve counting or comparisons, provide explicit formulas—not just descriptions.

**Fails:**
```
Adding more than one test at once: decision = "block"
```

**Works:**
```
<counting_tests>
To count new tests correctly:
1. Identify test methods in Old Content
2. Identify test methods in New Content
3. NEW TESTS = tests in New Content that are NOT in Old Content
4. If NEW TESTS == 1: ALWAYS ALLOWED (decision = null)
5. If NEW TESTS >= 2: VIOLATION (decision = "block")

IMPORTANT: The TOTAL number of tests does not matter.
Only the DIFFERENCE between old and new content matters.
</counting_tests>
```

**Why it works:** GLM 4.7 interprets ambiguous comparisons inconsistently. Explicit algorithms remove interpretation variance.

### Pattern 8: Positive/Negative Rule Pairing

For every list of violations, add a corresponding list of non-violations. This prevents over-blocking.

```
<violations>
ONLY these patterns result in decision = "block":

VIOLATION: MULTIPLE_TEST_ADDITION
- Write adds TWO OR MORE new test methods
- Count: (tests in New) - (tests in Old) >= 2

VIOLATION: PREMATURE_IMPLEMENTATION
- Implementation without failing test evidence
</violations>

<not_violations>
NOT A VIOLATION (do not block):
- Adding exactly ONE new test (always allowed)
- Modifying an existing test (not adding a test)
- Test file already has tests and you add ONE more (allowed)
</not_violations>
```

**Why it works:** Without explicit "allowed" cases, GLM 4.7 may over-apply violation patterns to edge cases.

### Pattern 9: Decision Chain Examples

For decision prompts, show examples of correct REASONING—not just output format. Include input conditions, evaluation steps, and final decision.

```
<examples>
EXAMPLE 1 - CORRECT DECISION (ALLOW):
Old Content: 5 test methods
New Content: 6 test methods (one new test added)
New tests: 6 - 5 = 1
Decision: null
Reason: "RED phase: adding exactly one new test is always allowed"

EXAMPLE 2 - CORRECT DECISION (BLOCK):
Old Content: 2 test methods
New Content: 5 test methods
New tests: 5 - 2 = 3
Decision: "block"
Reason: "MULTIPLE_TEST_ADDITION: Adding 3 new tests. Add one test at a time."

EXAMPLE 3 - CORRECT DECISION (ALLOW):
Old Content: test with assert x == "old_value"
New Content: same test with assert x == "new_value"
New tests: 0 (modified existing test, not a new test)
Decision: null
Reason: "Modifying existing test assertion is allowed"
</examples>
```

**Why it works:** GLM 4.7 needs concrete examples of correct reasoning to calibrate its decision logic.

### Pattern 10: Critical Rule Repetition

Repeat the most critical rule across multiple sections to reinforce it.

```
<critical_rule>
ADDING EXACTLY ONE NEW TEST IS ALWAYS ALLOWED.
</critical_rule>

<tdd_cycle>
PHASE: RED (Adding Tests)
- Adding ONE new test: decision = null (ALWAYS ALLOWED)
...
</tdd_cycle>

<violations>
NOT A VIOLATION:
- Adding exactly ONE new test (always allowed)
</violations>

<examples>
EXAMPLE 1: ... Decision: null, Reason: "adding one test is always allowed"
</examples>
```

**Why it works:** GLM 4.7 may "forget" rules encountered only once. Repetition reinforces priority.

### Pattern 11: Decision + Because + Evidence Template

Structure every decision response with three mandatory parts to force justification:

```
## OUTPUT FORMAT (MANDATORY)
For every response, structure as:

1. **DECISION**: [Specific action to take]
2. **BECAUSE**: [Primary reasoning - 1-2 sentences]
3. **EVIDENCE**: [Quote specific input that triggered this decision]

EXAMPLE:
DECISION: Write a test for `calculateDiscount()` first.
BECAUSE: TDD requires a failing test before implementation to ensure the test validates the new behavior.
EVIDENCE: "function calculateDiscount()" added at line 47 with no corresponding test.
```

**Why it works:** The three-part structure forces GLM-4.7 to surface reasoning that would otherwise stay in hidden `reasoning_content`. Each part serves a purpose: DECISION prevents vague advice, BECAUSE forces explanation, EVIDENCE forces citation.

### Pattern 12: Labeled Input for Citation

Structure dynamic input with labels so GLM-4.7 can reference specifics easily:

```
## INPUT (cite these labels in your response)
[FILE]: src/pricing.js
[LINES ADDED]: 12-24
[FUNCTION]: calculateDiscount
[TESTS MODIFIED]: None

Your response MUST cite at least one [LABEL] when explaining your decision.
```

**Why it works:** Labels give GLM-4.7 concrete anchors for citation. Without labels, the model may struggle to identify what to quote from unstructured input.

### Pattern 13: Rule Priority Levels

For complex rule sets, assign explicit priority levels to prevent ambiguous enforcement:

```
## RULES (evaluate in priority order)

R1 [CRITICAL]: No implementation without a failing test
R2 [HIGH]: Test files must change with implementation files
R3 [MEDIUM]: One assertion per test
R4 [LOW]: Use descriptive test names

## PRIORITY RESOLUTION
- CRITICAL overrides all others
- Same priority: apply rule listed FIRST
- Report the highest-priority violation only
```

**Why it works:** Explicit priorities prevent GLM-4.7 from enforcing low-priority rules when high-priority violations exist, reducing noise in feedback.

### Decision Prompt Adaptation Checklist

Additional items for decision-making prompts:

- [ ] Isolate the most critical rule in its own top-level section
- [ ] Provide explicit algorithms for any counting/comparison logic
- [ ] Pair every VIOLATION list with a NOT A VIOLATION list
- [ ] Include 3-4 examples showing input → reasoning → decision
- [ ] Repeat the critical rule in at least 3 different sections
- [ ] Use Decision + Because + Evidence template for output format
- [ ] Label input fields for easy citation ([FILE], [LINES], etc.)
- [ ] Assign priority levels to rules ([CRITICAL], [HIGH], [MEDIUM])

## API Configuration

### Enable Thinking Mode

GLM 4.7's reasoning requires explicit activation for complex conditional evaluation:

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_API_KEY",
    base_url="https://api.z.ai/api/paas/v4/"
)

response = client.chat.completions.create(
    model="glm-4.7",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_message}
    ],
    thinking={"type": "enabled"},  # REQUIRED for complex logic
    temperature=0.7,
    top_p=0.95,
    max_tokens=16384
)
```

### Thinking Mode Options

| Mode | Configuration | Use Case |
|------|---------------|----------|
| **Interleaved** | `{"thinking": {"type": "enabled"}}` | Default for complex tasks |
| **Preserved** | `{"thinking": {"type": "enabled", "clear": false}}` | Multi-turn agentic tasks |
| **Disabled** | `{"thinking": {"type": "disabled"}}` | Simple queries, cost savings |

### Recommended Parameters by Task

| Use Case | Temperature | top_p | Thinking |
|----------|-------------|-------|----------|
| Code review/analysis | 0.7 | 1.0 | Enabled |
| Rule enforcement | 0.6 | 0.95 | Enabled |
| Multi-turn coding | 1.0 | 0.95 | Preserved |
| Simple Q&A | 0.7 | 0.95 | Disabled |

### Stop Tokens

Prevent infinite generation loops:

```python
stop=["<|endoftext|>", "<|user|>", "<|observation|>"]
```

## Reusable Patterns

### Pattern 1: Directive Blocking Response

```
When blocking a user action, use this exact structure:

"You're [VERB]ing [SPECIFIC_ITEM]. [SPECIFIC_INSTRUCTION]. [CONCRETE_NEXT_STEP]."

Variables:
- VERB: adding/modifying/removing/refactoring
- SPECIFIC_ITEM: the exact function, class, or file name
- SPECIFIC_INSTRUCTION: the exact action with expected inputs/outputs
- CONCRETE_NEXT_STEP: run it, check the error, then return
```

### Pattern 2: Conditional Rule Evaluation

```
RULE EVALUATION (internal process):
Given: [user_action]
Check 1: [condition] → If true: [result]
Check 2: [condition] → If true: [result]
Check 3: [condition] → If true: [result]
Default: [fallback_result]

Output only the final result, not the evaluation process.
```

### Pattern 3: Context Extraction and Reference

```
CONTEXT PROVIDED:
- Action type: [extracted]
- Target: [extracted]
- Current state: [extracted]

Your response MUST mention at least 2 items from CONTEXT verbatim.
If a detail is missing, say "Not provided" instead of generalizing.
```

### Pattern 4: Anti-Generic Response Guard

```
FORBIDDEN RESPONSE PATTERNS:
- "This violates [principle]. Please follow [methodology]."
- "Remember to [general advice]."
- "Best practice is to [abstract guidance]."

REQUIRED RESPONSE PATTERN:
- "You're [specific action]. [Specific instruction for this exact case]."
```

### Pattern 5: Role + Constraint Opener

```
You are [ROLE] who gives SPECIFIC, ACTIONABLE feedback.
NEVER give generic advice. ALWAYS reference the exact code/action.
ALWAYS respond in English. Reason in English.

[Rest of system prompt...]
```

## Troubleshooting

### Generic/Abstract Responses

**Symptom:** GLM 4.7 says "Follow best practices" instead of specific guidance.

**Solution:**
1. Add explicit context-referencing requirements
2. Include FORBIDDEN patterns section
3. Add self-verification step
4. Provide output template with example

### Chinese Language Output

**Symptom:** GLM 4.7 outputs in Chinese or mixes languages.

**Solution:** Add at prompt start:
```
ALWAYS respond in English. Reason in English. Output in English.
```

### Ignored Instructions

**Symptom:** GLM 4.7 ignores constraints placed mid-prompt.

**Solution:** Move ALL mandatory rules to first 200 words of system prompt.

### Missing Specificity (No Line References)

**Symptom:** Feedback doesn't cite specific lines.

**Solution:**
```
OUTPUT REQUIREMENTS:
- Every piece of feedback MUST reference a specific line number
- Format: "Line [N]: [observation]"
- If you cannot cite a line number, your feedback is INVALID
```

### Infinite Generation Loops

**Symptom:** Model generates endlessly.

**Solution:** Add stop tokens:
```python
stop=["<|endoftext|>", "<|user|>", "<|observation|>"]
```

### Thinking Loops

**Symptom:** Model gets stuck in recursive reasoning.

**Solution:** Add to system prompt:
```
Do not get stuck in thinking loops. Be concise in your reasoning.
```

### Over-Blocking / Misapplied Rules

**Symptom:** Model blocks valid actions, applies rules too aggressively, or makes incorrect decisions on edge cases.

**Solution:**
1. Isolate the most critical "allow" rule in its own top-level section
2. Add explicit "NOT A VIOLATION" section alongside violations
3. Provide algorithms for any counting/comparison logic
4. Add 3-4 examples showing correct allow AND block decisions
5. Repeat the critical rule in multiple sections

See "Decision-Making Prompts" section for detailed patterns.

### Missing Justifications / Generic Reasoning

**Symptom:** Model makes correct decisions but doesn't explain why, or gives abstract justifications like "This violates best practices."

**Solution:**
1. Add Decision + Because + Evidence template (Pattern 11)
2. Label input fields for easy citation (Pattern 12)
3. Include example showing expected justification depth
4. Add "Your response MUST cite specific evidence from input"

See "Decision-Making Prompts" section for detailed patterns.

## Adaptation Quick Checklist

When converting any Claude prompt for GLM 4.7:

- [ ] Move ALL mandatory requirements to first 5 lines (first 200 words)
- [ ] Convert "should," "try to," "consider" → "MUST," "ALWAYS," "NEVER"
- [ ] Add 1-2 examples of exact desired output format
- [ ] Include explicit "FORBIDDEN" patterns to avoid
- [ ] Add context extraction section with reference requirement
- [ ] Enable thinking mode in API call: `{"thinking": {"type": "enabled"}}`
- [ ] Add self-verification step before response
- [ ] Set temperature to 0.6-0.7 for consistent rule application
- [ ] Add "ALWAYS respond in English. Reason in English." if needed

## Cost Comparison

| Provider | Input | Output |
|----------|-------|--------|
| GLM-4.7 (Z.ai) | $0.60/M tokens | $2.20/M tokens |
| GLM-4.7 (OpenRouter) | $0.40/M tokens | $1.50/M tokens |
| Claude Sonnet 4 | $3.00/M tokens | $15.00/M tokens |

GLM 4.7 is 5-7x cheaper than Claude Sonnet 4.
