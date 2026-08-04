# GPT-5.6 Prompt Adaptation Examples

## Example 1: Support Agent (step-prescriptive → outcome-first)

### Claude-style prompt (over-prescribes steps on GPT-5.6)

```markdown
You are a customer support agent. Follow these steps exactly:
1. Look up the customer's account.
2. Check the eligibility policy.
3. If eligible, process the refund.
4. Always double-check the account status before responding.
5. Always confirm the policy version before deciding.
6. Be concise. Keep responses short.
7. Never process a refund without checking eligibility. Never skip the policy check.
```

### GPT-5.6 adapted prompt

```markdown
Resolve the customer's refund request end to end.

Success means:
- make the eligibility decision from available policy and account evidence
- complete any allowed refund action before responding
- return completed_actions, customer_message, and blockers
- if required evidence is missing, ask for the smallest missing field

Require confirmation before external writes or anything that expands scope beyond
the refund request.
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Numbered step script → outcome + success criteria | GPT-5.6 chooses an efficient path when given the destination and completion bar |
| Removed duplicate eligibility/policy rules (steps 2, 5, 7) | State each instruction once — repeated rules create contract conflicts and burn reasoning tokens |
| Removed "double-check" re-verification | The success criteria already define done; redundant verification instructions add loops |
| Removed "Be concise. Keep responses short." | GPT-5.6 is more concise than GPT-5.5 by default; blanket brevity can over-truncate — set `text.verbosity` instead |
| Added confirmation boundary | GPT-5.6 is proactive and persistent; autonomy boundaries define what each request authorizes |

## Example 2: Coding Agent (approval-heavy → autonomy policy)

### Claude-style prompt (causes approval thrash on GPT-5.6)

```markdown
You are a coding assistant. Ask before making any change. Wait for approval before
running commands. Do not mutate files without permission. Ask first if you are
unsure. CRITICAL: You MUST verify your work with a subagent before finishing.
```

### GPT-5.6 adapted prompt

```markdown
For requests to answer, explain, review, diagnose, or plan, inspect the relevant
materials and report the result. Do not implement changes unless the request also
asks for them.

For requests to change, build, or fix, make the requested in-scope local changes and
run relevant non-destructive validation without asking first.

Require confirmation for external writes, destructive actions, or a material
expansion of scope.

After making changes, run the most relevant validation available: targeted tests for
changed behavior, type or lint checks when applicable, a minimal smoke test when full
validation is too expensive. If validation cannot be run, explain why and describe
the next best check.
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| Four repeated "ask first" rules → one three-tier policy | Repeating "ask first" / "do not mutate" / "wait for approval" causes unnecessary approval requests for safe, expected actions |
| Request-type routing (report vs. act vs. confirm) | Defines what each request authorizes so in-scope work continues without pauses |
| `CRITICAL: You MUST verify with a subagent` → concrete validation ladder | Reserve absolutes for invariants; a completion bar with named checks steers better than an aggressive trigger |

## Example 3: Research Assistant (vague thoroughness → retrieval budget)

### Claude-style prompt (over-searches on GPT-5.6)

```markdown
Be THOROUGH when gathering information. Make sure you have the FULL picture before
answering. Use additional searches as needed. Keep searching until you are certain.
```

### GPT-5.6 adapted prompt

```markdown
For ordinary questions, start with one broad search using short, discriminative
keywords. If the top results contain enough support for the core request, answer
from those results.

Make another retrieval call only when a required fact, owner, date, ID, or source is
missing; the user asked for exhaustive coverage; or an important claim would
otherwise be unsupported. Do not search again only to improve phrasing.

Attach citations to the claims they support. Label inference separately from
directly supported facts. If evidence is missing, say so rather than guessing —
absence of evidence is not a "no".
```

### Adaptation Rationale

| Change | Reason |
|--------|--------|
| "Be THOROUGH… FULL picture… until certain" → explicit retrieval budget | Maximal-thoroughness framing makes GPT-5.6 over-search small tasks; a budget with named escalation triggers bounds exploration |
| Added citation and inference-labeling rules | GPT-5.6 follows evidence contracts literally when they are stated as decision rules |
| Added missing-evidence handling | Prevents unsupported claims from filling gaps silently |

## Adaptation Checklist

- [ ] Outcome, success criteria, and stop rules stated; step scripts removed
- [ ] Each instruction stated once; contradictions and duplicates removed
- [ ] ALWAYS / NEVER / MUST only on true invariants; decision rules for judgment calls
- [ ] Blanket brevity instructions re-checked; `text.verbosity` used for the default
- [ ] Autonomy/approval boundaries defined (report vs. act vs. confirm)
- [ ] Retrieval and tool-call budgets replace "be thorough" framing
- [ ] `reasoning.effort` chosen deliberately (default `medium`; `max` only for hardest quality-first work)
