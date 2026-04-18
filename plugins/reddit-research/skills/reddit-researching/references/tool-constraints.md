# Tool Constraints

Behavioral quirks of the reddit-buddy MCP tools that affect how to interpret responses.

## Truncation

All truncation is **silent** — no indicator in the response, content just stops mid-sentence.

| Field | Cap | Consequence |
|---|---|---|
| Post `content` (get_post_details) | ~1000 chars | You see the opening, not the full argument |
| Comment `body` (user_analysis) | ~200 chars | Enough for tone, not for nuance |
| `extracted_links` | Only covers truncated slice | Empty means "no links in portion returned", not "no links in post" |

## Field Semantics

| Field | Actually means | Common misread |
|---|---|---|
| `total_comments` in get_post_details response | Comments returned in this response | Thread size (wrong — use `post.num_comments`) |
| `time_range: month` in user_analysis | Last 30 days only | Representative sample (wrong — hides patterns, use `year` or `all`) |

## Rate Limits

Anonymous access: ~10 calls/minute. The 3–6 call budget per research question exists because of this, not as an arbitrary constraint. Overriding default `limit`, `comment_limit`, `comment_depth`, or `max_top_comments` parameters burns quota for marginal signal — the defaults answer almost every question.
