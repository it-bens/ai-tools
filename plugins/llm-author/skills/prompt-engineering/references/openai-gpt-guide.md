# OpenAI GPT Prompt Engineering Guide (GPT-6, GPT-5.6)

GPT-6 (Astra, Sol, Luna) is the current OpenAI target generation. GPT-5.6 (Sol, Terra, Luna) guidance is kept and labeled, and the guide also marks what carries over from the earlier GPT-5 family (GPT-5 through GPT-5.5) for prompts that still target those models.

## Table of Contents

- [Model Family and Selection](#model-family-and-selection)
- [Core Prompting Posture](#core-prompting-posture)
- [API Parameters](#api-parameters)
- [GPT-6 Behavior and How to Prompt It](#gpt-6-behavior-and-how-to-prompt-it)
- [GPT-5.6 Behavior and How to Prompt It](#gpt-56-behavior-and-how-to-prompt-it)
- [Tool Use and Agentic Workflows](#tool-use-and-agentic-workflows)
- [Adapting Claude Prompts for GPT-6 and GPT-5.6](#adapting-claude-prompts-for-gpt-6-and-gpt-56)
- [Migrating to GPT-6](#migrating-to-gpt-6)
- [GPT-5 Family Baseline (Pre-5.6 Targets)](#gpt-5-family-baseline-pre-56-targets)
- [Quick Reference Templates](#quick-reference-templates)

## Model Family and Selection

### GPT-6

| Model | Best For |
|---|---|
| `gpt-6-astra` | Most capable: the hardest end-to-end work across code, apps, computer use, and research. `reasoning.effort` `low`–`max`; no `none` |
| `gpt-6-sol` | Everyday and complex coding and agentic work; the starting point for demanding agents. `reasoning.effort` `none`–`max`, default `medium` |
| `gpt-6-luna` | Most efficient: focused, clear, repeatable, high-volume tasks (extraction, classification, transformation, structured summaries). `reasoning.effort` `none`–`max`, default `medium` |

GPT-6 has no Terra tier, and tier names do not carry capability position across generations: GPT-6 Astra is the top tier, so GPT-6 Sol does not take over GPT-5.6 Sol's frontier position. Choose the GPT-6 model by workload, not by name. For Codex subagents, OpenAI's starting efforts are `medium` for Sol, `high` for Luna, and `low` for Astra; effort levels do not map exactly between generations, so compare a familiar task at a lower setting.

### GPT-5.6

| Model | Best For |
|---|---|
| `gpt-5.6-sol` | Frontier capability: hardest agentic, coding, and reasoning work (the `gpt-5.6` alias routes here) |
| `gpt-5.6-terra` | Balanced intelligence and cost for everyday work |
| `gpt-5.6-luna` | Efficient, high-volume, latency-sensitive workloads |

GPT-5.6's Sol, Terra, and Luna are capability tiers (replacing the earlier flagship/mini/nano naming); all three share the same prompting guidance. Prompt differences across the family come from `reasoning.effort` and `text.verbosity` settings, not from per-tier prompt styles.

## Core Prompting Posture

Verified for GPT-5.6. GPT-5.6 works best when the prompt defines the outcome, the important constraints, the available evidence, and the completion bar, then leaves the path to the model.

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

Use the Responses API for reasoning, tool-calling, and multi-turn workflows. Chat Completions with function tools works only at effective reasoning `none` on GPT-5.6, GPT-6 Sol, and GPT-6 Luna; GPT-6 Astra's tool calling requires Responses.

The table is verified for GPT-5.6. GPT-6 lists pro mode, persisted reasoning, prompt caching, Programmatic Tool Calling, and multi-agent orchestration among the GPT-5.6 capabilities it supports; its model pages do not list `text.verbosity`. GPT-6 differences: Astra has no `none` effort, and a `configuration_update` input item changes reasoning effort mid-conversation without rewriting the cached prompt prefix.

| Parameter | Values / Behavior |
|---|---|
| `reasoning.effort` | `none`, `low`, `medium`, `high`, `xhigh`, `max`; default `medium`. `max` is new in 5.6 — reserve it for the hardest quality-first workloads and compare against `xhigh` rather than adopting it globally |
| `reasoning.mode` | `"pro"` enables pro mode on the same model slug: more internal work, one final answer, higher latency and token use. Independent of effort. Do not prompt "think harder" or "generate candidates" — keep the same outcome-focused prompt |
| `reasoning.context` | Persisted reasoning across turns. GPT-5.6 defaults to `all_turns` (earlier models: `current_turn`). Set `current_turn` when earlier reasoning is stale — persisted reasoning is not an always-on optimization; stale reasoning adds tokens and anchors the model to an outdated approach |
| `text.verbosity` | `low` / `medium` / `high` — default level of response detail. Set the default here; put task-specific length and structure requirements in the prompt |
| Prompt caching | Explicit breakpoints via `prompt_cache_options.mode: "explicit"`; `prompt_cache_options.ttl` replaces `prompt_cache_retention`. Cache writes bill at 1.25× the uncached input rate — track `cached_tokens` and `cache_write_tokens` |

Before raising `reasoning.effort` to fix quality, check whether the prompt is missing a success criterion, dependency rule, tool-routing rule, or verification loop — effort increases are the last resort, not the first.

## GPT-6 Behavior and How to Prompt It

OpenAI offers these prompts "as a starting point across the GPT-6 model family. They address behavior observed with GPT-6 Astra; evaluate them with your chosen model and workload." Do not assume Sol or Luna behave like Astra — test each pattern on the target model.

### Bias toward action and completion

Astra is more likely to ask a clarifying or non-blocking question, or to stop after a first implementation for review, where earlier models would make assumptions and continue. Define completion before starting and state that action requests authorize the work:

```
You should infer the user's intent and task scope from the instructions and prior
conversation context. Your job is to bias towards action and carry the user's intended
task to completion.
```

Ask for approval only once a concrete, reviewable result exists — do the authorized work first so approval is the final step. Keep the confirmation tier explicit (see [Proactive and persistent](#proactive-and-persistent--set-autonomy-boundaries); that section and its template are mandatory for GPT-6 agentic prompts), but replace blanket "ask first" language written for earlier models — Astra can take it too seriously and stop where continuing is wanted.

### The user's instructions over skill guidelines

Astra follows instructions closely and is more sensitive to skills and `AGENTS.md`; unclear or conflicting guidance there can make it pause early. State the precedence:

```
The user's instructions take precedence over guidelines provided in a skill. If explicit
user instructions conflict with a skill's instructions, prioritize the user's instructions.
```

### Conditional, not blanket, instruction files

- Give `AGENTS.md` and skills conditional pointers instead of standing orders: "Use architecture.md for service boundaries, database.md for schema changes", not "Before every edit, read architecture.md, database.md, and deployment.md".
- Keep skill descriptions short and specific about when to use them: "Use when adding or changing a migration, or reviewing its rollout", not "Use when working with databases, queries, models, or persistence".
- Make a multi-workflow skill's root file a minimal router to supporting docs; drop step-by-step itineraries that over-constrain.
- Instruction files are shared across contributors' models: guidance that helps Sol or Luna may over-constrain Astra.

### Concise paragraphs over lists

Astra tends toward lists, tables, and Markdown. Where prose is wanted, say so:

```
Default to using clear, concise paragraphs, each developing one main idea. Use lists only
when the information is genuinely parallel, sequential, or easier to compare.
```

### Bounded testing and autonomous test runs

Astra tests and checks its work on its own, so carried-over "run the tests" encouragement leads to unnecessary testing. Bound re-verification, and grant standing permission for workflows known to be safe:

```
Run tests appropriate to the change and complete required checks. Once those pass,
broaden or repeat testing only when new changes, failures, or unresolved concerns
justify it; otherwise, continue toward completing the task.
```

```
The local tests use disposable fixtures and have no production access. Run them, fix
failures caused by the requested change, and rerun affected tests without asking for
approval at each step.
```

## GPT-5.6 Behavior and How to Prompt It

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

Mandatory for GPT-6 agentic prompts as well as GPT-5.6: keep the confirmation tier for external writes and destructive actions explicit.

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
PTC and multi-agent guidance below is verified for GPT-5.6; GPT-6 lists both among the GPT-5.6 capabilities it supports.

- **Programmatic Tool Calling (PTC)** — GPT-5.6 can write JavaScript in a hosted runtime to batch tool calls and reduce large intermediate outputs (filter, join, rank, deduplicate, aggregate). Scope it to a bounded stage and keep judgment, approvals, and citation-bearing steps as direct calls; a generic "use PTC efficiently" instruction does not work:

```
Use Programmatic Tool Calling only for the bounded record-reduction stage. Call only
the documented read-only tools. Filter and deduplicate the intermediate results, then
emit exactly the required compact schema with evidence fields. Use direct tool calls
for approval, semantic judgment, citations, and final validation.
```

  Test the program output and the final assistant message separately — a program can return correct records while the message omits a required field, citation, or caveat.
- **Multi-agent (beta, Responses API)** lets a GPT-5.6 instance coordinate parallel subagents and synthesize their results; use it for work that divides cleanly into independent workstreams.

## Adapting Claude Prompts for GPT-6 and GPT-5.6

| Aspect | Claude habit | GPT adaptation |
|---|---|---|
| Thinking control | `effort` parameter, adaptive thinking always on | `reasoning.effort` (`none`–`max`); `none` available for latency-critical paths (not on GPT-6 Astra) |
| Response length | Prompt for concision (Opus 5) | GPT-5.6: `text.verbosity` parameter for the default; prompt only for task-specific shape. GPT-6 Astra: state the writing style and structure (it defaults to lists and Markdown) |
| Format control | Structured Outputs; "respond without preamble" | Same instruction style works; API output defaults to plain text — ask for Markdown explicitly if wanted |
| XML structure | `<instructions>`, `<context>` tags | Works on both; keep tag names consistent |
| Aggressive triggers | Soften `CRITICAL: You MUST` | Same direction: reserve absolutes for invariants; contradictions cost more than on Claude — de-duplicate and de-conflict first |
| Verification scaffolding | Remove — Claude 5 self-verifies | Keep targeted validation asks ("run the most relevant validation available; if validation cannot run, explain why") — GPT-5.6 responds well to an explicit completion bar. GPT-6 Astra tests on its own: bound re-verification instead |
| Subagent delegation | Cap spawn counts in prompts | GPT-5.6: delegation is API-level (multi-agent beta / PTC), not prompt-level — scope it via the request configuration. GPT-6 Astra may delegate less than wanted: state when and how much to use subagents |

## Migrating to GPT-6

### GPT-5.6 → GPT-6

1. Set `model` to `gpt-6-astra`, `gpt-6-sol`, or `gpt-6-luna` by workload (see [Model Family and Selection](#model-family-and-selection)) — not by carrying the tier name over.
2. Preserve the current effective reasoning effort where supported. Astra has no `none`: use `low`. From `minimal`, start with `low` and compare on representative tasks.
3. When reasoning effort is not `none`, remove `temperature`, `top_p`, and `top_logprobs` (Chat Completions: also `logprobs`; Responses: drop `message.output_text.logprobs` from `include`).
4. Keep reasoning with tools on the Responses API. Astra's tool calling requires Responses; Sol and Luna keep GPT-5.6's Chat Completions limit (function calling only at `reasoning_effort: "none"`).
5. To change effort between responses, send `configuration_update` input items and keep request-level `reasoning.effort` unchanged, so the cached prompt prefix survives.
6. Audit skills and `AGENTS.md` for blanket or conflicting instructions, then apply the [GPT-6 guidance](#gpt-6-behavior-and-how-to-prompt-it) one change at a time, re-running evals per model.

### Earlier GPT-5.x → GPT-5.6

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
