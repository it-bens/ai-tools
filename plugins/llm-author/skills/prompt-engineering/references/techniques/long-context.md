# Long Context Tips

When working with large documents or extended conversations:

### Document Placement
- Place long documents at the beginning of the prompt
- Put instructions and questions after the document
- Use XML tags to clearly delineate document boundaries

### Retrieval Strategy
```xml
<document>
{{LONG_DOCUMENT}}
</document>

Find and quote the sections most relevant to answering: {{QUESTION}}
Then provide your analysis based only on those quoted sections.
```

### Context Management
- Summarize earlier conversation sections for very long chats
- Use explicit references to earlier content
- Consider chunking extremely long documents
