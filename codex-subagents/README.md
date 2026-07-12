# Codex Subagents

Codex agent definitions corresponding to subagents used by plugins in this repository. They are distributed separately from the plugins and must be installed before a dependent plugin can use them.

## Installation

Install only the agent definitions required by the plugins you use. Choose one Codex-supported scope:

- Personal: place the TOML file in the `agents` directory under your Codex home directory.
- Project: place the TOML file in `.codex/agents` at the project root.

Use the Included Subagents table to identify each required TOML file. Create the destination directory when it does not exist, place the TOML file there, then restart Codex or start a new session. Hash files are maintenance metadata and do not need to be installed. Replace an installed TOML file whenever its distributed definition changes.

## Source Synchronization

Each Codex definition mirrors the canonical agent listed in the Included Subagents table:

- `<definition-name>.toml` contains Codex-specific metadata and the copied canonical body in `developer_instructions`.
- `.<definition-name>.hash` contains the lowercase SHA-256 digest of the normalized canonical body.

Use this normalization for every agent:

1. Decode the canonical file as UTF-8 and remove an initial byte-order mark.
2. Convert CRLF and bare CR line endings to LF.
3. Exclude the YAML frontmatter and the blank line that follows it.
4. Normalize the body to exactly one trailing LF without changing any other whitespace.

Parse the TOML and compare `developer_instructions` with the normalized body, then compare the body's SHA-256 digest with the corresponding hash file. When a canonical body changes, replace the TOML body and update its digest in the same change.

## Adding a Subagent

1. Add `<definition-name>.toml` with host-specific metadata outside `developer_instructions`.
2. Copy the normalized canonical body verbatim into `developer_instructions`.
3. Add `.<definition-name>.hash` with the normalized body's SHA-256 digest.
4. Add a row to the Included Subagents table with the definition, agent name, canonical source, hash file, and dependent plugins.

## Included Subagents

| Codex definition | Agent name | Canonical source | Hash file | Required by |
|---|---|---|---|---|
| `ai-slop-writing-fixer.toml` | `human-author:ai-slop-writing-fixer` | `plugins/human-author/agents/ai-slop-writing-fixer.md` | `.ai-slop-writing-fixer.hash` | `commit-message-writer` |
