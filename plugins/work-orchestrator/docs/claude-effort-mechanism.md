# Claude reasoning effort and the subagent dial — findings

Where reasoning effort is set for a dispatched worker, and where the routing table's effort choices come from. Statements here describe what was measured or what the vendor documents; the routing decisions built on top live in `skills/orchestrating-subagent-work/references/model-routing.md`.

## What is settable, and where

| Surface | Mechanism | Granularity |
|---|---|---|
| Session | `/effort`, `--effort`, `CLAUDE_CODE_EFFORT_LEVEL`, `settings.json` `effortLevel` | Whole session |
| Skill | `effort` in `SKILL.md` frontmatter | While that skill is active |
| Subagent | `effort` in an agent definition (`agents/*.md` frontmatter, or `--agents` JSON) | Per definition |
| Subagent spawn | `model` and `effort` arguments of the Agent tool (`effort` since Claude Code 2.1.292) | Per spawn |
| Subagent fallback | `CLAUDE_CODE_SUBAGENT_EFFORT` (since Claude Code 2.1.316) | Every subagent for which nothing else names a level |

Levels are `low`, `medium`, `high`, `xhigh`, `max`. The default is `high` on Opus 5, Sonnet 5, and Fable 5.1; setting `high` explicitly on those models is identical to omitting the parameter. Opus 5.5 defaults to `medium` instead: omitting the parameter on Opus 5.5 is identical to setting `medium`, not `high`. For the session, precedence runs environment variable (`CLAUDE_CODE_EFFORT_LEVEL`), then configured or frontmatter level, then model default. For a subagent, a spawn's `effort` argument overrides the definition's `effort` (checked 2026-11-02, below), `CLAUDE_CODE_SUBAGENT_EFFORT` applies only when neither names a level, and otherwise the subagent inherits the session level. How `CLAUDE_CODE_EFFORT_LEVEL` interacts with a spawn's `effort` argument is untested.

Observed 2026-09-23 in this repository's session, on Claude Code 2.1.280: the `opus` alias resolves to `claude-opus-5-5` (seen as `message.model` in subagent transcripts spawned with `model: opus`).

A subagent with no `effort` from its spawn or its definition inherits the session level, unless `CLAUDE_CODE_SUBAGENT_EFFORT` is set. The inheritance is the documented default, not an inference; the environment variable is recorded in the Claude Code 2.1.316 changelog.

## The spawn-time argument takes effect (2026-11-02)

Checked 2026-11-02 on Claude Code 2.1.316 from a `medium` session, reading `CLAUDE_EFFORT` inside each spawned worker's Bash subprocess:

- Spawns with `effort: low` and `effort: max` reported `CLAUDE_EFFORT=low` and `CLAUDE_EFFORT=max`.
- A spawn-time `effort` overrides a definition's pinned `effort`: a definition with a pinned `effort` spawned with `effort: max` reported `CLAUDE_EFFORT=max`. The spawn-time `model` override was not part of these checks; the Agent tool's documentation states that its `model` parameter "Takes precedence over the agent definition's model frontmatter".
- A spawn with `model: haiku` and `effort: low` ran without an API error and reported `CLAUDE_EFFORT=low`. Its transcript shows `message.model` = `claude-haiku-5-5` on both of its assistant turns. The `haiku` alias resolves to Haiku 5.5 by default, the default Haiku model since Claude Code 2.1.293. The run does not show whether the API received the `effort` value or the client dropped it before the request; it shows only that no error occurred and the runtime reported `low`.
- `effort` is ignored for `subagent_type: fork`.

The Claude Code 2.1.292 changelog records the change: "Added an `effort` parameter to the Agent tool, so Claude runs a sub-agent at the effort level you ask for." These checks read the runtime's own report of the level; they did not measure an accuracy or token difference between levels.

## Choosing an effort

The vendor discriminator between the two dials, which the routing table applies: capability is the model setting, thoroughness is the effort setting. Operationally — a worker that skipped a file or stopped partway needs more effort; a worker that had everything it needed, tried, and still got it wrong needs a stronger model.

**Opus 5 is the most effort-sensitive model measured, which is why opus rows use three efforts.** From its system card: on FrontierBench v0.1 (74 terminal and agentic tasks under a mini-SWE-agent harness) mean reward runs 25% at `low`, 39% at `high`, and 44.4% at `xhigh`, with `max` at roughly 43% (inside the noise of `xhigh`). On FrontierCode v1.1 (150 real-pull-request coding tasks, run with Cognition) the best score on both the main and extended sets falls at `medium`, at 53.4% and 63.6%. A 19-point spread across rungs on one model is the largest effort sensitivity in any source gathered here, and the peak is not at the top.

These measurements are Opus 5's and are unvalidated on Opus 5.5. Effort level names don't correspond to the same amount of thinking across models: in Anthropic's own testing, "Claude Opus 5.5 at `medium` matches or exceeds Claude Opus 5 at `high` on coding and knowledge-work evaluations, and on several coding evaluations `low` comes close to it at much lower cost." The 19-point spread and the medium coding peak describe Opus 5's ladder; re-measuring the opus rows' efforts on Opus 5.5 is unfinished work, not a carried-over fact. One rung proxy on Opus 5.5, from the 2026-09-24 fix-batch run: `medium`, `high`, and `xhigh` produced identical outcomes (5/5 hidden fix tests and the out-of-fence scope gap reported, 2 runs each) at ~106k / ~134k / ~195k tokens and ~200 / ~335 / ~625 s. That is n=2 per rung on one task, consistent with the vendor statement above; it changes no routing.

**2026-09-23: Opus 5.5's safety classifiers can decline a dispatch outright, which is a routing fact, not an effort fact.** Vendor documentation: "Claude Opus 5.5 runs safety classifiers, including for biology, cybersecurity, and reasoning extraction"; on cybersecurity specifically, "Finding vulnerabilities in source code is allowed. High-risk dual-use cybersecurity activities are not" (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5, §Safeguard refusals). The migration guide states the classifiers widen on this model: "Its classifiers cover a broader set of categories than Claude Opus 5's, so expect `stop_details.category` values such as `"bio"` and `"reasoning_extraction"` in addition to `"cyber"`" (https://platform.claude.com/docs/en/models/opus-5-5/migration-guide, §Safety classifiers and fallback). Anecdotal and consistent with these documented classifiers: on 2026-09-22 and 2026-09-23 three Reddit users separately reported Opus 5.5 declining requests: signing in to test accounts for integration testing (r/ClaudeCode, post 1wny92q), biomedical animal-model data analysis (r/ClaudeCode, post 1wnxryk), and a cybersecurity task from a member of the Cyber Verification Program (r/codex, post 1wnkq8w). None of these reports carries the vendor's own methodology; they are read here as consistent with the documented biology and cybersecurity classifiers, not as independent confirmation of them.

**No row routes to `max`.** It measures within noise of `xhigh` on the one benchmark that separates them, Anthropic documents it as prone to overthinking on structured-output and less intelligence-sensitive work, and every agent here receives a bounded subtask rather than an open problem. At a given effort level, Opus 5.5 tends to think more per turn than Opus 5, most of all at `xhigh` and `max` (vendor). Independent measurement, cited as such: Artificial Analysis measured roughly 1.6x the output tokens on Opus 5.5 versus Opus 5 (https://artificialanalysis.ai/articles/claude-opus-5-5), and Simon Willison's max-effort runs hit the 128K output cap while the model was still reasoning, twice (https://simonwillison.net/2026/Sep/22/opus-and-sol-and-luna/).

**Sonnet's ceiling is `xhigh` by its own guidance**, which names it for the hardest coding and agentic use cases. Its documented risk at `low` is under-thinking on moderately complex tasks, so `lookup` on sonnet at `low` is scoped to closed questions. Anthropic's own effort table names subagent work as a canonical `low`-effort case, which is the argument for routing anything to `low` at all.

**Prefer a stronger model at a lower effort over a weaker model at a higher one.** On MCPMark's agentic tool-use tasks, gpt-5 at `low` (46.85%) beat gpt-5-mini at `high` (30.32%), and gpt-5-nano gained nothing from effort at any rung. That evidence is GPT-5 against GPT-5-mini, not Claude. The routing table has no opus `low` row on a maintainer default extrapolated from it: sonnet at `medium` covers the cell. This is untested on Claude. One local data point: in the 2026-09-24 fix-batch run, an implementation worker on opus at `medium` (2 runs) matched one on sonnet at `high` (2 runs) on the hidden fix tests and reported the out-of-fence scope gap 2/2 against 0/2, at ~106k against ~147k tokens (n=2, one task).

**Effort does not buy consistency.** MCPMark reports gpt-5 at `medium` scoring 68.5% pass@4 against 33.9% pass^4. Run-to-run variance of that size is not closed by any effort, which is why this plugin's two-worker confirmation is not an effort setting and does not scale down with one.

**One thing deliberately not encoded.** No measured evidence was found that running confirmers at a higher effort than producers beats matched efforts. The nearest academic work scales verifier count rather than verifier depth and is itself non-monotonic. Every recommendation to the contrary traced to posts without methodology.

## Cross-vendor note

Anthropic orders the two levers effort-first: set the effort, then add prompt guidance only if behavior still misses, because effort is a calibrated control and prompt wording is not. OpenAI orders them the other way for GPT-5.6, directing that a prompt be checked for a missing success criterion, dependency rule, tool-routing rule, or verification loop before effort is raised. A dispatch crossing both families cannot carry one ordering rule. The GPT side of this is in `gpt-5-6-model-family.md`.

## Routing-table basis (claude rows)

One row per claude actor in `model-routing.md`'s routing table. "Opus 5 measurement" is the system-card FrontierBench and FrontierCode ladder in §Choosing an effort, unvalidated on Opus 5.5, which is what the `opus` alias runs. "Fix-batch run" is the 2026-09-24 run recorded in `codex-dispatch-experiments.md` §Replication: one task, two runs per model and effort. The three opus efforts exist because of the Opus 5 measurement; which checkpoint gets which effort is maintainer judgment unless a row says otherwise.

| Routing row | Definition, model, effort | Basis kind | Evidence and strength | What would change it |
|---|---|---|---|---|
| One-to-two-fix follow-up | `implement`, sonnet, `medium` | maintainer judgment | No recorded evidence for this effort on this checkpoint. Sonnet's documented risk is under-thinking at `low` on moderately complex tasks (§Choosing an effort), which argues against `low`, not for `medium`. | A small-fix comparison across sonnet efforts, or sonnet against opus at `medium` |
| Substantial self-contained coding batch | `implement`, opus, `medium` | vendor measurement on Opus 5, vendor guidance, local observation (n=2) | Opus 5's FrontierCode peak falls at `medium` (§Choosing an effort). Vendor guidance: Opus 5.5 at `medium` matches or exceeds Opus 5 at `high` on coding evaluations. Fix-batch run: 5/5 hidden fix tests and the out-of-fence scope gap reported in 2 of 2 runs at ~106k tokens; `medium`, `high`, and `xhigh` gave identical outcomes, n=2 per effort. | An Opus 5.5 effort measurement on coding batches, or repeated runs where `medium` misses what `high` catches |
| Fix batch whose items interact across files | `implement`, sonnet or (dense code) opus, `high` | maintainer judgment, local observation (n=2) | No recorded evidence ties interacting items to these efforts. Fix-batch run, on a task whose cross-file interaction is not recorded: sonnet at `high` passed 5/5 hidden fix tests and reported the scope gap in 0 of 2 runs at ~147k tokens; opus at `high` passed 5/5 and reported it in 2 of 2 at ~134k. Sonnet 5's vendor default is `high` (§What is settable, and where). | A batch with recorded cross-file interaction run on both definitions, repeated |
| Coding batch reworking a mechanism or spanning packages | `implement`, opus, `xhigh` | vendor measurement on Opus 5, local observation (n=2) | Opus 5's FrontierBench agentic peak is `xhigh` at 44.4%, with `max` within noise (§Choosing an effort). Vendor: Opus 5.5 thinks more per turn at `xhigh` than Opus 5. Fix-batch run: outcomes identical to `medium` and `high` at ~195k tokens and ~625 s, n=2 on one task. | An Opus 5.5 effort measurement on multi-package work |
| Verification of review findings | `adversarial-check`, sonnet, `high` | maintainer judgment | No recorded measurement of confirmer model or effort; §Choosing an effort records that no evidence was found for confirmers above producers' efforts. `high` is Sonnet 5's vendor default. | A measured verdict-accuracy comparison across sonnet efforts or against opus |
| Verification a cheaper pass returned thin | `escalated-check`, opus, `medium` | maintainer judgment | Treating a thin or unconvincing verification as a case for a stronger model rather than a higher sonnet effort is a maintainer choice. Its closest support, the stronger-model-at-a-lower-effort preference (§Choosing an effort), is extrapolated from MCPMark's GPT-5 against GPT-5-mini result; no Claude measurement exists. | A Claude measurement of stronger-model-lower-effort against weaker-model-higher-effort |
| Diff review of a codex-written fix batch | `adversarial-check`, sonnet, `high` | model-family diversity, maintainer judgment | The routing rule that reviewer and implementer come from different families puts a claude reviewer on codex-written code (`model-routing.md` routing rules). The choice of sonnet at `high` has no recorded measurement. | A diff-review miss rate by claude definition |
| Gate re-run outside worker sandboxes | `gate-run`, haiku, `low` | cost, maintainer judgment | The row routes at `low`, the effort ladder's level for mechanical work; a `haiku` spawn at `effort: low` runs without an API error. Acceptance is deterministic exit-code and tail checking in the routing table, so the duty carries no decision. No recorded measurement of haiku transcription accuracy. | A transcription error observed against the raw command output |
| Deep read of one source | `source-read`, sonnet, `medium` | maintainer judgment | No recorded evidence for this effort on this checkpoint. | A deep-read comparison across sonnet efforts |
| One closed question with a stated place to look | `lookup`, sonnet, `low` | vendor guidance | Anthropic's effort table names subagent work as a canonical `low` case, and Sonnet's documented `low` risk on moderately complex tasks is why the row is scoped to closed questions (§Choosing an effort). | Wrong answers from `low` on questions inside that scope |
| Locating code, symbols, or convention instances | `search`, haiku, `low` | cost, maintainer judgment | `low` on the same basis as the gate re-run row; the duty is decision-free and its output is verified downstream (`model-routing.md` routing rules). No recorded measurement of haiku search recall. | A recall comparison against sonnet on the same searches |
| Mechanical enumeration, extraction, sweeps | `extract`, haiku, `low` | cost, maintainer judgment | Same basis as `search`: mechanical work at `low`, structured output, always verified downstream. No recorded measurement. | Verification stages rejecting haiku output often enough to cost more than a sonnet pass |
| Mechanism behind an observed behavior | `root-cause`, opus, `high` | vendor measurement on Opus 5, maintainer judgment | The Opus 5 ladder supports shipping `high`; assigning it to mechanism-finding has no recorded measurement. | An Opus 5.5 effort measurement on root-cause tasks |
| Two sources disagreeing | `source-conflict`, opus, `xhigh` | vendor measurement on Opus 5, maintainer judgment | The Opus 5 ladder's agentic peak is `xhigh`; assigning it to source adjudication has no recorded measurement. | An Opus 5.5 effort measurement on adjudication tasks |
| Open-ended design, architecture, root-cause judgment | session itself; `design`, opus, `xhigh` when fresh context is worth more | maintainer judgment | No recorded measurement. The dispatched form rests on the Opus 5 `xhigh` peak for the effort and on fresh context for the reason to dispatch. | A comparison of dispatched designs against session-reasoned ones |
| Runtime, device, or interactive surfaces | session itself | maintainer judgment | Not a model choice: the tooling is attached to the session. No recorded measurement. | Subagents gaining access to the attached tooling |

## Sources

Vendor documentation and first-party measurement:

- Effort parameter, levels, defaults, per-level guidance: https://platform.claude.com/docs/en/build-with-claude/effort
- Claude Code effort configuration and precedence: https://code.claude.com/docs/en/model-config
- Subagent frontmatter fields, inheritance, thinking configuration: https://code.claude.com/docs/en/sub-agents
- `MAX_THINKING_TOKENS`, `CLAUDE_EFFORT`, `CLAUDE_CODE_ALWAYS_ENABLE_EFFORT`: https://code.claude.com/docs/en/env-vars
- Model versus effort selection: https://claude.com/blog/claude-model-and-effort-level-in-claude-code
- FrontierBench and FrontierCode effort figures: Claude Opus 5 System Card, https://www-cdn.anthropic.com/c5fbac3f0b1280a933ebd26d3cb8bb9f5bdeaf48/Claude%20Opus%205%20System%20Card.pdf
- Per-model prompting guides: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/
- Per-model default effort table, Opus 5.5 behavior differences: https://platform.claude.com/docs/en/models/overview, https://platform.claude.com/docs/en/models/opus-5-5/whats-new-opus-5-5, https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5

Independent measurement, cited as such:

- Effort ablations and pass@4 versus pass^4 on agentic tool use: MCPMark, https://arxiv.org/pdf/2509.24002
- Effort-versus-cost on code editing: Aider polyglot leaderboard, https://aider.chat/docs/leaderboards/
- Opus 5.5 versus Opus 5 output-token volume at `max`: Artificial Analysis, https://artificialanalysis.ai/articles/claude-opus-5-5
- Opus 5.5 `max`-effort runs hitting the 128K output cap while still reasoning: Simon Willison, https://simonwillison.net/2026/Sep/22/opus-and-sol-and-luna/

The 2026-11-02 spawn-argument checks and the 2026-09-24 fix-batch data points above are local and unpublished, run once at the sample sizes stated; the fix-batch run is recorded in `codex-dispatch-experiments.md` §Replication, 2026-09-24.
