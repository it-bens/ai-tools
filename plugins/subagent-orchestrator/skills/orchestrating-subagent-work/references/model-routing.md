# Model routing

Assign every checkpoint an actor from this table. When a task type is absent, route by the closest profile: open-ended judgment → gpt-5.6-sol; specified everyday work → gpt-5.6-terra or sonnet; enumerated repeatable work → gpt-5.6-luna or haiku. When a model tier is updated, re-validate this table before relying on it.

`routing.additions` appends checkpoint-type rows for project checkpoint types this table has no profile for; default if not otherwise stated: none. Additions append only — a row here never rewrites one below, because the rows below carry the plugin's evidence base rather than a preference.

| Checkpoint type | Actor | Effort |
|---|---|---|
| Per-bundle focused review (commit-sized change) | codex `gpt-5.6-terra` | high |
| Pre-PR broad review (whole branch) | codex `gpt-5.6-sol` AND `gpt-5.6-terra`, identical prompt, outputs merged by the orchestrator | xhigh |
| Optional third broad pass: doc drift, installed-dependency semantics | codex `gpt-5.6-luna` | high |
| Review of security- or privacy-flavored scopes | codex `gpt-5.6-terra` (never sol) | high |
| Large triaged fix batch (≥3 fixes, decided designs) | codex `gpt-5.6-terra` | medium, escalate on gate failure |
| Fully enumerated fix batch, budget-constrained | codex `gpt-5.6-luna` | medium |
| One-to-two-fix follow-up | sonnet subagent | — |
| Verification of review findings | sonnet subagents, one per finding, verdict per the vocabulary below | — |
| Diff review of a codex-written fix batch | sonnet subagent — per-fix correctness against the decided design and test duties, plus containment (fenced files only, no new untracked files) | — |
| Gate re-run outside worker sandboxes after an implementer checkpoint | haiku subagent — runs the project's gates, reports exit codes and verbatim tails; acceptance is deterministic (every exit code zero AND no failure markers in the tails; exit-code/tail disagreement is a deviation); any non-zero exit is a deviation | — |
| Deep read of one source (installed package, spec, vendor doc) | sonnet subagent | — |
| Mechanical enumeration, extraction, catalog/convention sweeps, dispatch-prep | haiku subagents, structured output, always verified downstream | — |
| Open-ended design, architecture, root-cause judgment | session itself — no dispatch | — |
| Runtime, device, or interactive surfaces (simulators, e2e drivers, visual checks) | session itself with the attached tooling — no dispatch | — |

Routing rules:

- Default verification shape: producer plus one independent confirmer, from a different model family where the routing allows. A dual-confirmed result is final; the orchestrator does not re-verify it.
- An independent confirmer is a fresh worker that did not produce the result and shares no session with its producer; a resumed session never confirms its own prior output.
- Confirmation prompts are adversarial and blind: give the confirmer the claim and the artifact, instruct it to refute, and withhold the producer's reasoning. Parallel producers on the same prompt (the sol+terra broad pair) are co-producers, not confirmers — convergent findings still need a confirmer.
- A passing gate re-run confirms only the gate claim; it never counts as the second confirmation of any other result (fix correctness, findings, doc claims).
- Reviewer and implementer for the same artifact come from different model families: claude-implemented code gets codex review; codex-implemented code gets sonnet diff review.
- One-fix-per-dispatch is waste; batch triaged fixes. Unspecified, judgment-heavy implementation is not dispatched at all — finish the spec first.
- Haiku output never flows into a decision unverified: pair every haiku fan-out with a sonnet verification stage or a deterministic check (the gate re-run's exit-code acceptance is such a check). Give haiku decision-free instructions and a structured output schema; it does not recover from its own wrong guesses.
- Ignore severity labels from `gpt-5.6-sol` and re-rank its findings; `gpt-5.6-luna` severity labels are trustworthy; `gpt-5.6-terra` labels are usable.
- Finding-verdict vocabulary: confirmed / mechanism confirmed / adjudicated (real behavior, documented accepted decision — name where) / not verified / disputed (name which part fails).
- Effort ladder when the table gives none: low for mechanical work, medium for specified implementation, high for focused review, xhigh for broad review gates. Start low and escalate on weak results; a resumed codex session keeps its context across escalation. Table efforts are defaults: escalating is always allowed; downgrading a table effort is an adaptation that must be announced like a scope change, and verification requirements never scale down with effort. `routing.effort_defaults` overrides the effort for named checkpoint types; default if not otherwise stated: the table's efforts, then the ladder above. An assigned effort replaces the default for that checkpoint type only — going below it at dispatch time is still an announced adaptation.

`routing.codex_bias` is an override-shaped (non-list-shaped) named value with a single enum value; default if not otherwise stated: unset. It biases discretionary codex/claude assignments at the strategy node:

| Value | Semantics |
|---|---|
| *(unset)* | Default. The strategy node assigns actors per the table and its own judgment. No behavior change. |
| `codex-heavy` | Spend codex freely: run the optional third broad pass, run codex at the table's high efforts, and prefer codex as the implementer for discretionary batches. The pre-flight still gates codex availability. |
| `claude-lean` | Spend codex minimally: omit optional codex passes, run codex at table-minimum efforts, and prefer session/claude as the implementer for discretionary work. Codex stays on the load-bearing cross-family reviews. |
| `codex-less` | The claude-heavy terminus. Request a run without codex through the existing codex-less consent path; do not treat it as a new mode or bypass. |

Cross-family independence bounds this dial on both ends and is never overridden: a codex-implemented artifact's diff-review stays claude, and a claude/session-implemented artifact's review stays codex. Every implemented artifact costs exactly one codex touch, as implementer or reviewer, so swapping a batch's implementer family relocates codex between implementation and review rather than removing it. `claude-lean` reduces codex spend only by omitting optional passes and lowering effort; full codex elimination is available only at `codex-less`, so do not expect a linear codex saving from `claude-lean`. Where `routing.effort_defaults` pins an effort, that explicit override wins over the effort implied by this bias.

Codex-less substitutions (apply only after the consent gate):

- Review checkpoints → sonnet subagents running the identical prompt-block protocol from `worker-prompts.md`, one per scope; merge outputs in the session.
- Fix batches → sonnet subagents per non-overlapping file group, or the session itself. A subagent fix batch carries the full implementer prompt-block protocol, fence and gates included; the blocks do not lapse because the actor changed.
- Verification, sweeps, and deep reads are unchanged — they never depended on codex.
- Cross-family review coverage is lost in this mode; state that in the strategy message and in the final report.
