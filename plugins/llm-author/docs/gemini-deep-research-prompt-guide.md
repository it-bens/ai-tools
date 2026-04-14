# Gemini Deep Research Prompt Writing Guide

**A Comprehensive Reference for Crafting Effective Deep Research Prompts**

---

## Executive Summary

This guide synthesizes findings from official Google documentation, academic research on AI chatbot performance (including the Reference Hallucination Score methodology), and benchmark evaluations of Deep Research agents to provide actionable guidance for writing effective Gemini Deep Research prompts.

Three critical insights emerge from the analysis. First, **prompt specificity directly correlates with output quality**—detailed prompts with explicit scope boundaries, temporal constraints, and output format specifications significantly outperform vague or open-ended queries. Second, **citation accuracy remains a fundamental challenge** across all AI research agents, with documented error rates suggesting approximately 10% of citations may contain some form of inaccuracy; users must build verification workflows into their research process. Third, **complex or scenario-based prompts paradoxically increase hallucination risk** while potentially delivering more nuanced analysis, requiring careful balance between depth and reliability.

The guide provides structured templates, anti-patterns to avoid, and decision frameworks for different research contexts—from quick exploratory queries to comprehensive academic literature reviews. Users should expect to iterate on their prompts using Deep Research's plan editing feature and treat outputs as starting points requiring human verification rather than authoritative final products.

---

## About This Guide

### Source Documents Analyzed

| Document | Type | Key Contribution |
|----------|------|------------------|
| Gemini Deep Research Limitations & Requirements | Reference compilation | Technical specifications, access requirements, documented limitations, query optimization best practices |
| Reference Hallucination Score for Medical AI Chatbots (JMIR Medical Informatics, 2024) | Peer-reviewed research | Quantitative analysis of citation hallucination patterns, prompt structure effects on accuracy |
| ReportBench: Evaluating Deep Research Agents (ByteDance BandAI, 2025) | Benchmark study | Comparative evaluation of Deep Research agents, prompt engineering patterns, statement factuality metrics |

### Methodology

This guide was developed through:
1. **Document comprehension**: Extracting explicit statements about prompt writing and system behavior
2. **Pattern extraction**: Identifying structural, linguistic, and content patterns across successful examples
3. **Principle deduction**: Abstracting higher-level rules from observed patterns
4. **Gap analysis**: Documenting areas of uncertainty requiring further experimentation

### Confidence Levels

| Level | Definition | Evidence Basis |
|-------|------------|----------------|
| **High** | Directly stated in official documentation or confirmed across multiple independent sources | Google documentation, multiple academic papers |
| **Medium-High** | Observed consistently in benchmark evaluations or widely reported | ReportBench results, multiple user reports |
| **Medium** | Reasonable inference from available data | Single study findings, logical extension of documented behavior |
| **Low** | Logical deduction not directly supported by evidence | Theoretical considerations, isolated reports |

### How to Use This Guide

- **New users**: Start with "Understanding Gemini Deep Research" and "Core Principles" sections
- **Quick reference**: Jump to "Quick Reference" section for checklists and templates
- **Specific use cases**: Navigate to "Prompt Patterns by Research Type"
- **Troubleshooting**: Consult "Anti-Patterns and Common Mistakes"

---

## Understanding Gemini Deep Research

### What It Is

Gemini Deep Research is an agentic AI feature that autonomously executes multi-step research tasks by:
- Breaking down complex queries into research plans
- Executing dozens to hundreds of web searches
- Synthesizing information from multiple sources
- Generating comprehensive reports with citations

**Key differentiator**: Unlike standard chatbot interactions, Deep Research operates semi-autonomously over extended periods (5-20 minutes typically, up to 60 minutes maximum), conducting iterative research cycles before producing output.

### How It Works

**Technical Model** (Confidence: High)

```
User Prompt → Plan Generation → [User Review/Edit] → Iterative Research Cycles → Report Synthesis
                                                              ↓
                                                    ┌─────────────────┐
                                                    │ Per Cycle:      │
                                                    │ • Web searches  │
                                                    │ • Content fetch │
                                                    │ • Evaluation    │
                                                    │ • Synthesis     │
                                                    └─────────────────┘
```

**Processing Capacity**:

| Metric | Standard Task | Complex Task |
|--------|---------------|--------------|
| Search queries executed | ~80 | Up to ~160 |
| Input tokens processed | ~250k | ~900k |
| Output tokens generated | ~60k | ~80k |
| Typical completion time | 5-10 minutes | Up to 20 minutes |
| Maximum research time | 60 minutes (hard limit) |

**Underlying model**: Currently powered by Gemini 3 Pro (as of early 2026), evolved from Gemini 1.5 Pro at launch.

### Capabilities and Limitations

#### What Deep Research Can Do Well

| Capability | Confidence | Notes |
|------------|------------|-------|
| Broad topic exploration | High | Effective for understanding landscape of a field |
| Multi-source synthesis | High | Combines information from diverse web sources |
| Structured report generation | High | Produces organized, formatted outputs |
| Following explicit instructions | Medium-High | Responds well to specific formatting/scope requests |
| Iterative refinement via follow-ups | High | Can modify reports based on additional questions |

#### Documented Limitations

| Limitation | Confidence | Impact |
|------------|------------|--------|
| **Paywalled content inaccessible** | High | Cannot access subscription academic databases (Nature, IEEE, Elsevier) without user-provided PDFs |
| **Citation accuracy ~90%** | Medium-High | Approximately 10% of citations may have errors (wrong URL, fabricated link, misattributed content) |
| **Non-English quality degradation** | High | Google acknowledged reduced accuracy in non-English summaries |
| **Reproducibility impossible** | High | Web sources change; identical prompts may yield different results |
| **Cannot count words precisely** | High | Token-based processing prevents accurate word counting |
| **Spatial/logical puzzles fail** | High | Not designed for physical reasoning or precise counting |
| **Complex prompts increase hallucination** | Medium-High | Scenario-based prompts show higher error rates than basic queries |

#### Access Requirements

- Must be 18 years or older
- Requires Google account authentication
- Available in 150+ countries, 45+ languages
- **No audio input support**

---

## Core Principles

### Principle 1: Explicit Scope Definition

**Statement**: Every Deep Research prompt should explicitly define the boundaries of the research task, including topic scope, temporal boundaries, geographic constraints, and exclusions.

**Rationale**: The ReportBench study found that prompts without explicit boundaries led to "prompt hacking" where models would retrieve the original source paper rather than conducting independent research. Additionally, without scope constraints, Deep Research may over-generate citations without proportionally improving relevance.

**Evidence**: 
- ReportBench: "To ensure temporal consistency, we require each generated prompt to include a cutoff date"
- ReportBench: Models that ignored temporal constraints directly retrieved source papers rather than synthesizing new research
- Gemini documentation: "Set Boundaries: Exclude irrelevant topics to focus research efforts"

**Application**:
```
❌ Poor: "Research machine learning in healthcare"

✓ Good: "Research applications of transformer-based machine learning models 
        in medical diagnosis, focusing on peer-reviewed publications from 
        2022-2024. Exclude computer vision applications in radiology 
        (covered elsewhere). Focus on clinical validation studies rather 
        than purely technical benchmarks."
```

### Principle 2: Temporal Constraint Specification

**Statement**: Include explicit temporal boundaries using natural language date specifications, particularly for rapidly evolving fields.

**Rationale**: Without temporal constraints, Deep Research may mix outdated information with current findings, or in benchmark contexts, retrieve the exact paper the prompt was derived from. Temporal grounding also prevents the model from citing works that don't yet exist.

**Evidence**:
- ReportBench: All prompt templates include phrases like "Ensure only papers published before [date] are referenced"
- Reference Hallucination Score study: Publication date showed 47.4% hallucination rate, indicating models struggle with temporal accuracy without explicit guidance

**Application**:
```
Include phrases such as:
• "Focus on research published between January 2023 and December 2024"
• "Ensure only papers published before March 2025 are referenced"
• "Prioritize recent developments from the past 18 months"
• "If specific figures for 2025 are not available, explicitly state they 
   are projections or unavailable rather than estimating"
```

### Principle 3: Output Format Specification

**Statement**: Explicitly specify the desired output structure, citation format, and organizational approach.

**Rationale**: Deep Research responds well to structural instructions, and specifying format reduces post-processing work while improving consistency.

**Evidence**:
- Gemini documentation: "Specify Output Format: Request comparisons, timelines, pros/cons lists, etc."
- ReportBench prompts consistently include: "Responses are given in the form of an English language survey with citations where appropriate"
- User testing confirms citation style instructions (APA, MLA, Chicago) are followed when explicitly stated

**Application**:
```
Format specification examples:
• "Format in APA 7th. In-text (Author, Year). Reference list with DOI where available."
• "Structure the report with: Executive Summary, Methodology Overview, 
   Key Findings by Theme, Limitations, and Conclusion sections"
• "Present findings as a comparison table with columns for: Approach, 
   Advantages, Limitations, Key Papers"
```

### Principle 4: Graduated Complexity Matching

**Statement**: Match prompt complexity to the reliability requirements of your task—simpler prompts for higher accuracy needs, more detailed prompts for nuanced exploration.

**Rationale**: The Reference Hallucination Score study found that "complex or clinical scenarios triggered significantly more hallucinations across AI chatbots." However, detailed prompts also enable more specific and useful responses when verification workflows are in place.

**Evidence**:
- RHS study: "AI chatbots generally had significantly higher RHS when prompted with scenarios or complex format prompts (β coefficient=0.486; P<.001)"
- ReportBench: Three prompt granularities (sentence, paragraph, detail-rich) serve different purposes

**Application**:
```
For high-accuracy needs (facts, statistics, citations):
• Use simpler, more direct prompts
• Request specific, verifiable information
• Avoid hypothetical scenarios

For exploration and synthesis (understanding landscape, comparing approaches):
• Use detailed prompts with specific sub-questions
• Accept need for verification
• Leverage follow-up questions to drill down
```

### Principle 5: Explicit Handling Instructions for Unknowns

**Statement**: Provide explicit instructions for how Deep Research should handle missing, uncertain, or conflicting information.

**Rationale**: Without guidance, models may fabricate plausible-sounding information to fill gaps. Explicit instructions for handling unknowns improve transparency and reduce hallucination.

**Evidence**:
- Gemini documentation: "Prompt for unknowns: Instruct the agent on how to handle missing data"
- RHS study: Reference relevancy to prompt keywords showed 61.6% hallucination rate—highest among all metrics

**Application**:
```
Include instructions such as:
• "If specific data for [topic] is unavailable, explicitly state this 
   rather than estimating"
• "When sources conflict, present both perspectives with their respective 
   sources"
• "Mark any projections or estimates clearly as such"
• "If fewer than 5 relevant sources are found, note this limitation"
```

### Principle 6: Source Quality Direction

**Statement**: Specify preferred source types, quality criteria, and any sources to exclude.

**Rationale**: Without guidance, Deep Research may prioritize SEO-optimized content over authoritative sources. Academic research requires different source standards than market research.

**Evidence**:
- Limitations document: "SEO-optimized websites may rank higher than authoritative sources"
- ReportBench detail-rich prompts: "Focus on English literature published in top conferences/journals in natural language processing and artificial intelligence (e.g., ACL, EMNLP, NAACL, AAAI, WWW, ICLR)"

**Application**:
```
Source guidance examples:
• "Prioritize peer-reviewed sources from PubMed-indexed journals"
• "Focus on primary sources (company filings, official reports) rather 
   than news aggregators"
• "Prefer academic publications from ACL, NeurIPS, ICML, and ICLR"
• "Exclude blog posts and opinion pieces; focus on empirical research"
```

### Principle 7: Iterative Refinement Expectation

**Statement**: Treat the initial prompt as a starting point; plan to use Deep Research's plan editing and follow-up features to refine results.

**Rationale**: Deep Research shows users its research plan before execution and accepts modifications. This interactive capability is a core feature, not an afterthought.

**Evidence**:
- Gemini documentation: "Before Deep Research even begins its work, it will show you its research plan and allow you to change it as needed"
- User guidance: "Select the 'Edit plan' option to ask Deep Research to add something to the plan or go in a different direction"

**Application**:
```
Workflow:
1. Submit initial prompt
2. Review generated research plan
3. Edit plan to adjust scope, add directions, remove tangents
4. After report generation, use follow-up questions to:
   • Drill into specific findings
   • Request additional detail on sections
   • Ask for additions: "add camp cost details to my report"
```

---

## Prompt Structure Guide

### Recommended Components

A well-structured Deep Research prompt contains these elements (not all required for every query):

| Component | Purpose | Required? |
|-----------|---------|-----------|
| **Research Objective** | Core question or topic | Always |
| **Scope Definition** | Boundaries of investigation | Recommended |
| **Temporal Constraints** | Time period for sources/data | Recommended |
| **Source Preferences** | Quality/type of sources | Context-dependent |
| **Output Format** | Structure of response | Recommended |
| **Handling Instructions** | How to manage unknowns/conflicts | Recommended |
| **Exclusions** | Topics/sources to avoid | Context-dependent |
| **Context/Purpose** | Why you need this research | Helpful |

### Component Details

#### Research Objective

**Purpose**: Define the core question or topic to investigate.

**Best Practices**:
- Lead with the main research question
- Be specific about what you want to understand
- Avoid compound questions that mix unrelated topics

**Examples**:
```
✓ "Investigate the current state of federated learning approaches for 
   privacy-preserving medical AI"

✓ "Compare the environmental impact methodologies used by the top 10 
   global automotive manufacturers"

❌ "Tell me about AI and also what's happening with electric cars and 
   maybe some stuff about regulations"
```

**Common Mistakes**:
- Questions too broad to answer meaningfully
- Multiple unrelated questions in one prompt
- Ambiguous terminology without clarification

#### Scope Definition

**Purpose**: Establish clear boundaries for the research.

**Best Practices**:
- Define geographic scope if relevant
- Specify industries, domains, or subfields
- Clarify technical depth expected
- Indicate whether you want comprehensive coverage or representative examples

**Examples**:
```
Scope elements:
• Geographic: "Focus on implementations in the European Union"
• Domain: "Within the pharmaceutical manufacturing sector"
• Depth: "Technical analysis suitable for ML practitioners"
• Coverage: "Identify the 5 most influential approaches rather than 
  comprehensive listing"
```

#### Temporal Constraints

**Purpose**: Ground the research in a specific time period.

**Best Practices**:
- Use explicit date ranges
- Consider publication date vs. topic date (e.g., papers published 2023-2024 about events from 2020)
- Include cutoff instructions for live data

**Examples**:
```
• "Research published between 2022-2024"
• "Focus on developments since the release of GPT-4 (March 2023)"
• "Ensure only sources published before January 2025 are referenced"
• "For market data, use figures from Q3 2024 if 2025 data unavailable"
```

#### Source Preferences

**Purpose**: Guide Deep Research toward appropriate source quality and types.

**Best Practices**:
- Specify preferred publication venues for academic work
- Indicate preference for primary vs. secondary sources
- Note any required source characteristics (peer-reviewed, official, etc.)

**Examples**:
```
Academic: "Prioritize peer-reviewed publications from top-tier venues 
          (Nature, Science, leading field-specific journals)"

Business: "Focus on primary sources: SEC filings, official company 
          reports, and verified news from major financial publications"

Technical: "Prefer official documentation, GitHub repositories with 
           >1000 stars, and conference papers from ICLR, NeurIPS, ICML"
```

#### Output Format

**Purpose**: Specify how the response should be structured.

**Best Practices**:
- Request specific sections if needed
- Specify citation style explicitly with examples
- Indicate preferred length or depth
- Request specific deliverable types (comparison table, timeline, etc.)

**Examples**:
```
Structure: "Organize findings into: 1) Current approaches, 2) Evaluation 
           metrics used, 3) Identified limitations, 4) Future directions"

Citations: "Format in APA 7th. In-text (Author, Year). Reference list 
           with DOI where available."

Format type: "Present as a comparison matrix with rows for each 
             approach and columns for: Method, Data Requirements, 
             Performance, Limitations"
```

#### Handling Instructions

**Purpose**: Specify how to handle edge cases, unknowns, and conflicts.

**Best Practices**:
- Provide explicit instructions for missing data
- Specify how to handle conflicting sources
- Indicate tolerance for uncertainty

**Examples**:
```
• "If quantitative data is unavailable, note this explicitly rather 
   than estimating"
• "When sources disagree, present both positions with their evidence"
• "Flag any findings based on single sources or pre-prints"
• "Distinguish clearly between established consensus and emerging/
   contested findings"
```

### Structural Templates

#### Template 1: Academic Literature Review

```
I need a scholarly review on [TOPIC]. This review should focus on:

1. [Major direction/theme 1]: [Brief description]
2. [Major direction/theme 2]: [Brief description]
3. [Major direction/theme 3]: [Brief description]

Scope and constraints:
- Ensure only papers published before [DATE] are referenced
- Focus on peer-reviewed publications from [VENUES/FIELDS]
- [Geographic/domain constraints if any]

Output requirements:
- Format citations in [STYLE] format
- Structure as an academic survey with proper sections
- Include a summary of key findings and open research questions

Handling missing information:
- If specific data is unavailable, state this explicitly
- Note when findings are based on limited sources
```

#### Template 2: Market/Industry Analysis

```
Research [TOPIC/QUESTION] for [INDUSTRY/MARKET].

Scope:
- Geographic focus: [REGIONS]
- Time period: [DATE RANGE]
- Company scope: [e.g., "top 10 by market cap" or "Series B+ startups"]

I need to understand:
- [Key question 1]
- [Key question 2]  
- [Key question 3]

Preferred sources:
- Company filings, official reports, verified industry publications
- Exclude opinion pieces and unverified blog posts

Output format:
- Executive summary (2-3 paragraphs)
- Detailed findings by theme
- Data table comparing [key metrics] across [entities]
- Cite all specific claims with source links

If 2025 data is unavailable, use most recent available and note the date.
```

#### Template 3: Technical Comparison

```
Compare [TECHNOLOGY/APPROACH A] vs [TECHNOLOGY/APPROACH B] for [USE CASE].

Evaluation criteria:
- [Criterion 1]
- [Criterion 2]
- [Criterion 3]

Research parameters:
- Focus on empirical evaluations, not marketing claims
- Prefer benchmarks from [VENUES/SOURCES]
- Include only approaches with published results

Output as:
- Summary comparison table
- Detailed analysis for each criterion
- Recommendation with caveats
- All technical claims must be cited

Note any cases where direct comparison isn't possible due to 
different evaluation conditions.
```

#### Template 4: Quick Exploratory Query

```
I want to understand [TOPIC].

Key questions:
- What are the main approaches/perspectives?
- What are the current limitations or debates?
- What recent developments (past 2 years) are significant?

Keep the scope focused on [CONSTRAINT]. I can ask follow-up 
questions to dive deeper into specific areas.
```

---

## Writing Effective Prompts

### Language and Tone

**Recommended Approach** (Confidence: Medium-High)

- **Use clear, direct language**: Avoid ambiguity and jargon unless domain-specific terms are necessary
- **Imperative phrasing works well**: "Research...", "Compare...", "Analyze..."
- **Natural language is acceptable**: You don't need rigid formatting; conversational clarity works
- **Avoid over-complication**: Simple prompts often perform better for factual queries

**Evidence**: Google documentation states "You don't need to be a prompt-writing master. You can simply express your end goal."

**Examples**:
```
Natural and effective:
"I want to find the best summer camps in New York for my 10-year-old"

Structured and effective:
"Research transformer architectures for time-series forecasting, 
focusing on papers from 2023-2024. Compare attention mechanisms 
and report computational efficiency tradeoffs."

Overly complex (counterproductive):
"Utilizing your advanced natural language processing capabilities, 
I request that you engage in a comprehensive epistemological 
investigation of the ontological frameworks..."
```

### Specificity Guidelines

**When to Be Specific** (High specificity helps):
- Citation requirements (format, style)
- Temporal boundaries
- Source quality requirements
- Output structure
- Handling of unknowns

**When to Be General** (Allow flexibility):
- Initial exploration of unfamiliar topics
- When you don't know what sub-topics exist
- When you want Deep Research to identify relevant dimensions

**The Specificity Tradeoff**:
```
More Specific → More controlled output, but may miss relevant tangents
Less Specific → Broader coverage, but higher noise and hallucination risk
```

**Recommendation**: Start moderately specific, then use follow-up questions and plan editing to adjust.

### Scope Definition Strategies

**Bounded Scope** (Recommended for most research):
```
"Focus on [X] within [domain], excluding [Y]"
"Limit analysis to [time period] and [geographic region]"
"Consider only [source type] from [venues]"
```

**Open Exploration** (For initial discovery):
```
"What are the main research directions in [field]?"
"What aspects of [topic] should I investigate further?"
```

**Iterative Narrowing** (Best practice workflow):
1. Start with open exploration
2. Review plan/results
3. Narrow scope in follow-up or new query

### Context Provision

**What Context Helps**:
- Your purpose (academic paper, business decision, personal interest)
- Your expertise level
- How you plan to use the output
- Related work you've already done

**Example**:
```
"I'm writing a review paper on [topic] for [journal]. I've already 
covered [aspects]. I need to understand [specific area] at a level 
appropriate for researchers familiar with [background]. The review 
will be submitted by [date], so ensure sources are from before 
[cutoff]."
```

### Output Specification Best Practices

**Be Explicit About**:
- Section structure
- Citation format (with example)
- Whether you want exhaustive coverage or representative examples
- Length expectations (though exact word counts won't be met)
- Deliverable type (narrative, table, comparison, etc.)

**Citation Style Instructions That Work**:
```
"Format in APA 7th. In-text (Author, Year). Reference list with DOI 
where available."

"Use MLA 9th with hanging indents and access dates for web sources."

"Chicago author-date. Include page numbers for direct quotes."
```

---

## Prompt Patterns by Research Type

### Pattern: Academic Literature Survey

**Use Case**: Comprehensive review of research in a specific field

**Template**:
```
I need a scholarly review on [RESEARCH TOPIC]. This review should 
primarily focus on [N] major directions:

1. [Direction 1]: [Brief description of scope]
2. [Direction 2]: [Brief description of scope]
...

Please ensure that:
- All referenced literature is published before [CUTOFF DATE]
- Focus on [VENUE TYPES] (e.g., peer-reviewed journals, top-tier conferences)
- [Language constraints if any]

Do not cite [SPECIFIC PAPERS TO EXCLUDE if any].

Responses should be formatted as an English language survey with 
citations in [STYLE] format where appropriate.
```

**Key Considerations**:
- Include cutoff date to prevent citation of non-existent future papers
- Specify venue quality requirements
- Consider excluding known papers to encourage novel discovery
- Request academic citation format explicitly

**Example**:
```
I need a scholarly review on causal generative models in machine learning.
This review should primarily focus on two major directions:

1. Structural Causal Models with deep learning: How causal graphs are 
   integrated with neural networks for generative modeling
2. Intervention-based learning: Methods that learn causal relationships 
   through simulated or real interventions

Please ensure that:
- All referenced literature is published before May 2024
- Focus on publications from NeurIPS, ICML, ICLR, AISTATS, and UAI
- Include foundational work from the causality literature where relevant

Format citations in APA 7th style. Structure the review with an 
introduction to the problem space, sections for each direction, 
and a discussion of open challenges.
```

**Expected Output Characteristics**:
- Structured academic prose
- In-text citations with reference list
- Coverage of major approaches and papers
- Synthesis across sources, not just summarization

### Pattern: Technical Comparison

**Use Case**: Evaluating multiple approaches/tools/methods against each other

**Template**:
```
Compare [ITEM A], [ITEM B], and [ITEM C] for [USE CASE/APPLICATION].

Evaluation dimensions:
- [Dimension 1]: [What to measure]
- [Dimension 2]: [What to measure]
- [Dimension 3]: [What to measure]

Constraints:
- Focus on [empirical evaluations / official benchmarks / user reports]
- Timeframe: [DATE RANGE]
- [Domain/context constraints]

Output format:
- Comparison table with scores/ratings for each dimension
- Detailed narrative for each item
- Recommendation with explicit tradeoffs
- All claims must be cited

When direct comparison isn't possible, explain why and provide 
best available context.
```

**Key Considerations**:
- Define evaluation dimensions upfront
- Specify what counts as valid evidence
- Request explicit handling of non-comparable cases

### Pattern: Market/Industry Analysis

**Use Case**: Understanding market landscape, competitive dynamics, trends

**Template**:
```
Analyze [MARKET/INDUSTRY] with focus on [SPECIFIC ASPECT].

Scope:
- Geographic: [REGIONS]
- Time period: [DATE RANGE]
- Companies: [CRITERIA - e.g., "top 10 by revenue", "VC-backed startups"]

Research questions:
1. [Question about market size/dynamics]
2. [Question about key players]
3. [Question about trends/future]

Source preferences:
- Prioritize [official filings / industry reports / verified news]
- Exclude [opinion pieces / unverified claims]

Output:
- Executive summary (key findings)
- Detailed sections for each research question
- Data tables where applicable
- All statistics must include source and date

If current-year data unavailable, use most recent and note the date.
```

### Pattern: Policy/Regulatory Research

**Use Case**: Understanding regulatory landscape, compliance requirements

**Template**:
```
Research [REGULATORY TOPIC] affecting [INDUSTRY/DOMAIN] in [JURISDICTION].

Focus areas:
- Current requirements and key provisions
- Recent changes (past [N] years)
- Pending/proposed changes
- Enforcement patterns and notable cases

Time constraints:
- Regulations in effect as of [DATE]
- Note any upcoming changes with effective dates

Source requirements:
- Primary sources: Official regulatory texts, agency guidance
- Secondary: Legal analysis from reputable firms, industry associations

Output format:
- Summary of current requirements
- Timeline of recent/upcoming changes
- Practical implications for [stakeholder type]
- Key compliance considerations

Flag any areas of regulatory uncertainty or ongoing rulemaking.
```

### Pattern: Quick Fact-Finding

**Use Case**: Rapid answers to specific questions

**Template**:
```
[Direct question]

Requirements:
- [Recency requirement if any]
- Cite source for any statistics or specific claims

[Optional: Brief context about why you're asking]
```

**Example**:
```
What is the current market share breakdown for cloud infrastructure 
providers (AWS, Azure, GCP, others)?

Requirements:
- Use data from Q3 2024 or more recent
- Cite the source for market share figures

I'm preparing a slide for a strategy presentation.
```

**Key Considerations**:
- Keep it focused—one question
- Specify recency requirements
- Request citation for verifiable claims

---

## Anti-Patterns and Common Mistakes

### Anti-Pattern 1: Unconstrained Scope

**Description**: Prompts without any boundaries on topic, time, or sources.

**Why It's Problematic**:
- Results in unfocused, noisy output
- Higher hallucination rates
- May include outdated or irrelevant information
- Difficult to verify or use effectively

**How to Recognize It**:
```
❌ "Tell me everything about artificial intelligence in healthcare"
❌ "Research blockchain"
❌ "What's happening with climate change?"
```

**Correct Alternative**:
```
✓ "Research FDA-approved AI diagnostic tools for radiology, focusing 
   on approvals from 2022-2024. Include clinical validation data and 
   current adoption rates at US academic medical centers."
```

### Anti-Pattern 2: Implicit Temporal Assumptions

**Description**: Assuming Deep Research knows what "current" or "recent" means without specification.

**Why It's Problematic**:
- Model may use training data from various time periods
- "Recent" is ambiguous (days? months? years?)
- Publication date hallucination affects 47% of citations (per RHS study)

**How to Recognize It**:
```
❌ "What are the latest developments in..."
❌ "Research current best practices for..."
❌ "What's the most recent data on..."
```

**Correct Alternative**:
```
✓ "Research developments from January 2024 to present..."
✓ "Focus on best practices documented in 2023-2024..."
✓ "Use data published in 2024; if unavailable, note the most 
   recent available date"
```

### Anti-Pattern 3: Over-Complex Single Prompts

**Description**: Cramming multiple unrelated questions or excessive detail into one prompt.

**Why It's Problematic**:
- Complex/scenario prompts increase hallucination (per RHS study)
- Model may address some parts while neglecting others
- Harder to verify and iterate

**How to Recognize It**:
```
❌ "Research AI in healthcare AND blockchain AND IoT AND compare all 
   companies in each space AND provide investment recommendations AND 
   analyze regulatory implications across all jurisdictions..."
```

**Correct Alternative**:
```
✓ Start focused: "Research AI diagnostic tools in radiology..."
✓ Use follow-ups: "Now compare the top 3 companies in this space"
✓ Iterate: "What are the regulatory considerations for FDA approval?"
```

### Anti-Pattern 4: Expecting Precise Word Counts

**Description**: Requesting exact word counts in output.

**Why It's Problematic**:
- LLMs process tokens, not words
- Cannot accurately count during generation
- Will either overshoot or undershoot significantly

**How to Recognize It**:
```
❌ "Write exactly 500 words about..."
❌ "Provide a 1,000-word analysis of..."
```

**Correct Alternative**:
```
✓ "Provide a brief overview (2-3 paragraphs)..."
✓ "Write a comprehensive analysis (approximately 5-7 pages)..."
✓ "Keep the executive summary concise (under 300 words roughly)"
```

### Anti-Pattern 5: Trusting URLs Without Verification

**Description**: Assuming all citations and links are valid without checking.

**Why It's Problematic**:
- URL fabrication is a documented failure mode
- Links may return 404 errors
- Cited content may not support the claim

**Evidence**: "Gemini loves to hallucinate links... A link may seem legitimate at first glance, but clicking through can lead to 404 errors" (documented limitation)

**How to Recognize It**: Treating Deep Research output as final without clicking citations.

**Correct Alternative**:
```
✓ Click through every citation to verify
✓ Use the "G button" to identify sourced vs. synthesized content
✓ Cross-reference important claims with direct database access
✓ Budget verification time into your workflow
```

### Anti-Pattern 6: Using for Regulated Compliance Work

**Description**: Using Deep Research for work requiring audit trails, reproducibility, or regulatory compliance.

**Why It's Problematic**:
- No reproducibility (web sources change)
- No audit trail
- Not validated for GxP environments
- No BAA for HIPAA compliance

**How to Recognize It**:
```
❌ Using Deep Research for systematic reviews
❌ Relying on it for regulatory submission support
❌ Including PHI or confidential data in prompts
```

**Correct Alternative**:
```
✓ Use for initial exploration only
✓ Maintain validated systems for compliance work
✓ Document any Deep Research use in non-critical phases
✓ Never enter confidential/proprietary information
```

### Anti-Pattern 7: No Source Quality Guidance

**Description**: Not specifying what types of sources are acceptable.

**Why It's Problematic**:
- SEO-optimized content may outrank authoritative sources
- Mix of reliable and unreliable sources
- Academic work contaminated with blog posts

**How to Recognize It**:
```
❌ "Research the effectiveness of [treatment]"
(No guidance on peer-reviewed vs. blog posts vs. manufacturer claims)
```

**Correct Alternative**:
```
✓ "Research the effectiveness of [treatment], focusing on:
   - Randomized controlled trials published in PubMed-indexed journals
   - Systematic reviews from Cochrane or similar
   - Exclude manufacturer marketing materials and unverified testimonials"
```

---

## Advanced Techniques

### Technique: Staged Research Workflow

**Description**: Breaking complex research into multiple Deep Research sessions with progressive refinement.

**When to Use**:
- Very broad topics requiring comprehensive coverage
- When you need to understand the landscape before diving deep
- Multi-faceted questions with different source requirements

**Implementation**:
```
Stage 1 - Landscape mapping:
"What are the major research directions in [broad topic]? 
Identify 5-7 key themes and seminal papers for each."

Stage 2 - Deep dive (separate session per theme):
"Focusing specifically on [Theme 3 from Stage 1], provide a detailed 
analysis of current approaches, key papers, and open questions."

Stage 3 - Synthesis:
"Given my research on [themes], help me synthesize findings and 
identify cross-cutting insights and contradictions."
```

**Caveats**:
- More time-consuming
- May hit usage quotas with multiple sessions
- Requires manual synthesis across sessions

### Technique: Comparative Triangulation

**Description**: Running the same query with different scope constraints to triangulate reliable information.

**When to Use**:
- High-stakes research where accuracy is critical
- When you suspect source bias
- Verification of controversial claims

**Implementation**:
```
Query A: "[Research question] focusing on academic sources"
Query B: "[Research question] focusing on industry reports"
Query C: "[Research question] focusing on government/regulatory sources"

Then compare: Where do all three agree? Where do they diverge?
```

**Caveats**:
- Multiplies time and quota usage
- Requires manual comparison
- Still doesn't guarantee accuracy

### Technique: Explicit Uncertainty Elicitation

**Description**: Specifically prompting for what Deep Research doesn't know or is uncertain about.

**When to Use**:
- When completeness of coverage matters
- To identify gaps for further research
- Before making decisions based on research

**Implementation**:
```
Add to prompts:
"After presenting your findings, include a section titled 'Limitations 
and Gaps' that addresses:
1. Topics I asked about where limited information was found
2. Areas where sources conflicted and resolution wasn't clear
3. Types of sources that would strengthen these findings but weren't 
   available (e.g., paywalled journals, proprietary data)
4. Aspects of my question that couldn't be addressed with available 
   information"
```

**Caveats**:
- Model may still not accurately assess its own limitations
- Verify claimed gaps against actual availability

### Technique: Citation Style Enforcement

**Description**: Providing explicit citation format examples to ensure consistency.

**When to Use**:
- Academic writing with specific style requirements
- When you need consistent, parseable citations

**Implementation**:
```
"Format all citations in APA 7th edition style. Examples:

In-text: (Smith & Jones, 2023) or Smith and Jones (2023)

Reference list:
Smith, A. B., & Jones, C. D. (2023). Article title in sentence case. 
Journal Name in Title Case, 45(2), 123-145. https://doi.org/xxxxx

After completing the research, run through all citations and ensure 
they follow this exact format. Flag any citations where complete 
information (authors, year, title, source, DOI) couldn't be found."
```

**Caveats**:
- Still verify citations manually
- May miss some style nuances
- DOIs may not always be available

### Technique: Follow-Up Refinement Protocol

**Description**: Systematic use of follow-up questions to improve initial output.

**When to Use**:
- Initial output is useful but incomplete
- Want to drill into specific sections
- Need to verify or expand on claims

**Implementation**:
```
Standard follow-up sequence:
1. "Expand on [specific section] with more detail and additional sources"
2. "For the claim that [X], provide the specific source and quote"
3. "What alternative perspectives exist on [finding]?"
4. "Add [new aspect] to the existing report"
5. "What are the limitations of the sources used for [section]?"
```

**Caveats**:
- Follow-ups may use cached research (faster but same sources)
- For truly new direction, may need fresh query

---

## Quality Checklist

### Before Submitting a Prompt

**Scope & Boundaries**
- [ ] Research objective is clearly stated
- [ ] Topic boundaries are defined (what's in, what's out)
- [ ] Temporal constraints are explicit (date ranges, cutoffs)
- [ ] Geographic/domain scope is specified if relevant

**Source Requirements**
- [ ] Preferred source types are indicated
- [ ] Quality criteria are specified (peer-reviewed, official, etc.)
- [ ] Exclusions are noted if any

**Output Specifications**
- [ ] Desired structure is described
- [ ] Citation format is specified with example
- [ ] Handling instructions for unknowns/conflicts included

**Complexity Check**
- [ ] Prompt focuses on one coherent research question
- [ ] Not overloaded with unrelated sub-questions
- [ ] Complexity matches accuracy needs

### Evaluating Results

**Citation Verification**
- [ ] Clicked through at least a sample of citations
- [ ] Verified cited content actually supports the claims
- [ ] Checked for 404 errors or fabricated URLs
- [ ] Cross-referenced critical statistics with primary sources

**Coverage Assessment**
- [ ] Key topics from prompt are addressed
- [ ] No obvious major omissions
- [ ] Sources represent diverse perspectives (if relevant)

**Accuracy Indicators**
- [ ] Claims are appropriately hedged vs. definitive
- [ ] Dates and figures match cited sources
- [ ] No obvious anachronisms (citing future dates, etc.)

**Follow-Up Needs**
- [ ] Identified sections needing expansion
- [ ] Noted claims requiring additional verification
- [ ] Listed follow-up questions for deeper investigation

---

## Decision Trees

### Choosing Research Scope

```
Start: What is your primary goal?
│
├─► Quick answer to specific question
│   └─► Use: Simple, direct prompt
│       Scope: Narrow
│       Follow-up: As needed for clarification
│
├─► Understand landscape of a field
│   └─► Use: Exploratory prompt
│       Scope: Moderate
│       Follow-up: Narrow into interesting directions
│
├─► Comprehensive literature review
│   └─► Use: Detailed academic template
│       Scope: Well-defined but comprehensive
│       Follow-up: Section-by-section deep dives
│
├─► Make a decision (which tool/vendor/approach)
│   └─► Use: Comparison template
│       Scope: Bounded by decision criteria
│       Follow-up: Drill into tradeoffs
│
└─► Verify specific claims or facts
    └─► Use: Direct question with citation requirement
        Scope: Very narrow
        Follow-up: Request alternative sources
```

### Selecting Prompt Structure

```
How much do you know about the topic?
│
├─► Very little (exploring)
│   │
│   └─► Complexity tolerance?
│       ├─► Need high accuracy → Use simple prompt, verify everything
│       └─► Exploratory → Use open-ended, refine via follow-ups
│
├─► Moderate knowledge (focused research)
│   │
│   └─► Output type needed?
│       ├─► Academic survey → Use academic template with full constraints
│       ├─► Business decision → Use market/comparison template
│       └─► Technical evaluation → Use technical comparison template
│
└─► Expert (specific gaps)
    │
    └─► Use highly specific prompt
        Include: Known context, specific unknowns, source preferences
        Format: Precise output requirements
```

---

## Quick Reference

### Do's and Don'ts Summary Table

| Do | Don't | Reason |
|----|-------|--------|
| Include explicit date ranges | Say "recent" or "current" | Temporal ambiguity causes ~47% date hallucination |
| Specify source quality criteria | Trust all sources equally | SEO content may outrank authoritative sources |
| Click through citations | Trust URLs implicitly | URL fabrication is documented failure mode |
| Use follow-up questions | Cram everything in one prompt | Complex prompts increase hallucination |
| Request specific citation format | Assume format will be consistent | Explicit examples improve consistency |
| Define what's out of scope | Leave scope unbounded | Unbounded scope reduces focus and accuracy |
| Specify how to handle unknowns | Expect model to admit uncertainty | Models may fabricate rather than acknowledge gaps |
| Start simple, iterate | Start with maximum complexity | Iteration via editing/follow-ups is core feature |
| Verify critical claims independently | Use for regulated/compliance work | No reproducibility, audit trail, or validation |
| Include your purpose/context | Assume model understands intent | Context helps appropriate depth/tone |

### Prompt Component Cheatsheet

```
[RESEARCH OBJECTIVE]
Single clear statement of what you want to know

[SCOPE DEFINITION]
- Topic boundaries: Include X, Y; exclude Z
- Geographic: [regions/jurisdictions]  
- Domain: [industries/fields/subfields]
- Depth: [overview/comprehensive/technical]

[TEMPORAL CONSTRAINTS]
- "Publications from [START] to [END]"
- "Ensure sources before [CUTOFF DATE]"
- "If [YEAR] data unavailable, note most recent date"

[SOURCE PREFERENCES]  
- Type: [peer-reviewed/official/primary/etc.]
- Venues: [specific journals/conferences/publications]
- Exclude: [blogs/opinions/marketing/etc.]

[OUTPUT FORMAT]
- Structure: [sections/narrative/comparison table]
- Citation style: "[STYLE]. Example: [EXAMPLE]"
- Length: [brief/comprehensive/approximately N pages]

[HANDLING INSTRUCTIONS]
- Unknowns: "State explicitly if unavailable"
- Conflicts: "Present both perspectives"
- Uncertainty: "Flag findings from single sources"
```

### Common Phrases That Work

**Scope Definition**:
- "Focus exclusively on..."
- "Limit analysis to..."
- "Exclude from consideration..."
- "Within the context of..."

**Temporal Constraints**:
- "Ensure only papers published before [date] are referenced"
- "Focus on developments from [date] to present"
- "If [year] data is unavailable, explicitly state this"
- "Prioritize recent developments (past [N] months/years)"

**Source Quality**:
- "Prioritize peer-reviewed sources from..."
- "Focus on primary sources such as..."
- "Exclude [blogs/opinions/marketing materials]"
- "Prefer publications from [venue list]"

**Output Format**:
- "Format in [APA/MLA/Chicago] style"
- "Structure the response with sections for..."
- "Present as a comparison table with columns for..."
- "Responses should be given in the form of..."

**Handling Uncertainty**:
- "If specific data is unavailable, explicitly state this rather than estimating"
- "When sources conflict, present both positions with their evidence"
- "Mark any projections or estimates clearly as such"
- "Flag any findings based on single sources"

**Exclusions**:
- "Do not cite [specific paper/source]"
- "Exclude [topic] as it is covered elsewhere"
- "This research should not include..."

---

## Appendices

### Appendix A: Complete Example Prompts

#### Example 1: Academic Literature Review (Detail-Rich)

```
I need a detailed academic research report on using Graph Neural Networks 
(GNN) for text classification. The report should systematically review 
advancements in this field, with a focus on the following aspects:

1. **Core Methodology**: Provide a detailed explanation and comparison of 
   two main approaches: corpus-level GNNs and document-level GNNs. For 
   each method, thoroughly analyze graph construction strategies (e.g., 
   defining nodes and edges using PMI, TF-IDF, etc.), representation 
   methods for nodes and edges, and graph learning algorithms (e.g., 
   GCN, GAT, etc.).

2. **Key Model Analysis**: List and analyze representative models, such 
   as TextGCN, SGC, BertGCN (corpus-level), and Text-Level-GNN, TextING 
   (document-level).

3. **Evaluation and Challenges**: Summarize commonly used benchmark 
   datasets in this field (e.g., 20NG, R8, MR) and evaluation metrics 
   (e.g., Accuracy, F1-score), and discuss major challenges faced by 
   current research, such as scalability, computational costs, and 
   integration with pre-trained language models.

**Restrictions**:
- Only refer to and cite papers published before July 2024
- Focus on English literature published in top conferences/journals in 
  natural language processing and artificial intelligence (e.g., ACL, 
  EMNLP, NAACL, AAAI, WWW, ICLR)

Format citations in APA 7th style. Structure as an academic survey with 
appropriate sections. Include an introduction to the problem space and 
conclude with open research questions.
```

#### Example 2: Market Analysis (Paragraph-Level)

```
Analyze the current state of the enterprise AI code assistant market, 
focusing on tools for software development teams.

Scope:
- Geographic: Global, with emphasis on North American adoption
- Time period: Q1 2024 through Q4 2024
- Companies: Both established players (GitHub Copilot, Amazon CodeWhisperer) 
  and emerging startups with Series A+ funding

Research questions:
1. What is the current market size and projected growth rate?
2. How do the top 5 tools compare on features, pricing, and enterprise 
   security capabilities?
3. What are the main adoption barriers reported by enterprise customers?
4. What regulatory or compliance considerations affect enterprise adoption?

Source preferences:
- Prioritize Gartner, Forrester, and IDC reports where available
- Company filings and official announcements
- Verified news from major tech publications (TechCrunch, The Information, etc.)
- Exclude promotional blog posts and unverified claims

Output:
- Executive summary (3-4 paragraphs)
- Comparison table of top 5 tools
- Detailed sections for each research question
- All market figures must cite source and date

If Q4 2024 data is unavailable, use most recent available and note the date.
```

#### Example 3: Quick Technical Query (Sentence-Level)

```
What are the key differences between LoRA and QLoRA for fine-tuning large 
language models? Focus on memory efficiency, training speed, and quality 
tradeoffs based on published benchmarks from 2023-2024. Cite sources for 
specific performance claims.
```

### Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Deep Research** | Google's agentic AI feature that autonomously conducts multi-step research over extended periods |
| **Hallucination** | AI-generated content that is factually incorrect, fabricated, or unsupported by sources |
| **Citation hallucination** | Fabricated or non-existent citations, including fake URLs, wrong paper titles, or misattributed authors |
| **Statement hallucination** | Claims that deviate from or misrepresent the cited source content |
| **Prompt hacking** | When an AI retrieves the original source paper rather than conducting independent research (in benchmark contexts) |
| **Temporal constraint** | Explicit date boundaries in prompts to limit the time period of sources considered |
| **Reference Hallucination Score (RHS)** | Quantitative metric for evaluating citation accuracy across multiple bibliographic elements |
| **Token** | The basic unit LLMs process; roughly 3/4 of a word on average |
| **G button** | Feature to identify directly sourced (green) vs. synthesized (orange) content |
| **Plan editing** | Deep Research feature allowing users to modify the research plan before execution |

### Appendix C: Source Document Index

| Document | Citation | Key Topics |
|----------|----------|------------|
| Gemini Deep Research Limitations & Requirements | Internal reference compilation, February 2026 | Access requirements, technical specs, documented limitations, query optimization |
| Reference Hallucination Score for Medical AI Chatbots | Aljamaan et al., JMIR Medical Informatics, 2024 | Hallucination metrics, prompt complexity effects, citation accuracy |
| ReportBench: Evaluating Deep Research Agents | Li et al., ByteDance BandAI, 2025 (arXiv:2508.15804) | Benchmark methodology, prompt templates, comparative performance |

### Appendix D: Areas Requiring Further Research

| Area | Current Gap | Suggested Investigation |
|------|-------------|------------------------|
| **Optimal prompt length** | No systematic study of prompt length vs. output quality tradeoffs | A/B testing with controlled prompt variations |
| **Language-specific optimization** | Non-English quality degradation documented but mitigation strategies unknown | Testing bilingual prompts, translation strategies |
| **Follow-up vs. new query** | When does cached research help vs. hurt? | Controlled comparison of follow-up vs. fresh sessions |
| **Multi-session synthesis** | Best practices for combining results across sessions | Workflow experiments |
| **Citation verification automation** | Manual verification required; automation opportunities | Tool development for batch verification |
| **Domain-specific tuning** | General guidance applies; domain-specific optimizations unknown | Domain expert evaluation of optimized prompts |

### Appendix E: Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | February 2026 | Initial release based on analysis of source documents |

---

*This guide should be updated as Google releases new documentation, user community best practices evolve, and additional academic research on Deep Research agents becomes available.*
