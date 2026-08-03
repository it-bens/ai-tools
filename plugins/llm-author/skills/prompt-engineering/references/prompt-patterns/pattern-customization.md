# Pattern Customization

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
