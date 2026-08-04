# Model routing

Assign every checkpoint an actor from this table. Codex actors are model tiers; claude actors are the agent definitions in `agents/`. When a task type is absent, route by the closest profile: open-ended judgment → gpt-5.6-sol; specified everyday work → gpt-5.6-terra or an `implement-sonnet-*` definition; enumerated repeatable work → gpt-5.6-luna or a haiku definition. When a model tier is updated, re-validate this table before relying on it.

`routing.additions` appends checkpoint-type rows for project checkpoint types this table has no profile for; default if not otherwise stated: none. Additions append only — a row here never rewrites one below, because the rows below carry the plugin's evidence base rather than a preference.

| Checkpoint type | Actor | Effort |
|---|---|---|
| Per-bundle focused review (commit-sized change) | codex `gpt-5.6-terra` | high |
| Pre-PR broad review (whole branch) | codex `gpt-5.6-sol` AND `gpt-5.6-terra`, identical prompt, outputs merged by the orchestrator | xhigh |
| Optional third broad pass: doc drift, installed-dependency semantics | codex `gpt-5.6-luna` | high |
| Review of security- or privacy-flavored scopes | codex `gpt-5.6-terra` (never sol) | high |
| Large triaged fix batch (≥3 fixes, decided designs) | codex `gpt-5.6-terra` | medium, escalate on gate failure |
| Fully enumerated fix batch, budget-constrained | codex `gpt-5.6-luna` | medium |
| One-to-two-fix follow-up | `implement-sonnet-medium` | medium |
| Substantial coding batch whose items are self-contained (decided designs, no cross-item interaction) | `implement-opus-medium` | medium |
| Fix batch whose items interact across files | `implement-sonnet-high`, or `implement-opus-high` where the surrounding code is dense enough that reading it correctly is most of the work | high |
| Coding batch reworking a mechanism or spanning packages | `implement-opus-xhigh` | xhigh |
| Verification of review findings | `investigate-sonnet-high`, one dispatch per finding, verdict per the vocabulary below | high |
| Verification a cheaper pass returned thin or unconvincing on | `investigate-opus-medium` | medium |
| Diff review of a codex-written fix batch | `investigate-sonnet-high` — per-fix correctness against the decided design and test duties, plus containment (fenced files only, no new untracked files) | high |
| Gate re-run outside worker sandboxes after an implementer checkpoint | `gate-run-haiku` — acceptance is deterministic (every exit code zero AND no failure markers in the tails; exit-code/tail disagreement is a deviation); any non-zero exit is a deviation | — |
| Deep read of one source (installed package, spec, vendor doc) | `investigate-sonnet-medium` | medium |
| One closed question with a stated place to look | `investigate-sonnet-low` | low |
| Locating code, symbols, or instances of a convention | `search-haiku` | — |
| Mechanical enumeration, extraction, catalog/convention sweeps, dispatch-prep | `investigate-haiku`, structured output, always verified downstream | — |
| Mechanism behind an observed behavior the session cannot pin down | `investigate-opus-high` | high |
| Two sources disagreeing on something a checkpoint turns on | `investigate-opus-xhigh` | xhigh |
| Open-ended design, architecture, root-cause judgment | session itself — no dispatch; `design-opus-xhigh` when an approach reached from fresh context is worth more than further session reasoning | xhigh where dispatched |
| Runtime, device, or interactive surfaces (simulators, e2e drivers, visual checks) | session itself with the attached tooling — no dispatch | — |

Routing rules:

- Default verification shape: producer plus one independent confirmer, from a different model family where the routing allows. A dual-confirmed result is final; the orchestrator does not re-verify it.
- An independent confirmer is a fresh worker that did not produce the result and shares no session with its producer; a resumed session never confirms its own prior output.
- Confirmation prompts are adversarial and blind: give the confirmer the claim and the artifact, instruct it to refute, and withhold the producer's reasoning. Parallel producers on the same prompt (the sol+terra broad pair) are co-producers, not confirmers — convergent findings still need a confirmer.
- A passing gate re-run confirms only the gate claim; it never counts as the second confirmation of any other result (fix correctness, findings, doc claims).
- Reviewer and implementer for the same artifact come from different model families: claude-implemented code gets codex review; codex-implemented code gets sonnet diff review.
- One-fix-per-dispatch is waste; batch triaged fixes. Unspecified, judgment-heavy implementation is not dispatched at all — finish the spec first.
- A substantial batch of self-contained fixes with decided designs matches both the codex `gpt-5.6-terra` row and the `implement-opus-medium` row. Those two are one discretionary implementer choice rather than a conflict: `routing.codex_bias` arbitrates it, and the rule above gives the artifact a reviewer from the other family whichever way it goes. Declare which side the strategy took.
- Haiku output never flows into a decision unverified: pair every haiku fan-out with a sonnet verification stage or a deterministic check (the gate re-run's exit-code acceptance is such a check). Give haiku decision-free instructions and a structured output schema; it does not recover from its own wrong guesses.
- Ignore severity labels from `gpt-5.6-sol` and re-rank its findings; `gpt-5.6-luna` severity labels are trustworthy; `gpt-5.6-terra` labels are usable.
- Finding-verdict vocabulary: confirmed / mechanism confirmed / adjudicated (real behavior, documented accepted decision — name where) / not verified / disputed (name which part fails).
- Claude effort is carried by the agent definition, not by the dispatch: an `effort` argument passed at spawn time is silently discarded. Route to the agent whose name states its rung, and change rungs by routing to a different agent. Haiku accepts no effort at all, so a haiku checkpoint's only dial is which model it goes to. A checkpoint that needs a rung no definition in `agents/` carries is a plugin change, not a dispatch-time choice.
- Escalation criterion when a result is weak: a worker that skipped part of the scope or stopped partway needs a higher rung; a worker that had everything it needed, tried, and still got it wrong needs a stronger model. Prefer a stronger model at a lower rung over a weaker model at a higher one.
- Effort ladder when the table gives none: low for mechanical work, medium for specified implementation, high for focused review, xhigh for broad review gates. `max` is not routed to. Start low and escalate on weak results; a resumed codex session keeps its context across escalation. Table efforts are defaults: escalating is always allowed; downgrading a table effort is an adaptation that must be announced like a scope change, and verification requirements never scale down with effort. `routing.effort_defaults` overrides the effort for named checkpoint types; default if not otherwise stated: the table's efforts, then the ladder above. An assigned effort replaces the default for that checkpoint type only — going below it at dispatch time is still an announced adaptation. On a codex checkpoint the assignment sets the invocation flag; on a claude checkpoint it selects the agent definition carrying that rung, and an assignment naming a rung no shipped definition carries cannot be honored — say so rather than dispatching the nearest one silently.

`routing.codex_bias` is an override-shaped (non-list-shaped) named value with a single enum value; default if not otherwise stated: unset. It biases discretionary codex/claude assignments at the strategy node:

| Value | Semantics |
|---|---|
| *(unset)* | Default. The strategy node assigns actors per the table and its own judgment. No behavior change. |
| `codex-heavy` | Spend codex freely: run the optional third broad pass, run codex at the table's high efforts, and prefer codex as the implementer for discretionary batches. The pre-flight still gates codex availability. |
| `claude-lean` | Spend codex minimally: omit optional codex passes, run codex at table-minimum efforts, and prefer session/claude as the implementer for discretionary work. Codex stays on the load-bearing cross-family reviews. |
| `codex-less` | The claude-heavy terminus. Request a run without codex through the existing codex-less consent path; do not treat it as a new mode or bypass. |

Cross-family independence bounds this dial on both ends and is never overridden: a codex-implemented artifact's diff-review stays claude, and a claude/session-implemented artifact's review stays codex. Every implemented artifact costs exactly one codex touch, as implementer or reviewer, so swapping a batch's implementer family relocates codex between implementation and review rather than removing it. `claude-lean` reduces codex spend only by omitting optional passes and lowering effort; full codex elimination is available only at `codex-less`, so do not expect a linear codex saving from `claude-lean`. Where `routing.effort_defaults` pins an effort, that explicit override wins over the effort implied by this bias.

Codex-less substitutions (apply only after the consent gate):

- Review checkpoints → `investigate-sonnet-high` running the identical prompt-block protocol from `worker-prompts.md`, one dispatch per scope; merge outputs in the session. Escalate a thin result to `investigate-opus-medium` rather than re-running the same rung.
- Fix batches → `implement-sonnet-medium` or `implement-sonnet-high` per non-overlapping file group, or the session itself. A subagent fix batch carries the full implementer prompt-block protocol, fence and gates included; the blocks do not lapse because the actor changed.
- Verification, sweeps, and deep reads are unchanged — they never depended on codex.
- Cross-family review coverage is lost in this mode; state that in the strategy message and in the final report.
