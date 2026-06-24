@README.md

## Directory & File Structure

```
plugins/code-comment-writer/
├── .claude-plugin/plugin.json
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── LICENSE
├── README.md
└── skills/
    └── writing-code-comments/
        ├── SKILL.md                                  # Workflow, steps, extension contract, named values
        ├── scripts/
        │   └── scope.sh                              # Deterministic scope resolution + skip filtering
        └── references/                               # Progressive-disclosure knowledge
            ├── api-docs.md                           # API-doc contract rules, visibility, params/returns
            ├── documentation-surface.md              # docs.surface invariant + Relocate decision procedure
            ├── removal-patterns.md                   # Removable comment patterns
            ├── improvement-examples.md               # Before/after vague-comment fixes
            ├── implementation-comment-condensation.md# Condense WHY comments
            ├── preservation-guidelines.md            # Valuable comment checklist
            ├── consistency-checking.md               # Code/comment mismatch detection
            ├── uncertainty-patterns.md               # HIGH/MEDIUM/LOW classification + verification prompts
            └── special-cases.md                      # Legacy code, algorithms, generated files
```

## Component Overview

This plugin provides:
- **Skill** (`skills/writing-code-comments/`): the workflow for reviewing and editing code comments, with a deterministic scope script, an uncertainty pass, a read-only mode, and a generic `Pre-Step-N` / `Post-Step-N` extension contract plus named configuration values.

**No commands, agents, hooks, or MCP servers.** Skill-only plugin. The companion `code-comment-writer-extension-setup` plugin provisions overlays for projects that want to extend the skill.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify workflow shape, mode/scope detection, step bodies, report format, named values | `skills/writing-code-comments/SKILL.md` | Steps 1-8, digraph, extension contract |
| Modify scope resolution, the skip set, or git line-range extraction | `skills/writing-code-comments/scripts/scope.sh` | Scope types, exit codes, `FILE <path> <ranges>` manifest |
| Modify removal / improvement / condensation / preservation / consistency rules | `references/*.md` | One reference per categorization rule |
| Modify API-documentation treatment | `references/api-docs.md` | Visibility, contract vs implementation, params/returns |
| Modify uncertainty classification | `references/uncertainty-patterns.md` | Content signals, HIGH/MEDIUM patterns, verification prompts |
| Modify documentation-surface enforcement | `references/documentation-surface.md` | `docs.surface` invariant, Relocate decision procedure |

## Testing

BATS tests for `scope.sh` live in `plugin-tests/code-comment-writer/`. Run with:

```bash
.bats/bats-core/bin/bats plugin-tests/code-comment-writer/scope.bats
```
