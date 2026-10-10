# Software Writer

Four universal, opinionated skills for writing software: `writing-code`, `writing-tests`, `writing-docs`, and `sweeping-dead-code`. Each ships a workflow with universal rules and an extension contract through which projects register their own conventions. `writing-code` carries one reference per language (Bash, Go, Python, TypeScript, PHP); `writing-tests` carries one per **test framework**, since table idioms, isolation models, and cleanup mechanisms differ per framework rather than per language. `sweeping-dead-code` carries one tool reference per language, holding the definition-search commands and the read-only invocation of each dead-code tool.

The skills are opinionated by design. Opinions can be tuned within the extension contract; a project that disagrees beyond that should copy the plugin and go its own way.

The `writing-docs` anti-slop step dispatches the `human-author:ai-slop-writing-fixer` subagent. Install the `human-author` plugin before using `writing-docs` on Claude Code; on Codex, install the matching custom agent from `codex-subagents/` in this repository.

## Quick Start

```bash
/plugin install software-writer@itb-ai-tools
```

**Restart Claude Code** after installing or updating so the extension-delivery hooks load.

Without project-specific additions, the skills run on universal defaults: stack detection from file extensions and project signals, the universal test-data source list, the built-in documentation-surface taxonomy, and a `CLAUDE.md` pointer-file convention.

## Skills

### Writing Code

**Triggers:** writing or editing implementation code — any change that adds, modifies, or removes logic, signatures, or comments on the lines being written, including cleaning up the comments on code being edited. Test files and their fixtures belong to `writing-tests`, except deleting a test whose only subject a `writing-code` edit deleted.

**Behavior:** consults the stack's doc tool before any uncertain API call, gates new package dependencies on registry verification, routes wrapped domains through in-repo primitives, enforces explicit dependency entry and a non-test caller for every new export, deletes symbols an edit leaves without a non-test reference (searching the stack's indirect-reference forms, repeating until nothing more is orphaned), scans each line against the stack's footgun catalog, and classifies every comment into a two-tier policy (API doc comments as contract, implementation comments as point-of-use why) after checking it against the code it describes.

### Writing Tests

**Triggers:** authoring, editing, or reviewing an automated test — any change to a test file or its fixtures.

**Behavior:** identifies the single behavior under test, stops and reports to the caller when the subject has no production caller or the arrange needs a state no caller produces, takes the classicist position (state verification through the public API, seams over mocks), sources arrange data so the test is self-explanatory, structures bodies as AAA or stack-idiomatic tables, guards order/parallel independence, and runs a final gate for case redundancy and guard-clause isolation.

### Writing Docs

**Triggers:** writing or editing a repository documentation surface — a README, an architecture document, a `CLAUDE.md`/`AGENTS.md` pointer file, or a registered project surface. Code comments, commit messages, and PR descriptions are out of scope.

**Behavior:** enforces the single-owner invariant (every fact has exactly one owning surface; other surfaces point), applies fixed surface shapes (Handled / Refused / Not covered contracts, existence-gated pointer files), applies house writing-style targets while writing, dispatches the `human-author:ai-slop-writing-fixer` subagent on prose surfaces, and closes with a cross-surface quality gate (single-owner, cross-ref integrity, code-vs-claim drift).

### Sweeping Dead Code

**Triggers:** an explicit request to find, list, audit, or sweep unused or dead code across a path, the repository, or a branch. It does not activate during implementation work. Code an edit orphans belongs to `writing-code`.

**Behavior:** reports only and never edits, deletes, stages, or formats a project file. It asks for the scope when the request names none, enumerates every definition in scope with the stack's search commands into a JSON Lines ledger in the system temporary directory, and runs the dead-code tools the project already has (knip, staticcheck, deadcode, vulture, ruff, pylint, the shipmonk PHPStan extension, Psalm, ShellCheck) in the read-only form its tool reference gives, or as a `sweep.tools` command the user approved, stopping the sweep when a tool run changes a tracked or unignored file. It collects plain-name, indirect-reference, and non-code evidence per row, marks reachability from published roots through production references, and classifies each row `published`, `live`, `uncertain`, `test-only`, or `dead`. Every `dead` and `test-only` row goes to an independent refutation subagent before the report lists it.

**Model:** none of the four skills pins a model or effort level, so they run on whatever model the session uses. `sweeping-dead-code` spawns its refutation subagents on the session's model and pins none.

## Extension Contract

Projects register their own conventions through two additive shapes: `Pre-Step-N` / `Post-Step-N` workflow positions, and named configuration values that override the defaults documented inline in each skill body. Extension files live at `.claude/extensions/software-writer/<skill>.md`; on Claude Code the plugin's own hooks deliver them wrapped in a structural envelope whenever the matching skill runs, so projects carry no delivery configuration. An extension may also cite project documentation surfaces that are read on demand. Every skill works without any extension.

`EXTENSION.md` owns the contract: extension file layout, delivery, both mechanisms in detail, reference-like extensions, the recognized named values per skill, and worked examples for registering a code framework and extending the documentation surface map.

The companion plugin `software-writer-extension-setup` writes extension files for you. Its `setting-up-software-writer-extension` skill explores the codebase, drafts per-skill extension content conversationally, writes the files plus the Codex `AGENTS.override.md` delivery, re-syncs existing extension files against a changed codebase, and migrates v1 (`.claude/hook-contexts/`) setups.

## House Style

The opinions the skills own, with their honest status:

| Opinion | Status |
|---|---|
| Classicist testing stance; production seams over mocks | Backed by change-detector literature and recent over-mocking evidence; still a stance — the mockist school exists. |
| Default no implementation comment; API doc comments are the contract | A two-tier synthesis of the two major comment-philosophy positions, which disagree on exactly this point. |
| Every fact has one owning surface | Aligned with the docs-DRY "define once" principle; stricter than ARID; per-surface exemptions supported via `docs.surfaces`. |
| Pointer file ≤30 lines, pointer-only, existence-gated | House style for context economy; the public AGENTS.md convention sets no ceiling and trends verbose. |
| Sentence-length / FK style targets | House numbers; near, not identical to, industry consensus. |
| No symbol without a non-test caller: new exports need one, symbols an edit orphans are deleted | Speculative Generality diagnostic plus YAGNI, sharpened by Hyrum's Law; the orphan rule is the same diagnostic applied to removals. |

## License

MIT
