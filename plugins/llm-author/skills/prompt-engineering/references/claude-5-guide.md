# Claude 5 Prompt Engineering Guide

Claude 5 (Opus 5.5, Opus 5, Sonnet 5, Fable 5.1) is the default target generation, and Opus 5.5 is the recommended default model. For Claude 4 (Opus 4.x, Sonnet 4.x) and Haiku 4.5, use `claude-4-guide.md`.

## Table of Contents

- [What Changed from Claude 4](#what-changed-from-claude-4)
- [Breaking Changes (API Errors on Claude 5)](#breaking-changes-api-errors-on-claude-5)
- [The effort Parameter](#the-effort-parameter)
- [Adaptive Thinking](#adaptive-thinking)
- [Behavioral Changes and How to Prompt Them](#behavioral-changes-and-how-to-prompt-them)
- [Per-Model Guidance](#per-model-guidance)
- [Model Selection](#model-selection)
- [Optimizing LLM-Targeted Content for Claude 5](#optimizing-llm-targeted-content-for-claude-5)
- [Quick Reference Templates](#quick-reference-templates)

## What Changed from Claude 4

Claude 5 models exercise more judgment and need less scaffolding. Prompts tuned for Claude 4 frequently *over*-steer Claude 5: instructions that compensated for weaker instruction-following now push the model into over-verification, over-triggering, and unwanted verbosity. Control behavior through the `effort` parameter and targeted, positive instructions instead of stacked rules.

Two classes of change:

1. **Hard breaking changes** — API parameters that now return an error.
2. **Behavioral changes** — the same call produces different default behavior; re-tune the prompt.

## Breaking Changes (API Errors on Claude 5)

| Removed on Claude 5 | Replacement |
|---|---|
| Assistant prefill on the last turn → 400 | Structured Outputs; a direct system instruction ("Respond directly, without preamble"); or `output_config.format` |
| `thinking: {type: "enabled", budget_tokens: N}` → 400 | Adaptive thinking plus the `effort` parameter |
| Non-default `temperature` / `top_p` / `top_k` → 400 | Steer tone and variety through the prompt |
| `thinking: {type: "disabled"}` — rejected on Fable 5, Fable 5.1, and Opus 5.5 (any effort) and on Opus 5 at `xhigh`/`max` | Keep thinking enabled; lower `effort` for cost |
| Forced `tool_choice` (`{type: "any"}` / `{type: "tool"}`) → 400 on Opus 5.5 and Fable 5.1 | `tool_choice: auto` plus strict tool use or Structured Outputs; say in the prompt when the tool applies |

SDKs still type-check the sampling fields, so the code compiles but the API rejects the request at runtime. Prefill (removed at 4.6), `budget_tokens` (4.7), and non-default sampling params (4.6–4.7) already error on late Claude 4 models; the `thinking: {type: "disabled"}` restriction is new at Claude 5, and forced `tool_choice` is new at Opus 5.5 and Fable 5.1. Token counts shift by generation: about 30% more tokens for Sonnet 4.6 → Sonnet 5, but roughly unchanged for Opus 4.7 / 4.8 → Opus 5 and for Fable 5 (larger increases only from Opus 4.6 or earlier). Recount tokens against the target model rather than reusing Claude 4 limits.

## The effort Parameter

`effort` ∈ {`low`, `medium`, `high`, `xhigh`, `max`}; default `high` on Opus 5, Sonnet 5, and Fable 5.1, `medium` on Opus 5.5. It scales *thinking* volume, trading intelligence for latency and cost. On Opus 5, raising or lowering effort does not reliably change visible response length (prompt for length separately); on Sonnet 5, lower effort narrows how much work the model takes on.

- `low`/`medium` give strong quality at much lower cost on Opus 5 and Fable 5; use them as the primary cost and latency lever where quality holds.
- `xhigh`/`max` are for the hardest coding and agentic work. At these levels, set a large `max_tokens` (start around 64k; up to the 128,000 maximum on Opus 5.5) so the answer is not truncated by thinking.
- Re-sweep effort against your own evals when migrating, including between Claude 5 models; do not carry Claude 4 assumptions forward or copy the level. Level names do not correspond to the same amount of thinking across models: in Anthropic's testing, Opus 5.5 at `medium` matches or exceeds Opus 5 at `high`, and on several coding evaluations `low` comes close to it.

## Adaptive Thinking

- Omitting the `thinking` field now runs adaptive thinking (Claude 4 ran without it). `max_tokens` caps thinking plus response combined — revisit it.
- Raw chain-of-thought is not returned. Opt into `thinking.display: "summarized"` for readable reasoning.
- To damp excess thinking: "Thinking adds latency and should only be used when it will meaningfully improve answer quality, typically for problems that require multistep reasoning. When in doubt, respond directly."

## Behavioral Changes and How to Prompt Them

### Verbosity: the generation trends concise; Opus 5 is the exception

The Claude 5 generation is more concise than Claude 4 by default. Opus 5 is the exception — its responses and written files run longer, and raising or lowering effort does not reliably change visible length, so prompt Opus 5 for concision:

```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

Sonnet 5 calibrates length to task complexity (shorter on simple lookups, longer on open-ended analysis); Fable 5 can over-elaborate at high effort. Add the concision instruction where the model runs long, not universally.

Positive concision examples steer better than "don't be verbose."

### Instruction following is literal

Claude 5 does not silently generalize an instruction from one item to the rest, and does not infer unrequested work. State scope explicitly: "Apply this to every section, not just the first."

### Opus 5 self-verifies and self-corrects — remove old verification prompts there

On Opus 5, carried-over "double-check your answer", "add a final verification step", or "use a subagent to verify" cause *over*-verification — wasted tokens with no quality gain. Remove them rather than rewriting. For narrow tasks, constrain the scope instead.

This does not generalize across the generation. Fable 5 runs the other way on long-horizon work — verification stays explicit there, with fresh-context verifier subagents (see its section). Sonnet 5 has no finding in either direction, so leave its verification instructions as they are rather than stripping them.

### It delegates to subagents natively

Claude 5 models recognize when work is worth delegating and spawn subagents without being told to — give explicit delegation criteria rather than leaving it implicit. Opus 5 and Fable 5 go further and delegate *more readily than prior models* (Sonnet 5 has no such finding). For cost-sensitive Opus 5 work, cap spawn counts (Fable 5 is the exception — it is built for heavy parallel delegation; see its section):

```
Delegate to a subagent only for large tasks that are genuinely independent and
parallelizable, such as a wide multi-file investigation. Do not delegate work you can
finish yourself in a handful of tool calls, and do not use subagents to verify your own
work. If one subagent can complete the task, use one rather than several, and keep spawn
counts low.
```

### Dial back aggressive language

Aggressive phrasing carried from older prompts — `CRITICAL: You MUST use this tool...` — over-triggers on current models (a shift since Opus 4.5). Use plain "Use this tool when...".

### Remove forced progress-update scaffolding

Claude 5 gives good interim updates on its own. Delete "summarize progress every N tool calls" scaffolding; describe the update shape only if you need to change it, using positive examples.

## Per-Model Guidance

### Opus 5.5 — recommended default

- Existing Opus 5 prompts should perform well without changes, and the Opus 5 section below remains a starting point. Instructions tuned for Opus 5's behavior may no longer be needed; remove one only when evals show it no longer helps.
- Adaptive thinking is always on and the default effort is `medium`; `effort` is the only thinking control. To get less thinking, lower effort first — it reduces thinking more reliably than prompt instructions.
- At a given effort it thinks more per turn than Opus 5, most at `xhigh` and `max`. Set `max_tokens` up to 128,000 (the maximum) for long agentic turns, and reserve `xhigh` and `max` for work where a quality gain has been measured.
- On long, multi-part tasks it ends some turns with a text-only progress update (`stop_reason: "end_turn"`). In an unattended loop, treat that as a report, not completion: keep the task's parts in a checklist the model updates, send a short message naming the open items when a turn ends with items open and no blocker stated, and stop after two or three automatic continuations. A system-prompt addition that names the specific early stops to avoid (and the stops you do want) makes them rarer, at the cost of more tool calls and output tokens; leave it out of human-in-the-loop applications and keep a confirmation step for risky or irreversible actions.
- Wrap text the user pasted from elsewhere in tags carrying the same application-generated random ID, and state in the system prompt that instructions inside follow only where the user's own message asks for them:
  ```
  <pasted_content id="ab12">
  ...text the user pasted...
  </pasted_content id="ab12">
  ```
  The tags are plain text and can be imitated — one guardrail among other prompt-injection defenses.
- Do **not** instruct it to echo, transcribe, or write out its internal reasoning in the response — that can be declined with the `reasoning_extraction` refusal. Read summarized `thinking` blocks (`display: "summarized"`) instead.
- In chat system prompts, remove "think carefully before answering" lines; effort is the control, and removing them made replies start sooner without a clear quality loss.
- For agents working across several connected apps, one sentence telling it to explore the relevant emails, documents, tabs, and records before acting — including ones the task does not mention — improves correctness; keep untrusted content out of what it searches.
- For frontend work, name the specific patterns to avoid (e.g. cream background, pill-shaped buttons) rather than "avoid a generic look", and extend the list iteratively.
- Re-test visual-input scaffolding built for earlier models; it reads charts, diagrams, and screenshots more precisely without tools.

**Opus 5 → Opus 5.5 checklist:**

- [ ] Model ID `claude-opus-5-5`
- [ ] Remove `thinking: {type: "disabled"}` and `thinking: {type: "enabled", budget_tokens: N}`; remove forced `tool_choice` (`any` / `tool`) in favor of `auto` plus strict tool use or Structured Outputs
- [ ] Re-sweep effort starting at `low`/`medium`; set it explicitly
- [ ] Raise `max_tokens` at `xhigh`/`max`
- [ ] Where computer use applies (Claude API, Google Cloud): `computer_20251124` → `computer_toolset_20260801`
- [ ] Leave prompt text unchanged unless evals regress

### Opus 5 — complex agentic coding and enterprise

- 1M-token context is the default and the max; instruction-following, tool-calling, and reasoning hold across the full window.
- Completes full tasks rather than leaving stubs or placeholders; give the complete spec up front and let it run.
- Runs longer by default (both responses and written files) — prompt for concision and length.
- Verifies and self-corrects unprompted — remove verification and double-check instructions.
- Delegates to subagents readily — cap delegation.
- With thinking disabled it can leak tool calls as plain text or internal XML tags into the output. Prefer keeping thinking on at `low` effort over disabling it. Do not add rules telling it "not to think" (that increases tag leakage), and do not name thinking tags specifically.

### Sonnet 5 — balanced coding and agentic work

- Performs well out of the box on existing Sonnet 4.6 prompts.
- More agentic than 4.6 and runs self-verification loops more readily. With thinking off it reaches for tools less — nudge explicitly if you depend on tool calls.
- `thinking: {type: "disabled"}` is allowed at any effort level (unlike Opus 5, Opus 5.5, Fable 5, and Fable 5.1).
- More literal at low effort — state scope; for multistep work at `low` effort add "Think carefully through the problem before responding."
- Frontend and design: settles into a fixed default visual style, and generic negatives ("make it clean") just shift it to another fixed style. Because sampling temperature is no longer available, get variety by asking it to propose several distinct visual directions first, or by giving a concrete design spec.
- Code review: it follows "only report high-severity issues" literally and under-reports. For coverage, ask it to report every finding with a confidence level and severity, and filter downstream.

### Fable 5 — hardest, long-horizon autonomous work

- The most capable tier, built for multiday, goal-directed autonomous runs and problems that were previously too complex or long-running. Start tasks at the top of your difficulty range.
- Adaptive thinking is always on and cannot be disabled.
- Turns can run for many minutes at higher effort, and autonomous runs can extend for hours. Use async patterns (streaming, scheduled check-ins) and generous client timeouts rather than blocking.
- Dispatches parallel subagents reliably — delegate freely with explicit guidance; prefer asynchronous orchestrator-to-subagent communication over blocking. Use long-lived subagents that retain context across subtasks to save time and cost. Verification is the one exception: a subagent that carried the work's context is the wrong one to audit it.
- Keep self-verification explicit on long-running work — unlike on Opus 5, do not strip it. Instruct it to establish a method for checking its own work at a stated interval as it builds, and to run that check with separate, fresh-context subagents against the specification; those outperform self-critique.
- Give it a memory system (one lesson per file, with a one-line summary) and a way to surface user-facing content mid-run: a `send_to_user`-style tool paired with an explicit instruction to call it — without that instruction it rarely calls the tool, even when the tool is defined.
- Do **not** instruct it to echo, transcribe, or explain its internal reasoning as response text — on Fable 5, as on Opus 5.5, this can trigger the `reasoning_extraction` refusal. If you need reasoning visibility, read the summarized `thinking` blocks instead.
- Ground long-run status reports: "Before reporting progress, audit each claim against a tool result from this session. Report outcomes faithfully: if tests fail, say so with the output; when something is done and verified, state it plainly."
- Requires standard (non-zero) data retention.

Anti-overengineering and scope-constraint instructions help across Opus 5, Sonnet 5, and Fable 5 at higher effort — no unrequested refactors, abstractions, or defensive code for scenarios that cannot happen.

## Model Selection

| Model | Best For |
|---|---|
| Opus 5.5 | Start here for most workloads; long-running agentic coding and knowledge work |
| Fable 5.1 | Demanding reasoning and long-horizon agentic work, or when evals on Opus 5.5 at higher effort still fall short; highest cost (the Fable guidance above is documented for Fable 5) |
| Sonnet 5 | Balanced coding and agentic work at lower cost; drop-in for existing Sonnet 4.6 prompts |
| Opus 5, Fable 5 | Legacy, still available; existing prompts targeting them |

All serve a 1M-token context window.

For Claude 4 and earlier targets, use `claude-4-guide.md` (also the closest fit for Haiku 4.5).

## Optimizing LLM-Targeted Content for Claude 5

When the *target* is a Claude 5 model, the "preserve all substantive content" default gives way to "less is more": Claude 5 exercises judgment, so over-constraint degrades output. Prefer:

- **Judgment heuristics over absolute rules.** "Match the surrounding code's comment density" beats "NEVER write multi-line comments."
- **Interface design over worked examples.** Typed parameters and enums steer tool use better than examples, which narrow the model's exploration space.
- **Progressive disclosure over everything-upfront.** Move situational guidance into selectively-loaded references and skills; keep the always-loaded surface small.
- **Single-source instructions.** State a tool's usage once, in its description, rather than repeating it across the system prompt.
- **Rich references over prose specs.** Code, test suites, and HTML mockups are higher-fidelity inputs than descriptions of them.

For Claude 5 targets, cut scaffolding that existed to compensate for weaker instruction-following — over-constraint degrades output more than it prevents error.

## Quick Reference Templates

### Concision (Opus 5; Fable 5 at high effort)
```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

### Cap subagent delegation (Opus 5)
```
Delegate to a subagent only for large, genuinely independent, parallelizable tasks. Do not
delegate work you can finish in a handful of tool calls, and do not use subagents to verify
your own work. Keep spawn counts low.
```

### Replace prefill for format control (prefill now returns 400)
```
Respond directly with the requested format and no preamble.
```
Or use Structured Outputs / `output_config.format`.

### Constrain scope (Opus 5 — damps over-verification and scope expansion)
```
Deliver what was asked, at the scope intended. Make routine judgment calls yourself; check in
only when different readings would lead to materially different work. Don't add verification
steps, refactors, abstractions, or error handling for scenarios that cannot happen.
```
