# Code Generation Pattern

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
