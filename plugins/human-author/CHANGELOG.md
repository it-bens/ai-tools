# Changelog

All notable changes to the `human-author` plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-05-28

### Changed

- Refined the `Better` example for the bold-as-title rule in `ai-slop-writing-fixer`. The previous version folded the topic phrase into the sentence body (`The "5-10" threshold needs...`), which trained the agent to destroy the navigation handle when the input was structured as an enumeration. The new version keeps the topic phrase as plain leading text (`Threshold and override. "5-10" needs...`) and adds a follow-up clause clarifying that the bold span is the trigger, not the topic phrase itself.

## [1.1.1] - 2026-05-28

### Changed

- Broadened the bold-as-title formatting rule in `ai-slop-writing-fixer` to cover punctuation variants the previous wording missed (`**X.**`, `**X**` with no trailing punctuation, and bold spans that already contain a colon such as `**Scope: per-panel only.**`). The previous wording named only `**X:**` and let the other shapes slip through, including in numbered lists. Added a `Bad`/`Better` pair illustrating the numbered-list case.

## [1.1.0] - 2026-05-28

### Added

- `debug` input on `ai-slop-writing-fixer`. When true, the output gains per-change `reasoning` and a `considered` list of candidates the agent weighed but did not change. Intended for diagnosing insufficient corrections.

## [1.0.0] - 2026-05-28

### Added

- Initial release.
- `ai-slop-writing-fixer` agent: receives prose, returns prose with anti-slop rule violations corrected plus a structured change report. Covers punctuation patterns, banned vocabulary, banned sentence patterns, sentence rhythm, parallelism in compound predicates, concreteness, intent-attribution, formatting discipline, and tone.
