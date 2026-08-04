# GPT-5.6 (OpenAI) Prompt Engineering Guide

GPT-5.6 (Sol, Terra, Luna) is the current OpenAI target generation. Guidance below also marks what carries over from the earlier GPT-5 family (GPT-5 through GPT-5.5) for prompts that still target those models.

## Table of Contents

- [Model Family and Selection](#model-family-and-selection)
- [Core Prompting Posture](#core-prompting-posture)
- [API Parameters](#api-parameters)
- [Behavioral Changes and How to Prompt Them](#behavioral-changes-and-how-to-prompt-them)
- [Tool Use and Agentic Workflows](#tool-use-and-agentic-workflows)
- [Adapting Claude Prompts for GPT-5.6](#adapting-claude-prompts-for-gpt-56)
- [Migrating from Earlier GPT-5.x](#migrating-from-earlier-gpt-5x)
- [GPT-5 Family Baseline (Pre-5.6 Targets)](#gpt-5-family-baseline-pre-56-targets)
- [Quick Reference Templates](#quick-reference-templates)

## Model Family and Selection

| Model | Best For |
|---|---|
| `gpt-5.6-sol` | Frontier capability: hardest agentic, coding, and reasoning work (the `gpt-5.6` alias routes here) |
| `gpt-5.6-terra` | Balanced intelligence and cost for everyday work |
| `gpt-5.6-luna` | Efficient, high-volume, latency-sensitive workloads |

Sol, Terra, and Luna are capability tiers (replacing the earlier flagship/mini/nano naming); all three share the same prompting guidance. Prompt differences across the family come from `reasoning.effort` and `text.verbosity` settings, not from per-tier prompt styles.

## Core Prompting Posture

GPT-5.6 works best when the prompt defines the outcome, the important constraints, the available evidence, and the completion bar, then leaves the path to the model.

- **Outcome-first, not step-prescriptive.** Describe the destination and success criteria; do not script every step. Include explicit stopping conditions so the model knows when the task is done.
- **Leaner prompts outperform.** Remove repeated statements of the same rule, style and process instructions that don't change behavior, examples that don't change behavior, and tools irrelevant to the task. State each instruction once. Trim one group at a time and re-run the same evals rather than rewriting wholesale.
- **Contradictions hurt more than gaps.** GPT-5-class models follow prompt contracts closely; conflicting rules create more instability than missing detail, because the model spends reasoning tokens trying to reconcile them. Hunt and remove contradictions before adding anything.
- **Reserve absolutes for invariants.** Use ALWAYS / NEVER / must / only for true invariants (safety rules, required fields, actions that must never happen). For judgment calls — when to search, ask, use a tool, keep iterating — give decision rules instead.
- **Preserve explicit user values; avoid universal defaults.** When the correct value is implicit, provide decision criteria and let the model reason from context or schema rather than hardcoding keyword maps or blanket defaults.

Suggested prompt skeleton:

```
Role: [the model's function and context]
Personality: [tone and collaboration style]
Goal: [user-visible outcome]
Success criteria: [what must be true before the final answer]
Constraints: [policy, safety, business, evidence, and side-effect limits]
Tools: [which tools to use, when, and what not to use]
Output: [sections, length, format, and tone]
Stop rules: [when to retry, fallback, abstain, ask, or stop]
```

## API Parameters

Use the Responses API for reasoning, tool-calling, and multi-turn workflows. Chat Completions with function tools works only at effective reasoning `none` on GPT-5.6.

| Parameter | Values / Behavior |
|---|---|
| `reasoning.effort` | `none`, `low`, `medium`, `high`, `xhigh`, `max`; default `medium`. `max` is new in 5.6 — reserve it for the hardest quality-first workloads and compare against `xhigh` rather than adopting it globally |
| `reasoning.mode` | `"pro"` enables pro mode on the same model slug: more internal work, one final answer, higher latency and token use. Independent of effort. Do not prompt "think harder" or "generate candidates" — keep the same outcome-focused prompt |
| `reasoning.context` | Persisted reasoning across turns. GPT-5.6 defaults to `all_turns` (earlier models: `current_turn`). Set `current_turn` when earlier reasoning is stale — persisted reasoning is not an always-on optimization; stale reasoning adds tokens and anchors the model to an outdated approach |
| `text.verbosity` | `low` / `medium` / `high` — default level of response detail. Set the default here; put task-specific length and structure requirements in the prompt |
| Prompt caching | Explicit breakpoints via `prompt_cache_options.mode: "explicit"`; `prompt_cache_options.ttl` replaces `prompt_cache_retention`. Cache writes bill at 1.25× the uncached input rate — track `cached_tokens` and `cache_write_tokens` |

Before raising `reasoning.effort` to fix quality, check whether the prompt is missing a success criterion, dependency rule, tool-routing rule, or verification loop — effort increases are the last resort, not the first.

## Behavioral Changes and How to Prompt Them

### More concise by default

GPT-5.6 is more concise than GPT-5.5. Blanket "Be concise" / "Keep it short" instructions carried over from older prompts may now be redundant or over-truncate. Control the default with `text.verbosity` and state what a short answer must keep:

```
Lead with the conclusion. Include the evidence needed to support it, any material
caveat, and the next action. Omit secondary detail and repetition.
```

Define tone concretely instead of with labels like "friendly" or "empathetic":

```
State the answer directly. If the user reports a problem, acknowledge the specific
issue before giving the next step. Use reassurance only when it is relevant. Omit
generic praise and unnecessary sign-offs.
```

### Proactive and persistent — set autonomy boundaries

GPT-5.6 infers the underlying goal and intended level of work from context and continues multi-step work without prompting. Define what each request authorizes:

```
For requests to answer, explain, review, diagnose, or plan, inspect the relevant
materials and report the result. Do not implement changes unless the request also
asks for them.

For requests to change, build, or fix, make the requested in-scope local changes
and run relevant non-destructive validation without asking first.

Require confirmation for external writes, destructive actions, purchases, or a
material expansion of scope.
```

Name safe local actions explicitly, keep the policy in one place, and state each rule once — repeating "ask first", "do not mutate", or "wait for approval" causes unnecessary approval requests for safe, expected actions. For long-running work, name the current layer (research, design, implementation, review, external coordination) so the model does not silently drift between layers.

### Grounding and retrieval discipline

Give a retrieval budget instead of "search thoroughly":

```
For ordinary Q&A, start with one broad search using short, discriminative keywords.
If the top results contain enough support for the core request, answer from those
results. Make another retrieval call only when a required fact, owner, date, ID, or
source is missing. Do not search again only to improve phrasing.
```

Require that citations attach to the claims they support, that inference is labeled separately from supported fact, and that missing evidence is reported rather than papered over — absence of evidence should not silently become a factual "no".

### Progress updates

Ask for a short user-visible preamble before the first tool call, then updates only at phase changes:

```
Before tool calls for a multi-step task, send a one- or two-sentence user-visible
update that states the first step. During the task, update only when a major phase
begins or a finding changes the plan.
```

## Tool Use and Agentic Workflows

- **Expose only task-relevant tools.** Describe what each tool does, when to use it, important return fields, and error behavior — once, in the tool description.
- **State prerequisites explicitly** when correctness depends on lookups: "Before taking an action, resolve required discovery, retrieval, and validation steps. Do not skip a prerequisite because the intended final state seems obvious."
- **Parallelize independent reads; keep dependent calls sequential.** After parallel retrieval, synthesize before acting. On empty or suspiciously narrow results, try one or two meaningful fallbacks before concluding nothing exists.
- **Programmatic Tool Calling (PTC)** — GPT-5.6 can write JavaScript in a hosted runtime to batch tool calls and reduce large intermediate outputs (filter, join, rank, deduplicate, aggregate). Scope it to a bounded stage and keep judgment, approvals, and citation-bearing steps as direct calls; a generic "use PTC efficiently" instruction does not work:

```
Use Programmatic Tool Calling only for the bounded record-reduction stage. Call only
the documented read-only tools. Filter and deduplicate the intermediate results, then
emit exactly the required compact schema with evidence fields. Use direct tool calls
for approval, semantic judgment, citations, and final validation.
```

  Test the program output and the final assistant message separately — a program can return correct records while the message omits a required field, citation, or caveat.
- **Multi-agent (beta, Responses API)** lets a GPT-5.6 instance coordinate parallel subagents and synthesize their results; use it for work that divides cleanly into independent workstreams.

## Adapting Claude Prompts for GPT-5.6

| Aspect | Claude habit | GPT-5.6 adaptation |
|---|---|---|
| Thinking control | `effort` parameter, adaptive thinking always on | `reasoning.effort` (`none`–`max`); `none` available for latency-critical paths |
| Response length | Prompt for concision (Opus 5) | `text.verbosity` parameter for the default; prompt only for task-specific shape |
| Format control | Structured Outputs; "respond without preamble" | Same instruction style works; API output defaults to plain text — ask for Markdown explicitly if wanted |
| XML structure | `<instructions>`, `<context>` tags | Works on both; keep tag names consistent |
| Aggressive triggers | Soften `CRITICAL: You MUST` | Same direction: reserve absolutes for invariants; contradictions cost more than on Claude — de-duplicate and de-conflict first |
| Verification scaffolding | Remove — Claude 5 self-verifies | Keep targeted validation asks ("run the most relevant validation available; if validation cannot run, explain why") — GPT-5.6 responds well to an explicit completion bar |
| Subagent delegation | Cap spawn counts in prompts | Delegation is API-level (multi-agent beta / PTC), not prompt-level — scope it via the request configuration |

## Migrating from Earlier GPT-5.x

1. Switch the model and preserve the current reasoning effort as the baseline, then compare the same setting and one level lower — GPT-5.6 often holds quality with fewer tokens.
2. Run representative evals before changing the prompt.
3. Remove obsolete scaffolding, repeated instructions, and irrelevant tools.
4. Add only the smallest targeted instruction that fixes a measured regression.
5. Re-run evals after each prompt or reasoning change. Do not rewrite a working prompt stack at once — you lose attribution for behavior changes.

Migration hazards:

- GPT-5.4 (and its mini/nano tiers) commonly defaulted `reasoning.effort` to `none`; GPT-5.6 defaults to `medium`. An unedited migration silently gets slower and costlier — set effort explicitly.
- Re-check brevity instructions ("Be concise") — GPT-5.6's tighter default can turn them into over-truncation.
- Persisted reasoning defaults flipped to `all_turns` — verify multi-turn cost and behavior, and drop to `current_turn` where earlier reasoning goes stale.
- Implicit caching now places a managed breakpoint near the latest user or tool message; a large stable prefix followed by a changing suffix can lose cache hits — use explicit breakpoints for stable prefixes.
- `prompt_cache_retention` is replaced by `prompt_cache_options.ttl`.

## GPT-5 Family Baseline (Pre-5.6 Targets)

For prompts still targeting GPT-5 through GPT-5.5, these earlier-generation patterns apply (and remain compatible with 5.6):

- **Agentic eagerness is steerable in both directions.** Less eagerness: lower `reasoning_effort`, define explicit exploration criteria and a tool-call budget, and give an escape hatch ("proceed even if it might not be fully correct"). More eagerness: raise effort and add a persistence block ("keep going until the query is completely resolved; never stop at uncertainty — research or deduce the most reasonable approach and continue").
- **Tool preambles are trained behavior** — steer their frequency and style rather than suppressing them.
- **Markdown is off by default in the API.** Ask for it explicitly ("Use Markdown only where semantically correct"); re-assert every 3–5 turns in long conversations if adherence degrades.
- **Minimal reasoning (`reasoning_effort: minimal/none`) needs more prompt support**: a brief thought-process summary at the start of the answer, thorough tool preambles, maximally disambiguated tool instructions, and explicit planning, because the model has fewer reasoning tokens to plan with.
- **Metaprompting works**: give the model the current prompt, the desired and observed behavior, and ask for minimal edits — it is a strong optimizer of its own prompts.

## Quick Reference Templates

### Stopping conditions (prevents over- and under-iteration)
```
Resolve the request in the fewest useful tool loops, but do not let loop minimization
outrank correctness, required evidence, calculations, or required citations. After
each result, ask whether the core request can now be answered with useful evidence.
If yes, answer. If required evidence is still missing, name the missing fact and use
the smallest useful fallback.
```

### Outcome-first task definition
```
Resolve the customer's issue end to end.

Success means:
- make the eligibility decision from available policy and account evidence
- complete any allowed action before responding
- return completed_actions, customer_message, and blockers
- if required evidence is missing, ask for the smallest missing field
```

### Completion bar for coding work
```
After making changes, run the most relevant validation available: targeted tests for
changed behavior, type or lint checks when applicable, a minimal smoke test when full
validation is too expensive. If validation cannot be run, explain why and describe
the next best check.
```

### Editing / rewriting preservation
```
Preserve the requested artifact, length, structure, genre, and factual claims first.
Improve clarity, flow, and correctness without adding new claims, sections, or a more
promotional tone unless requested.
```
