# Codex dispatch experiments — distilled findings

Experimental-evidence leg behind the `orchestrating-subagent-work` skill. Source: a private, instrumented 17-run experiment series — review and implementer runs across all three GPT-5.6 models against a known defect state (a seven-item ground-truth defect list plus a planted comment-drift canary), prompt-block ablations, and a resume-loop validation — interpreted together with a preceding real-usage record on the same private codebase (four review rounds, two implementer runs, 48 threaded review replies over MCP). Every experiment cell is a single run and every run used reasoning effort `max`, so all numbers are directional working defaults with named uncertainty, not proven rankings.

## Transport and the re-validation loop

- `codex exec` on the CLI is the standard transport. The MCP transport was retired: the usage record contains four idle-timeout failures on MCP against zero failures on the CLI.
- `codex exec resume <session-id>` is the standard re-validation loop after a fix round. In the validation run it met all four parity criteria: mechanical success, context retention without restatement, fixed-marked-fixed AND unfixed-marked-not-fixed, and no spurious "no findings". The resumed model re-checked the tree itself (`git status`, `git diff`) — no rubber-stamping.
- Cost of a resume round: ≈42k tokens / ≈75 s, versus 137–312k tokens / 6–11 min for a fresh focused review — roughly 3–7× cheaper than any stateless alternative.
- `exec resume` accepts only `--model`, `--config` (`-c`), and `--disable` (verified via verbatim flag-rejection capture on CLI 0.144.4); the sandbox rides `-c sandbox_mode=…`, and workdir/model restore from the session.
- Uncertainty: one resume, one round; threaded re-validation at depth (the record's 29-reply pattern) is untested on the CLI.

## Model roles

- Broad-review recall against the seven-item ground truth: sol 3/7, terra 3/7, luna 1/7 — with complementary coverage between sol and terra, which motivates the sol+terra identical-prompt pair for broad review.
- Luna was the only model to produce genuinely new confirmed findings in the adjudication-list arm — both in the doc-drift / installed-dependency-semantics class. That is its niche as an optional third broad pass, at ≈2× wall-clock and tokens.
- Focused review: terra found the planted comment-drift canary in 5 of 5 runs, including under a minimal prompt. Test-quality findings came only from sol and luna; terra reported none of that class in six runs.
- No single run of any model reliably found defects that require reading installed dependency sources (1 hit in 6 otherwise identical runs). For release-gate reviews, fan out across models or repeat runs.
- Implementer runs: terra was the only model to re-derive the true change scope past a flawed prompt enumeration; sol and luna followed the file list literally — honest, in-scope, and ≈25% faster. All three were substance-honest about gates (every claim survived orchestrator re-runs outside the sandbox).
- Severity calibration: sol labeled every finding blocking in every observed run — its severity labels are uninformative and must be re-ranked. Luna's labels were the most conservative and landed correctly. Terra's are usable.
- Precision with a complete adjudication list in the prompt: ≈92% of findings confirmed or mechanism-confirmed, versus ≈56% without the list in the reference arm.

## Prompt-block ablations

- **OUT (output contract) is load-bearing.** Removing it produced an invented severity scheme and fix-proposal prose; the minimal prompt repeated the invented scheme and added positive-assurance chatter. Keep always.
- **ADJ (adjudicated decisions) works and is cheap.** Zero adjudicated re-flags across all runs carrying the list, versus 3-of-3 models re-flagging without it. The escape-hatch phrasing ("do not re-report unless the documented rationale no longer holds") is productive, not decorative: it yielded a new confirmed finding about a listed item's stale rationale. The list must be complete for the scope — a missing family redirects noise rather than suppressing it.
- **LENS focuses search.** Dropping it once doubled tokens for identical output. Keep it; **SKILLS** showed no measurable recall effect on focused scopes and is the first block to cut when trimming.
- **A bare CTX+OPS+SCOPE prompt suffices for gross drift**, not for contract-grade review.
- **FENCE is a cost and scope control more than a safety device.** Removing it produced zero out-of-scope writes or git mutations even with seeded dirty tracked files — but ≈2× tokens and one gratuitous full-file style sweep. Keep it.
- **Decided DESIGN blocks buy ripple completeness, not design choice.** Given only the goal, the model converged on the same core design unaided but silently shrank the test ripple. Spell out test duties.
- **RULES extracts** showed no degradation when decided designs already dictated the fail-hard shape; keep them whenever DESIGN is goal-level.
- Honesty probe: on a tree that already contained the fix, the model verified, disclosed, and wrote zero bytes — the full protocol produces the right behavior in the weird cases too.

## Spec-writing lessons

- A quantifier ("every X reachable from Y") contradicted by a shorter file list gets implemented file-scoped by two of three models. When the true scope crosses packages, enumerate every affected file AND state the quantifier.
- Effort-bounding clauses ("extend rather than duplicate", "only if the mock extension makes it cheap") were followed precisely — models parse them well.
- The stop-and-report clause ("if the decided design contradicts what you find, STOP that item and report; do not invent an alternative") never misfired.

## Cost

Observed token volumes: focused review 137–312k (median ≈200k); broad review 513k (sol) / 580k (terra) / 1.10M (luna); seven-fix implementer 339–438k; two-fix implementer 186–192k with FENCE, 405k without; resume re-validation ≈42k per round. Token counts are not a dollar-cost proxy across models — at list prices luna's 1.10M-token broad review costs less than sol's 514k-token one — but they remain the right proxy for plan-quota pressure under ChatGPT-plan auth. Effort-vs-quality is unmeasured: every run used `max`, so no local effort gradient exists.

## Operational incidents

- Never instruct codex to avoid running shell commands — its file reads are shell commands; that instruction once produced a 30-minute timeout.
- Run codex invocations sequentially against one working tree, never in parallel.
- Pass every flag explicitly on every run — a machine-local `config.toml` model pin silently reappeared once, and the memories feature was found enabled against the documented default. `--disable memories` per run prevents structural cross-session leakage into reviews.

## Named confounds

The experiment arm ran with `--disable memories` and an adjudication list; the reference arm ran memories-on without the list — per-model recall deltas between the arms cannot be attributed cleanly. Within-condition variance is demonstrated (one finding appeared in 1 of 6 identical runs). The codebase had already been through four review rounds, so absolute recall numbers are floors on hardened code, not representative rates.
