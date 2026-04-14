# Prompt Optimization Report Template

## Purpose
Document prompt improvements with clear before/after comparisons and rationale.

## Best Used For
- Tracking prompt iteration history
- Documenting optimization decisions
- Creating reproducible prompt improvement processes
- Sharing prompt engineering learnings

---

## Report Structure

# Prompt Optimization Report

**Prompt Name**: [Identifier for the prompt]
**Date**: [Date of optimization]
**Version**: [Before] → [After]

---

## Executive Summary

[2-3 sentences describing the optimization goal and outcome]

**Key Improvement**: [Primary metric improved]
**Technique Applied**: [Main technique used]

---

## Original Prompt

```markdown
[Complete original prompt]
```

### Original Performance
| Metric | Value |
|--------|-------|
| Success Rate | [X%] |
| Consistency | [Low/Medium/High] |
| Output Quality | [1-5 rating] |
| Common Issues | [Brief list] |

---

## Issue Analysis

### Problems Identified

1. **[Issue Category 1]**: [Description]
   - Symptom: [What went wrong]
   - Frequency: [How often]
   - Impact: [Severity]

2. **[Issue Category 2]**: [Description]
   - Symptom: [What went wrong]
   - Frequency: [How often]
   - Impact: [Severity]

### Root Causes

- [Root cause 1 with explanation]
- [Root cause 2 with explanation]

---

## Optimization Strategy

### Techniques Applied

1. **[Technique Name]**
   - Purpose: [What it addresses]
   - Implementation: [How it was applied]
   - Reference: [Documentation link if applicable]

2. **[Technique Name]**
   - Purpose: [What it addresses]
   - Implementation: [How it was applied]

### Changes Made

| Section | Original | Optimized | Rationale |
|---------|----------|-----------|-----------|
| [Section] | [Before] | [After] | [Why] |
| [Section] | [Before] | [After] | [Why] |

---

## Optimized Prompt

```markdown
[Complete optimized prompt]
```

### Key Improvements Highlighted

1. **[Change 1]**: [Explanation of improvement]
2. **[Change 2]**: [Explanation of improvement]
3. **[Change 3]**: [Explanation of improvement]

---

## Results

### Performance Comparison

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Success Rate | [X%] | [Y%] | [+Z%] |
| Consistency | [Rating] | [Rating] | [Change] |
| Output Quality | [1-5] | [1-5] | [+/-] |
| Issue Occurrence | [Freq] | [Freq] | [Change] |

### Test Cases

**Test 1**: [Description]
- Before: [Result]
- After: [Result]
- ✅/❌ Improvement

**Test 2**: [Description]
- Before: [Result]
- After: [Result]
- ✅/❌ Improvement

---

## Recommendations

### For This Prompt
- [Ongoing monitoring recommendation]
- [Potential further improvements]

### General Learnings
- [Transferable insight 1]
- [Transferable insight 2]

---

## Example: Customer Feedback Analyzer Optimization

# Prompt Optimization Report

**Prompt Name**: Customer Feedback Analyzer
**Date**: 2025-01-15
**Version**: 1.0 → 2.0

---

## Executive Summary

The original prompt inconsistently categorized feedback and often missed multi-category items. By adding structured examples and explicit multi-category instructions, accuracy improved from 72% to 94%.

**Key Improvement**: Multi-category detection accuracy +31%
**Technique Applied**: Multishot prompting with diverse examples

---

## Original Prompt

```markdown
Analyze this customer feedback and categorize the issues. Use these
categories: UI/UX, Performance, Feature Request, Integration, Pricing,
and Other. Also rate the sentiment (Positive/Neutral/Negative) and
priority (High/Medium/Low).

Here is the feedback: {{FEEDBACK}}
```

### Original Performance
| Metric | Value |
|--------|-------|
| Success Rate | 72% |
| Consistency | Low |
| Output Quality | 2/5 |
| Common Issues | Missed multi-category, inconsistent format |

---

## Issue Analysis

### Problems Identified

1. **Single Category Bias**: Prompt only assigned one category even when feedback mentioned multiple issues
   - Symptom: "Dashboard is slow and ugly" only tagged as Performance
   - Frequency: 40% of multi-issue feedback
   - Impact: High - missing actionable insights

2. **Inconsistent Output Format**: No specified structure led to varying formats
   - Symptom: Sometimes prose, sometimes lists, sometimes tables
   - Frequency: Every response varied
   - Impact: Medium - difficult to parse programmatically

3. **Missing Explanations**: No rationale for categorization decisions
   - Symptom: Couldn't understand why certain choices were made
   - Frequency: Always
   - Impact: Low - but helpful for review

### Root Causes

- No examples showing multi-category handling
- No explicit format specification
- Vague instructions ("categorize the issues")

---

## Optimization Strategy

### Techniques Applied

1. **Multishot Prompting**
   - Purpose: Demonstrate exact output format and multi-category handling
   - Implementation: Added 3 diverse examples including multi-category case

2. **XML Structure**
   - Purpose: Enforce consistent, parseable output
   - Implementation: Specified output format with tags

3. **Explicit Instructions**
   - Purpose: Remove ambiguity about multi-category handling
   - Implementation: Added "Items may belong to multiple categories"

### Changes Made

| Section | Original | Optimized | Rationale |
|---------|----------|-----------|-----------|
| Categories | Implied single | Explicit multi-category allowed | Multi-issue feedback common |
| Examples | None | 3 diverse examples | Format demonstration |
| Output | Unspecified | XML structured | Parseability |
| Context | None | Business context added | Appropriate prioritization |

---

## Optimized Prompt

```markdown
Our CS team is overwhelmed with unstructured feedback. Your task is
to analyze feedback and categorize issues for our product and
engineering teams.

Categories: UI/UX, Performance, Feature Request, Integration, Pricing, Other
Items may belong to MULTIPLE categories when appropriate.

Sentiment: Positive / Neutral / Negative
Priority: High (blocks usage) / Medium (impacts experience) / Low (minor)

<examples>
<example>
Input: The new dashboard is a mess! It takes forever to load, and I
can't find the export button. Fix this ASAP!
Category: UI/UX, Performance
Sentiment: Negative
Priority: High
</example>
<example>
Input: Love the Salesforce integration! Would be great to add Hubspot.
Category: Integration, Feature Request
Sentiment: Positive
Priority: Medium
</example>
<example>
Input: Overall satisfied with the product. Support team is helpful.
Category: Other (Customer Support)
Sentiment: Positive
Priority: Low
</example>
</examples>

Now analyze this feedback:
<feedback>
{{FEEDBACK}}
</feedback>

Output format:
<analysis>
<item>
<input>[Original feedback]</input>
<category>[Category or categories]</category>
<sentiment>[Sentiment]</sentiment>
<priority>[Priority]</priority>
</item>
</analysis>
```

---

## Results

### Performance Comparison

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Success Rate | 72% | 94% | +22% |
| Multi-category Accuracy | 63% | 94% | +31% |
| Format Consistency | Low | High | ✓ |
| Output Quality | 2/5 | 4.5/5 | +2.5 |

### Test Cases

**Test 1**: "Dashboard slow and confusing"
- Before: Performance only
- After: Performance, UI/UX ✅

**Test 2**: "Love the API, hate the pricing"
- Before: Pricing only
- After: Integration (Positive), Pricing (Negative) ✅

---

## Recommendations

### For This Prompt
- Monitor for new category needs as product evolves
- Consider adding "Billing" category separate from "Pricing"

### General Learnings
- Always include multi-value examples when lists can have multiple items
- Explicit output format eliminates parsing issues
- Business context helps appropriate prioritization
