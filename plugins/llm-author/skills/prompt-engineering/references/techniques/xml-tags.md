# XML Tags for Structure

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
