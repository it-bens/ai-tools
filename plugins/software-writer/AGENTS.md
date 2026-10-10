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
    │       └── stacks/
    │           ├── {bash,go,python,typescript,php}.md
    │           └── {bash,go,python,typescript,php}-indirect-references.md
    ├── writing-tests/
    │   ├── SKILL.md
    │   └── references/
    │       ├── behavior.md
    │       ├── data.md
    │       ├── shape.md
    │       ├── independence.md
    │       └── stacks/                    # one file per test framework, plus its referenced-by-name list
    │           ├── go/{stdlib-testing,testify,ginkgo-gomega,indirect-references}.md
    │           ├── go/{stdlib-testing,testify,ginkgo-gomega}-referenced-by-name.md
    │           ├── python/{pytest,unittest,indirect-references}.md
    │           ├── python/{pytest,unittest}-referenced-by-name.md
    │           ├── typescript/{vitest,jest,node-test,mocha,indirect-references}.md
    │           ├── typescript/{vitest,jest,node-test,mocha}-referenced-by-name.md
    │           ├── php/{phpunit,pest,indirect-references}.md
    │           └── php/{phpunit,pest}-referenced-by-name.md
    ├── writing-docs/
    │   ├── SKILL.md
    │   └── references/
    │       ├── surface-shapes.md
    │       ├── writing-style.md
    │       └── pointer-file.md
    └── sweeping-dead-code/
        ├── SKILL.md
        └── references/
            ├── refutation-prompt.md
            ├── tools/{bash,go,python,typescript,php}.md
            └── stacks/
                ├── {bash,go,python,typescript,php}/indirect-references.md
                ├── go/{stdlib-testing,testify,ginkgo-gomega}-referenced-by-name.md
                ├── python/{pytest,unittest}-referenced-by-name.md
                ├── typescript/{vitest,jest,node-test,mocha}-referenced-by-name.md
                └── php/{phpunit,pest}-referenced-by-name.md
```

## Component Overview

This plugin provides:

- **Skill** (`skills/writing-code/`): the implementation-code workflow — API-consultation gate, new-dependency gate, in-repo primitives lookup, dependency entry shape, caller scope and orphaned-symbol sweep, stack footgun check, code-comment consistency gate, two-tier comment classification.
- **Skill** (`skills/writing-tests/`): the test-authoring workflow — single behavior, production-caller stop, seam decision, arrange-data sourcing, body shape, independence, redundancy and guard-clause gate.
- **Skill** (`skills/writing-docs/`): the documentation workflow — surface confirmation, fixed surface shapes, style-while-writing, anti-slop subagent dispatch, cross-surface quality gate.
- **Skill** (`skills/sweeping-dead-code/`): the report-only dead-code sweep — scope resolution (path, repository, branch), definition ledger, read-only tool runs behind a write guard, evidence collection, reachability classification, independent refutation subagents, coverage check.

- **Hooks** (`hooks/`): Claude Code extension delivery — a `PostToolUse` hook (matcher `Skill`) and a `UserPromptSubmit` hook run `inject-extension.sh`, which delivers a project's `.claude/extensions/software-writer/<skill>.md` wrapped in the `<project_extension>` envelope and stays silent for every other skill, prompt, or project.

**No commands, agents, or MCP servers.** The `sweeping-dead-code` refutation step spawns fresh subagents from its own prompt, `references/refutation-prompt.md`. The `writing-docs` anti-slop step dispatches the `human-author:ai-slop-writing-fixer` subagent, which requires the `human-author` plugin on Claude Code and the matching custom agent from `codex-subagents/` on Codex. The companion `software-writer-extension-setup` plugin writes project extension files.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify a workflow shape, step body, or named-value default | `skills/<skill>/SKILL.md` | Digraph, Steps 1-N, extension contract, named values |
| Modify universal comment classification | `skills/writing-code/references/comments.md` | Consistency gate, classification table, load-bearing why, negative invariant, regex exception, tightening, marker discipline, banned patterns |
| Modify the primitives table shape or decision test | `skills/writing-code/references/primitives.md` | `code.primitives` rows, missing-wrapper rule |
| Modify universal test rules | `skills/writing-tests/references/{behavior,data,shape,independence}.md` | Do/don't-test lists, seam patterns, DAMP, assertion rules, leak vectors |
| Modify a language's doc-tool queries, footguns, or doc-comment convention | `skills/writing-code/references/stacks/<stack>.md` | One file per language; footguns are language-level |
| Modify a language's indirect-reference forms | `templates/software-writer/indirect-references/<stack>.md` (repo root) | Source of truth for the copies in `writing-code`, `writing-tests`, and `sweeping-dead-code`; refresh them with `.github/scripts/validate-file-sync.sh --fix`, which CI runs in check mode. Never edit a copy |
| Modify a test framework's idioms or isolation model | `skills/writing-tests/references/stacks/<stack>/<framework>.md` | One file per framework; table idiom, error-path idiom, isolation constraints, version pin |
| Modify a test framework's referenced-by-name forms | `templates/software-writer/test-references/<stack>/<framework>.md` (repo root) | Source of truth for the `<framework>-referenced-by-name.md` copies in `writing-tests` and `sweeping-dead-code`; refresh them with `.github/scripts/validate-file-sync.sh --fix`. Never edit a copy |
| Modify a language's definition patterns or dead-code tool invocations | `skills/sweeping-dead-code/references/tools/<stack>.md` | `## Definition patterns` search commands; per tool the run command, never-pass flags, test handling, reading findings, limits |
| Modify the refutation subagent's prompt | `skills/sweeping-dead-code/references/refutation-prompt.md` | Read-only fence, candidate rows, indirect and test-side forms, per-row verdict |
| Add support for a new test framework | `skills/writing-tests/references/stacks/<stack>/<framework>.md` + the routing table in `skills/writing-tests/SKILL.md` Step 1 + a `templates/software-writer/test-references/<stack>/<framework>.md` template with its two manifest pairs + the table in `skills/sweeping-dead-code/SKILL.md` Step 2 | A framework gets its own file even when it is the only one for its stack; never fold it into a sibling's file |
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
