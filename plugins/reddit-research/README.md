# Reddit Research

Structured Reddit research via the `reddit-buddy` MCP server. Ships a workflow skill that guides scoping, searching, drilling, and synthesizing Reddit findings as attributed claims, and auto-starts the MCP server on plugin load.

## What It Does

- Auto-starts the `reddit-buddy` MCP server (`npx -y reddit-mcp-buddy`) so search, browse, get_post_details, user_analysis, and reddit_explain are available out of the box.
- Ships the `reddit-researching` skill that auto-invokes when the model is about to call a reddit-buddy tool, when the user asks for Reddit research, or when any web research is prompted.
- When web research is prompted without Reddit mentioned, the skill asks the user once whether to include Reddit before any reddit-buddy call.

## Prerequisites

- Node.js (for `npx`).
- Anonymous access is the default. Rate limit is ~10 calls/minute, which is why the skill enforces a 3 to 6 call budget per research question.

## Installation

```bash
/plugin install reddit-research@itb-ai-tools
```

Restart Claude Code after installation so the MCP server initializes.

## Tools Provided

| Tool                                                       | Purpose                                                        |
|------------------------------------------------------------|----------------------------------------------------------------|
| mcp__plugin_reddit-research_reddit-buddy__search_reddit    | Topic search across Reddit, optionally filtered by subreddits. |
| mcp__plugin_reddit-research_reddit-buddy__browse_subreddit | Recent activity in one subreddit.                              |
| mcp__plugin_reddit-research_reddit-buddy__get_post_details | Post body plus comment tree for one post.                      |
| mcp__plugin_reddit-research_reddit-buddy__user_analysis    | Credibility check on a poster.                                 |
| mcp__plugin_reddit-research_reddit-buddy__reddit_explain   | Static dictionary. The skill forbids its use.                  |

## License

MIT
