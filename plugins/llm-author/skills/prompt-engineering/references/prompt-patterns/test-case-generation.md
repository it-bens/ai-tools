# Test Case Generation Pattern

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
