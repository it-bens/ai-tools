# Codex dispatch experiments — distilled findings

Experimental-evidence leg behind the `orchestrating-subagent-work` skill. Source: a private, instrumented 17-run experiment series — review and implementer runs across all three GPT-5.6 models against a known defect state (a seven-item ground-truth defect list plus a planted comment-drift canary), prompt-block ablations, and a resume-loop validation — interpreted together with a preceding real-usage record on the same private codebase (four review rounds, two implementer runs, 48 threaded review replies over MCP). Every experiment cell is a single run and every run used reasoning effort `max`, so all numbers are directional working defaults with named uncertainty, not proven rankings.

## Transport and the re-validation loop

- `codex exec` on the CLI is the standard transport. The MCP transport was retired: the usage record contains four idle-timeout failures on MCP against zero failures on the CLI.
- `codex exec resume <session-id>` is the standard re-validation loop after a fix round. In the validation run it met all four parity criteria: mechanical success, context retention without restatement, fixed-marked-fixed AND unfixed-marked-not-fixed, and no spurious "no findings". The resumed model re-checked the tree itself (`git status`, `git diff`) — no rubber-stamping.
- Cost of a resume round: ≈42k tokens / ≈75 s, versus 137–312k tokens / 6–11 min for a fresh focused review — roughly 3–7× cheaper than any stateless alternative.
- On CLI 0.144.4, `exec resume` accepted only `--model`, `--config` (`-c`), and `--disable` (verified via verbatim flag-rejection capture). On CLI 0.156.1 (2026-09-24) it also accepts, among others, `--enable`, `--image`, `--json`, `-o/--output-last-message`, `--output-schema`, `--ephemeral`, `--ignore-user-config`, `--ignore-rules`, `--skip-git-repo-check`, `--worktree`, `--strict-config`, `--last`, and `--all`, and still rejects `--sandbox` and `-C`. The skill's policy keeps a resume to `--model`, `-c`, and `--disable`; the sandbox rides `-c sandbox_mode=…`, and workdir/model restore from the session.
- Uncertainty: one resume, one round; threaded re-validation at depth (the record's 29-reply pattern) is untested on the CLI.

## Model roles

- Broad-review recall against the seven-item ground truth: sol 3/7, terra 3/7, luna 1/7 (one run per model, hardened code) — with complementary coverage between sol and terra, which motivates the sol+terra identical-prompt pair for broad review. 2026-09-24 replication: 6 of 6 broad reviewers found every in-scope planted item on fresh code, so neither the ranking nor the complementarity was observable.
- Luna was the only model to produce genuinely new confirmed findings in the adjudication-list arm (one run per model) — both in the doc-drift / installed-dependency-semantics class. That motivated it as an optional third broad pass, at ≈2× wall-clock and tokens. Not replicated 2026-09-24: valid-new findings per model were gpt-6-astra 4, gpt-6-sol 2, gpt-5.6-sol 1–2, gpt-5.6-terra 0, gpt-5.6-luna 0, gpt-6-luna 0 (one run each). Six runs each of the gpt-5.6-sol, gpt-6-sol, and gpt-5.6-terra broad cells gave 0 to 4 valid-new findings per run and 7, 5, and 0 in total (§Stability): single-run counts do not separate the models, and six runs separate terra from the two sol models on this fixture.
- Focused review: terra found the planted comment-drift canary in 5 of 5 runs, including under a minimal prompt; the 2026-09-24 replication is consistent (6 of 6 focused reviews, one per model, found it). Test-quality findings appeared in sol and luna runs (how many sol and luna runs is not recorded) and in none of six terra runs. Not replicated 2026-09-24: gpt-5.6-terra found the planted test-quality defect (one run).
- No single run of any model reliably found defects that require reading installed dependency sources (1 hit in 6 otherwise identical runs). For release-gate reviews, fan out across models or repeat runs.
- Implementer runs (one per model): terra was the only model to re-derive the true change scope past a flawed prompt enumeration; sol and luna followed the file list literally — honest, in-scope, and ≈25% faster. All three were substance-honest about gates (every claim survived orchestrator re-runs outside the sandbox). Not replicated 2026-09-24: with the out-of-list file fenced rather than allowed, gpt-5.6-terra did not report the scope gap (codex 0/4, Opus 5.5 6/6); gate claims matched in 12 of 12 implementer runs.
- Severity calibration (single-run cells): sol labeled every finding blocking in every observed run. Luna's labels were the most conservative and landed correctly. Terra's were usable. Not replicated 2026-09-24: gpt-5.6-sol's labels matched the key on 6 of 8 key items and over-rated 2, the same two items in 6 of 6 runs (§Stability); gpt-5.6-luna was one of 5 of 6 broad reviewers that rated the non-blocking D7 blocking. The routing rule is now model-neutral: every codex model's labels are re-ranked.
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

## Replication, 2026-09-24

Setup: a fresh Python 3.14 stdlib project (2,141 LOC, 18 files) with 7 planted defects plus a comment-drift canary, planted by a Claude model; the answer key and hidden acceptance tests were withheld from every worker. Codex CLI 0.156.1 through a proxy. Efforts were xhigh (broad review), high (focused and security review), and medium (codex implementers) instead of `max`; Claude implementers ran as the shipped definitions. One run per codex cell except the gpt-5.6-sol, gpt-6-sol, and gpt-5.6-terra broad cells (six runs each, §Stability), two per Claude rung. Two independent scorers (sonnet, opus) scored the reviews; hidden tests scored the implementers. Models: gpt-5.6-sol/terra/luna and gpt-6-astra/sol/luna.

| Observation | Result |
|---|---|
| Recall | 16/16 reviews (6 broad, 6 focused, 4 security) found every in-scope planted item (gpt-5.6-terra's broad review with partial hits on 3) — a ceiling, so recall did not discriminate |
| Severity | The non-blocking D7 was rated blocking by 5 of 6 broad reviewers and labeled correctly by 1 of 6 (gpt-6-luna); across 18 stability runs of three models it was rated blocking 17 times (§Stability) |
| Valid-new findings beyond the key | gpt-6-astra 4, gpt-6-sol 2, gpt-5.6-sol 1–2, gpt-5.6-terra 0, gpt-5.6-luna 0, gpt-6-luna 0 (one run each; over six runs per model, gpt-5.6-sol ranged 0 to 4 and gpt-5.6-terra had 0 in every run, §Stability) |
| Security friction | None in 4 security reviews (gpt-6-astra, gpt-6-sol, gpt-5.6-sol, gpt-5.6-terra) on a path-traversal scope with no offensive-security content |
| Canary | Found by 6 of 6 focused reviews |
| Implementers | 12/12 runs (4 codex at medium, 8 Claude) passed all 5 hidden fix tests and regression; 0 of 12 wrote outside the fence; gate claims matched in 12 of 12 |
| Claude implementer tokens (2 runs each) | sonnet-high 142,926 / 151,973; opus-medium 105,224 / 107,062 |
| Scope trap (one fix's true scope crossed the fence; correct behavior is stop and report) | Opus 5.5 at medium/high/xhigh 6/6; Sonnet 5 at high 0/2; codex (gpt-6-sol, gpt-5.6-terra, gpt-6-luna, gpt-5.6-luna) 0/4 |

Five per-model GPT-5.6 observations from the earlier series did not replicate on the same model IDs:

- gpt-5.6-sol labeling every finding blocking — 6 of 8 key-item labels matched, 2 over-rated, identically in 6 of 6 runs.
- gpt-5.6-luna as the only source of new confirmed findings — 0 valid-new.
- gpt-5.6-luna's labels as the most conservative and correct — it was one of the 5 of 6 broad reviewers that rated D7 blocking.
- gpt-5.6-terra reporting no test-quality findings — it found the planted test-quality defect.
- gpt-5.6-terra as the only model re-deriving true scope — 0/1 on the fenced trap; codex implementers 0/4.

Confounds: single runs per codex cell, three broad cells excepted; fresh code versus the earlier series' hardened code; xhigh/high/medium versus the earlier all-`max` runs; a fenced trap versus the earlier trap that allowed out-of-list edits; proxy routing to the named models unverified; possible silent backend updates between the series.

Per-model GPT-5.6 behavior rules are therefore treated as single-run observations, not stable model traits.

### Stability

The broad cells of gpt-5.6-sol, gpt-6-sol, and gpt-5.6-terra each ran five more times with the identical prompt, effort `xhigh`, and fixture, on separate copies of the fixture; with the replication run that makes six runs per model. The runs ran concurrently (5 for gpt-5.6-sol, then 10 for the other two), so wall-clock includes proxy load. Two scorers (sonnet, opus) scored every run independently. They agreed on every fact; where they classified a finding differently, the rule applied is that a finding naming only half of a planted item's mechanism counts as partial.

| Measure (six runs each) | gpt-5.6-sol | gpt-6-sol | gpt-5.6-terra |
|---|---|---|---|
| Runs with all 8 key items fully found | 6 | 6 | 2 (canary missed once; D2 partial twice, D3 and D4 partial once each) |
| D7's second site (`invoice.py:84`) named with its path | 6 | 2 (mentioned without a path in 2 more) | 5 |
| D7 (non-blocking) labeled blocking | 6 | 5 | 6 |
| D6 (non-blocking) labeled blocking | 6 | 0 | 0 |
| Other key-item labels | correct wherever found, 6 of 6 runs | correct wherever found, 6 of 6 runs | correct wherever found, 6 of 6 runs |
| Valid findings beyond the key, per run | 2, 1, 0, 0, 4, 0 (7 in total) | 2, 0, 1, 0, 2, 0 (5 in total) | 0 in every run |
| Tokens | 131,396 to 160,445 | 77,118 to 105,513 | 80,135 to 115,855 |
| Wall-clock | 346 to 721 s | 165 to 272 s | 191 to 296 s |

Every finding beyond the key was confirmed valid by both scorers; two claims (a partial CSV left by a failed export write, a DST-gap occurrence booked at a shifted wall-clock time) appeared under both sol models.

On this fixture:

- Key-item recall and labels are stable within each model. Each model repeated the same label errors from run to run; the one run-to-run label change is a single gpt-6-sol run that labeled D7 correctly.
- D7 was over-rated in 17 of 18 runs across the three models, so the replication's single correct D7 label (gpt-6-luna, one run) does not identify a model that labels better.
- D6 over-rating separates gpt-5.6-sol from the other two in 6 of 6 runs each.
- Findings beyond the key vary from 0 to 4 per run within one model, so a single-run count cannot rank models. Six runs separate gpt-5.6-terra (0 in total) from both sol models (5 and 7) and do not separate the two sol models from each other.
- gpt-5.6-terra found no key item that gpt-5.6-sol missed in any run, so the sol/terra complementarity from the original series was not observed; with sol at the recall ceiling there was nothing for terra to add.

The stability runs cover one fixture, one effort, and three models, with sol's recall at the ceiling. They do not show how the models compare on code where recall has room to vary.

## Named confounds

The experiment arm ran with `--disable memories` and an adjudication list; the reference arm ran memories-on without the list — per-model recall deltas between the arms cannot be attributed cleanly. Within-condition variance is demonstrated (one finding appeared in 1 of 6 identical runs). The codebase had already been through four review rounds, so absolute recall numbers are floors on hardened code, not representative rates.

All results above are GPT-5.6 (sol/terra/luna) at the stated effort on Codex CLI 0.144.4, and do not transfer to GPT-6 models by tier name — this covers the GPT-5.6 Sol safeguard basis in `gpt-5-6-model-family.md` for routing security- or privacy-flavored review to Terra.

## Routing-table basis (codex rows)

One row per codex actor in `model-routing.md`'s routing table, plus the closest-profile fallbacks in its first paragraph. "Original series" is the 17-run series above (one run per cell, effort `max`, hardened code); "replication" is §Replication, 2026-09-24. Tier design intent is from `gpt-5-6-model-family.md` §Tier design intent. No effort in these rows rests on a local effort comparison: the original series ran only `max`, and the replication ran one effort per row type.

| Routing row | Actor as assigned | Basis kind | Evidence and strength | What would change it |
|---|---|---|---|---|
| Fallback: open-ended judgment | `gpt-5.6-sol` | vendor positioning | Sol's design intent names "ambiguous, difficult, or high-value tasks", and OpenAI's tie-breaker is "If you are unsure, start with Sol" (`gpt-5-6-model-family.md` §Tier design intent). No local measurement of open-ended judgment. | A local comparison on open-ended tasks, or a GPT-6 re-validation of the tiers |
| Fallback: specified everyday work | `gpt-5.6-terra` (or an `implement-sonnet-*` definition) | vendor positioning | Terra's design intent is "everyday work" at a lower cost than GPT-5.5 (`gpt-5-6-model-family.md` §Tier design intent). No local measurement of the fallback itself. | A tier rev, or a GPT-6 re-validation, since GPT-6 has no Terra |
| Fallback: enumerated repeatable work | `gpt-5.6-luna` (or a haiku definition) | vendor positioning, cost | Luna's design intent is "clear, repeatable tasks", at $0.20 / $1.20 per 1M tokens against Terra's $2 / $12 (`gpt-5-6-model-family.md` §Tier design intent). No local measurement of the fallback itself. | A local run where Luna misses on an enumerated task that Terra completes |
| Per-bundle focused review | `gpt-5.6-terra`, high | local observation, vendor positioning | Original series: Terra found the comment-drift canary in 5 of 5 runs (§Model roles). The replication found it in 6 of 6 focused reviews, one per model, so the canary does not separate Terra from the other models. Effort `high` is maintainer judgment: the original runs were all `max`, and the replication ran focused review only at `high`. | A focused-review comparison across models on a defect that is not found by all of them, or an effort comparison at fixed model |
| Pre-PR broad review | `gpt-5.6-sol` AND `gpt-5.6-terra`, xhigh | local observation | Original series: recall sol 3/7, terra 3/7, luna 1/7, with complementary coverage between sol and terra, one run per model (§Model roles). The replication hit the recall ceiling (6 of 6 broad reviewers found every in-scope planted item), so it neither supports nor contradicts the ranking or the complementarity. Stability runs (six per model, §Stability): gpt-5.6-terra found no key item that gpt-5.6-sol missed, and it produced no findings beyond the key, where the sol models produced 7 and 5; with sol at the recall ceiling on this fixture, this neither confirms nor refutes complementarity on harder code. Effort `xhigh` is maintainer judgment (effort ladder in `model-routing.md`). | Repeated broad reviews on code where recall does not reach the ceiling, showing whether the sol/terra complementarity holds |
| Optional third broad pass | `gpt-5.6-luna`, high | cost, maintainer judgment | The original basis was Luna producing the only new confirmed findings in the adjudication-list arm, one run per model (§Model roles). The replication recorded 0 valid-new findings for gpt-5.6-luna (one run), so the row now claims only a third model's coverage. Cost: Luna's 1.10M-token broad review costs less at list prices than Sol's 514k-token one (§Cost). A third model from the same family is not model-family diversity. | Repeated broad reviews measuring whether a third model adds findings the sol/terra pair misses; one model's valid-new count ranged 0 to 4 over six identical runs (§Stability), so a single run per model cannot show it |
| Review of security- or privacy-flavored scopes | `gpt-5.6-terra`, high | vendor positioning, maintainer judgment | The original basis was Sol's safeguards blocking "roughly ten times more potentially harmful activity" (`gpt-5-6-model-family.md` §Tier design intent). The replication saw no friction in 4 security reviews, gpt-5.6-sol included, on a scope with no offensive-security content (§Replication), and the Sol exclusion was dropped. No recorded evidence says Terra reviews security scopes better than Sol; keeping Terra is maintainer judgment. | Security reviews with offensive-security content across Sol and Terra, recording friction and findings per model |
| Large triaged fix batch | `gpt-5.6-terra`, medium | vendor positioning, local observation | Original series: Terra was the one implementer of three that re-derived the true change scope, one run per model (§Model roles). The replication did not reproduce it: 0/1 on the fenced scope trap, codex implementers 0/4. Replication: 4 of 4 codex implementers at `medium`, gpt-5.6-terra among them, passed all 5 hidden fix tests, with gate claims matching in 4 of 4 (§Replication). Effort `medium` rests on those 4 runs (1 per model) and the documented default of `medium` when effort is unset (`gpt-5-6-model-family.md` §Reasoning effort). | Repeated fix-batch runs per codex model, or a gate failure rate at `medium` that `high` removes |
| Fully enumerated fix batch, budget-constrained | `gpt-5.6-luna`, medium | vendor positioning, cost, local observation | Luna's design intent is "clear, repeatable tasks" at the lowest GPT-5.6 price (`gpt-5-6-model-family.md` §Tier design intent). Original series: Luna followed the file list literally, honest and in scope, ≈25% faster than Terra, one run (§Model roles). Replication: gpt-5.6-luna at `medium` passed all 5 hidden fix tests, one run (§Replication). | Repeated enumerated-batch runs where Luna fails tests that Terra passes |
