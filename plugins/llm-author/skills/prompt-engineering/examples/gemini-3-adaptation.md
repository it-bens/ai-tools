# Gemini 3 Prompt Adaptation Examples

## Purpose

Before/after examples showing how to transform Claude 4 prompts for Gemini 3 to achieve quality parity.

## Best Used For

- Converting existing Claude prompts to work with Gemini 3
- Understanding Gemini 3's instruction processing differences
- Building new prompts optimized for Gemini 3

---

## Example 1: Code Review Assistant

### Claude 4 Prompt (produces terse output on Gemini 3)

```markdown
You are a code review assistant. Review this code for issues related to
security, performance, and readability. Provide helpful feedback with
specific suggestions for improvement.

<code>
{{code_to_review}}
</code>
```

### Gemini 3 Adapted Prompt

```markdown
<code>
{{code_to_review}}
</code>

Based on the code above, provide a detailed code review covering security,
performance, and readability.

For EACH issue found, include:
1. The specific line or section affected
2. Why it's problematic
3. A concrete code fix

<examples>
<example>
Issue found: SQL injection vulnerability at line 15
Problem: User input is concatenated directly into SQL query
Fix:
```python
# Before
query = f"SELECT * FROM users WHERE id = {user_id}"
# After
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```
</example>
</examples>

Provide a comprehensive review with at least 3 findings. Do not summarize briefly.

CONSTRAINTS:
- Reference specific line numbers
- Include code examples for every fix
- Categorize each issue as [CRITICAL], [IMPORTANT], or [SUGGESTION]
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Moved code before instructions | Long context: instructions after data for better adherence |
| Added "detailed" and "comprehensive" | Gemini defaults to minimal output |
| Added few-shot example | Gemini strongly benefits from examples |
| Added constraints at end | Better adherence when constraints follow main content |
| Specified minimum findings | Prevents terse single-issue responses |

---

## Example 2: Document Summarization

### Claude 4 Prompt

```markdown
Summarize the following technical document. Focus on:
- Key architectural decisions
- Trade-offs discussed
- Recommended next steps

Keep the summary under 500 words.

<document>
{{long_technical_document}}
</document>
```

### Gemini 3 Adapted Prompt

```markdown
<document>
{{long_technical_document}}
</document>

Based on the technical document above, create a comprehensive summary.

Structure your summary as follows:

## Key Architectural Decisions
[List each decision with a brief rationale]

## Trade-offs Discussed
[For each trade-off, explain both sides and the conclusion reached]

## Recommended Next Steps
[Numbered list of actionable items from the document]

<example>
## Key Architectural Decisions
1. **Microservices over monolith**: Chosen for independent scaling of high-traffic services
2. **PostgreSQL for primary data**: Selected for ACID compliance and JSON support

## Trade-offs Discussed
- **Consistency vs Availability**: Chose strong consistency for financial data, eventual consistency for analytics
- **Build vs Buy**: Custom auth system for regulatory compliance despite higher maintenance cost

## Recommended Next Steps
1. Complete POC for message queue integration by Q2
2. Conduct load testing with projected 2025 traffic volumes
3. Document API contracts for all inter-service communication
</example>

Provide thorough coverage of each section. Include specific details from the document, not generic summaries.

CONSTRAINTS:
- Maximum 500 words total
- Must reference specific sections or quotes from the document
- Do not include information not present in the document
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Document placed first | Instructions after long content for better following |
| Added structural template | Explicit format improves compliance |
| Added complete example | Shows expected depth and format |
| "Comprehensive" and "thorough" added | Counters minimal output tendency |
| Constraints moved to end | Stronger adherence at prompt end |

---

## Example 3: Error Diagnosis with Screenshot

### Claude 4 Prompt

```markdown
I'm attaching a screenshot of an error. Also, here are the relevant logs:

<logs>
{{error_logs}}
</logs>

Please diagnose the issue and suggest a fix.
```

### Gemini 3 Adapted Prompt

```markdown
I'm providing two inputs for diagnosis:
1. IMAGE: A screenshot showing the error state
2. TEXT: The relevant application logs

[Attached: error_screenshot.png]

<logs>
{{error_logs}}
</logs>

Using BOTH the screenshot AND the logs above, diagnose this issue.

Your analysis must:
- From the IMAGE: Identify the error message, affected component, and UI state
- From the LOGS: Find the corresponding error trace and timestamp
- SYNTHESIZE both to determine root cause

<example>
## Error Identification
- Screenshot shows: "Connection refused" dialog in the API Settings panel
- Logs show: `ConnectionError: ECONNREFUSED 127.0.0.1:5432` at 14:23:07

## Root Cause
The PostgreSQL database service is not running. The application attempted to connect on the default port (5432) but the service was unavailable.

## Recommended Fix
1. Check if PostgreSQL is running: `sudo systemctl status postgresql`
2. If stopped, start it: `sudo systemctl start postgresql`
3. If port conflict, verify port in `postgresql.conf` matches application config
</example>

Provide a detailed diagnosis with specific references to both the screenshot and logs.

VERIFICATION:
- Did you reference specific content from the screenshot?
- Did you cite specific log entries with timestamps?
- Is your diagnosis consistent with both sources?
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Explicitly numbered inputs | Multimodal: reference each modality clearly |
| "Using BOTH" instruction | Forces consideration of all inputs |
| Separated analysis by source | Prevents ignoring one input |
| Added complete example | Shows expected synthesis depth |
| Added verification block | Gemini benefits from self-checking |

---

## Example 4: Agentic Task Decomposition

### Claude 4 Prompt

```markdown
You are a research assistant with access to web search and file operations.

Help me research the current state of WebAssembly adoption and create a summary report.
```

### Gemini 3 Adapted Prompt

```markdown
You are a research assistant with access to:
- web_search: Search for current information
- read_file: Read local documentation
- write_file: Save findings

TASK: Research WebAssembly adoption and create a summary report.

DECOMPOSITION APPROACH:
1. Break this task into discrete research subtasks
2. Execute ONE tool call per step
3. After each result, evaluate what's learned before proceeding
4. Synthesize findings after all research is complete

EXECUTION PLAN:
Step 1: Search for "WebAssembly adoption 2024 statistics"
Step 2: Search for "WebAssembly use cases production 2024"
Step 3: Search for "WebAssembly vs JavaScript performance benchmarks"
Step 4: Read any relevant local docs if available
Step 5: Synthesize into report

HANDLING ISSUES:
- If search returns outdated info: try alternative query
- If search fails: note and continue with other sources
- If conflicting data found: note both with sources

REPORT FORMAT:
## WebAssembly Adoption Report

### Current Adoption Metrics
[Statistics with sources]

### Key Use Cases
[Real production examples]

### Performance Considerations
[Benchmark data]

### Conclusions
[Synthesis of findings]

Begin with Step 1. Report your findings after each step before proceeding.
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Explicit tool listing | Gemini benefits from clear capability scope |
| Decomposition instructions | Agentic: explicit task breakdown |
| Step-by-step plan | Reduces skipped steps |
| Error handling block | Agentic: explicit retry/fallback patterns |
| "Report after each step" | Ensures visibility into progress |

---

## Reusable Adaptation Patterns

### Pattern: Post-Context Instructions

Use at the start of any prompt with long data:

```markdown
<data>
{{long_content}}
</data>

Based on the data above, [instruction].
```

### Pattern: Verbosity Request

Add when detailed output is needed:

```markdown
Provide a detailed, comprehensive response that includes:
- Specific examples
- Step-by-step reasoning
- Edge cases

Do not summarize briefly. Expand on each point.
```

### Pattern: Few-Shot Template

Add before the actual task:

```markdown
<examples>
<example>
Input: [sample]
Output: [expected format]
</example>
</examples>

Now process:
Input: {{actual_input}}
Output:
```

### Pattern: Self-Verification Block

Add at prompt end:

```markdown
VERIFICATION (complete before responding):
- Does the response address all parts of the question?
- Are all claims supported by the input data?
- Does the format match the template?
```

### Pattern: Constraint Footer

Always place constraints last:

```markdown
CONSTRAINTS:
- [Constraint 1]
- [Constraint 2]
- [Constraint 3]
```

---

## API Configuration Template

Include with Gemini 3 prompts when providing API usage guidance:

```python
import google.generativeai as genai

genai.configure(api_key="YOUR_API_KEY")

# For most tasks
model = genai.GenerativeModel(
    "gemini-2.0-flash",  # Or "gemini-2.0-pro" for complex reasoning
    system_instruction=system_prompt
)

response = model.generate_content(
    user_prompt,
    generation_config=genai.GenerationConfig(
        temperature=1.0,      # Always keep at 1.0
        top_p=0.95,
        top_k=40,
        max_output_tokens=8192
    )
)

# For structured JSON output
response = model.generate_content(
    prompt,
    generation_config=genai.GenerationConfig(
        temperature=1.0,
        response_mime_type="application/json",
        response_schema=your_schema
    )
)
```

---

## Testing Guide

After adapting a prompt for Gemini 3:

1. **Test output verbosity** - Verify response includes requested detail, not just summaries
2. **Test format compliance** - Confirm output matches the template/examples provided
3. **Test with long context** - Verify instructions after data are followed
4. **Test multimodal** - Confirm all input types are referenced (if applicable)
5. **Compare with Claude** - Run same input through both models to verify parity
