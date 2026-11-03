# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-11-03

### Fixed

- The plugin now declares `llm-author` as a Claude Code plugin dependency, so installing it also installs `llm-author`. The diagnosing skill invokes `llm-author:prompt-engineering`.

## [1.0.0] - 2026-04-02

### Added

- `diagnosing` skill: analyzes unexpected output from a skill, agent, or command against its source instructions, classifies root causes, and generates introspection questions for the misbehaving session.
- `introspecting` skill: answers those introspection questions about the session's own behavior, grounded in the source files it read.
