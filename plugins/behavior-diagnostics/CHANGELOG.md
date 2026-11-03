# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- The plugin now declares `llm-author` as a Claude Code plugin dependency, so installing it also installs `llm-author`. The diagnosing skill invokes `llm-author:prompt-engineering`.
