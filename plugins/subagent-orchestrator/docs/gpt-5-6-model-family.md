# GPT-5.6 model family and Codex CLI — external research findings

Official-positioning leg behind the `orchestrating-subagent-work` skill's routing table. Method: a 95-agent deep-research workflow (2026-07-15) — search fan-out, claim extraction, dedup, and three adversarial refute-votes per surviving claim (90 raw claims → 52 after dedup → top 24 verified → 23 survived, 1 killed) — plus manual gap-closing fetches for mis-pathed sources. Statements here describe what the models are designed for; the observed behavior lives in `codex-dispatch-experiments.md`. Sol, Terra, and Luna are durable capability tiers that "advance on their own cadence" (OpenAI) — re-check this document whenever a tier revs.

## Tier design intent (released 2026-07-09 GA)

| Tier | Design intent (official) | $/1M in / out | Cached in |
|---|---|---|---|
| `gpt-5.6-sol` | Flagship. "Strongest capability for complex coding, computer use, research, and cybersecurity." For "ambiguous, difficult, or high-value tasks that need extra analysis, judgment, or polish." | $5 / $30 | $0.50 |
| `gpt-5.6-terra` | Balanced workhorse. "Everyday work, with performance competitive with GPT-5.5 at a lower cost." "A natural starting point for work you previously gave GPT-5.5." | $2.50 / $15 | $0.25 |
| `gpt-5.6-luna` | Fast and affordable. "For clear, repeatable tasks … specific, high-volume tasks when you know what a good result looks like: extraction, classification, transformation, structured summaries." | $1 / $6 | $0.10 |

- Killed claim (3/3 refute votes): "Sol and Luna are smaller and faster variants compared to Terra" — the hierarchy is Sol > Terra > Luna.
- Shared limits: ≈1.05M-token context, 128K max output, text+image input, tools (functions, web search, file search, computer use). The bare alias `gpt-5.6` routes to Sol.
- The capability ladder is not uniform per task: on some agentic benchmarks Luna scores within a point of Terra (Agents' Last Exam 50.3 vs 50.4) while trailing badly on others (Big Finance Bench 36 vs 51). Official tie-breaker: "If you are unsure, start with Sol."
- Sol's cybersecurity safeguards "block roughly ten times more potentially harmful activity" than previous models — security-flavored prompts may hit safeguard friction on Sol, which is why the routing table sends security- and privacy-flavored review scopes to Terra.
- Sol is additionally served on Cerebras infrastructure at up to 750 tokens/s; the Codex fast-mode claim for GPT-5.6 is weakly sourced (one refute vote) — verify before relying on it.
- Plan gating in Codex: Free/Go get Terra only; Plus and up choose Sol/Terra/Luna with per-model effort. Under ChatGPT-plan auth each model draws on its own usage pool; Sol's pool is the scarcest (launch-week pool sizes circulated as Sol 15–90 / Terra 20–110 / Luna 50–280 per 5-hour window — unverified, treat as an ordering only).

## Reasoning effort

- GPT-5.6 exposes effort levels `none/minimal, low, medium, high, xhigh, max`. The config-reference enum tops at `xhigh`, but CLI 0.144.4 demonstrably accepts and echoes `max` (a settings-gated level available on all plans with GPT-5.6 access); default is `medium` when unset.
- Official policy: "Use the lowest reasoning effort that produces the result you need." "Max gives the selected model more time to reason about a single task … Most tasks do not need Max."
- There is no exact effort mapping from GPT-5.5 — recalibrate per task rather than porting old settings. Community reports (unverified tier): effort scales tokens roughly linearly, with diminishing returns from medium→high on some benchmarks.

## Codex CLI configuration facts

- `approval_policy`: `untrusted | on-request | never | { granular = … }`; `sandbox_mode`: `read-only | workspace-write | danger-full-access`. A `review_model` config key provides a standing model override for `/review`.
- Memories: `features.memories` is off by default; when enabled, a two-phase pipeline (per-thread extraction → global consolidation into `~/.codex/memories/`) leaks prior sessions into later runs structurally. `--disable memories` per run is the guarantee; `[memories] generate_memories = false` stops new extraction.
- `codex exec`: progress streams to stderr, final message to stdout; `--json` turns stdout into a JSONL event stream whose `turn.completed` events carry exact usage splits (`input_tokens`, `cached_input_tokens`, `output_tokens`, `reasoning_output_tokens`) — capture these for real cost accounting; the human-readable total is coarse. `--output-schema` forces schema-conformant final JSON; `-o/--output-last-message` writes and still prints; `--ephemeral` skips persisting the session and therefore kills later resume — never use it on a thread meant for re-validation. `codex exec` requires a git repository by default (`--skip-git-repo-check` overrides).
- Caching: 30-minute minimum cache life with explicit breakpoints; cache reads −90%, cache writes 1.25× input rate. Sequential runs over the same repo context within 30 minutes reuse each other's cache — batch related review runs.
- Deprecations at research time: `gpt-5.2` and `gpt-5.3-codex` are deprecated under ChatGPT sign-in.

## Sources

- GPT-5.6 GA announcement: https://openai.com/index/gpt-5-6/
- GPT-5.6 Sol preview announcement: https://openai.com/index/previewing-gpt-5-6-sol/
- Codex model choice guidance: https://developers.openai.com/codex/models
- Codex configuration reference: https://developers.openai.com/codex/config-reference
- Codex non-interactive mode: https://developers.openai.com/codex/noninteractive
- API model pages and pricing: https://developers.openai.com/api/docs/models, https://developers.openai.com/api/docs/pricing
- GPT-5.6 in GitHub Copilot: https://github.blog/changelog/2026-07-09-openais-gpt-5-6-sol-terra-and-luna-are-now-available-in-github-copilot/
- Deployment safety notes: https://deploymentsafety.openai.com/gpt-5-6-preview
