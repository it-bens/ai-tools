# Codex Subagents

Codex versions of subagents required by plugins in this repository. Install these separately before using a plugin that depends on them.

## Installation

Choose one Codex-supported agent scope:

- Personal: place the TOML file in the `agents` directory under your Codex home directory.
- Project: place the TOML file in `.codex/agents` at the project root.

Create the destination directory when it does not exist, place `ai-slop-writing-fixer.toml` there, then restart Codex or start a new session. Replace the installed file whenever the distributed agent changes.

## Included Agents

| File | Agent name | Required by |
|---|---|---|
| `ai-slop-writing-fixer.toml` | `human-author:ai-slop-writing-fixer` | `commit-message-writer` |
