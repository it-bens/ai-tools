# Gemini Deep Research Prompt Guide

Specialized prompting for Gemini's Deep Research feature—an agentic AI that autonomously conducts multi-step research over extended periods (5-60 minutes).

## When This Guide Applies

Use this guide when the user's request involves:
- Explicit mention of "deep research" or "Gemini Deep Research"
- Requests for comprehensive literature reviews with citations
- Multi-source research synthesis requiring extended investigation
- Tasks needing autonomous web research and report generation

For standard Gemini prompts (interactive, immediate response), use `gemini-3-guide.md` instead.

## Critical Limitations

Account for these when crafting prompts and output notes:
- **Citation accuracy ~90%** — include verification reminders in output
- **Paywalled content inaccessible** — note if academic databases required
- **Complex prompts increase hallucination** — match complexity to accuracy needs
- **Non-English quality degradation** — prefer English for critical research

## Core Principles

### 1. Explicit Scope Definition

Every prompt must define clear boundaries. Without them, results are unfocused and hallucination-prone.

**Required boundaries:**
- Topic scope (what's included, what's excluded)
- Geographic constraints (if relevant)
- Domain/field limitations
- Depth expectation (overview vs. comprehensive vs. technical)

```
❌ "Research machine learning in healthcare"

✓ "Research transformer-based ML models in medical diagnosis.
   Focus on peer-reviewed publications from 2022-2024.
   Exclude radiology computer vision (covered elsewhere).
   Focus on clinical validation studies, not technical benchmarks."
```

### 2. Temporal Constraint Specification

Always include explicit date boundaries. Without them, Deep Research mixes outdated information with current findings and may cite non-existent future works.

**Effective patterns:**
- `"Focus on research published between January 2023 and December 2024"`
- `"Ensure only papers published before [date] are referenced"`
- `"If 2025 data unavailable, explicitly state this rather than estimating"`

### 3. Output Format Specification

Deep Research follows structural instructions well. Specify:
- Report structure (sections, subsections)
- Citation format with examples
- Deliverable type (narrative, comparison table, timeline)

```
"Format citations in APA 7th. In-text: (Author, Year).
Reference list with DOI where available.

Structure: Executive Summary, Methodology Overview,
Key Findings by Theme, Limitations, Conclusion."
```

### 4. Source Quality Direction

Without guidance, SEO-optimized content may outrank authoritative sources.

**For academic research:**
```
"Prioritize peer-reviewed publications from PubMed-indexed journals.
Focus on venues: ACL, NeurIPS, ICML, ICLR.
Exclude blog posts and opinion pieces."
```

**For business/market research:**
```
"Focus on primary sources: SEC filings, official company reports.
Prefer verified news from major financial publications.
Exclude promotional content and unverified claims."
```

### 5. Handling Instructions for Unknowns

Prevent fabrication by specifying how to handle missing data:

```
"If specific data for [topic] is unavailable, explicitly state this.
When sources conflict, present both perspectives with citations.
Mark projections or estimates clearly as such.
If fewer than 5 relevant sources found, note this limitation."
```

### 6. Graduated Complexity Matching

**For high-accuracy needs** (facts, statistics, critical citations):
- Use simpler, direct prompts
- Request specific, verifiable information
- Avoid hypothetical scenarios

**For exploration and synthesis** (understanding landscape, comparing approaches):
- Use detailed prompts with specific sub-questions
- Accept need for verification
- Plan follow-up questions for drilling down

## Prompt Structure Template

```
[RESEARCH OBJECTIVE]
Clear statement of what you want to know

[SCOPE DEFINITION]
- Topic boundaries: Include X, Y; exclude Z
- Geographic/domain constraints (if relevant)
- Depth: overview / comprehensive / technical

[TEMPORAL CONSTRAINTS]
- "Publications from [START] to [END]"
- "If [YEAR] data unavailable, note most recent date"

[SOURCE PREFERENCES]
- Type: peer-reviewed / official / primary
- Venues/publications to prioritize
- Sources to exclude

[OUTPUT FORMAT]
- Structure: sections or deliverable type
- Citation style: [STYLE]. Example: [EXAMPLE]
- Length guidance (approximate, not exact word count)

[HANDLING INSTRUCTIONS]
- How to handle unknowns: "State explicitly if unavailable"
- How to handle conflicts: "Present both perspectives"
- Uncertainty markers: "Flag findings from single sources"
```

## Research Type Templates

### Academic Literature Review

```
I need a scholarly review on [TOPIC]. Focus on:

1. [Direction 1]: [Brief scope]
2. [Direction 2]: [Brief scope]
3. [Direction 3]: [Brief scope]

Constraints:
- Only papers published before [DATE]
- Focus on [VENUES/FIELDS]
- [Geographic/domain limits if any]

Output:
- Format citations in [STYLE] with examples
- Structure as academic survey with sections
- Include summary and open research questions

If data unavailable, state explicitly rather than estimating.
```

### Technical Comparison

```
Compare [A] vs [B] vs [C] for [USE CASE].

Evaluation criteria:
- [Criterion 1]
- [Criterion 2]
- [Criterion 3]

Research parameters:
- Focus on empirical evaluations, not marketing
- Sources from [VENUES/TIMEFRAME]
- Include only approaches with published results

Output:
- Comparison table with ratings per dimension
- Detailed analysis for each criterion
- Recommendation with caveats
- All claims must be cited

When direct comparison impossible, explain why.
```

### Market/Industry Analysis

```
Analyze [MARKET/INDUSTRY] focusing on [ASPECT].

Scope:
- Geographic: [REGIONS]
- Time: [DATE RANGE]
- Companies: [CRITERIA]

Key questions:
1. [Market size/dynamics question]
2. [Key players question]
3. [Trends/future question]

Sources:
- Prioritize official filings, industry reports
- Exclude opinion pieces and unverified claims

Output:
- Executive summary (3-4 paragraphs)
- Detailed sections per question
- Data tables with source and date for all statistics

If current-year data unavailable, use most recent and note date.
```

### Quick Exploratory Query

```
I want to understand [TOPIC].

Key questions:
- What are the main approaches/perspectives?
- What are current limitations or debates?
- What recent developments (past 2 years) are significant?

Keep scope focused on [CONSTRAINT].
I can ask follow-up questions to dive deeper.
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Unconstrained scope | Unfocused, noisy output | Define topic, time, source boundaries |
| Implicit temporal ("recent") | ~47% date hallucination rate | Use explicit date ranges |
| Over-complex single prompts | Higher hallucination rate | Start focused, use follow-ups |
| Exact word count requests | LLMs process tokens, not words | Use approximate length guidance |
| No source guidance | SEO content outranks authoritative sources | Specify source types and venues |
| Trusting URLs without verification | URL fabrication is documented | Click through and verify citations |

## Phrases That Work

**Scope definition:**
- "Focus exclusively on..."
- "Limit analysis to..."
- "Exclude from consideration..."

**Temporal constraints:**
- "Ensure only papers published before [date] are referenced"
- "If [year] data is unavailable, explicitly state this"

**Source quality:**
- "Prioritize peer-reviewed sources from..."
- "Exclude [blogs/opinions/marketing materials]"

**Handling uncertainty:**
- "If specific data is unavailable, state this rather than estimating"
- "When sources conflict, present both positions with evidence"

## Iteration Note

Deep Research supports plan editing before execution and follow-up questions after. Include iteration suggestions in output when the research topic has natural drill-down paths.
