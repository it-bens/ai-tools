# Project Communication

Turn repository activity into platform-formatted posts. Hosts skills that walk repo history (commits, PRs, releases) and produce communication artifacts for chat, blog, release notes, and similar channels.

## Skills

| Skill | What it does |
|---|---|
| `changelog-summarizing` | Generate Discord and Slack summary posts of repository changes since a given date. Walks committed history on `main`, groups commits by conventional-commit scope, synthesizes each group into a contextual paragraph, and runs anti-AI-slop validation before producing platform-formatted outputs. |

## Quick Start

```bash
/plugin install project-communication@itb-ai-tools
```

Then ask Claude in any repository:

```
Summarize the changes since 2026-04-01 for Discord and Slack.
```

Or with a relative date:

```
Summarize what shipped since last Monday.
```

## What It Does

- **Reads committed history only.** Operates on `main` as if from a clean checkout. Uncommitted changes, staged work, and untracked files are ignored.
- **Groups by conventional-commit scope.** Parses `type(scope): subject` from each subject line. Commits without a scope go into a "General" group.
- **Detects clusters.** Sequential commits, shared PR numbers, and overlapping diffs that belong to one initiative get merged into a single narrative.
- **Synthesizes user-facing changes.** Internal refactors and structural moves get skipped unless they change observable behavior.
- **Validates against anti-slop rules.** Em dashes, banned vocabulary, formulaic transitions, and metronomic sentence rhythm get caught and rewritten before output.
- **Produces two outputs.** Discord (markdown) and Slack (mrkdwn) carry the same content with platform-native formatting. Splits the Discord version at section boundaries when it exceeds 2000 characters.

## Requirements

- Repository follows [Conventional Commits](https://www.conventionalcommits.org/) so scope grouping works.
- Optional, for linked section headers: supply a scope-to-subdirectory mapping at invocation (e.g., "link sections to `src/<scope>`"). Without a mapping, headers are plain bold text. Linked output also needs a configured `origin` remote and the mapped subdirectory to exist on `main`.

## Output Shape

Each post contains:

1. A title line with the date range.
2. One section per scope, with an emoji prefix and (optionally) a link to the scope's subdirectory.
3. A "🔧 General" section for unscoped or cross-cutting commits.
4. A short, self-aware AI-authorship footer.

Discord uses `**bold**` and `[text](url)` markdown. Slack uses `*bold*` mrkdwn with bare URLs on the line below the header.

## Tone

Casual and developer-to-developer. Contractions, no marketing-speak, no exclamation marks. Emojis appear in section headers only.

## License

MIT
