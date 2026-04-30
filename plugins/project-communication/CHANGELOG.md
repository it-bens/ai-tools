# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-04-30

Initial release.

### Skill - Changelog Summarizing

- Nine-phase workflow: parse date, discover commits, analyze diffs, group by scope, synthesize, anti-slop validation, format, adaptive length, present.
- Conventional-commit scope grouping with cluster detection across sequential commits and shared PR numbers.
- Discord (markdown) and Slack (mrkdwn) outputs with platform-native formatting.
- Discord 2000-character message splitting at section boundaries with per-message character counts.
- `references/writing-rules-anti-ai-slop.md` for em-dash ban, banned vocabulary, sentence rhythm, and concreteness rules.
- Graceful degradation when the `origin` remote is missing or scope-to-subdirectory mapping does not resolve (links omitted, plain bold headers).
