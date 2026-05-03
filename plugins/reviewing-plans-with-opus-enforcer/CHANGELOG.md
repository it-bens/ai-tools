# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-03

### Added
- Initial release
- PreToolUse hook on the Skill tool that blocks `reviewing-plans` invocations on non-Opus sessions
- Detects active model by parsing the most recent `message.model` entry from the session transcript
- Block message with guidance to switch via `/model opus`
