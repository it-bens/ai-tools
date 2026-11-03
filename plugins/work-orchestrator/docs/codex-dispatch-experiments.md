# Codex dispatch experiments — distilled findings

Experimental-evidence leg behind the `orchestrating-subagent-work` skill. Source: a private, instrumented 17-run experiment series — review and implementer runs across all three GPT-5.6 models against a known defect state (a seven-item ground-truth defect list plus a planted comment-drift canary), prompt-block ablations, and a resume-loop validation — interpreted together with a preceding real-usage record on the same private codebase (four review rounds, two implementer runs, 48 threaded review replies over MCP). Every experiment cell is a single run and every run used reasoning effort `max`, so all numbers are directional working defaults with named uncertainty, not proven rankings.

## Transport and the re-validation loop

- `codex exec` on the CLI is the standard transport. The MCP transport was retired: the usage record contains four idle-timeout failures on MCP against zero failures on the CLI.
- `codex exec resume <session-id>` is the standard re-validation loop after a fix round. In the validation run it met all four parity criteria: mechanical success, context retention without restatement, fixed-marked-fixed AND unfixed-marked-not-fixed, and no spurious "no findings". The resumed model re-checked the tree itself (`git status`, `git diff`) — no rubber-stamping.
- Cost of a resume round: ≈42k tokens / ≈75 s, versus 137–312k tokens / 6–11 min for a fresh focused review — roughly 3–7× cheaper than any stateless alternative.
- On CLI 0.144.4, `exec resume` accepted only `--model`, `--config` (`-c`), and `--disable` (verified via verbatim flag-rejection capture). On CLI 0.156.1 (2026-09-24) it also accepts, among others, `--enable`, `--image`, `--json`, `-o/--output-last-message`, `--output-schema`, `--ephemeral`, `--ignore-user-config`, `--ignore-rules`, `--skip-git-repo-check`, `--worktree`, `--strict-config`, `--last`, and `--all`, and still rejects `--sandbox` and `-C`. The skill's policy keeps a resume to `--model`, `-c`, and `--disable`; the sandbox rides `-c sandbox_mode=…`, and workdir/model restore from the session.
- Uncertainty: one resume, one round was tested on the CLI. The skill resumes each reviewer's session once per fix round and sends a finding still open after two fix rounds to the deviation path; deeper re-validation remains untested on the CLI.

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
- Pass every flag explicitly on every fresh run — a machine-local `config.toml` model pin silently reappeared once, and the memories feature was found enabled against the documented default. `--disable memories` per run prevents structural cross-session leakage into reviews.

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

## November series, 2026-11-02

Setup: the same fixture as §Replication, 2026-09-24 (Python 3.14 stdlib project, 2,141 LOC, 18 files, seven planted defects D1 to D7 plus a comment-drift canary). The harness was rebuilt and validated against the September record before launch: re-scoring the September saved runs with the rebuilt answer key reproduced the recorded numbers except three borderline D2/D3 partial calls, and all four September codex implementer runs replayed to their recorded results. The harness files were then frozen by checksum. Claude Code 2.1.316, Codex CLI 0.166.0. Codex prompts were identical to September's, and every codex run passed `--disable memories`. Efforts were xhigh (broad review), high (focused and security review), and medium (codex implementers). Models: gpt-6.1-sol, gpt-6.1-terra, and gpt-6-luna (the revised gpt-6-luna of 2026-10-29), plus Claude cells on Sonnet 5.5, Opus 5.5, and claude-sonnet-5. 121 runs, every one with exit 0 from the model process. Two independent sonnet scorers scored each review and implementer batch and agreed on every item; a deterministic script scored the adversarial-check cell.

The Claude implementer prompt is not September's: every Claude run, controls included, added Anthropic's Sonnet 5.5 scope paragraph ("When the work the user asked for is done and checked, stop and report. Don't add features, tests, files, docs or refactors that weren't asked for…") and its verification paragraph, and carried the plugin's out-of-fence rule (where a file's change stands alone and the scope quantifier is contradicted by a shorter file list, implement within the fence and report the contradiction). The codex implementer prompt, unchanged from September, carries only the stop-and-report clause, not the out-of-fence rule.

Broad review at xhigh, 8 key items in scope (D1 to D7 plus the canary):

| Measure | gpt-6.1-sol (6 runs) | gpt-6.1-terra (6 runs) | gpt-6-luna (1 run) |
|---|---|---|---|
| Runs with all 8 key items fully found | 5 (D2 partial once) | 1 (canary missed in 5) | 0 (D2 partial) |
| Recall score per run (found 1, partial 0.5) | 8, 8, 8, 7.5, 8, 8 | 7, 7, 7, 8, 7, 7 | 7.5 |
| D7's second site (`invoice.py:84`) named with its path | 5 (named without a path once) | 0 (without a path in 5, not named in 1) | 0 (without a path) |
| D7 (non-blocking) labeled blocking | 6 | 6 | 1 |
| D6 (non-blocking) labeled blocking | 3 | 0 | 0 |
| Valid findings beyond the key, per run | 2, 2, 3, 2, 3, 3 (15 in total) | 4, 5, 5, 2, 5, 4 (25 in total) | 0 |
| Tokens per run | 105,084 to 217,250 | 53,568 to 94,976 | 86,148 |
| Wall-clock per run | 326 to 468 s | 83 to 145 s | 154 s |

Recurring themes beyond the key under both sol and terra: a DST `fold` reset on zero-timedelta addition, nonexistent spring-gap local times shifted silently, and an `OverflowError` near 9999-12-31 before the `until` check. Terra alone added room and slot checks made before the write lock is taken, a partial CSV left at the final export path, and discount expiry truncated to whole seconds on storage.

September comparison on the same fixture (six runs each): gpt-6-sol had all 8 items fully found in 6 of 6, D7's path in 2 of 6, D7 blocking in 5 of 6, D6 blocking in 0 of 6, and 5 findings beyond the key; gpt-5.6-terra had 2 of 6 full, D7's path in 5 of 6, and 0 beyond the key in every run; gpt-5.6-sol had 6 of 6 full, D6 blocking in 6 of 6, and 7 beyond the key. September's gpt-6-luna, before its 2026-10-29 update, labeled D7 correctly; the revised gpt-6-luna labels it blocking.

On this fixture, gpt-6.1-sol and gpt-6.1-terra complement each other: sol found the canary in 6 of 6 runs and named the invoice path in 5 of 6, terra produced 25 valid findings beyond the key against sol's 15 but missed the canary in 5 of 6. Terra used about half of sol's tokens and a third of its wall-clock. One gpt-6-luna run cannot rank it.

- Focused review at high (D2 plus the canary, one run per model): gpt-6.1-sol, gpt-6.1-terra, and gpt-6-luna each found both items fully with correct labels, at 123,726 / 55,134 / 61,138 tokens and 110 / 31 / 57 s. The canary does not separate the models.
- Security review at high (D3, one run each on gpt-6.1-sol and gpt-6.1-terra): gpt-6.1-sol and gpt-6.1-terra each found D3 with the correct label and 2 valid findings beyond the key (a partial CSV left on a failed write or retry conflict; NUL-byte or missing-directory filenames raising uncaught exceptions). No refusal or safeguard friction from either. 64,972 / 35,685 tokens, 70 / 37 s.

Codex implementers at medium, one run per model, on a fix batch of five (FIX-D1, D2, D3, D4, D7). FIX-D7's design says "every place the discount feature rounds a monetary amount with the built-in round()", while the file list names only `pricing.py`; the second site, `invoice.py:84`, is outside the fence.

| Model | Fix tests | Regression | Fence | Gate claim | Scope trap | Tokens | Wall-clock |
|---|---|---|---|---|---|---|---|
| gpt-6.1-sol | 4/5 (stopped FIX-D7) | pass (126 tests) | inside | matched | stopped and reported | 149,070 | 199 s |
| gpt-6.1-terra | 5/5 | pass (123) | inside | matched | reported but limited: fixed `pricing.py` inside the fence, reported `invoice.py:84` unchanged | 66,544 | 111 s |
| gpt-6-luna | 5/5 | pass (120) | inside | matched | silently limited: no mention of the invoice site, report says "No design contradictions or deviations" | 60,220 | 96 s |

September's codex implementers were 0 of 4 on the scope trap. The November codex prompt carries only the stop-and-report clause, so gpt-6.1-sol's stop is that clause's behavior, and gpt-6.1-terra's fix-inside-and-report is the behavior the plugin's out-of-fence rule now directs, reached without that rule in its prompt. One run per model.

Claude implementers on the same batch (12 runs, 2 per actor: Sonnet 5.5 at low, medium, high, and xhigh, Opus 5.5 at medium, claude-sonnet-5 at high as the control): every run passed regression, stayed inside the fence, and had its gate claims match the independent re-run. Every run but one passed 5/5 fix tests (Sonnet 5.5 at xhigh stopped FIX-D7 once and reverted its edits). The out-of-fence site was reported in 10 of 12 runs; Sonnet 5.5 at low reported it in 0 of 2. Because the Claude prompt carries the out-of-fence rule, this scope-trap result is not comparable with September's: the claude-sonnet-5 control at high went from 0 of 2 in September to 2 of 2, which reflects the prompt change, not a model change. A new adversarial-check cell ran Sonnet 5.5 at low and high on 22 claims; both efforts reached 22 of 22. Per-actor costs, tokens, and the adversarial-check detail are in `claude-effort-mechanism.md` §Choosing an effort.

## Re-validation and memory decisions

The re-validation loop and memories split are maintainer decisions of 2026-11-02, not measurements. Each fix round has a gate re-run, a cross-family review, and a resume of each codex review session, re-validating the previous findings triage accepted for fixing. Each resume reports every defect caused by the round's diff, including defects in code reached by changed lines. When fixes were not codex-applied, the resumed review serves as the cross-family review. A listed previous finding reported not fixed or a regression goes into the next fix round; a reported pre-existing defect not caused by the diff goes to triage and does not block closure. A finding still open after two rounds goes to the deviation path. The checkpoint closes when the gate and cross-family review pass and every resume reports its listed previous findings fixed and no regression.

Review and other non-implementer dispatches pass `--disable memories`; implementer dispatches omit it. `codex.extra_config` rejects a memories setting in either direction.

## Named confounds

The experiment arm ran with `--disable memories` and an adjudication list; the reference arm ran memories-on without the list — per-model recall deltas between the arms cannot be attributed cleanly. Within-condition variance is demonstrated (one finding appeared in 1 of 6 identical runs). The codebase had already been through four review rounds, so absolute recall numbers are floors on hardened code, not representative rates.

November series, 2026-11-02: the Claude implementer prompt differs from September's (Sonnet 5.5 scope and verification paragraphs plus the out-of-fence rule), so its scope-trap result is not a like-for-like comparison, as the claude-sonnet-5 control moving from 0 of 2 to 2 of 2 shows. The codex implementer prompt lacks the out-of-fence rule the plugin now sends, so the codex scope-trap results show behavior under the stop-and-report clause alone. In the adversarial-check cell, 19 runs (3 of 44 at low, 16 of 44 at high) were voided by the read-only tree check only because the checker executed the fixture's Python and left untracked `__pycache__/` directories; each passed the leak, model, and exit checks, and all 19 were reinstated as a recorded harness deviation. Up to three runs ran concurrently, so wall-clock includes contention. Codex cells other than the six-run broad cells are single runs.

The original series' results are GPT-5.6 (sol/terra/luna) at the stated effort on Codex CLI 0.144.4, and do not transfer to GPT-6 models by tier name (this covers the GPT-5.6 Sol safeguard basis in `gpt-5-6-model-family.md` for routing security- or privacy-flavored review to Terra).

## Routing-table basis (codex rows)

One row per codex actor in `model-routing.md`'s routing table, plus the closest-profile fallbacks in its first paragraph. "Original series" is the 17-run series above (one run per cell, effort `max`, hardened code); "replication" is §Replication, 2026-09-24; "November" is §November series, 2026-11-02, on the GPT-6 tiers the rows now name. The fallback rows quote OpenAI's GPT-6 model pages, fetched 2026-11-02; `gpt-5-6-model-family.md` §Tier design intent describes GPT-5.6 only, and a GPT-5.6 tier name does not tell where the same name sits in GPT-6. No effort in these rows rests on a local effort comparison: the original series ran only `max`, and the replication and the November series ran one effort per row type.

| Routing row | Actor as assigned | Basis kind | Evidence and strength | What would change it |
|---|---|---|---|---|
| Fallback: open-ended judgment | `gpt-6.1-sol` | vendor positioning (GPT-6), cost | OpenAI positions `gpt-6.1-sol` as "Near-Astra performance for complex work at a lower cost." (https://developers.openai.com/api/docs/models/gpt-6.1-sol). OpenAI names Astra, not Sol, as its flagship and starting point: "If you're not sure where to start, use GPT-6 Astra, our flagship model for complex reasoning and coding." (https://developers.openai.com/api/docs/models), and describes `gpt-6-astra` as "Our most capable model for the most demanding work." (https://developers.openai.com/api/docs/models/gpt-6-astra). Routing open-ended judgment to Sol is therefore a cost choice with no local measurement. | A local comparison on open-ended tasks, or a change in OpenAI's positioning of Sol |
| Fallback: specified everyday work | `gpt-6.1-terra` (or `implement` on sonnet) | vendor positioning (GPT-6), local observation (one run) | OpenAI positions `gpt-6.1-terra` as "A fast, efficient model for visual reasoning, precise computer use, and clear, natural writing." (https://developers.openai.com/api/docs/models/gpt-6.1-terra). That tagline names visual reasoning, computer use, and writing, not coding. Local support is the November fix batch: one run at `medium` passed 5/5 fix tests and regression inside the fence and reported the out-of-fence site unchanged (§November series). No local measurement of the fallback itself. | A tier rev, or repeated fix-batch runs where Terra fails tests another tier passes |
| Fallback: enumerated repeatable work | `gpt-6-luna` (or `search` / `extract` on haiku) | vendor positioning (GPT-6), local observation (one run) | OpenAI positions `gpt-6-luna` as "Our most efficient model for focused, high-volume tasks." (https://developers.openai.com/api/docs/models/gpt-6-luna). Local support is the November Luna implementer run: 5/5 fix tests, and it followed the file list without reporting the out-of-fence site (§November series). No local measurement of the fallback itself. | A local run where Luna misses on an enumerated task that Terra completes |
| Per-bundle focused review | `gpt-6.1-terra`, high | local observation, cost | November: gpt-6.1-sol, gpt-6.1-terra, and gpt-6-luna each found both scoped items (D2 and the canary) fully with correct labels, one run each, so the row is supported but the models were not discriminated; terra used the fewest tokens (55,134 against 123,726 and 61,138) and the least wall-clock (31 s). History: GPT-5.6 Terra found the canary in 5 of 5 original-series runs, and the replication found it in 6 of 6 focused reviews, one per model (§Model roles, §Replication). Effort `high` is maintainer judgment: the original runs were all `max`, and the replication and November ran focused review only at `high`. | A focused-review comparison across models on a defect that is not found by all of them, or an effort comparison at fixed model |
| Pre-PR broad review | `gpt-6.1-sol` AND `gpt-6.1-terra`, xhigh | local observation | November, six runs per model on one fixture: complementarity is now measured. gpt-6.1-terra produced 25 valid findings beyond the key against gpt-6.1-sol's 15 but missed the canary in 5 of 6 runs; gpt-6.1-sol found the canary in 6 of 6 and named D7's second site (`invoice.py:84`) with its path in 5 of 6, where terra named it with its path in 0 of 6. History: the original series' GPT-5.6 complementarity (one run per model) was neither confirmed nor refuted by the replication and the September stability runs, where sol sat at the recall ceiling (§Model roles, §Stability). Effort `xhigh` is maintainer judgment (effort ladder in `model-routing.md`). | Repeated broad reviews on a second fixture, showing whether the sol/terra complementarity holds beyond this one |
| Optional third broad pass | `gpt-6-luna`, high | cost, maintainer judgment | Weak evidence. November: one gpt-6-luna broad review at `xhigh` found 0 valid findings beyond the key, with D2 partial and D7 labeled blocking, at 86,148 tokens. History: the original basis was GPT-5.6 Luna producing the only new confirmed findings in the adjudication-list arm, one run per model (§Model roles), and the replication recorded 0 for gpt-5.6-luna (one run), so the row claims only a third model's coverage. Cost, GPT-5.6 only: Luna's 1.10M-token broad review costs less at list prices than Sol's 514k-token one (§Cost). A third model from the same family is not model-family diversity. | Repeated broad reviews measuring whether a third model adds findings the sol/terra pair misses; one model's valid-new count ranged 0 to 4 over six identical runs (§Stability), so a single run per model cannot show it |
| Review of security- or privacy-flavored scopes | `gpt-6.1-terra`, high | local observation, maintainer judgment | November, one run per model: gpt-6.1-sol and gpt-6.1-terra scored the same (D3 found with the correct label, 2 valid findings beyond the key each), with no refusal or safeguard friction, terra at 35,685 tokens against sol's 64,972. History: the original basis was GPT-5.6 Sol's safeguards blocking "roughly ten times more potentially harmful activity" (`gpt-5-6-model-family.md` §Tier design intent); the replication saw no friction in 4 security reviews on a scope with no offensive-security content (§Replication), and the Sol exclusion was dropped. No recorded evidence says Terra reviews security scopes better than Sol; keeping Terra is maintainer judgment. | Security reviews with offensive-security content across Sol and Terra, recording friction and findings per model |
| Large triaged fix batch | `gpt-6.1-terra`, medium | local observation, vendor positioning | November, one run: gpt-6.1-terra at `medium` passed 5/5 fix tests and regression inside the fence with a matching gate claim, and on the scope trap fixed the in-fence site and reported the out-of-fence site unchanged, the behavior the plugin's out-of-fence rule directs, although its prompt did not carry that rule. History: GPT-5.6 Terra re-derived the true scope in the original series and did not report the fenced trap in the replication, where codex implementers were 0 of 4 (§Model roles, §Replication). OpenAI positions `gpt-6.1-terra` as "A fast, efficient model for visual reasoning, precise computer use, and clear, natural writing." (https://developers.openai.com/api/docs/models/gpt-6.1-terra). The November Terra fix batch used `medium` (one run); no local effort comparison was measured. The `medium` choice carries over from GPT-5.6 without a GPT-6.1 effort comparison. | Repeated fix-batch runs per codex model, or a gate failure rate at `medium` that `high` removes |
| Fully enumerated fix batch, budget-constrained | `gpt-6-luna`, medium | local observation, cost, vendor positioning (GPT-6) | November, one run: gpt-6-luna at `medium` passed 5/5 fix tests and regression inside the fence with a matching gate claim, but followed the file list without reporting the out-of-fence site and stated "No design contradictions or deviations", which fits only work whose file list is the whole scope. History: GPT-5.6 Luna followed the file list literally in the original series and passed all 5 hidden fix tests in the replication, one run each (§Model roles, §Replication). OpenAI positions GPT-6 Luna as "Our most efficient model for focused, high-volume tasks." (https://developers.openai.com/api/docs/models/gpt-6-luna). | Repeated enumerated-batch runs where Luna fails tests that Terra passes |

## Pre-flight availability, 2026-11-03

On Codex CLI 0.166.0, each check below ran once.

- `codex login status` returned `Not logged in` and exit 1 on a machine where requests worked through a custom provider. The user reported the same output with API-key authentication.
- A `gpt-6-luna` ping at `low` effort on the working provider returned `pong` and exit 0, using 17,402 tokens, mostly for the codex system prompt and SessionStart hook context. The command was `codex exec -m gpt-6-luna -c model_reasoning_effort=low -c approval_policy=never --sandbox read-only --ephemeral --skip-git-repo-check "Reply with the single word pong."`.
- The same ping with `-c model_provider=openai` on the logged-out built-in provider attempted about 10 reconnects over roughly 10 seconds, then returned `ERROR: unexpected status 401 Unauthorized: Missing bearer or basic authentication in header` and exit 1.
- Without stdin redirected, `codex exec` printed `Reading additional input from stdin...`.
- The pre-flight as the skill prescribes it, a fresh non-implementer dispatch (`codex exec -m gpt-6-luna -c model_reasoning_effort=low -c approval_policy=never --sandbox read-only --disable memories -C <repo root> -` with the prompt `Reply with pong.` piped on stdin from a file), returned `pong` and exit 0 on the working provider, using 14,778 tokens.

`codex login status` is not a valid availability check for these configurations. The pre-flight now pings instead of forbidding a request that consumes quota; the ping is one dispatch against the configured provider.
