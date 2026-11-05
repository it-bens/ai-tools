# Changelog

## [Unreleased]

### Added

- `writing-code` Write-the-line step: when an edit makes a function fail where it used to return a value, every place on each call path that swallows or replaces the new failure is held to the no-silent-fallback rule. A fallback that covers both a documented failure and the new one is split: the new failure gets its own status or error type, and the fallback stays for the documented failure only. A fallback on a published surface is reported to the user instead of changed.

### Changed

- `writing-code` Step 6 checks each comment written, edited, or kept on the lines being written or edited against the code and runs any claim the comment makes about the language, the interpreter, or a tool in an isolated probe, never by running the code under edit. A run counts only on the version or platform the claim names. A claim a run refutes is corrected, limited to the refuted part; a claim that cannot be run here stays unchanged and is reported to the user as unverified. A workaround whose trigger is gone, or whose removal criterion a run shows met, is neither a contradiction nor a refuted claim: it is kept with the wording of its criterion, and the report to the user names both. A comment that contradicts the code is corrected, never deleted to resolve the mismatch, and still goes on to classification; when classification deletes a comment this step corrected, the report to the user names the deletion and its bucket. The step heading is now "Check and classify each comment".
- `writing-code` `comments.exemption_markers` is retired, and `comments.preserve_patterns` now makes Step 6 skip a matching comment that existed before the edit entirely: no consistency check, no probe, no classification, no edit. Such a comment is deleted only together with the code it describes. A comment the edit writes is not covered. This breaks projects that assigned `comments.exemption_markers`; see Migration from 2.4.0.
- `writing-code` footguns come only from `code.footgun_additions`. The stack references carry no footgun catalog, Step 5 is now "Footgun check", and with no `code.footgun_additions` registered it passes without a check.
- `writing-code` Step 3 deletes a guard as dead only when no supported version, platform, or input reaches it.
- `writing-code` workflow diamond before Step 4 asks whether the edit adds a new dependency or export, removes a call or reference, replaces an implementation, or changes a signature.
- `writing-docs` `docs.style` spells its default out inline in the skill: sentences of at most 25 words averaging 12-17, paragraphs of at most 4 sentences, and predominantly active voice; a number stays only when replacing it with "several" would lose information, a rule outside the default. The pointer-bullet rules live in the skill body. The companion-file rule fixes `AGENTS.md` as the owner of the content with `CLAUDE.md` a one-line include, and the extension content no longer names the owner.
- `sweeping-dead-code` Path scope is the tracked files under the named paths, and the report names the untracked files there as not swept. Bash is detected from `.sh`, `.bash`, and `.bats` files and from extensionless files with a `sh` or `bash` shebang, and a `.bats` file also detects `bats`; Python from `*.py` files and extensionless files with a `python` shebang. The TypeScript patterns include `.mts` and `.cts`. Every stack's file-list command lists the tracked files of the scope with `git ls-files` and applies each directory `sweep.exclude` entry as the exclude pathspec `':(exclude,glob)**/<entry>/**'` and each file-pattern entry as `':(exclude,glob)**/<entry>'`; Step 1 excludes from the whole sweep (no ledger row, no tool evidence) the files that an entry which is not a path describes, such as files whose header marks them as generated. The definition patterns of every stack run over those tracked files only, so a tool finding in a file outside them is not a ledger row. The bash `file` row covers listed files that are not test files, and a `source`, `.`, `load`, or `bats_load_library` line naming a file counts as a reference to it; a bats test file is a `.bats` file or another file under a directory that holds `.bats` files, unless production code sources or runs it. The ShellCheck run reports SC2034, SC2317, and SC2329 as the dead-code findings, and the PHPStan-core section is merged into the shipmonk section.
- `sweeping-dead-code` gives no `file` row to an executable file in any stack, so the top-level code of an executable TypeScript or PHP script counts as a root, as it already did for Bash and Python. The tool references no longer state the exclusion per stack.
- `sweeping-dead-code` Step 4 adds a row for an unmatched tool finding only when Step 3 gives the named definition a row in the scope Step 1 sets. A finding about an import, a local variable, a parameter, an executable file, or a definition outside the Branch scope's ledger is not a row. The tool references drop the finding types that never name such a definition: vulture `unused import`, pylint `unused-import`, `unused-variable` and `unused-argument`, and Psalm `UnusedParam`. ruff is no longer run, since its only findings were unused imports and unused local variables.
- `writing-tests` Step 6 counts a regression case as unique, and the preservation check keeps it, only when a later change can reintroduce the regression through the public behavior. The falsifiability check requires that a realistic change, not only a deliberate edit of the asserted value or a bug in the underlying tool, can make the test fail; a test that fails only that way goes back to Step 2 to be reframed or deleted. In `references/behavior.md`, behavior a type checker, linter, or release gate already enforces is not tested, nor is a read-back of what a config file or manifest states, and the drift-guard carve-out covers only registries that change independently and whose parity no other gate enforces.
- The `bats-referenced-by-name` template, copied into `writing-tests` and `sweeping-dead-code`, lists `bats_test_function --description '<name>' -- <function>` as a by-name reference to a function.

### Removed

- `writing-code` SKILL.md loses its intro paragraph, the Hyrum's Law, YAGNI, slopsquatting, and shell-manifest rationale, the swallow-form list and caller-fallback elaboration (Step 3 keeps two rules and the published-surface report), the illustrative input forms, the Explicit Dependencies and Speculative Generality labels, and the Step 4 skip sentence. `references/comments.md` loses the consistency section, the worked examples, the banned-pattern blocks, the prefer-types and deprecation lines, the markers section, the commented-out-code TODO exception, the line-number explanation, and the "Contradicts the code" row. `references/primitives.md` loses the three example rows and "What the lookup is not". The stack references lose the query tables, the escalation prose, the footgun catalogs, the path-boundary entries, and the doc-comment examples; each keeps its documentation sources with their query forms and one doc-comment convention line.
- `writing-tests` SKILL.md loses the Step 1 version-pin check and the testify layering note, the over-mocking and seam rationale, the Mystery Guest sentence, the DAMP three-occurrence rule, and the naming-order rule. The arrange-source list moves into `references/data.md`, the Step 5 leak vectors and hermetic sentence into `references/independence.md`, the CLI-output rules into `references/shape.md`, and the guard-clause detail into `references/behavior.md`. `behavior.md` loses its worked examples, the redundancy criteria (Step 6 owns them), and the seam anti-pattern. `data.md` loses its examples, parser-fixture lists, identifier rules, DAMP thresholds, and the Builder versus Object Mother comparison. `shape.md` loses its examples, the assertion-strength section, the business-language names, the order table, and the execution-time smell. `independence.md` loses its examples, the Flag and Skip tables, the fixture-scope table, and the per-framework non-deterministic-call tables. Each framework reference keeps one table-construct line and loses version pins, error-path idioms, isolation and parallelism, mock-reset facts, status capture, doubles, helpers, `Eventually`, doctest, and Hypothesis.
- `writing-docs` `references/writing-style.md` loses the numeric targets, the Flesch-Kincaid sentence, the illustrative table, the numbers section, and the rejections table. `references/pointer-file.md` loses the bullet rules, the rationale line, the WRONG and CORRECT pairs, and the rationalizations table. `references/surface-shapes.md` reduces the Limitations example, the C4 floor, and the changelog discipline to one line each.
- `sweeping-dead-code` tool references lose every Test handling and Limits line and the rest of each Read findings line; each tool keeps one findings line naming which entries are dead-code findings. The bash ShellCheck section keeps Run, Never-pass, and a findings line.

### Migration from 2.4.0

A project that assigned `comments.exemption_markers` in a `writing-code` extension file moves those markers into `comments.preserve_patterns`. The name `comments.exemption_markers` is no longer read.

## [2.4.0] - 2026-10-12

### Added

- `writing-code` Confirm-dependencies-and-surface-scope step runs Caller scope in reverse: when an edit removes a call, replaces an implementation, or changes a signature, every symbol that lost a reference keeps a non-test reference or is deleted in the same edit, with the tests whose only subject it was. The search covers the plain name, the stack's indirect-reference forms, and non-code files, and repeats until a pass deletes nothing. Replaced implementations go in the same change. Symbols on a published surface are reported instead of deleted.
- `code.dead_code_check` named value: a project command that reports unused code, run after the orphaned-symbol search.
- `writing-code` references `stacks/<stack>-indirect-references.md` for all five stacks: the language and framework forms that reach a symbol without its plain name at the call site. the Confirm-dependencies-and-surface-scope step loads the matching file for the orphaned-symbol search.
- `writing-tests` Identify-the-single-behavior step stops before writing a test whose subject has no production caller and is no entry point, and reports it to the user or the invoking workflow as a dead-code candidate. the Source-the-arrange-data step stops the same way when the arrange needs a state no production caller produces. The skill never deletes production code: the only production change it leaves in place is a seam introduced in the Identify-the-single-behavior step, and the Final-quality-gate falsifiability check's temporary removal is restored and verified against the saved `git diff -- <file>` output.
- `writing-tests` references `stacks/<stack>/indirect-references.md` for Bash, Go, PHP, Python, and TypeScript, the same lists `writing-code` uses. Both skills hold a copy, generated from one repository template and checked in CI, so neither skill cites the other's files.
- `writing-tests` references `stacks/<stack>/<framework>-referenced-by-name.md` for each test framework: data providers, fixtures, hooks, mock targets, and config entries that reference test code by name. Each is a copy of a repository template.
- `sweeping-dead-code` skill: a report-only sweep for unused code across a path, the repository, or a branch, triggered only by an explicit request. It enumerates definitions with per-stack search commands into a JSON Lines ledger in the system temporary directory, runs the dead-code tools the project already has behind a write guard that stops the sweep when a run changes a tracked or unignored file, classifies each row `published`, `live`, `uncertain`, `test-only`, or `dead` by reachability from published roots, and sends every `dead` and `test-only` row to an independent refutation subagent before reporting it. Named values: `project.stacks`, `sweep.exclude`, `sweep.tools`, `sweep.entry_points`, `sweep.refutation_batch_size`.
- `sweeping-dead-code` references `tools/<stack>.md` for Bash, Go, PHP, Python, and TypeScript: the definition-search commands and, per tool (ShellCheck; staticcheck and deadcode; shipmonk/dead-code-detector, Psalm, and PHPStan core; vulture, ruff, and pylint; knip), the run command, the flags never to pass, test handling, how to read findings, and limits. It also references `refutation-prompt.md` and holds copies of the five indirect-reference lists.
- Repository templates `templates/software-writer/test-references/<stack>/<framework>.md` for each test framework, copied into `writing-tests` and `sweeping-dead-code` as `references/stacks/<stack>/<framework>-referenced-by-name.md` and checked in CI.
- `inject-extension.sh` delivers `.claude/extensions/software-writer/sweeping-dead-code.md` on both the Skill-tool and the slash-command path.
- `writing-code` Write-the-line step refuses an unrecognized or invalid input with a message before any fallback runs: a parse failure on a user-supplied file, an argument type no branch handles, an empty value where one is required. Logging and then falling back is allowed only where the fallback is the documented behavior; a documented default for an absent optional value is not such a fallback.
- `writing-code` Write-the-line step validates every argument of an entry point or a function with side effects before its first bootstrap, write, spawn, or network call; streaming or incremental input is validated one unit at a time before that unit is acted on.
- `writing-code` Write-the-line single-definition rule: search for an existing helper before writing logic and call it, add no second copy of a function or third copy of a block of 3+ lines (generated and manifest-synced copies are exempt), parametrize bodies that differ only by a literal, and delete dead guards, dead assignments, and forwarding-only wrappers in the touched lines, except a wrapper registered as a primitive and a symbol on a published surface. the orphaned-symbol paragraph of the Confirm-dependencies-and-surface-scope step covers the symbols those deletions leave unreferenced.
- `writing-code` footgun entry in all five stack references: normalize the path and the root first so `/a/box/../etc` does not pass as inside `/a/box`, then match by equality or by a prefix that ends in the separator, never a bare substring or unanchored prefix (`/a/box` must not match `/a/box-extras`). Each stack names its idiom: `realpath` on both, then `[[ $q == "$r" || $q == "$r/"* ]]` in Bash; `filepath.Rel` plus `filepath.IsLocal` in Go; `os.path.normpath` or `Path.resolve()` on both, then `PurePath.is_relative_to` in Python; `path.relative`, with `fs.realpathSync` first when symlinks matter, in TypeScript; `realpath` on both, then equality or `str_starts_with` on the root plus `/` in PHP.
- `writing-tests` Final-quality-gate falsifiability check: the test fails when the behavior is removed (delete the guard or revert the line under test, run the test, expect a failure, restore the code, and confirm with `git diff -- <file>` that the file matches its state before the check), the expected value does not already hold before the act, and every claim in the test name is asserted.
- `writing-tests` Final-quality-gate step keeps no test when removing the code under test leaves every observable output unchanged on every input the code can receive: it stops and reports the code as a redundant-code candidate, naming the code path that already produces the same output. The stop reuses the dead-code stop node.
- `writing-tests` Final-quality-gate coverage check: every guard, refusal, option, default, and blocking rule the edit adds or changes gets a case that triggers it, and a test list that mirrors a production registry is read from that registry at run time instead of written as a literal list.
- `writing-tests` shape reference: a refusal test asserts the guard's own message as well as the exit code when a test double can fail with the same status, and a test that checks a call log asserts every logged call, not only the first. the Structure-the-body step points to the refusal rule. Where a framework has no parametrized construct, the table-driven row defers to the framework reference's idiom: a loop that registers one test per case, or one thin test per case calling a shared helper.
- `writing-tests` data reference: a fixture or stub that stands in for an external tool returns that tool's real output whenever the code under test parses it; a stub that only records its arguments stays fine for tests of how a command is built. Helper-extraction occurrences count across all test files that share an ancestor, and an existing helper that performs the arrange is called instead of inlined.
- `writing-tests` Bash stack: `stacks/bash/bats.md` covers `--partial` only for a fragment that cannot match a wrong value and the full line otherwise, the `--index` limit, asserting a captured status when a function runs without `run`, fixture `git` isolated from the developer's configuration, sourcing files that set shell options only inside `run bash -c`, per-line ShellCheck disables, one thin `@test` per case calling a shared helper for a fixed case table, and a `bats_test_function` loop (bats-core 1.11.0+) over a checked registry read for cases that mirror a production registry. `stacks/bash/bats-referenced-by-name.md` and `stacks/bash/indirect-references.md` are copies of repository templates, and `sweeping-dead-code` Detect-stacks-and-load-references step loads the BATS file too.
- `writing-tests` refusal idiom in the non-Bash framework references (`stdlib-testing`, `testify`, `ginkgo-gomega`, `pytest`, `unittest`, `phpunit`, `pest`, `jest`, `mocha`, `node-test`, `vitest`): each names the form that passes on any failure, a test double's included (`err != nil`, `require.Error`, `HaveOccurred()`, a bare exception type, a bare `toThrow()` or `assert.throws(fn)`), and the form that pins the refusal (error identity, a type with its message, or a message pattern). A class, type, or sentinel alone pins the refusal only when no test double or other code path in the test can produce it; otherwise the message or pattern is asserted too. `shape.md` points to them at the refusal exception.

### Changed

- `writing-code` Confirm-dependencies-and-surface-scope step no longer skips an edit that removes a call or reference, and the diamond between the Write-the-line and Confirm-dependencies-and-surface-scope steps routes removals.
- `writing-code` comments reference: the "Redundant with docs" bucket also covers a comment that restates another symbol's doc comment, and cuts it to the local why plus a reference to that symbol.
- `writing-code` bash footgun entry for `cmd | while read` now covers every subshell: `$(…)`, `( … )`, and each pipeline stage. A variable assigned there never reaches the caller, the last stage runs in the current shell only under `shopt -s lastpipe` (bash 4.2+), and `$(…)` strips trailing newlines, so separators go outside the substitution.
- `writing-code` bash footgun entry for stdout and stderr: it now also says never to parse a capture that merged stderr. `out=$(cmd 2>&1)` followed by `jq` or a shape check breaks on the first warning line, including one from a wrapper that merges stderr internally; capture stdout alone, check the exit status, and parse only on success.
- `writing-code` bash footgun entry for BSD/GNU divergence: the temp-file-plus-`mv` advice now creates the temp file in the target's directory (`mktemp "$(dirname -- "$target")/.tmp.XXXXXX"`), because `mv` across filesystems is a copy plus delete, not an atomic rename. It also notes that `mktemp` creates mode 0600 and `mv` carries it onto the target; copy the existing file with `cp -p` first to keep its mode.
- `writing-code` bash footgun entry for `jq empty`: `.x // true` never yields `false`; use `if has("x") then .x else true end` for a boolean whose default is not `false`.
- `writing-tests` Final-quality-gate redundancy deletes the data provider, fixture, or helper a deleted case alone referenced.

## [2.3.0] - 2026-10-06

### Added

- `writing-code` bash footgun catalog entry for `jq empty`: it exits 0 on empty, whitespace-only, and `null` input, so a parse check does not prove a document is present. The entry names the test per question: parseability, exactly one document, object shape, or both at once with `jq -se 'length == 1 and (.[0] | type == "object")'`, and the `// empty` versus `has()` split for a present `false`.

## [2.2.0] - 2026-08-27

### Added

- `writing-code` reference `references/stacks/bash.md`: the shell's introspection builtins as the doc-consultation surface (`type`, `declare -p`, `shopt`/`set -o`, `help`, `BASH_VERSINFO`) with the escalation paths past them, a 16-entry footgun catalog covering quoting and expansion, exit status under `set -e`, subshells and streams, input reading, and the BSD/GNU and bash-3.2/bash-4 portability splits, plus the Google Shell Style Guide function header as the doc-comment convention.
- `writing-code` Step 1 routes the `bash` stack, and detects it from the file alone — `.sh`, `.bash`, `.bats`, or a `sh`/`bash` shebang — ahead of every project signal, because shell scripts carry no manifest and routinely sit inside a project of another stack.

## [2.1.0] - 2026-08-03

### Added

- `writing-code` Step 6 opens with a code-comment consistency gate: a comment that contradicts the code it describes is corrected rather than left standing, and never deleted to resolve the mismatch. Systematic reviews of the code-comment literature rank comment/code inconsistency the top quality attribute, on the grounds that a misleading comment is worse than a missing one — the skill had no rule for it.
- Five named values on `writing-code`: `comments.preserve_patterns`, `comments.exemption_markers`, `todo.ticket_format`, and `domain.terms` are new, and `docs.surfaces` is now read by `writing-code` as well as `writing-docs`, so a comment restating a registered surface is cut to its local why plus a stable identifier.
- `references/comments.md` gained the rules the classification table had no bucket for: legal and license headers are never touched, commented-out code is deleted because version control holds it, non-trivial regular expressions are the documented exception to "explains-what gets removed", and marker discipline covers `TODO`/`FIXME` ownership and deprecation notices that name a replacement and a removal timeline.

### Changed

- The visibility rule now decides comment tier rather than syntax: structured tags on an exported or protected declaration are a contract, the same tags on a private declaration are an implementation comment and usually get deleted.
- The negative-invariant shape extends to every construct that reads as a mistake and is not — intentional switch fall-through, a deliberately empty catch block, a discarded return kept for its side effect — since several linters suppress their diagnostic only because the comment is present.
- The load-bearing-why section names the content that qualifies by construction however plainly worded: external spec/RFC/ticket citations, algorithm complexity and trade-offs, security and compliance constraints, thread-safety and lock-ordering requirements, workarounds with removal criteria, and design decisions that foreclose an alternative.
- The banned doc-backlink pattern was contradictory with the doc-surface rules absorbed in this release and is now one rule: a comment whose entire content is a pointer is still deleted, while a stable identifier attached to a why that reads on its own (`— ADR-0007`) is kept. Section-heading backlinks remain banned because they rot on rename.
- Over-specified why-comments gained tightening guidance (filler phrases, restatement, uniform enumerations) with an explicit floor: enumerations whose entries need different handling, thresholds, rule identifiers, and removal criteria survive at full length, and `domain.terms` entries are never swapped for a near-synonym.
- `writing-code`'s description no longer excludes retrospective comment cleanup, and covers improving comments on code being edited.

### Removed

- The `code-comment-writer` and `code-comment-writer-extension-setup` plugins are deleted; their durable rules live in `writing-code` as of this release. The standalone retrospective audit does not carry over — there is no scope resolution over commits, ranges, or branches, no read-only reporting mode, and no uncertainty-classification pass. Comment work now happens on the code being edited. Projects that assigned `paths.ignore` or `paths.conservative` lose those names; both governed audit scope and have no meaning in a per-edit workflow.

## [2.0.2] - 2026-07-23

### Fixed

- Codex reported `UserPromptSubmit hook (failed)` on every submitted prompt. Codex discovers and runs the shipped `PostToolUse` / `UserPromptSubmit` hooks but does not set `CLAUDE_PROJECT_DIR`, and `inject-extension.sh` treated the missing variable as a hard failure (exit 1) before reading stdin or self-gating. The variable is the Claude Code delivery-path signal, so the script now self-gates silently (exit 0) when it is absent: on Codex the hook does nothing and delivery flows entirely through the committed `AGENTS.override.md`. Claude Code behavior, which always sets the variable, is unchanged.

## [2.0.1] - 2026-07-20

### Fixed

- Codex delivery: the documented `AGENTS.override.md` envelope used `@path` references, but Codex resolves no includes inside AGENTS files and reads them as literal strings, so neither the extension files nor a root `AGENTS.md` were ever loaded. The envelope now carries the bare file path in `<extension_path>` plus handling instructions that say when to read the file (before executing the skill's workflow, or when a step first cites a named value or workflow position it defines), and root `AGENTS.md` guidance is retained through an explicit read instruction.

## [2.0.0] - 2026-07-20

### Added

- Shipped Claude Code delivery: `hooks/hooks.json` (`PostToolUse` on the Skill tool, `UserPromptSubmit` for slash invocations) and the self-gating `hooks/scripts/inject-extension.sh`. The script stays silent unless one of the three skills is invoked and the project has a matching extension file, so extension-file existence is the per-project opt-in. Projects no longer carry any delivery configuration.
- Structural envelope around delivered extension content: a `<project_extension>` block with `skill` and `position` attributes and `<handling_instructions>` stating identity, inertness, and whether the skill body is loaded yet. The envelope restates no mechanism semantics; the skill bodies own those.
- Reference-like extensions documented in `EXTENSION.md`: an extension file may cite project documentation surfaces, read on demand at the step that cites them. Cited files must be docs surfaces registered in `docs.surfaces` — no agent-only reference trees under `.claude/`. All three skill bodies gained the read-on-demand sentence.
- BATS suite `plugin-tests/software-writer/` covering the inject script's gating, delivery envelope, and loud-failure paths.

### Changed

- Canonical extension file path is now `.claude/extensions/software-writer/<skill>.md` (was `.claude/hook-contexts/<skill>.md`). The new path doubles as the v1/v2 discriminator: the shipped script reads only the new path, so unmigrated v1 projects keep their old project-provisioned delivery without double injection.
- Vocabulary unified on "extension content" / "extension file"; "overlay" removed from `EXTENSION.md` and from the one stray use in the `writing-docs` skill body.
- `EXTENSION.md` gained a Delivery section (shipped hooks, envelope shape, envelope-wrapped Codex `AGENTS.override.md` discovery) and a Reference-Like Extensions section.

### Migration from 1.x

Run the `software-writer-extension-setup` skill (2.x) in each provisioned project: it rewrites the extension files at the new path, deletes the legacy `.claude/hook-contexts/writing-*.md` files, and removes the six v1 hook entries from the project settings. Until then, v1 projects keep working on their old delivery, without the envelope. Restart Claude Code after updating the plugin so the shipped hooks load.

## [1.0.0] - 2026-07-20

### Added

- `writing-code` skill: API-consultation gate with per-stack doc-tool query tables, new-dependency existence gate, `code.primitives` in-repo wrapper lookup, dependency entry shape and caller-scope checks, per-stack footgun catalogs (Go, Python, TypeScript, PHP), and two-tier comment classification with the six-bucket table.
- `writing-tests` skill: classicist behavior-first workflow with the three-way seam decision, arrange-data sourcing rules, body-shape and assertion rules (including CLI-output hierarchy and ANSI stripping), independence leak vectors, and the redundancy and guard-clause quality gate.
- Per-framework test references, one file per test framework rather than per language, since table idioms, isolation models, and cleanup mechanisms differ per framework: Go (stdlib `testing`, testify, Ginkgo with Gomega), Python (pytest, `unittest`), TypeScript (Vitest, Jest, `node:test`, Mocha with Chai), PHP (PHPUnit, Pest). Each names the version it was written against where the framework ships breaking changes often enough for version-gated rules to matter.
- `writing-docs` skill: single-owner invariant, fixed surface shapes (Handled / Refused / Not covered contracts skeleton, §Limitations anti-pattern, existence-gated pointer files), house writing-style targets, anti-slop dispatch to `human-author:ai-slop-writing-fixer`, and the cross-surface quality gate.
- Generic `Pre-Step-N` / `Post-Step-N` extension contract and recognized named configuration values on all three skills (`project.stacks`, `code.*`, `tests.*`, `docs.*`).
- `EXTENSION.md`: the owning surface for the extension contract — overlay file layout, both mechanisms, the recognized named values per skill, and worked examples for registering a code framework and extending the documentation surface map.
- `dependencies` entry on `human-author` in `.claude-plugin/plugin.json`; Codex manifest and marketplace registration.

### Provenance

Research sources behind the universal and stack rules. Citations live here only; skill bodies use bare semantic anchors.

**Testing:**

- Google Testing Blog: "Change-Detector Tests Considered Harmful" (2015), "Test Behavior, Not Implementation" (2013), "Tests Too DRY? Make Them DAMP!" (2019), "Flaky Tests at Google" (2016), "Hermetic Servers" (2012) — testing.googleblog.com
- Kent Beck: "Test Desiderata" (2019) — testdesiderata.com
- Gerard Meszaros: xUnit Test Patterns test-smell catalog (Fragile Test, Eager Test, Mystery Guest, Assertion Roulette) — xunitpatterns.com
- Martin Fowler: "Mocks Aren't Stubs" (2007), "Eradicating Non-Determinism in Tests" (2011), bliki "Yagni", "ObjectMother", "TestDouble" — martinfowler.com
- Nat Pryce: "Test Data Builders" (2007) — natpryce.com
- Vladimir Khorikov: Unit Testing Principles, Practices, and Patterns (Manning) — the four pillars
- "Are Coding Agents Generating Over-Mocked Tests?" (MSR 2026) — arXiv:2602.00409
- Go Wiki TableDrivenTests and the Go subtests blog post — go.dev; pytest parametrize documentation — docs.pytest.org; Vitest parallelism and API documentation — vitest.dev; PHPUnit data-provider documentation — docs.phpunit.de

**Framework references (verified 2026-07-20):**

- Go: `testing` and `errors` package documentation — pkg.go.dev; `go help testflag` for `-parallel` and `-shuffle`; Go 1.22/1.24/1.25 release notes for loop variables, `T.Context`, and `synctest` — go.dev/doc; testify release policy — github.com/stretchr/testify; Ginkgo v2 migration guide — onsi.github.io/ginkgo
- Python: pytest reference and how-to guides for `raises`, parametrize, monkeypatch, and fixture scopes — docs.pytest.org; pytest 9.0/9.1 changelog — github.com/pytest-dev/pytest; pytest-xdist distribution docs — pytest-xdist.readthedocs.io; `unittest` and `doctest` library docs — docs.python.org
- TypeScript: Vitest configuration docs for `isolate`, `pool`, `fileParallelism`, and the mock-reset flags — github.com/vitest-dev/vitest and vitest.dev; Jest API docs — jestjs.io; Node.js `test` and `assert` API docs plus the CLI concurrency defaults — nodejs.org and github.com/nodejs/node; Mocha parallel-mode and assertion docs — mochajs.org; Chai BDD API — chaijs.com
- PHP: PHPUnit 13 manual (writing tests, fixtures) — docs.phpunit.de; PHPUnit 10/11/12/13 release announcements for the annotation-to-attribute transition — phpunit.de/announcements; Pest datasets, exceptions, hooks, and optimization docs — pestphp.com

**Code:**

- "We Have a Package for You! A Comprehensive Analysis of Package Hallucinations by Code Generating LLMs" (2025); "Importing Phantoms" — arXiv:2501.19012 (the new-dependency gate)
- John Ousterhout: A Philosophy of Software Design, comments chapters (interface comments are the abstraction); Robert C. Martin: Clean Code ch. 4 and "Necessary Comments" (2017) — the two-tier comment policy resolves their documented disagreement
- Mark Seemann: "Composition Root" (2011) — blog.ploeh.dk; DevIQ: Explicit Dependencies Principle — deviq.com
- Hyrum's Law — hyrumslaw.com; Go Proverbs (Rob Pike, Gopherfest 2015)
- Go doc comments — go.dev/doc/comment; PEP 257 — peps.python.org; Google Python and TypeScript style guides — google.github.io/styleguide; TSDoc — tsdoc.org; phpDocumentor DocBlock — docs.phpdoc.org
- Go 1.22 per-iteration loop variables — go.dev/blog/loopvar-preview (verified 2026-07-19)

**Docs:**

- Diátaxis — diataxis.fr; Standard Readme — github.com/RichardLitt/standard-readme
- Write the Docs docs-principles (ARID, Unique) and docs-as-code — writethedocs.org; Google documentation best practices — google.github.io/styleguide/docguide
- agents.md spec — agents.md; Claude Code CLAUDE.md guidance — code.claude.com/docs/en/memory
- arc42 — arc42.org; C4 model — c4model.com; ADR (Michael Nygard, 2011) — cognitect.com; Keep a Changelog — keepachangelog.com
- Google and Microsoft style guides — developers.google.com/style, learn.microsoft.com/style-guide
