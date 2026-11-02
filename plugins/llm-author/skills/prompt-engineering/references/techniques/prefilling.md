# Prefilling (API Only)

**Claude 4 and earlier only.** On Claude 5 models (Opus 5.5, Sonnet 5.5, Haiku 5.5, Fable 5.1; legacy Opus 5, Sonnet 5, Fable 5), prefilling the assistant message returns a 400 error. Use Structured Outputs, `output_config.format`, or a direct "respond without preamble" system instruction instead. See `claude-5-guide.md#breaking-changes-api-errors-on-claude-5`.

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
