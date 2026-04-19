---
name: reddit-researching
version: 1.0.1
description: >
  MUST invoke before any mcp__plugin_reddit-research_reddit-buddy__* tool call, when
  the user asks to research, search, or investigate anything on Reddit (phrases like
  "reddit research", "check reddit", "reddit says"), when reddit-buddy results already
  appear in the conversation, or when web research is prompted (skill asks once whether
  to include Reddit). Provides the structured scoping / search / drill / synthesis
  workflow — a 3–6 call budget and truncation-aware interpretation are non-optional;
  reddit-buddy primitives without this workflow produce noisy, over-truncated, or
  misattributed findings.
allowed-tools:
  - mcp__plugin_reddit-research_reddit-buddy__search_reddit
  - mcp__plugin_reddit-research_reddit-buddy__browse_subreddit
  - mcp__plugin_reddit-research_reddit-buddy__get_post_details
  - mcp__plugin_reddit-research_reddit-buddy__user_analysis
  - AskUserQuestion
---

# Reddit Research

Structured Reddit research via reddit-buddy MCP. Anonymous access; the server is rate-limited to ~10 calls/minute, which is why this workflow enforces a rigid 3–6 call budget per research question.

Consult `references/tool-constraints.md` before interpreting any response — reddit-buddy silently truncates content and has field-name collisions that cause common misreadings.

## Prerequisite Check

Verify at least one `mcp__plugin_reddit-research_reddit-buddy__*` tool is available. If none are found, tell the user Reddit research is unavailable (the reddit-buddy MCP server is not running) and stop. Do not substitute WebFetch on reddit.com — Reddit blocks direct LLM access.

## Mode Detection

Decide which branch applies before any research work:

- **Explicit Reddit** — The user asked for Reddit research, or reddit-buddy results already appear in the conversation → proceed to Phase 1.
- **Generic web research** — The user asked for web research without mentioning Reddit → ask the user once via AskUserQuestion whether to include Reddit. Remember the answer for the session. No → exit. Yes → Phase 1.
- **Tool-call guardrail** — Claude is about to call a reddit-buddy tool and this skill has not yet been entered → run Phase 1 before the call proceeds.

## Workflow

Track the running reddit-buddy call count from here onward; the deliverable requires it.

### Phase 1: Scope

State the research question in one sentence, then ask: can a decisive answer fit within 3–6 reddit-buddy calls? If not, the scope is too broad — decompose into tighter sub-questions and pick one. Never raise the budget; the rate limit makes it rigid.

### Phase 2: Search

Start with `search_reddit`. Build a tight, distinctive query — "claude plugin marketplace add" not "plugin marketplace" (Reddit search is loose keyword matching, not semantic).

Pick sort and time by intent:
- **Current consensus** → `sort: top`, `time: month`
- **Breaking news** → `sort: new`
- **Exact-phrase hunts** → `sort: relevance` (default)

Pass `subreddits` when the target community is known. For community-pulse queries ("what is r/X discussing right now"), skip `search_reddit` and call `browse_subreddit` instead.

Sequence every call — never parallelize reddit-buddy tools. Each response should shape the next query. Keep default `limit`, `comment_limit`, `comment_depth`, and `max_top_comments` values; overriding them burns quota for marginal signal.

### Phase 3: Drill

Scan search hits by title and preview, then classify each:
- **Clearly relevant** → call `get_post_details`. Pass `subreddit` together with `post_id`, or pass `url`. Omitting `subreddit` triggers an extra internal lookup and doubles the API cost.
- **Uncertain** → skip. Do not spend calls exploring maybes.

For credibility checks on a poster, call `user_analysis` with `time_range: year` or `all`. The `month` default is a 30-day window that hides long-term patterns.

Never call `reddit_explain` — it is a static dictionary with tiny coverage; training knowledge is strictly better.

### Phase 4: Synthesize

Every Reddit finding is a **claim**, not a fact. Reddit is opinions and self-reports — attribution is mandatory, not decorative.

| Do | Don't |
|---|---|
| "One Reddit post (r/sub, u/user, 2026-03-12) claims X" | "Reddit confirms X" |
| "The post opens by claiming X" (when content was truncated) | "The post argues X" (unverifiable past the truncation cap) |
| Attribute to specific post, user, subreddit, and date | Present unattributed summaries |

## Deliverable

Produce a research summary containing:

- [ ] Each finding attributed to a specific post — subreddit, user, and date.
- [ ] Each finding framed as a claim with source, never as established fact.
- [ ] Truncation flagged wherever it affects interpretation.
- [ ] Total reddit-buddy call count disclosed at the end.
