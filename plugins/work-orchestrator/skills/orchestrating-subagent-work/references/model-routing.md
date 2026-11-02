# Model routing

Assign every checkpoint an actor from this table. Codex actors are model tiers; claude actors are a duty definition from `agents/` run on the model the row names, at the row's effort. When a task type is absent, route by the closest profile: open-ended judgment → gpt-5.6-sol; specified everyday work → gpt-5.6-terra or `implement` on sonnet; enumerated repeatable work → gpt-5.6-luna or `search` / `extract` on haiku. When a model tier is updated, re-validate this table before relying on it; its rows are working defaults drawn from small samples, not measured rankings.

`routing.additions` appends checkpoint-type rows for project checkpoint types this table has no profile for, each naming its actor and effort in this table's shape — a claude actor as a duty definition from `agents/` plus a model; default if not otherwise stated: none. Additions append only — a row here never rewrites one below, because the rows below are the plugin's defaults, each with its recorded basis in the plugin's docs, so an addition cannot silently override one.

| Checkpoint type | Actor | Effort |
|---|---|---|
| Per-bundle focused review (commit-sized change) | codex `gpt-5.6-terra` | high |
| Pre-PR broad review (whole branch) | codex `gpt-5.6-sol` AND `gpt-5.6-terra`, identical prompt, outputs merged by the orchestrator | xhigh |
| Optional third broad pass, adding a third model's coverage to the broad pair | codex `gpt-5.6-luna` | high |
| Review of security- or privacy-flavored scopes | codex `gpt-5.6-terra` | high |
| Large triaged fix batch (≥3 fixes, decided designs) | codex `gpt-5.6-terra` | medium, escalate on gate failure |
| Fully enumerated fix batch, budget-constrained | codex `gpt-5.6-luna` | medium |
| One-to-two-fix follow-up | `implement` on sonnet | medium |
| Substantial coding batch whose items are self-contained (decided designs, no cross-item interaction) | `implement` on opus | medium |
| Fix batch whose items interact across files | `implement` on sonnet, or on opus where the surrounding code is dense enough that reading it correctly is most of the work | high |
| Coding batch reworking a mechanism or spanning packages | `implement` on opus | xhigh |
| Verification of review findings | `adversarial-check` on sonnet, one dispatch per finding, verdict per the vocabulary below | high |
| Verification a cheaper pass returned thin or unconvincing on | `escalated-check` on opus | medium |
| Diff review of a codex-written fix batch | `adversarial-check` on sonnet — per-fix correctness against the decided design and test duties, plus containment (fenced files only, no new untracked files) | high |
| Gate re-run outside worker sandboxes after an implementer checkpoint | `gate-run` on haiku — acceptance is deterministic (every exit code zero AND no failure markers in the tails; exit-code/tail disagreement is a deviation); any non-zero exit is a deviation | low |
| Deep read of one source (installed package, spec, vendor doc) | `source-read` on sonnet | medium |
| One closed question with a stated place to look | `lookup` on sonnet | low |
| Locating code, symbols, or instances of a convention | `search` on haiku | low |
| Mechanical enumeration, extraction, catalog/convention sweeps, dispatch-prep | `extract` on haiku, structured output, always verified downstream | low |
| Mechanism behind an observed behavior the session cannot pin down | `root-cause` on opus | high |
| Two sources disagreeing on something a checkpoint turns on | `source-conflict` on opus | xhigh |
| Open-ended design, architecture, root-cause judgment | session itself — no dispatch; `design` on opus when an approach reached from fresh context is worth more than further session reasoning | xhigh where dispatched |
| Runtime, device, or interactive surfaces (simulators, e2e drivers, visual checks) | session itself with the attached tooling — no dispatch | — |

Routing rules:

- Default verification shape: producer plus one independent confirmer, from a different model family where the routing allows. A dual-confirmed result is final; the orchestrator does not re-verify it.
- An independent confirmer is a fresh worker that did not produce the result and shares no session with its producer; a resumed session never confirms its own prior output.
- Nested delegation: a subagent actor spawns its own subagents only when its dispatch directs it, per `worker-prompts.md` §Nested subagents. The definitions that permit the Agent tool: `implement`, `adversarial-check`, `escalated-check`, `root-cause`, `source-conflict`, and `design`; the leaf definitions `search`, `extract`, `gate-run`, `lookup`, and `source-read` never spawn. A nested spawn names a leaf definition plus the model and effort of that duty's row in this table. A subagent a worker spawned is part of that worker — it never serves as the independent confirmer, and its output relaxes no verification requirement.
- Confirmation prompts are adversarial and blind: give the confirmer the claim and the artifact, instruct it to refute, and withhold the producer's reasoning. Parallel producers on the same prompt (the sol+terra broad pair) are co-producers, not confirmers — convergent findings still need a confirmer.
- A passing gate re-run confirms only the gate claim; it never counts as the second confirmation of any other result (fix correctness, findings, doc claims).
- Reviewer and implementer for the same artifact come from different model families: claude-implemented code gets codex review; codex-implemented code gets sonnet diff review.
- One-fix-per-dispatch is waste; batch triaged fixes. Unspecified, judgment-heavy implementation is not dispatched at all — finish the spec first.
- A substantial batch of self-contained fixes with decided designs matches both the codex `gpt-5.6-terra` row and the `implement`-on-opus row. Those two are one discretionary implementer choice rather than a conflict: `routing.codex_bias` arbitrates it, and the rule above gives the artifact a reviewer from the other family whichever way it goes. Declare which side the strategy took.
- Haiku output never flows into a decision unverified: pair every haiku fan-out with a sonnet verification stage or a deterministic check (the gate re-run's exit-code acceptance is such a check). Give haiku decision-free instructions and a structured output schema: haiku gets no decisions, so its output reaches a decision only through verification.
- Every codex model's severity labels are provisional: re-rank findings by the orchestrator's own assessment before triage.
- Finding-verdict vocabulary: confirmed / mechanism confirmed / adjudicated (real behavior, documented accepted decision — name where) / not verified / disputed (name which part fails).
- Claude model and effort are set on the spawn, not in the definition: every claude dispatch names the duty definition and passes the row's model and effort as the Agent tool's `model` and `effort` arguments. A definition pins neither, so a spawn that omits one runs on whatever the session or environment supplies. Change the model or the effort by changing the arguments; the duty stays the definition. `routing.model_defaults` overrides the model for named claude checkpoint types; default if not otherwise stated: the table's models. An assignment names haiku, sonnet, or opus, never fable, and applies only to a claude actor: it never moves a checkpoint between codex and claude, so cross-family independence is untouched, and a checkpoint assigned haiku falls under the haiku rule below.
- Escalation criterion when a result is weak: a worker that skipped part of the scope or stopped partway needs a higher effort; a worker that had everything it needed, tried, and still got it wrong needs a stronger model. By default, prefer a stronger model at a lower effort over a weaker model at a higher one.
- A safeguard refusal from any worker, codex included — a declined request in place of the duty's output — is off-profile output, not a result: re-route a claude refusal to the codex actor this table names for that scope type, to a different claude model, or back to the session itself; re-route a codex refusal to a different codex model, to a claude actor, or back to the session itself; never accept the decline as the verdict. Opus's classifiers can decline life-sciences biology work (everyday health and educational questions are unaffected) and high-risk dual-use cybersecurity activity but leave source-code vulnerability finding allowed, so security code review is not excluded from opus.
- Effort ladder when the table gives none: low for mechanical work, medium for specified implementation, high for focused review, xhigh for broad review gates. `max` is not routed to. Start low and escalate on weak results; a resumed codex session keeps its context across escalation. Table efforts are defaults: escalating is always allowed; downgrading a table effort is an adaptation that must be announced like a scope change, and verification requirements never scale down with effort. `routing.effort_defaults` overrides the effort for named checkpoint types; default if not otherwise stated: the table's efforts, then the ladder above. An assigned effort replaces the default for that checkpoint type only — going below it at dispatch time is still an announced adaptation. On a codex checkpoint the assignment sets the invocation flag; on a claude checkpoint it sets the spawn's `effort` argument.

`routing.codex_bias` is an override-shaped (non-list-shaped) named value with a single enum value; default if not otherwise stated: unset. It biases discretionary codex/claude assignments at the strategy node:

| Value | Semantics |
|---|---|
| *(unset)* | Default. The strategy node assigns actors per the table and its own judgment. No behavior change. |
| `codex-heavy` | Spend codex freely: run the optional third broad pass, run codex at the table's high efforts, and prefer codex as the implementer for discretionary batches. The pre-flight still gates codex availability. |
| `claude-lean` | Spend codex minimally: omit optional codex passes, run codex at table-minimum efforts, and prefer session/claude as the implementer for discretionary work. Codex stays on the load-bearing cross-family reviews. |
| `codex-less` | The claude-heavy terminus. Request a run without codex through the existing codex-less consent path; do not treat it as a new mode or bypass. |

Cross-family independence bounds this dial on both ends and is never overridden: a codex-implemented artifact's diff-review stays claude, and a claude/session-implemented artifact's review stays codex. Every implemented artifact costs exactly one codex touch, as implementer or reviewer, so swapping a batch's implementer family relocates codex between implementation and review rather than removing it. `claude-lean` reduces codex spend only by omitting optional passes and lowering effort; full codex elimination is available only at `codex-less`, so do not expect a linear codex saving from `claude-lean`. Where `routing.effort_defaults` pins an effort, that explicit override wins over the effort implied by this bias.

Codex-less substitutions (apply only after the consent gate):

- Review checkpoints → `adversarial-check` on sonnet at high, running the identical prompt-block protocol from `worker-prompts.md`, one dispatch per scope; merge outputs in the session. Escalate a thin result to `escalated-check` on opus at medium rather than re-running the same model and effort.
- Fix batches → `implement` on sonnet at medium or high per non-overlapping file group, or the session itself. A subagent fix batch carries the full implementer prompt-block protocol, fence and gates included; the blocks do not lapse because the actor changed.
- Verification, sweeps, and deep reads are unchanged — they never depended on codex.
- Cross-family review coverage is lost in this mode; state that in the strategy message and in the final report.
