# Changelog

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
