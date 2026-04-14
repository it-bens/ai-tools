# Prompt Chain Template

## Purpose
Multi-step workflow template for complex tasks requiring sequential processing.

## Best Used For
- Research-to-report workflows
- Content creation pipelines
- Analysis and recommendation processes
- Any task where output from one step feeds the next

## Chain Overview

### Step 1: [PHASE NAME - e.g., "Research"]

**Purpose**: [What this step accomplishes]

**Input**: [What information/context is provided]

**Prompt**:
```markdown
# [Phase Name]

## Context
<context>
{{INPUT_DATA_OR_REQUIREMENTS}}
</context>

## Task
[Clear description of what to accomplish in this step]

## Process
1. [First action]
2. [Second action]
3. [Third action]

## Output Requirements
Provide your output in <[output_tag]> tags with the following structure:
- [Required element 1]
- [Required element 2]
- [Required element 3]

## Quality Criteria
- [Criterion 1]
- [Criterion 2]
```

**Output**: Structured data in `<[output_tag]>` tags for next step

---

### Step 2: [PHASE NAME - e.g., "Draft"]

**Purpose**: [What this step accomplishes]

**Input**: Output from Step 1

**Prompt**:
```markdown
# [Phase Name]

## Previous Step Output
<previous_output>
{{STEP_1_OUTPUT}}
</previous_output>

## Task
Using the above [research/analysis/data], [create/generate/produce] [output type].

## Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

## Format
[Specify exact format expected]

## Output
Provide the [output type] in <[output_tag]> tags.
Mark any areas requiring verification with [VERIFY].
```

**Output**: [Description of output] in `<[output_tag]>` tags

---

### Step 3: [PHASE NAME - e.g., "Review"]

**Purpose**: [What this step accomplishes]

**Input**: Output from Step 2

**Prompt**:
```markdown
# [Phase Name]

## Draft to Review
<draft>
{{STEP_2_OUTPUT}}
</draft>

## Review Checklist
- [ ] [Check 1]
- [ ] [Check 2]
- [ ] [Check 3]
- [ ] All [VERIFY] items resolved

## Task
Review the draft against the checklist. Resolve any issues and produce the final version.

## Output
1. List of issues found and how they were resolved
2. Final [output type] in <final> tags
3. Any remaining concerns requiring human review
```

**Output**: Final deliverable in `<final>` tags

---

## Integration Notes

### Manual Execution
1. Run Step 1, capture output from `<[output_tag]>` tags
2. Paste Step 1 output into Step 2 prompt at `{{STEP_1_OUTPUT}}`
3. Run Step 2, capture output
4. Paste Step 2 output into Step 3 prompt at `{{STEP_2_OUTPUT}}`
5. Run Step 3 for final output

### Validation Between Steps
Before proceeding to the next step:
- Verify output contains all required elements
- Check that output is in expected format
- Resolve any errors or gaps before continuing

### Error Handling
If a step produces unexpected output:
- Review the input to that step
- Check if previous step output was correctly formatted
- Re-run the step with clarified instructions if needed

---

## Example: Research Report Chain

### Step 1: Research

```markdown
# Research Phase

## Topic
<topic>
{{RESEARCH_TOPIC}}
</topic>

## Research Questions
1. What are the key trends in this area?
2. What are the main challenges and opportunities?
3. What do industry experts recommend?

## Available Sources
<sources>
{{SOURCE_MATERIALS}}
</sources>

## Task
Analyze the provided sources to answer the research questions.

## Output Requirements
Provide findings in <findings> tags:
- Key facts with source attribution
- Relevant statistics
- Expert opinions with attribution
- Gaps in available information
- Conflicting information (if any)
```

### Step 2: Draft Report

```markdown
# Draft Phase

## Research Findings
<findings>
{{STEP_1_FINDINGS}}
</findings>

## Report Requirements
- Length: 1500-2000 words
- Sections: Executive Summary, Key Findings, Analysis, Recommendations
- Audience: Senior leadership (non-technical)

## Task
Create a comprehensive report incorporating all findings.

## Output
Provide the draft report in <draft> tags.
Mark any claims needing verification with [VERIFY].
Mark any areas needing additional research with [RESEARCH NEEDED].
```

### Step 3: Review and Finalize

```markdown
# Review Phase

## Draft Report
<draft>
{{STEP_2_DRAFT}}
</draft>

## Original Findings
<findings>
{{STEP_1_FINDINGS}}
</findings>

## Review Checklist
- [ ] All findings accurately incorporated
- [ ] No claims without source attribution
- [ ] Executive summary reflects key points
- [ ] Recommendations are actionable
- [ ] All [VERIFY] and [RESEARCH NEEDED] items addressed
- [ ] Appropriate for senior leadership audience

## Task
1. Check draft against findings for accuracy
2. Resolve all flagged items
3. Improve clarity and flow
4. Produce final report

## Output
1. Issues found and resolutions in <review_notes> tags
2. Final report in <final_report> tags
3. Any items requiring human review in <human_review> tags
```

---

## Usage Notes
- Target model: Claude Opus 4 or Sonnet 4
- Each step should complete fully before proceeding
- Preserve exact tag names between steps for consistent parsing
- Consider adding validation prompts between steps for critical workflows

## Testing Guide
1. Run through the chain with sample data
2. Verify output tags are correctly formatted at each step
3. Check that information flows correctly between steps
4. Test with edge cases to identify failure points

## Customization Points
- **Number of steps**: Add or remove steps as needed
- **Tag names**: Use descriptive tags for your domain
- **Validation criteria**: Add step-specific quality checks
- **Error handling**: Add fallback instructions for common issues
