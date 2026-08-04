# Claude reasoning effort and the subagent dial — findings

Why this plugin ships agent definitions at all, and where the rung choices come from. Statements here describe what was measured or what the vendor documents; the routing decisions built on top live in `skills/orchestrating-subagent-work/references/model-routing.md`.

This is a workaround. Claude Code has open issues on per-spawn reasoning effort; when it becomes settable at dispatch time, most of this document and most of `agents/` becomes unnecessary.

## What is settable, and where

| Surface | Mechanism | Granularity |
|---|---|---|
| Session | `/effort`, `--effort`, `CLAUDE_CODE_EFFORT_LEVEL`, `settings.json` `effortLevel` | Whole session |
| Skill | `effort` in `SKILL.md` frontmatter | While that skill is active |
| Subagent | `effort` in an agent definition (`agents/*.md` frontmatter, or `--agents` JSON) | Per definition |
| Subagent spawn | **nothing** | — |

Levels are `low`, `medium`, `high`, `xhigh`, `max`. The default is `high` on every effort-capable model, and setting `high` explicitly is identical to omitting the parameter. Precedence runs environment variable, then configured or frontmatter level, then model default.

A subagent with no `effort` in its definition inherits the session level. That is the documented default, not an inference.

## The spawn-time argument is silently discarded

The Agent tool accepts an `effort` argument and ignores it. It does not error, warn, or downgrade — the value has no effect. Three lines of evidence, gathered 2026-08-04 on Claude Code 2.x with an `xhigh` session:

**A battery at two declared rungs.** Six sonnet subagents received an identical eight-problem reasoning battery with tools forbidden — three chained modular-arithmetic sequences with dual tallies, two five-digit products with digit sums, an overlapping-substring count over a 90-character string, a modular exponentiation, and a divisibility-plus-digit-sum selection. Ground truth was computed in Python, not by hand. Three spawns declared `effort: low`, three declared `effort: max`.

All six returned byte-identical, fully correct answers on all eight problems, with zero tool uses.

| Declared | Tokens | Mean | Duration | Mean |
|---|---|---|---|---|
| `low` | 76,668 / 75,692 / 82,074 | 78,145 | 222.7 s / 221.0 s / 279.5 s | 241 s |
| `max` | 66,696 / 80,200 / 76,366 | 74,421 | 153.0 s / 248.4 s / 218.2 s | 207 s |

The `low` runs cost more and ran longer, with fully overlapping ranges. Effort scales thinking volume, so a working parameter would show `low` consuming markedly fewer tokens — Anthropic's own figures put low at roughly 64% below xhigh. There is no dose-response here.

**An invalid value passes.** `effort: "banana"` was accepted without a validation error and the agent ran normally. A parameter the tool validates would reject it.

**The runtime reports the session level.** `CLAUDE_EFFORT`, which the harness sets in subagent Bash subprocesses to the active level for the turn, read `xhigh` inside both a `low` spawn and a `max` spawn — matching the main session.

Limits of this experiment, stated because they matter: every run therefore executed at `xhigh`, so the battery was never exercised at a genuinely low rung. This establishes the absence of an effect through cost and through the runtime's own report, not through a demonstrated accuracy gap. Six runs is also a small sample; the token overlap is wide enough that a small effect could hide in it, but not one large enough to matter.

The practical consequence for maintainers: writing `effort` into a spawn produces a plausible-looking dispatch that quietly runs at whatever the session happens to be set to. A definition is the only mechanism that binds.

## Haiku 4.5 has no effort parameter

Haiku 4.5 rejects `effort` at the API. The exclusion is unconditional — `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT`, which forces the parameter onto unrecognised model identifiers, still excludes it by name.

Its depth lever is manual extended thinking. It is the one current model that accepts `thinking: {type: "enabled", budget_tokens: N}` and rejects adaptive thinking. In Claude Code that budget is `MAX_THINKING_TOKENS`, a process-wide environment variable, and the subagent frontmatter field list contains no thinking or budget field. So per-worker depth control for haiku does not exist, and the haiku definitions here carry no effort by necessity rather than by choice.

Haiku subagents also receive depth instructions the other models do not. Probes of built-in agent types on haiku reported `<thinking_mode>interleaved</thinking_mode>` and `<max_thinking_length>31999</max_thinking_length>` in their instructions; the same probes on sonnet and opus reported no depth directive at all. That is harness-injected per model and cannot be set from a definition.

## Choosing a rung

The vendor discriminator between the two dials, which the routing table applies: capability is the model setting, thoroughness is the effort setting. Operationally — a worker that skipped a file or stopped partway needs more effort; a worker that had everything it needed, tried, and still got it wrong needs a stronger model.

**Opus 5 is the most effort-sensitive model measured, which is why three rungs ship.** From its system card: on FrontierBench v0.1 (74 terminal and agentic tasks under a mini-SWE-agent harness) mean reward runs 25% at `low`, 39% at `high`, and 44.4% at `xhigh`, with `max` at roughly 43% — inside the noise of `xhigh`. On FrontierCode v1.1 (150 real-pull-request coding tasks, run with Cognition) the best score on both the main and extended sets falls at `medium`, at 53.4% and 63.6%. A 19-point spread across rungs on one model is the largest effort sensitivity in any source gathered here, and the peak is not at the top.

**`max` ships on nothing.** It measures within noise of `xhigh` on the one benchmark that separates them, Anthropic documents it as prone to overthinking on structured-output and less intelligence-sensitive work, and every agent here receives a bounded subtask rather than an open problem.

**Sonnet's ceiling is `xhigh` by its own guidance**, which names it for the hardest coding and agentic use cases. Its documented risk at `low` is under-thinking on moderately complex tasks, so `investigate-sonnet-low` is scoped to closed questions. Anthropic's own effort table names subagent work as a canonical `low`-effort case, which is the argument for having a cheap rung at all.

**Prefer a stronger model at a lower rung over a weaker model at a higher one.** On MCPMark's agentic tool-use tasks, gpt-5 at `low` (46.85%) beat gpt-5-mini at `high` (30.32%), and gpt-5-nano gained nothing from effort at any rung. The finding is cross-vendor rather than Claude-specific, and it is the reason the set has no opus `low` variant — sonnet at `medium` dominates that cell.

**Effort does not buy consistency.** MCPMark reports gpt-5 at `medium` scoring 68.5% pass@4 against 33.9% pass^4. Run-to-run variance of that size is not closed by any rung, which is why this plugin's two-worker confirmation is not an effort setting and does not scale down with one.

**One thing deliberately not encoded.** No measured evidence was found that running confirmers at a higher rung than producers beats matched rungs. The nearest academic work scales verifier count rather than verifier depth and is itself non-monotonic. Every recommendation to the contrary traced to posts without methodology.

## Cross-vendor note

Anthropic orders the two levers effort-first — set the rung, then add prompt guidance only if behavior still misses, because effort is a calibrated control and prompt wording is not. OpenAI orders them the other way for GPT-5.6, directing that a prompt be checked for a missing success criterion, dependency rule, tool-routing rule, or verification loop before effort is raised. A dispatch crossing both families cannot carry one ordering rule. The GPT side of this is in `gpt-5-6-model-family.md`.

## Sources

Vendor documentation and first-party measurement:

- Effort parameter, levels, defaults, per-level guidance: https://platform.claude.com/docs/en/build-with-claude/effort
- Claude Code effort configuration and precedence: https://code.claude.com/docs/en/model-config
- Subagent frontmatter fields, inheritance, thinking configuration: https://code.claude.com/docs/en/sub-agents
- `MAX_THINKING_TOKENS`, `CLAUDE_EFFORT`, `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT`: https://code.claude.com/docs/en/env-vars
- Model versus effort selection: https://claude.com/blog/claude-model-and-effort-level-in-claude-code
- FrontierBench and FrontierCode effort figures: Claude Opus 5 System Card, https://www-cdn.anthropic.com/c5fbac3f0b1280a933ebd26d3cb8bb9f5bdeaf48/Claude%20Opus%205%20System%20Card.pdf
- Per-model prompting guides: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/

Independent measurement, cited as such:

- Effort ablations and pass@4 versus pass^4 on agentic tool use: MCPMark, https://arxiv.org/pdf/2509.24002
- Effort-versus-cost on code editing: Aider polyglot leaderboard, https://aider.chat/docs/leaderboards/

The spawn-time experiment above is local and unpublished, run once at the sample sizes stated.
