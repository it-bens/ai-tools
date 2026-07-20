@README.md

## Directory & File Structure

```
plugins/software-writer/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md
├── EXTENSION.md
├── README.md
├── hooks/
│   ├── hooks.json                     # PostToolUse (Skill) + UserPromptSubmit delivery hooks
│   └── scripts/
│       └── inject-extension.sh        # self-gating extension delivery with structural envelope
└── skills/
    ├── writing-code/
    │   ├── SKILL.md
    │   └── references/
    │       ├── comments.md
    │       ├── primitives.md
    │       └── stacks/{go,python,typescript,php}.md
    ├── writing-tests/
    │   ├── SKILL.md
    │   └── references/
    │       ├── behavior.md
    │       ├── data.md
    │       ├── shape.md
    │       ├── independence.md
    │       └── stacks/                    # one file per test framework
    │           ├── go/{stdlib-testing,testify,ginkgo-gomega}.md
    │           ├── python/{pytest,unittest}.md
    │           ├── typescript/{vitest,jest,node-test,mocha}.md
    │           └── php/{phpunit,pest}.md
    └── writing-docs/
        ├── SKILL.md
        └── references/
            ├── surface-shapes.md
            ├── writing-style.md
            └── pointer-file.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/writing-code/`): the implementation-code workflow — API-consultation gate, new-dependency gate, in-repo primitives lookup, dependency entry shape, caller scope, stack footgun check, two-tier comment classification.
- **Skill** (`skills/writing-tests/`): the test-authoring workflow — single behavior, seam decision, arrange-data sourcing, body shape, independence, redundancy and guard-clause gate.
- **Skill** (`skills/writing-docs/`): the documentation workflow — surface confirmation, fixed surface shapes, style-while-writing, anti-slop subagent dispatch, cross-surface quality gate.

- **Hooks** (`hooks/`): Claude Code extension delivery — a `PostToolUse` hook (matcher `Skill`) and a `UserPromptSubmit` hook run `inject-extension.sh`, which delivers a project's `.claude/extensions/software-writer/<skill>.md` wrapped in the `<project_extension>` envelope and stays silent for every other skill, prompt, or project.

**No commands, agents, or MCP servers.** The `writing-docs` anti-slop step dispatches the `human-author:ai-slop-writing-fixer` subagent, which requires the `human-author` plugin on Claude Code and the matching custom agent from `codex-subagents/` on Codex. The companion `software-writer-extension-setup` plugin writes project extension files.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify a workflow shape, step body, or named-value default | `skills/<skill>/SKILL.md` | Digraph, Steps 1-N, extension contract, named values |
| Modify universal comment classification | `skills/writing-code/references/comments.md` | Six-bucket table, load-bearing why, negative invariant, banned patterns |
| Modify the primitives table shape or decision test | `skills/writing-code/references/primitives.md` | `code.primitives` rows, missing-wrapper rule |
| Modify universal test rules | `skills/writing-tests/references/{behavior,data,shape,independence}.md` | Do/don't-test lists, seam patterns, DAMP, assertion rules, leak vectors |
| Modify a language's doc-tool queries, footguns, or doc-comment convention | `skills/writing-code/references/stacks/<stack>.md` | One file per language; footguns are language-level |
| Modify a test framework's idioms or isolation model | `skills/writing-tests/references/stacks/<stack>/<framework>.md` | One file per framework; table idiom, error-path idiom, isolation constraints, version pin |
| Add support for a new test framework | `skills/writing-tests/references/stacks/<stack>/<framework>.md` + the routing table in `skills/writing-tests/SKILL.md` Step 1 | A framework gets its own file even when it is the only one for its stack; never fold it into a sibling's file |
| Modify documentation surface shapes | `skills/writing-docs/references/surface-shapes.md` | README shapes, Handled/Refused/Not covered, §Limitations anti-pattern |
| Modify pointer-file rules | `skills/writing-docs/references/pointer-file.md` | Existence gate, bullet discipline, per-bullet decision test |
| Modify writing-style targets | `skills/writing-docs/references/writing-style.md` | Sentence constraints, jargon, numbers, diagrams |
| Add, rename, or retire a named value | `skills/<skill>/SKILL.md` + `EXTENSION.md` | The recognized-values tables must match the names and inline defaults cited in the skill bodies |
| Document how projects extend the skills | `EXTENSION.md` | Extension file layout, delivery, both mechanisms, reference-like extensions, named-value tables, worked examples |
| Change the delivery envelope, gating, or failure behavior | `hooks/scripts/inject-extension.sh` | `<project_extension>` envelope, position variants, silent gates vs loud failures |
| Change delivery events or timeout | `hooks/hooks.json` | `PostToolUse` matcher `Skill`, `UserPromptSubmit` |

## Testing

BATS tests for the delivery script in `plugin-tests/software-writer/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run
.bats/bats-core/bin/bats plugin-tests/software-writer/*.bats
```

Skill-body changes have no automated tests. Validate them by invoking each skill in a scratch project without an extension file (universal defaults) and in a project with one (extension contract, envelope delivery).
