# Use Examples (Multishot Prompting)

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
