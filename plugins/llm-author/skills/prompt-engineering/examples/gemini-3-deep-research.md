# Gemini Deep Research Prompt Examples

## Purpose

Ready-to-adapt templates for Gemini Deep Research prompts across common research types.

## Best Used For

- Creating prompts for Gemini's autonomous Deep Research feature
- Academic literature reviews with proper citations
- Market and industry analysis requiring multi-source synthesis
- Technical comparisons with empirical data
- Any research task requiring extended autonomous investigation

---

## Example 1: Academic Literature Review

### Weak Prompt (produces unfocused, hallucination-prone output)

```markdown
Research machine learning in healthcare and write a literature review.
```

### Deep Research Optimized Prompt

```markdown
I need a scholarly review on transformer-based machine learning models for medical diagnosis.

Focus on these research directions:
1. Clinical validation studies: Real-world performance in diagnostic settings
2. Regulatory pathways: FDA/CE approval processes for AI diagnostics
3. Integration challenges: EMR integration, clinician adoption barriers

Constraints:
- Only papers published between January 2022 and December 2024
- Focus on peer-reviewed publications from Nature Medicine, JAMA, Lancet Digital Health, and npj Digital Medicine
- Exclude radiology/imaging applications (covered elsewhere)
- Focus on clinical validation, not purely technical benchmarks

Output requirements:
- Format citations in APA 7th. In-text: (Author, Year). Reference list with DOI where available.
- Structure as academic survey: Introduction, Methods Overview, Findings by Direction, Limitations, Future Directions
- Include a summary table of key studies with sample sizes and performance metrics

Handling uncertainty:
- If specific approval statistics unavailable, state explicitly rather than estimating
- When studies report conflicting results, present both with methodology differences noted
- Flag any findings based on single studies or preprints
```

### Why This Works

| Element | Purpose |
|---------|---------|
| Three specific directions | Prevents scope creep and unfocused research |
| Explicit date range | Prevents ~47% date hallucination rate |
| Named venues | Ensures authoritative sources over SEO content |
| Explicit exclusions | Focuses research effort |
| Citation format with example | Ensures parseable, consistent citations |
| Handling instructions | Reduces fabrication when data is missing |

---

## Example 2: Technical Comparison

### Weak Prompt

```markdown
Compare different vector databases for my AI application.
```

### Deep Research Optimized Prompt

```markdown
Compare Pinecone, Weaviate, Milvus, and Qdrant for production RAG applications.

Evaluation criteria:
1. Query performance: Latency at 1M, 10M, and 100M vector scales
2. Operational complexity: Self-hosted vs managed, maintenance requirements
3. Cost efficiency: Pricing models, hidden costs at scale
4. Integration ecosystem: LangChain, LlamaIndex, major cloud providers

Research parameters:
- Focus on benchmarks from 2023-2024 with documented methodology
- Prioritize official documentation, peer-reviewed comparisons, and verified engineering blogs
- Exclude vendor marketing materials and unverified claims
- Include only approaches with published benchmark results

Output format:
- Comparison matrix with scores (1-5) for each criterion
- Detailed analysis section for each database (500-700 words each)
- Recommendation matrix by use case (startup, enterprise, research)
- All performance claims must cite source with date

Handling gaps:
- When direct comparison data unavailable, explain methodology differences
- If pricing has changed recently, note the date of pricing information
- For conflicting benchmarks, present both with testing conditions
```

### Why This Works

| Element | Purpose |
|---------|---------|
| Named competitors | Bounds the research scope |
| Quantified criteria | Enables objective comparison |
| Source exclusions | Filters out marketing bias |
| Structured output | Ensures actionable deliverable |
| Use case matrix | Provides decision-ready output |

---

## Example 3: Market Analysis

### Weak Prompt

```markdown
What's happening in the AI code assistant market?
```

### Deep Research Optimized Prompt

```markdown
Analyze the enterprise AI code assistant market for Fortune 500 adoption decisions.

Scope:
- Geographic focus: North America and Western Europe
- Time period: Q1 2024 through Q4 2024
- Companies: GitHub Copilot, Amazon CodeWhisperer, Cursor, Codeium, Tabnine
- Customer segment: Enterprise (1000+ developers)

Research questions:
1. Market sizing: Current TAM/SAM and growth projections
2. Feature comparison: Security, compliance, on-premise deployment options
3. Adoption barriers: What's blocking enterprise rollout?
4. Pricing structures: Per-seat, usage-based, enterprise agreements

Source preferences:
- Prioritize Gartner, Forrester, IDC reports where available
- SEC filings and official company announcements for factual data
- Verified enterprise case studies with named customers
- Exclude promotional content, unverified user testimonials

Output structure:
- Executive summary (3 paragraphs max)
- Market size table with source and date for each figure
- Feature comparison matrix
- Enterprise adoption case studies (minimum 3)
- Recommendation framework for evaluation

Data handling:
- If Q4 2024 data unavailable, use most recent and note the quarter
- For pricing, note if figures are list price vs negotiated enterprise rates
- Mark any projections clearly distinct from historical data
```

### Why This Works

| Element | Purpose |
|---------|---------|
| Decision context stated | Shapes research depth and focus |
| Geographic/temporal bounds | Ensures relevant, current data |
| Named competitors | Prevents scope expansion |
| Source hierarchy | Prioritizes authoritative over SEO content |
| Data freshness instructions | Prevents outdated statistics |

---

## Example 4: Quick Exploratory Query

### Weak Prompt

```markdown
Tell me about WebAssembly.
```

### Deep Research Optimized Prompt

```markdown
I want to understand the current state of WebAssembly for server-side applications.

Key questions:
- What are the main runtime options (Wasmtime, Wasmer, WasmEdge) and their trade-offs?
- What production use cases exist beyond edge computing?
- What are the current limitations blocking broader adoption?
- What developments in the past 18 months are most significant?

Keep scope focused on server-side/backend use cases. Exclude browser-based WebAssembly.

I'll use follow-up questions to dive deeper into specific runtimes or use cases.

Cite sources for any specific performance claims or adoption statistics.
```

### Why This Works

| Element | Purpose |
|---------|---------|
| Focused scope (server-side) | Prevents broad, shallow coverage |
| Specific questions | Guides research direction |
| Explicit exclusions | Avoids irrelevant browser content |
| Follow-up expectation | Sets stage for iterative refinement |
| Citation requirement | Ensures verifiable claims |

---

## Output Delivery Template

When delivering Deep Research prompts, include:

```markdown
## Deep Research Notes

- Execution time: 5-20 minutes typical (up to 60 for complex topics)
- Review the research plan before execution and adjust scope as needed
- Verify citations—approximately 10% may contain errors
- Use the "Edit plan" option to add directions or remove tangents

## Iteration Suggestions

- [Follow-up to expand specific section]
- [Follow-up to drill into a finding]
- [Follow-up to compare alternatives]
```

---

## Anti-Pattern Reference

| Don't | Do Instead |
|-------|------------|
| "Research AI trends" | "Research transformer architectures for time-series forecasting, 2023-2024" |
| "What's the latest on..." | "Focus on developments from January 2024 to present" |
| "Write exactly 1000 words" | "Provide comprehensive analysis (approximately 5-7 pages)" |
| No source guidance | "Prioritize peer-reviewed sources from [venues]" |
| Trust all URLs | Include verification reminder in output notes |
