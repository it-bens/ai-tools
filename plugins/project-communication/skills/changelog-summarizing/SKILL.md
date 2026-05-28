---
name: changelog-summarizing
description: Write a summary post about repository changes since a given date for Discord and Slack. Analyzes commits on main, groups by conventional-commit scope, and produces separate platform-formatted posts.
allowed-tools: Bash, Read, Grep, AskUserQuestion, Agent
---

# Changelog Summary Post

Generate summary posts about repository changes since a given date. Produces two separate outputs: one formatted for Discord (markdown) and one for Slack (mrkdwn).

## Requirements

- Working directory is a git repository.
- Commit subjects follow `type(scope): subject` so scope grouping works. Commits without a scope go into a "General" group.
- User provides a date (absolute or relative).
- Optional, for linked section headers: a scope-to-subdirectory mapping supplied by the user (e.g., "link sections to `src/<scope>`"). Without a mapping, headers are plain bold text.

## Hard Constraints

- **Main branch only.** Only analyze committed history on the `main` branch. Ignore uncommitted files, staged changes, untracked files, and working tree state entirely. The skill operates as if in a clean checkout.
- **Repository URL:** required only when emitting links. Resolve via `git remote get-url origin`. If no remote is configured, omit scope links and produce text-only output.
- **Scope-to-subdirectory mapping:** never assume a default. Emit a link only when (a) the user provided a mapping, (b) the remote is configured, and (c) the mapped subdirectory exists. If any condition fails, use plain bold text for the header.

## Phase 1: Parse Date

Extract the date from the user's input. Accept absolute dates ("2026-04-01") and relative dates ("last Monday", "two weeks ago").

If no date is provided, ask:

> What date should I summarize changes from? (e.g., "2026-04-01" or "last Monday")

If the date is in the future, inform the user and stop.

## Phase 2: Discover Commits

Run:

```bash
git log main --since="<date>" --format="%H %s" --no-merges
```

If no commits are found, inform the user and stop:

> No commits found on main since <date>.

## Phase 3: Analyze Each Commit

For every commit hash from Phase 2, run:

```bash
git show <hash>
```

For each commit, extract:
1. The full commit message (intent)
2. The diff (actual code changes)
3. The conventional commit scope from the subject line (if present)

Analyze both the message and the diff to understand what actually changed and why.

## Phase 4: Group and Cluster

**Group by scope:** Parse `type(scope): subject` from each commit's subject line. Group commits by their scope value. Commits without a scope go into a "General" group.

**Detect clusters:** Within each group, identify commits that contribute to the same feature or initiative. Signals include:
- Sequential commits with related subjects
- PR numbers appearing in multiple commits
- Commits that build on each other's changes (visible in diffs)

Clusters get synthesized into a single narrative paragraph instead of being listed separately.

## Phase 5: Synthesize

For each scope group, write a short contextual paragraph. Follow these rules:

- Focus on user-facing changes: new features, bug fixes, changed behavior, new tools. Describe what changed and why it matters to someone using the affected component
- Internal changes (refactoring, extracting shared code, restructuring files, renaming internals) get skipped unless they change user-visible behavior
- If multiple commits in a group are part of the same feature, merge them into one narrative
- Contextualize changes in the broader project direction when a connection exists (e.g., "builds on the migration support from last week")
- The "General" section covers cross-cutting or unscoped changes

## Phase 6: Anti-Slop Validation

Dispatch the `human-author:ai-slop-writing-fixer` subagent via the Agent tool. Pass the synthesized prose from Phase 5 as `content`. The agent applies em-dash, banned-vocabulary, sentence-pattern, rhythm, and concreteness corrections, then returns the fixed prose plus a structured change report. Use the returned `fixed_content` as input to Phase 7. If the `changes` list is non-empty, the violations are already corrected; do not re-apply them.

## Phase 7: Format Output

Produce two separate outputs: one for Discord (markdown) and one for Slack (mrkdwn). Both carry the same content, but use each platform's native formatting for links, bold, and headers.

### Scope Links

Headers are plain bold text by default. Emit a link only when the user supplied a scope-to-subdirectory mapping at invocation. With a mapping, build the URL from the remote (`git remote get-url origin`) and the mapped path:

`<repo-url>/tree/main/<mapped-path>`

Skip the link for a given scope if no remote is configured or the mapped subdirectory does not exist. In either case, fall back to plain bold text.

The "General" section never gets a link.

### Emoji Section Headers

Each scope group gets an emoji prefix. Pick an emoji that fits the scope's purpose; reuse the same emoji for the same scope across posts.

For the "General" section, use 🔧.

### Discord Format (markdown)

Discord supports standard markdown. Use `**bold**` for emphasis, `[text](url)` for links.

```
**Summary: Changes since <date>**

**<emoji> [<scope>](<repo-url>/tree/main/<mapped-path>)**

<contextual paragraph>

**🔧 General**

...

<AI transparency footer>
```

When the link is omitted (no remote, or subdirectory missing), use:

```
**<emoji> <scope>**
```

### Slack Format (mrkdwn)

Slack uses mrkdwn: `*bold*` for bold. No markdown headers. Place scope URLs as plain text on the line below the bold header (Slack auto-links them).

```
*Summary: Changes since <date>*

*<emoji> <scope>*
<repo-url>/tree/main/<mapped-path>

<contextual paragraph>

*🔧 General*

...

<AI transparency footer>
```

When the link is omitted, drop the URL line entirely.

### AI Transparency Footer

End every post with a short, funny, self-aware one-liner acknowledging LLM authorship. Must be different each time. Keep it to one or two sentences.

### Tone

Casual and conversational. Use contractions ("don't", "isn't"). No marketing-speak, no enthusiasm ("exciting new feature"). Just describe what happened in a way that's quick to read.

Emojis appear in section headers only, not scattered through prose.

## Phase 8: Adaptive Length

The post length should match the volume and significance of changes. A quiet week with 3 small fixes gets a short post. Two weeks with 20+ commits across 4 scopes gets a longer, more detailed one. Don't compress meaningful content just to hit an arbitrary target.

**Slack:** No hard character limit. Write what the changes need.

**Discord:** 2000-character message limit. If the Discord version exceeds 2000 characters, split it into multiple messages at natural section boundaries (between scope groups). Each message must be self-contained and under 2000 characters. Mark split points clearly:

```
Message 1: title + first N scope groups + "(continued...)"
Message 2: remaining scope groups + footer
```

Count characters for each Discord message and verify all are under 2000.

## Phase 9: Present

Present both versions in separate code blocks, clearly labeled. Show character counts for each Discord message.

```
## Discord

\`\`\`
<discord formatted post, or multiple blocks if split>
\`\`\`
> Message 1: <N> characters
> Message 2: <N> characters (if split)

## Slack

\`\`\`
<slack formatted post>
\`\`\`
```
