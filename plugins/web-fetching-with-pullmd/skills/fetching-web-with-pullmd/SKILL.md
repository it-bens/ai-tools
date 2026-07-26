---
name: fetching-web-with-pullmd
version: 1.4.0
description: "This skill should be used when the user asks to 'read this page', 'what does this URL say', 'fetch this article', 'summarize this PDF', or 'get the transcript of this video', or when web content is needed as context for another task. Fetches web pages, PDF/Word/PowerPoint/Excel/EPUB documents, and YouTube videos as clean Markdown via PullMD. Also a fallback when the host's native web research returns poor or noisy results. Do NOT use for GitHub URLs (use gh), Reddit URLs, or JSON API endpoints."
---

# Fetching Web Content with PullMD

Fetch web pages, documents, and YouTube videos as clean Markdown with the `read_url` tool of the PullMD MCP server. The server already knows its instance — this skill never needs the URL.

## Decision flow

```dot
digraph pullmd {
    "Need to read a URL?" [shape=doublecircle];
    "GitHub URL?" [shape=diamond];
    "Use gh CLI" [shape=box];
    "Reddit URL?" [shape=diamond];
    "Use a Reddit research MCP, else ask the user" [shape=box];
    "JSON API?" [shape=diamond];
    "Fetch JSON directly" [shape=box];
    "read_url tool available?" [shape=diamond];
    "Tell user to set up the PullMD MCP server" [shape=box];
    "Call read_url" [shape=box];
    "Got clean Markdown?" [shape=diamond];
    "Use the Markdown" [shape=doublecircle];
    "Fall back to native web research" [shape=box];

    "Need to read a URL?" -> "GitHub URL?";
    "GitHub URL?" -> "Use gh CLI" [label="yes"];
    "GitHub URL?" -> "Reddit URL?" [label="no"];
    "Reddit URL?" -> "Use a Reddit research MCP, else ask the user" [label="yes"];
    "Reddit URL?" -> "JSON API?" [label="no"];
    "JSON API?" -> "Fetch JSON directly" [label="yes"];
    "JSON API?" -> "read_url tool available?" [label="no"];
    "read_url tool available?" -> "Call read_url" [label="yes"];
    "read_url tool available?" -> "Tell user to set up the PullMD MCP server" [label="no"];
    "Tell user to set up the PullMD MCP server" -> "Fall back to native web research";
    "Call read_url" -> "Got clean Markdown?";
    "Got clean Markdown?" -> "Use the Markdown" [label="yes"];
    "Got clean Markdown?" -> "Fall back to native web research" [label="no / failed"];
}
```

## Pre-flight

Before relying on PullMD, confirm the `read_url` tool of the PullMD MCP server is in your available tools. If it is not, the server is not registered or authenticated in this session. Tell the user how to register it for the active host:

- Claude Code: `claude mcp add --transport http <name> <instance>/mcp`, then `/mcp` for authentication.
- Codex: `codex mcp add <name> --url <instance>/mcp`, then `codex mcp login <name>` for OAuth authentication.

Until then, fall back to the host's native web research for content it can handle and report any remaining gap.

## Parameters

`read_url` takes `url` (required) plus these optional parameters:

| Param          | Default | Notes                                                                                                    |
| -------------- | ------- | -------------------------------------------------------------------------------------------------------- |
| `query`        | none    | Return only the sections relevant to this query (BM25 over the converted Markdown). Omit for the full page. |
| `max_tokens`   | `600`   | Token budget for `query` extraction (64–20000). Without `query`, irrelevant.                              |
| `frontmatter`  | `false` | Prepend a YAML metadata block (title, source, quality, …).                                                |
| `nocache`      | `false` | Bypass the cache and re-fetch from source.                                                                |
| `extractor`    | auto    | Force `readability` / `trafilatura` / `playwright` instead of the auto choice.                            |
| `pdf_ocr`      | `false` | High-quality OCR for PDFs (table-grade output; needs a server-side OCR key).                              |
| `yt_timecodes` | `links` | YouTube transcripts: `links` (clickable), `plain` (`[MM:SS]`), `none`.                                    |
| `yt_chunk`     | —       | YouTube transcript block size in seconds; `0` = per original snippet.                                     |

### Examples

```
read_url(url="https://example.com/blog/why-we-migrated")
read_url(url="https://example.com/docs/api", query="rate limiting")          # only the relevant sections
read_url(url="https://example.org/research/whitepaper.pdf", pdf_ocr=true)
read_url(url="https://example.com/app/dashboard", extractor="playwright")   # force full render of a JS-heavy page
read_url(url="https://example.com/status", nocache=true)                    # fresh, uncached
```

## Tips

- `frontmatter=true` adds a metadata block (title, source, extraction quality, and — for media/YouTube — author, date, duration, token usage).
- For a JS-heavy page that came back thin, set `extractor="playwright"` to force a full render.
- `list_recent` lists recently fetched URLs (and their share ids); `get_share` re-fetches a prior result by its 8-hex share id. Both are tools of the PullMD MCP server.
- If `read_url` returns poor output or fails, fall back to the host's native web research for content it can handle and report any remaining gap.
