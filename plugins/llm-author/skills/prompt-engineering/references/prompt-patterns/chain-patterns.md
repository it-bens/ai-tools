# Chain Patterns

## Research-to-Report Chain

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

## Problem-Solution-Implementation Chain

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
