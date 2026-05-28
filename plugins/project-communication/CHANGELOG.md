# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-05-28

### Changed
- Phase 6 now dispatches the `human-author:ai-slop-writing-fixer` subagent via the Agent tool instead of reading an inline anti-slop reference. The agent applies the corrections and returns the fixed prose. This shifts anti-slop maintenance to the `human-author` plugin and picks up its broader ruleset (pre-empted concession, hedge openers, balanced hedging, parallelism in compound predicates, label-not-explanation, plus the existing em-dash ban, banned vocabulary, sentence patterns, rhythm, and concreteness rules).
- `allowed-tools` on the skill now includes `Agent` so the subagent dispatch is allowed.
- `Authoring Rules` in `CLAUDE.md` reversed the "anti-slop reference is self-contained" rule; anti-slop is now delegated to the subagent.

### Added
- `dependencies` entry on `human-author` in `.claude-plugin/plugin.json`. Installing this plugin now auto-installs `human-author`.

### Removed
- `skills/changelog-summarizing/references/writing-rules-anti-ai-slop.md` (and the now-empty `references/` directory). The ruleset lives in the `human-author:ai-slop-writing-fixer` agent.

## [1.0.0] - 2026-04-30

Initial release.

### Skill - Changelog Summarizing

- Nine-phase workflow: parse date, discover commits, analyze diffs, group by scope, synthesize, anti-slop validation, format, adaptive length, present.
- Conventional-commit scope grouping with cluster detection across sequential commits and shared PR numbers.
- Discord (markdown) and Slack (mrkdwn) outputs with platform-native formatting.
- Discord 2000-character message splitting at section boundaries with per-message character counts.
- `references/writing-rules-anti-ai-slop.md` for em-dash ban, banned vocabulary, sentence rhythm, and concreteness rules.
- Graceful degradation when the `origin` remote is missing or scope-to-subdirectory mapping does not resolve (links omitted, plain bold headers).
