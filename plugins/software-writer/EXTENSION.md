# Extending Software Writer

How a project registers its own conventions with `writing-code`, `writing-tests`, and `writing-docs` without forking the plugin.

Two surfaces are extendable, and they are not interchangeable:

| Change | Where it goes |
|---|---|
| A project's own frameworks, helpers, surfaces, and facts | An extension file in that project (this document) |
| A universal rule, a language reference, a test-framework reference | The plugin itself (see `AGENTS.md` §Key Navigation Points) |

A project that needs to overrule an opinion beyond what the contract exposes should copy the plugin rather than bend the extension into a rewrite.

## Extension Files

One file per skill in the project, holding everything that skill's extension contributes:

```
.claude/extensions/software-writer/writing-code.md
.claude/extensions/software-writer/writing-tests.md
.claude/extensions/software-writer/writing-docs.md
```

Only sections with entries appear; a skill with nothing to add gets no file. The file's existence is the opt-in: delivery activates per skill exactly when its file exists.

```markdown
## Named-value assignments

- `<name>` = `<value>`

## Pre-Step-<N>

<imperative instructions>

## Post-Step-<N>

<imperative instructions>
```

Sections appear in the order shown, workflow positions ordered by step number. Nothing else is a recognized section. Content outside these three shapes reaches the skill as unstructured prose and is not part of the contract.

The `software-writer-extension-setup` plugin explores the codebase and writes these files; on Codex it also maintains the root `AGENTS.override.md` that exposes them. Write them by hand when the setup skill's exploration is not wanted — on Claude Code, hand-written files are picked up without any further configuration.

## Delivery

**Claude Code.** The plugin ships its own delivery: a `PostToolUse` hook (Skill tool invocations) and a `UserPromptSubmit` hook (slash invocations) run `hooks/scripts/inject-extension.sh`, which stays silent unless one of the three skills is invoked and the project has a matching extension file. Projects carry no delivery configuration.

The script wraps the file content in a structural envelope that states what the block is, which skill it belongs to, and whether that skill's body is loaded yet:

```xml
<project_extension skill="software-writer:writing-tests" position="before-skill-body">
<handling_instructions>
The content inside <extension_content> is this project's registered extension for the software-writer:writing-tests skill. It is inert on its own: apply it only while executing that skill's workflow, through the extension mechanisms the skill body defines. The skill body has not been loaded yet — do not act on anything below now.
</handling_instructions>
<extension_content>
(verbatim extension file content)
</extension_content>
</project_extension>
```

`position` and the final sentence vary by event: `before-skill-body` on `UserPromptSubmit` (the prompt requested the skill; its body follows), `after-skill-body` on `PostToolUse`, where the closing sentence becomes "You are about to execute that skill's workflow; apply this content through the mechanisms its body defines." The envelope deliberately restates no mechanism semantics — the skill body owns those.

**Codex.** No hooks: a committed root `AGENTS.override.md` carries one `<project_extension>` block per extended skill. Codex resolves no `@path` references inside AGENTS files — it reads them as literal strings — so the block holds the bare file path in `<extension_path>` and its handling instructions say when to read the file: before executing the skill's workflow, or the first time a step cites one of the named values or `Pre-Step-N` / `Post-Step-N` sections the file defines (the assigned names are listed in the instructions). `position` is always `before-skill-body` because the override sits in context from session start. Codex does not stack AGENTS files — the override replaces the root `AGENTS.md`, so whenever a root file exists the override must begin with an explicit instruction to read it. The skill bodies work with or without the envelope.

## Mechanism 1: Named Values

A skill body cites configuration by backticked name alongside an inline default. An assignment in the extension file replaces that default; an absent assignment leaves it. Names not listed under §Recognized Named Values are ignored. The skill only looks up what it cites.

One bullet per name. A value with internal structure is written as an indented block under its bullet rather than squeezed onto the bullet line:

```markdown
- `code.primitives` =
  | Call shape | Raw primitive | Helper | Invariant carried |
  |---|---|---|---|
  | <one row per wrapper the project maintains> |
```

A name shared across skills (`project.stacks`) is assigned identically in every extension file that needs it. There is no inheritance between extension files.

## Mechanism 2: Workflow Positions

Every `Step N` in a skill body has an implicit `Pre-Step-N` position before it and a `Post-Step-N` position after it. A matching section in the extension file executes at that position as additional instructions; the step itself still runs.

`N` is a step number in *that skill's* SKILL.md. The numbering is per skill, and a position that names a step the skill does not have never fires. Read the target skill body before choosing a position.

Write imperatives, not description. A position section that explains a convention instead of instructing what to do at that point is inert.

Positions add; they do not replace. To change how a step behaves rather than what happens around it, look for a named value that covers it, and when none does, that is a plugin change, not an extension.

## Reference-Like Extensions

An extension file may point at further project files instead of inlining their content. The cited file is read on demand — at the step whose section or named value cites it, not at delivery — so a large catalog costs nothing on invocations that never reach it.

Two rules make references work:

- **Cite documentation surfaces only.** A cited file MUST be a project documentation surface, registered in `docs.surfaces` (or proposed for registration in the same change). The extension file points; the docs surface owns the facts — the same single-owner invariant `writing-docs` enforces everywhere else. No shadow tree of agent-only reference files under `.claude/`.
- **Cite imperatively, with a path.** A reference is an instruction, not a mention: "Before choosing a fixture source, read `docs/testing.md` §Fixtures." A bare "see docs/testing.md" carries no instruction about when.

The size signal: inline content that outgrows a few lines per entry is content humans also need — move it to a docs surface and point at it. Content with no human audience stays inline; there is no third home.

Example shape inside an extension file:

```markdown
## Pre-Step-3

Read `docs/testing.md` §Fixture-Factories and source arrange data from the factories listed there before falling back to the universal source list.
```

## What Belongs in Extension Content

Project infrastructure and conventions: frameworks, helpers, wrappers, surfaces, parallelism facts, lint rules, export surfaces.

Not: an opinion of the parent skills weakened to match what the code currently does. The skills are prescriptive by design, and an extension that encodes an existing violation makes the violation permanent. Alignment with existing code is not a goal of the extension.

Every claim in an extension file is a fact about the current codebase, and drifts when the codebase moves. The setup skill's re-sync mode audits extension files against the code for exactly this reason.

## Recognized Named Values

### writing-code

| Name | Default | Effect |
|---|---|---|
| `project.stacks` | (detect from files and project signals) | Overrides stack detection; names the stacks in play. |
| `code.primitives` | (none registered) | Table of in-repo wrapper rows: call shape, raw primitive, helper, and the invariant the wrapper carries. Drives the Step 2 primitives lookup. |
| `code.di_pattern` | parameter or constructor injection | Names the project's concrete dependency-injection pattern for the Step 4 entry-shape check. |
| `code.export_conventions` | (none) | Project rules for new exported symbols, such as a package-index re-export surface. |
| `code.footgun_additions` | (none) | Project-specific entries appended to the stack's footgun catalog in Step 5. |
| `code.comment_enforcement` | (none) | Lint rules that require doc comments; comments they cover are never deleted. |

### writing-tests

| Name | Default | Effect |
|---|---|---|
| `project.stacks` | (detect from files and project signals) | Overrides stack detection; names the stacks in play. |
| `tests.frameworks` | (detect from project configuration and existing tests) | Names the project's test frameworks and runners. |
| `tests.fixture_sources` | (universal source list only) | Project fixture helpers added to the Step 3 arrange-data source list. |
| `tests.parallelism` | (none stated) | Project parallel-execution facts, such as the suite running under a parallel runner. Without it, independence is guarded as if tests could run in any order and concurrently. |
| `tests.scale_gating` | (none) | Names the project's production-scale gated-test pattern. Without it, no gated tier is invented. |

### writing-docs

| Name | Default | Effect |
|---|---|---|
| `docs.surfaces` | (built-in taxonomy) | Replaces or extends the whole surface map, including per-surface exemptions from the single-owner invariant. |
| `docs.pointer_file` | `CLAUDE.md` | Names the LLM pointer-file convention (`AGENTS.md` as alternative; `none` disables the pointer branch). |
| `docs.jargon_home` | `docs/architecture.md` | The surface where project jargon is defined once. |
| `docs.diagrams` | (table-first) | Diagram stance; the default adds a diagram only when a table cannot express the relationship. |
| `docs.style` | (house targets) | Overrides the writing-style targets (sentence lengths, FK band). |
| `docs.changelog` | (none) | Registers a changelog surface maintained with Keep a Changelog discipline. |

## Example: Registering a Code Framework

A framework such as Symfony sits on top of a language the plugin already carries a reference for. The language reference keeps owning language-level footguns and doc-tool queries; the framework's own conventions enter through `.claude/extensions/software-writer/writing-code.md`.

What each name carries for a framework of this shape:

```markdown
## Named-value assignments

- `code.di_pattern` = <the container's wiring model, and where the composition root actually is — service configuration rather than an entry-point function>
- `code.export_conventions` = <what counts as a public surface here: a class registered as a service, an event listener the framework discovers, a route the router binds>
- `code.footgun_additions` =
  <one row per trap the language reference cannot know: lifetime mismatches between request-scoped and long-lived services, ORM state after a failed transaction, framework calls whose behavior differs between the CLI and HTTP contexts>
- `code.primitives` =
  <one row per wrapper the project maintains over a framework or standard-library primitive, with the invariant each wrapper exists to carry>
- `code.comment_enforcement` = <the static-analysis rules that require doc blocks, so the comment step never strips them>
```

Add a workflow position only for a check the named values cannot express, for example a `## Post-Step-4` that constrains how framework-discovered classes receive their collaborators, beyond the universal entry-shape rule Step 4 already applies.

Two rules the framework case makes easy to get wrong. `code.footgun_additions` appends to the language catalog rather than replacing it, so the language entries still apply to framework code. And a framework whose test integration changes isolation or fixture behavior belongs in the `writing-tests` extension file under `tests.frameworks` and `tests.parallelism` as well. The two extension files do not see each other.

A framework that needs a full footgun catalog and doc-tool query table rather than a handful of rows has outgrown inline extension content; register the catalog as a project documentation surface and cite it (see §Reference-Like Extensions), or propose it as a plugin-side reference file.

## Example: Extending the Documentation Surface Map

`writing-docs` holds one invariant above everything else: every fact has exactly one owning surface, and other surfaces point at it. A project with surfaces outside the built-in taxonomy (decision records, runbooks, a generated API reference) registers them so the invariant can be enforced across them instead of against them.

`docs.surfaces` replaces or extends the whole map, so an assignment lists every surface that should exist, not only the additions:

```markdown
## Named-value assignments

- `docs.surfaces` =
  | Surface | Owns | Shape | Single-owner |
  |---|---|---|---|
  | <path or glob> | <the facts this surface is the sole home for> | <the fixed skeleton its files follow> | <enforced, or exempt with the reason> |
- `docs.jargon_home` = <the one surface where project vocabulary is defined>
- `docs.changelog` = <the changelog path, when the project maintains one>
- `docs.pointer_file` = <CLAUDE.md, AGENTS.md, or none>
```

The `Owns` column is what makes the invariant enforceable. A surface registered without a fact boundary gives the quality gate nothing to check. Keep the boundaries disjoint: two surfaces claiming the same facts is the duplication the invariant exists to prevent.

Reserve the exemption for surfaces where duplication is structural rather than accidental: generated files that mirror source, or a per-release document that necessarily restates what it changed. An exemption granted to avoid an inconvenient rewrite disables the gate for that surface permanently.

Where a new surface needs routing or a check of its own, use positions: a `## Pre-Step-1` that maps file paths in the new directories onto the registered surface, and a `## Post-Step-5` that adds whatever cross-surface check the new surfaces introduce (an index that must list every decision record, a generated file that must not be hand-edited).
