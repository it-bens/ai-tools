# Chain of Thought Prompting

Giving Claude space to think improves performance on complex tasks by breaking problems into steps.

### When to Use CoT
- Complex math, logic, or analysis
- Multi-step reasoning
- Tasks humans would need to think through
- Decisions with many factors

### When NOT to Use CoT
- Simple factual queries
- Tasks where latency is critical
- Straightforward format transformations

### CoT Levels

**Basic (least structured):**
```
Think step-by-step before answering.
```

**Guided (more structure):**
```
Think before answering. First, identify the key requirements.
Then, consider the trade-offs. Finally, provide your recommendation.
```

**Structured (most reliable):**
```
Think before answering in <thinking> tags. First, analyze X.
Then, evaluate Y. Finally, in <answer> tags, provide your recommendation.
```

**Claude 5:** thinking is adaptive and on by default, so visible `<thinking>`/`<answer>` scaffolding is a Claude 4 / earlier pattern — on Claude 5 it can cause tag leakage (Opus 5) or a refusal (Fable 5). See `claude-5-guide.md#adaptive-thinking`.

### Example: Financial Analysis

**Without CoT:**
```
A client wants to invest $10,000 in either a volatile stock (12% returns)
or a guaranteed bond (6%). They need the money in 5 years for a house down
payment. What do you recommend?
```
Result: Generic recommendation without rigorous analysis.

**With Structured CoT:**
```
A client wants to invest $10,000 in either a volatile stock (12% returns)
or a guaranteed bond (6%). They need the money in 5 years for a house down
payment.

Analyze in <thinking> tags:
1. Calculate potential outcomes for each option
2. Assess the client's risk tolerance given their goal
3. Consider historical market volatility over 5-year periods

Then provide your recommendation in <answer> tags.
```
Result: Rigorous analysis with calculations and justified recommendation.
