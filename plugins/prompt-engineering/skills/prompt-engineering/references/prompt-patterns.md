# Reusable Prompt Patterns

Production-ready patterns for common prompt engineering scenarios.

## Table of Contents

- [Analysis Patterns](#analysis-patterns)
- [Generation Patterns](#generation-patterns)
- [Transformation Patterns](#transformation-patterns)
- [Review Patterns](#review-patterns)
- [Chain Patterns](#chain-patterns)
- [Specialized Patterns](#specialized-patterns)
- [Pattern Customization](#pattern-customization)

---

## Analysis Patterns

### Structured Analysis Pattern

For comprehensive analysis with consistent output structure.

```markdown
# Analysis Request

## Context
<context>
{{CONTEXT_OR_DATA}}
</context>

## Analysis Framework

Analyze the above using this framework:

<instructions>
1. **Summary**: Provide a 2-3 sentence executive summary
2. **Key Findings**: List 3-5 major observations
3. **Implications**: What do these findings mean?
4. **Recommendations**: Actionable next steps
5. **Risks**: Potential concerns or limitations
</instructions>

## Output Format

Structure your response as:
<analysis>
<summary>...</summary>
<findings>
- Finding 1
- Finding 2
</findings>
<implications>...</implications>
<recommendations>
- Recommendation 1
- Recommendation 2
</recommendations>
<risks>...</risks>
</analysis>
```

### Comparative Analysis Pattern

For comparing options, approaches, or alternatives.

```markdown
# Comparative Analysis

## Options to Compare
<options>
{{OPTION_LIST}}
</options>

## Evaluation Criteria
Evaluate each option against these criteria:
- {{CRITERION_1}}
- {{CRITERION_2}}
- {{CRITERION_3}}

## Analysis Requirements

For each option:
1. Score against each criterion (1-5)
2. Identify key strengths
3. Identify key weaknesses
4. Note any deal-breakers or prerequisites

## Output Format

| Option | {{CRITERION_1}} | {{CRITERION_2}} | {{CRITERION_3}} | Overall |
|--------|-----------------|-----------------|-----------------|---------|
| ...    | ...             | ...             | ...             | ...     |

### Detailed Assessment
[Per-option analysis following the requirements above]

### Recommendation
[Clear recommendation with justification]
```

### Root Cause Analysis Pattern

For debugging and troubleshooting.

```markdown
# Root Cause Analysis

## Problem Description
<problem>
{{PROBLEM_DESCRIPTION}}
</problem>

## Available Information
<context>
{{LOGS_ERRORS_DATA}}
</context>

## Analysis Process

<thinking>
1. **Symptom Analysis**: What are the observable symptoms?
2. **Hypothesis Generation**: What could cause these symptoms?
3. **Evidence Evaluation**: What evidence supports/refutes each hypothesis?
4. **Root Cause Identification**: What is the most likely root cause?
</thinking>

## Output

<answer>
**Root Cause**: [Primary cause]
**Contributing Factors**: [Secondary causes if any]
**Evidence**: [Supporting data]
**Resolution**: [Recommended fix]
**Prevention**: [How to prevent recurrence]
</answer>
```

---

## Generation Patterns

### Structured Content Generation Pattern

For creating content with specific format requirements.

```markdown
# Content Generation Request

## Purpose
{{PURPOSE_DESCRIPTION}}

## Target Audience
{{AUDIENCE_DESCRIPTION}}

## Requirements
<requirements>
- Tone: {{TONE}}
- Length: {{LENGTH}}
- Format: {{FORMAT}}
- Key points to include: {{KEY_POINTS}}
</requirements>

## Examples
<examples>
<example>
{{EXAMPLE_CONTENT}}
</example>
</examples>

## Generation Instructions

Create content that:
1. Addresses the stated purpose
2. Is appropriate for the target audience
3. Follows all format requirements
4. Incorporates the key points naturally

## Output

Provide the content in the specified format, ready for use.
```

### Code Generation Pattern

For generating production-quality code.

```markdown
# Code Generation Request

## Task Description
{{TASK_DESCRIPTION}}

## Technical Context
- Language: {{LANGUAGE}}
- Framework: {{FRAMEWORK}}
- Environment: {{ENVIRONMENT}}

## Requirements
<requirements>
1. {{FUNCTIONAL_REQ_1}}
2. {{FUNCTIONAL_REQ_2}}
3. {{FUNCTIONAL_REQ_3}}
</requirements>

## Quality Standards
- Include error handling for edge cases
- Follow {{LANGUAGE}} best practices and idioms
- Add clear comments for complex logic
- Ensure the solution is general, not hard-coded

## Anti-Hacking Instruction
Write a high quality, general purpose solution. Do not hard-code values
or create solutions that only work for specific inputs. If any requirement
is unclear or seems incorrect, ask for clarification.

## Output Format

```{{LANGUAGE}}
[Code here]
```

### Usage Example
[Brief example of how to use the code]

### Notes
[Any important considerations or limitations]
```

### Documentation Generation Pattern

For creating technical documentation.

```markdown
# Documentation Request

## Subject
{{SUBJECT_TO_DOCUMENT}}

## Documentation Type
{{TYPE: API Reference / User Guide / Tutorial / README}}

## Target Audience
{{AUDIENCE: Developers / End Users / Administrators}}

## Scope
<scope>
What to include:
- {{INCLUDE_1}}
- {{INCLUDE_2}}

What to exclude:
- {{EXCLUDE_1}}
</scope>

## Style Requirements
- Use {{VOICE: active / passive}} voice
- Maintain {{TONE: formal / conversational}} tone
- Include examples for {{EXAMPLE_AREAS}}

## Structure

Follow this outline:
1. Overview / Introduction
2. Prerequisites (if applicable)
3. Main content sections
4. Examples
5. Troubleshooting (if applicable)
6. References

## Output

Provide complete, production-ready documentation in markdown format.
```

---

## Transformation Patterns

### Data Transformation Pattern

For converting data between formats.

```markdown
# Data Transformation

## Input
<input format="{{INPUT_FORMAT}}">
{{INPUT_DATA}}
</input>

## Target Format
{{OUTPUT_FORMAT_DESCRIPTION}}

## Transformation Rules
<rules>
1. {{RULE_1}}
2. {{RULE_2}}
3. {{RULE_3}}
</rules>

## Edge Case Handling
- If {{CONDITION_1}}: {{ACTION_1}}
- If {{CONDITION_2}}: {{ACTION_2}}

## Output

Provide the transformed data in the target format.
Do not include explanations unless the transformation requires decisions.
```

### Text Rewriting Pattern

For adapting content for different contexts.

```markdown
# Content Adaptation

## Original Content
<original>
{{ORIGINAL_TEXT}}
</original>

## Target Context
- Audience: {{TARGET_AUDIENCE}}
- Tone: {{TARGET_TONE}}
- Purpose: {{TARGET_PURPOSE}}
- Constraints: {{CONSTRAINTS}}

## Adaptation Guidelines
<guidelines>
1. Preserve core meaning and key information
2. Adjust vocabulary for target audience
3. Modify tone to match target context
4. {{ADDITIONAL_GUIDELINE}}
</guidelines>

## Output

Provide the adapted content ready for use.
```

---

## Review Patterns

### Code Review Pattern

For systematic code analysis.

```markdown
# Code Review Request

## Code to Review
<code language="{{LANGUAGE}}">
{{CODE}}
</code>

## Review Focus Areas
<focus>
- [ ] Correctness: Does the code work as intended?
- [ ] Performance: Are there efficiency issues?
- [ ] Security: Are there vulnerabilities?
- [ ] Maintainability: Is the code readable and maintainable?
- [ ] Best Practices: Does it follow language/framework conventions?
</focus>

## Project Context
{{BRIEF_PROJECT_CONTEXT}}

## Output Format

## Review Summary
[1-2 sentence overall assessment]

## Issues Found

### Critical
[Issues that must be fixed]

### Suggestions
[Improvements to consider]

### Positive Notes
[What's done well]

## Specific Line Comments
| Line | Issue | Suggestion |
|------|-------|------------|
| ...  | ...   | ...        |
```

### Document Review Pattern

For reviewing written content.

```markdown
# Document Review

## Document
<document>
{{DOCUMENT_CONTENT}}
</document>

## Review Criteria
<criteria>
- Clarity: Is the writing clear and unambiguous?
- Accuracy: Is the information correct?
- Completeness: Are all necessary topics covered?
- Structure: Is the organization logical?
- Tone: Is the tone appropriate for the audience?
</criteria>

## Target Audience
{{AUDIENCE}}

## Output

## Overall Assessment
[Brief summary of document quality]

## Strengths
[What works well]

## Areas for Improvement
[Specific issues with suggested fixes]

## Detailed Comments
[Section-by-section feedback]
```

---

## Chain Patterns

### Research-to-Report Chain

Step 1: Research
```markdown
# Research Phase

## Topic
{{TOPIC}}

## Research Questions
1. {{QUESTION_1}}
2. {{QUESTION_2}}
3. {{QUESTION_3}}

## Available Sources
<sources>
{{SOURCE_MATERIALS}}
</sources>

## Output

In <findings> tags, provide:
- Key facts discovered
- Relevant quotes with source attribution
- Gaps in available information
- Conflicting information (if any)
```

Step 2: Draft (receives Step 1 output)
```markdown
# Draft Phase

## Research Findings
<findings>
{{STEP_1_OUTPUT}}
</findings>

## Report Requirements
- Length: {{LENGTH}}
- Format: {{FORMAT}}
- Sections: {{REQUIRED_SECTIONS}}

## Output

In <draft> tags, create a complete report incorporating the findings.
Mark any areas needing verification with [VERIFY].
```

Step 3: Review (receives Step 2 output)
```markdown
# Review Phase

## Draft Report
<draft>
{{STEP_2_OUTPUT}}
</draft>

## Review Checklist
- [ ] All findings incorporated
- [ ] [VERIFY] items resolved or flagged
- [ ] Logical flow
- [ ] Clear conclusions
- [ ] Actionable recommendations

## Output

Provide the final report with all issues resolved.
List any remaining concerns that require human review.
```

### Problem-Solution-Implementation Chain

Step 1: Problem Analysis
```markdown
# Problem Analysis

## Problem Statement
{{PROBLEM}}

## Context
{{CONTEXT}}

## Output

In <analysis> tags, provide:
- Root cause identification
- Impact assessment
- Constraints to consider
- Success criteria
```

Step 2: Solution Design (receives Step 1 output)
```markdown
# Solution Design

## Problem Analysis
<analysis>
{{STEP_1_OUTPUT}}
</analysis>

## Output

In <solutions> tags, provide:
- 2-3 viable solution approaches
- Pros/cons for each
- Resource requirements
- Recommended approach with justification
```

Step 3: Implementation Plan (receives Step 2 output)
```markdown
# Implementation Planning

## Solutions Analysis
<solutions>
{{STEP_2_OUTPUT}}
</solutions>

## Output

For the recommended solution, provide:
- Detailed implementation steps
- Dependencies and prerequisites
- Risk mitigation strategies
- Success metrics
- Rollback plan
```

---

## Specialized Patterns

### Customer Feedback Analysis Pattern

```markdown
# Feedback Analysis

## Feedback Data
<feedback>
{{FEEDBACK_MESSAGES}}
</feedback>

## Analysis Requirements

Categorize each feedback item:
- Category: {{CATEGORY_OPTIONS}}
- Sentiment: Positive / Neutral / Negative
- Priority: High / Medium / Low
- Action Required: Yes / No

## Output Format

For each feedback item:
```
Feedback: [Original text]
Category: [Category]
Sentiment: [Sentiment]
Priority: [Priority]
Action: [Required action if any]
---
```

## Summary
[Aggregate insights and patterns]
```

### API Design Pattern

```markdown
# API Endpoint Design

## Purpose
{{ENDPOINT_PURPOSE}}

## Resource
{{RESOURCE_NAME}}

## Operations Needed
{{CRUD_OPERATIONS}}

## Design Constraints
- Style: REST / GraphQL
- Authentication: {{AUTH_METHOD}}
- Rate limiting: {{RATE_LIMITS}}

## Output

For each endpoint:
- Method and path
- Request parameters/body
- Response format
- Error responses
- Example request/response

Follow {{STYLE}} best practices and naming conventions.
```

### Test Case Generation Pattern

```markdown
# Test Case Generation

## Code/Feature to Test
<subject>
{{CODE_OR_FEATURE}}
</subject>

## Test Requirements
- Framework: {{TEST_FRAMEWORK}}
- Coverage: {{COVERAGE_REQUIREMENTS}}
- Types: Unit / Integration / E2E

## Output

Generate test cases covering:
1. Happy path scenarios
2. Edge cases
3. Error conditions
4. Boundary values

For each test:
- Test name (descriptive)
- Setup/preconditions
- Test steps
- Expected outcome
- Cleanup (if needed)
```

---

## Pattern Customization

### Adding Domain Context

Enhance any pattern by adding domain-specific context:

```markdown
## Domain Context
<domain>
Industry: {{INDUSTRY}}
Terminology: {{KEY_TERMS}}
Constraints: {{REGULATORY_OR_BUSINESS_CONSTRAINTS}}
Standards: {{APPLICABLE_STANDARDS}}
</domain>
```

### Adding Examples

Make patterns more precise with examples:

```markdown
## Examples
<examples>
<example>
<input>{{EXAMPLE_INPUT}}</input>
<output>{{EXPECTED_OUTPUT}}</output>
</example>
</examples>
```

### Adding Quality Gates

For critical outputs, add verification:

```markdown
## Quality Verification

Before providing output, verify:
- [ ] All requirements addressed
- [ ] Format matches specification
- [ ] No assumptions made without documentation
- [ ] Edge cases considered

If any verification fails, note the issue before the output.
```
