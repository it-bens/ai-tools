# Comprehensive Prompting Techniques

Detailed reference for all core prompting techniques, ordered from most broadly effective to specialized.

## Table of Contents

- [Be Clear and Direct](#1-be-clear-and-direct)
- [Use Examples (Multishot Prompting)](#2-use-examples-multishot-prompting)
- [Chain of Thought Prompting](#3-chain-of-thought-prompting)
- [XML Tags for Structure](#4-xml-tags-for-structure)
- [System Prompts and Role Prompting](#5-system-prompts-and-role-prompting)
- [Prefilling (API Only)](#6-prefilling-api-only)
- [Prompt Chaining](#7-prompt-chaining)
- [Long Context Tips](#8-long-context-tips)
- [Reduce Hallucinations](#9-reduce-hallucinations)
- [Technique Selection Guide](#technique-selection-guide)

## 1. Be Clear and Direct

Claude functions like a brilliant new employee with no prior context on norms, styles, or preferences. The more precisely instructions explain desired outcomes, the better the response.

### The Golden Rule
Show the prompt to a colleague with minimal context. If they're confused, Claude will be too.

### Providing Context

Include contextual information:
- **Purpose**: What task results will be used for
- **Audience**: Who the output is meant for
- **Workflow position**: Where this task fits in a larger process
- **Success definition**: What successful completion looks like

### Specificity Techniques

**Be explicit about output:**
```
Output only the JSON object. Do not include any explanation or preamble.
```

**Use sequential steps:**
```
Instructions:
1. Parse the input data
2. Validate all required fields
3. Transform to the target format
4. Return the result in JSON
```

**Specify format precisely:**
```
Format your response as a markdown table with columns:
| Feature | Description | Priority |
```

### Example: Anonymizing Data

**Vague (produces errors):**
```
Remove all personally identifiable information from these messages.
```

**Clear (produces correct output):**
```
Your task is to anonymize customer feedback for our quarterly review.

Instructions:
1. Replace all customer names with "CUSTOMER_[ID]"
2. Replace email addresses with "EMAIL_[ID]@example.com"
3. Redact phone numbers as "PHONE_[ID]"
4. If a message mentions a specific product, leave it intact
5. If no PII is found, copy the message verbatim
6. Output only the processed messages, separated by "---"

Data to process:
{{FEEDBACK_DATA}}
```

## 2. Use Examples (Multishot Prompting)

Examples are the most reliable shortcut for getting exact output formats. They reduce misinterpretation and enforce uniform structure.

### Crafting Effective Examples

**Relevance**: Examples mirror actual use case
**Diversity**: Cover edge cases and variations
**Clarity**: Wrap in `<example>` tags for structure

### Example Count Guidelines
- Format enforcement: 1-2 examples
- Complex tasks: 3-5 examples
- Edge cases: Add specific examples for tricky scenarios

### Structure

```xml
<examples>
<example>
Input: The dashboard is slow and I can't find the export button.
Category: UI/UX, Performance
Sentiment: Negative
Priority: High
</example>
<example>
Input: Love the Salesforce integration! Would be great to add Hubspot too.
Category: Integration, Feature Request
Sentiment: Positive
Priority: Medium
</example>
</examples>

Now analyze this feedback: {{FEEDBACK}}
```

### Example Quality

Claude 4 models pay very close attention to example details. Ensure:
- Examples align with behaviors to encourage
- No unintended patterns that Claude might pick up
- Diversity prevents overfitting to specific formats

## 3. Chain of Thought Prompting

Giving Claude space to think improves performance on complex tasks by breaking problems into steps.

### When to Use CoT
- Complex math, logic, or analysis
- Multi-step reasoning
- Tasks humans would need to think through
- Decisions with many factors

### When NOT to Use CoT
- Simple factual queries
- Tasks where latency is critical
- Straightforward format transformations

### CoT Levels

**Basic (least structured):**
```
Think step-by-step before answering.
```

**Guided (more structure):**
```
Think before answering. First, identify the key requirements.
Then, consider the trade-offs. Finally, provide your recommendation.
```

**Structured (most reliable):**
```
Think before answering in <thinking> tags. First, analyze X.
Then, evaluate Y. Finally, in <answer> tags, provide your recommendation.
```

### Example: Financial Analysis

**Without CoT:**
```
A client wants to invest $10,000 in either a volatile stock (12% returns)
or a guaranteed bond (6%). They need the money in 5 years for a house down
payment. What do you recommend?
```
Result: Generic recommendation without rigorous analysis.

**With Structured CoT:**
```
A client wants to invest $10,000 in either a volatile stock (12% returns)
or a guaranteed bond (6%). They need the money in 5 years for a house down
payment.

Analyze in <thinking> tags:
1. Calculate potential outcomes for each option
2. Assess the client's risk tolerance given their goal
3. Consider historical market volatility over 5-year periods

Then provide your recommendation in <answer> tags.
```
Result: Rigorous analysis with calculations and justified recommendation.

## 4. XML Tags for Structure

XML tags help Claude parse prompts accurately, leading to higher-quality outputs.

### Benefits
- **Clarity**: Separate different prompt components
- **Accuracy**: Reduce misinterpretation
- **Flexibility**: Easy to modify specific sections
- **Parseability**: Extract specific parts from responses

### Common Tag Patterns

**Input/Output:**
```xml
<contract>
{{CONTRACT_TEXT}}
</contract>

<instructions>
1. Analyze indemnification clauses
2. Identify liability limitations
3. Flag unusual terms
</instructions>

Provide findings in <analysis> tags.
```

**Examples:**
```xml
<examples>
<example>
<input>...</input>
<output>...</output>
</example>
</examples>
```

**Structured Response:**
```xml
<thinking>
[Reasoning process]
</thinking>

<answer>
[Final response]
</answer>
```

### Best Practices
- Use consistent tag names throughout the prompt
- Reference tags explicitly: "Using the contract in <contract> tags..."
- Nest tags for hierarchical content: `<outer><inner></inner></outer>`
- Combine with other techniques for maximum effect

## 5. System Prompts and Role Prompting

The system parameter sets Claude's role and dramatically improves domain-specific performance.

### Role Prompting Benefits
- **Enhanced accuracy**: Better performance on domain-specific tasks
- **Tailored tone**: Communication style matches expertise
- **Improved focus**: Claude stays within task requirements

### Effective Role Definition

**Basic:**
```
You are a data scientist at a Fortune 500 company.
```

**Enhanced:**
```
You are a senior data scientist specializing in customer behavior analysis
at a Fortune 500 retail company. You have 15 years of experience with
predictive modeling and are presenting findings to the executive team.
```

### Example: Legal Analysis

**Without role:**
```
Analyze this software licensing agreement for potential risks.
Focus on indemnification, liability, and IP ownership.
```
Result: Surface-level summary that may miss critical issues.

**With role:**
```
System: You are the General Counsel of a Fortune 500 tech company.

User: We're considering this software licensing agreement for our core
data infrastructure. Analyze it for potential risks, focusing on
indemnification, liability, and IP ownership. Give your professional opinion.
```
Result: Deep analysis identifying critical issues with specific recommendations.

### Role Specificity
More specific roles yield better results:
- "data scientist" < "data scientist specializing in customer insights"
- "lawyer" < "General Counsel of a Fortune 500 tech company"

## 6. Prefilling (API Only)

Guide responses by starting the assistant message with desired text.

### Use Cases
- **Format enforcement**: Prefill `{` to force JSON output
- **Skip preambles**: Jump directly to content
- **Maintain character**: Keep roleplay consistent

### Examples

**JSON enforcement:**
```python
messages=[
    {"role": "user", "content": "Extract product info as JSON: ..."},
    {"role": "assistant", "content": "{"}  # Prefill
]
```

**Character maintenance:**
```python
messages=[
    {"role": "user", "content": "What do you deduce about this shoe?"},
    {"role": "assistant", "content": "[Sherlock Holmes]"}  # Prefill
]
```

### Important Notes
- Prefill cannot end with trailing whitespace
- Not available with extended thinking mode
- Claude continues from where prefill leaves off

## 7. Prompt Chaining

Break complex tasks into sequential subtasks, each receiving Claude's full attention.

### When to Chain
- Multi-step workflows where output feeds into next step
- Tasks requiring different "modes" (research, then write, then edit)
- Complex processes needing validation between steps

### Chain Structure

**Step 1: Research**
```
Research the topic and provide key findings in <findings> tags.
```

**Step 2: Draft** (receives Step 1 output)
```
Using these findings:
<findings>{{STEP1_OUTPUT}}</findings>

Draft a comprehensive report in <draft> tags.
```

**Step 3: Review** (receives Step 2 output)
```
Review this draft for accuracy and clarity:
<draft>{{STEP2_OUTPUT}}</draft>

Provide specific improvement suggestions.
```

### Best Practices
- Clear handoff format between steps
- Validation at each step before proceeding
- Error handling for failed steps
- Consider parallel chains for independent subtasks

## 8. Long Context Tips

When working with large documents or extended conversations:

### Document Placement
- Place long documents at the beginning of the prompt
- Put instructions and questions after the document
- Use XML tags to clearly delineate document boundaries

### Retrieval Strategy
```xml
<document>
{{LONG_DOCUMENT}}
</document>

Find and quote the sections most relevant to answering: {{QUESTION}}
Then provide your analysis based only on those quoted sections.
```

### Context Management
- Summarize earlier conversation sections for very long chats
- Use explicit references to earlier content
- Consider chunking extremely long documents

## 9. Reduce Hallucinations

Strategies for improving factual accuracy:

### Permission to Say "I Don't Know"
```
If you're not certain about something, say so. It's better to admit
uncertainty than to make up information.
```

### Ground in Provided Context
```
Answer based ONLY on the information in the provided document.
If the answer isn't in the document, say "Not found in provided context."
```

### Request Citations
```
For each claim, cite the specific source from the provided materials.
Format: [Source: document name, section]
```

### Verification Instructions
```
Before stating any fact, verify it's supported by the provided context.
If you find conflicting information, note the discrepancy.
```

## Technique Selection Guide

| Task Type | Primary Techniques |
|-----------|-------------------|
| Format-specific output | Examples, XML tags, Prefilling |
| Complex reasoning | Chain of thought, XML structure |
| Domain expertise | Role prompting, Context |
| Multi-step workflows | Prompt chaining |
| Long documents | XML tags, Retrieval strategy |
| Consistency | Examples, Prefilling |
| Accuracy | Grounding, Verification |
