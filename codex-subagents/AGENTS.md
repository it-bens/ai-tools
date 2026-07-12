@README.md

# Development Guide

## Layout Convention

Each subagent adds one installable definition and one synchronization hash:

```text
codex-subagents/
|-- AGENTS.md
|-- CLAUDE.md
|-- README.md
|-- <definition-name>.toml
`-- .<definition-name>.hash
```

## File Navigation

| Task | File |
|---|---|
| Find installation instructions, registered agents, or canonical sources | `README.md` |
| Change Codex-specific agent metadata | `<definition-name>.toml` |
| Change shared agent behavior | The canonical source listed in `README.md` |
| Check whether a Codex body matches its canonical source | `.<definition-name>.hash` |

## Authoring Rules

1. **Treat the catalog as the registry.** Every TOML definition must have one Included Subagents row naming its canonical source, hash file, and dependent plugins.
2. **Copy canonical bodies verbatim.** Keep Codex-specific metadata outside `developer_instructions`; do not summarize or adapt the canonical body.
3. **Keep hashes paired with definitions.** Name each sidecar `.<definition-name>.hash` and update it in the same change as its TOML body.
4. **Preserve agent names.** Shared plugin instructions use agent names as compatibility contracts across hosts.
5. **Keep definitions independent.** Each TOML file must remain installable without copying unrelated subagents.
6. **Keep installation instructions portable.** Do not include user-specific absolute paths, checkout-specific source paths, shell-only copy commands, or dependencies on optional runtimes.
7. **Keep Codex definitions separate from plugins.** Plugins may document a prerequisite but must not assume that an agent definition is installed with the plugin.
8. **Treat installed copies as outputs.** Edit definitions in `codex-subagents/`; replace personal or project-scoped copies only for local verification.
