# Claude 5 Prompt Engineering Guide

Optimizations for Claude 5 models: Opus 5, Sonnet 5, and Fable 5. Claude 5 is the default target generation. For Claude 4 (Opus 4.x, Sonnet 4.x) and Haiku 4.5, use `claude-4-guide.md`.

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
| `thinking: {type: "disabled"}` — rejected on Fable 5 (any effort) and on Opus 5 at `xhigh`/`max` | Keep thinking enabled; lower `effort` for cost |

SDKs still type-check the sampling fields, so the code compiles but the API rejects the request at runtime. Of the four rows, only the `thinking: {type: "disabled"}` restriction is genuinely new at Claude 5; prefill (removed at 4.6), `budget_tokens` (4.7), and non-default sampling params (4.6–4.7) already error on late Claude 4 models. Token counts shift by generation: about 30% more tokens for Sonnet 4.6 → Sonnet 5, but roughly unchanged for Opus 4.7 / 4.8 → Opus 5 and for Fable 5 (larger increases only from Opus 4.6 or earlier). Recount tokens against the target model rather than reusing Claude 4 limits.

## The effort Parameter

`effort` ∈ {`low`, `medium`, `high`, `xhigh`, `max`}; default `high`. It scales *thinking* volume, trading intelligence for latency and cost. On Opus 5, raising or lowering effort does not reliably change visible response length (prompt for length separately); on Sonnet 5, lower effort narrows how much work the model takes on.

- `low`/`medium` give strong quality at much lower cost on Opus 5 and Fable 5; use them as the primary cost and latency lever where quality holds.
- `xhigh`/`max` are for the hardest coding and agentic work. At these levels, set a large `max_tokens` (start around 64k) so the answer is not truncated by thinking.
- Re-sweep effort against your own evals when migrating; do not carry Claude 4 assumptions forward.

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

### It self-verifies and self-corrects — remove old verification prompts

Carried-over "double-check your answer", "add a final verification step", or "use a subagent to verify" now cause *over*-verification — wasted tokens with no quality gain. Remove them rather than rewriting. For narrow tasks, constrain the scope instead.

### It delegates to subagents more readily

All Claude 5 models delegate more readily and do so proactively — give explicit delegation criteria rather than leaving it implicit. For cost-sensitive Opus 5 work, cap spawn counts (Fable 5 is the exception — it is built for heavy parallel delegation; see its section):

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

### Opus 5 — complex agentic coding and enterprise

- 1M-token context is the default and the max; instruction-following, tool-calling, and reasoning hold across the full window.
- Completes full tasks rather than leaving stubs or placeholders; give the complete spec up front and let it run.
- Runs longer by default (both responses and written files) — prompt for concision and length.
- Verifies and self-corrects unprompted — remove verification and double-check instructions.
- Delegates to subagents readily — cap delegation.
- With thinking disabled it can leak tool calls as plain text or internal XML tags into the output. Prefer keeping thinking on at `low` effort over disabling it. Do not add rules telling it "not to think" (that increases tag leakage), and do not name thinking tags specifically.
- `effort` matters more here than on any prior Opus — experiment with it actively when you upgrade.

### Sonnet 5 — balanced coding and agentic work

- Performs well out of the box on existing Sonnet 4.6 prompts.
- More agentic than 4.6 and runs self-verification loops more readily. With thinking off it reaches for tools less — nudge explicitly if you depend on tool calls.
- `thinking: {type: "disabled"}` is allowed at any effort level (unlike Opus 5 and Fable 5).
- More literal at low effort — state scope; for multistep work at `low` effort add "Think carefully through the problem before responding."
- Frontend and design: settles into a fixed default visual style, and generic negatives ("make it clean") just shift it to another fixed style. Because sampling temperature is no longer available, get variety by asking it to propose several distinct visual directions first, or by giving a concrete design spec.
- Code review: it follows "only report high-severity issues" literally and under-reports. For coverage, ask it to report every finding with a confidence level and severity, and filter downstream.

### Fable 5 — hardest, long-horizon autonomous work

- The most capable tier, built for multiday, goal-directed autonomous runs and problems that were previously too complex or long-running. Start tasks at the top of your difficulty range.
- Adaptive thinking is always on and cannot be disabled.
- Turns can run for many minutes at higher effort, and autonomous runs can extend for hours. Use async patterns (streaming, scheduled check-ins) and generous client timeouts rather than blocking.
- Dispatches parallel subagents reliably — delegate freely with explicit guidance; prefer asynchronous orchestrator-to-subagent communication over blocking, and use long-lived subagents that retain context across subtasks to save time and cost.
- Give it a memory system (one lesson per file, with a one-line summary) and a way to surface user-facing content mid-run: a `send_to_user`-style tool paired with an explicit instruction to call it — without that instruction it rarely calls the tool, even when the tool is defined.
- Do **not** instruct it to echo, transcribe, or explain its internal reasoning as response text — this can trigger a refusal. If you need reasoning visibility, read the summarized `thinking` blocks instead.
- Ground long-run status reports: "Before reporting progress, audit each claim against a tool result from this session. Report outcomes faithfully: if tests fail, say so with the output; when something is done and verified, state it plainly."
- Requires standard (non-zero) data retention.

Anti-overengineering and scope-constraint instructions help across all three models at higher effort — no unrequested refactors, abstractions, or defensive code for scenarios that cannot happen.

## Model Selection

| Model | Best For |
|---|---|
| Fable 5 | Hardest, longest-running autonomous and agentic problems; multiday runs; highest capability at highest cost |
| Opus 5 | Complex agentic coding, large refactors, and enterprise work; long-horizon tasks |
| Sonnet 5 | Balanced coding and agentic work at lower cost; drop-in for existing Sonnet 4.6 prompts |

All three serve a 1M-token context window by default.

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

### Concision (Claude 5 runs long by default)
```
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

### Cap subagent delegation
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

### Constrain scope (damps self-verification and scope expansion)
```
Deliver what was asked, at the scope intended. Make routine judgment calls yourself; check in
only when different readings would lead to materially different work. Don't add verification
steps, refactors, abstractions, or error handling for scenarios that cannot happen.
```
