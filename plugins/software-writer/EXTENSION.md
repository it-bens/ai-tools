# Extending Software Writer

How a project registers its own conventions with `writing-code`, `writing-tests`, and `writing-docs` without forking the plugin.

Two surfaces are extendable, and they are not interchangeable:

| Change | Where it goes |
|---|---|
| A project's own frameworks, helpers, surfaces, and facts | An overlay file in that project (this document) |
| A universal rule, a language reference, a test-framework reference | The plugin itself (see `AGENTS.md` §Key Navigation Points) |

A project that needs to overrule an opinion beyond what the contract exposes should copy the plugin rather than bend the overlay into a rewrite.

## Overlay Files

One file per skill in the project, holding everything that skill's overlay contributes:

```
.claude/hook-contexts/writing-code.md
.claude/hook-contexts/writing-tests.md
.claude/hook-contexts/writing-docs.md
```

Only sections with entries appear; a skill with nothing to add gets no file.

```markdown
## Named-value assignments

- `<name>` = `<value>`

## Pre-Step-<N>

<imperative instructions>

## Post-Step-<N>

<imperative instructions>
```

Sections appear in the order shown, workflow positions ordered by step number. Nothing else is a recognized section. Content outside these three shapes reaches the skill as unstructured prose and is not part of the contract.

The `software-writer-extension-setup` plugin writes these files and the host delivery configuration that exposes them. Write them by hand only when the setup skill's exploration is not wanted; the delivery configuration is still required either way.

## Mechanism 1: Named Values

A skill body cites configuration by backticked name alongside an inline default. An assignment in the overlay replaces that default; an absent assignment leaves it. Names not listed under §Recognized Named Values are ignored. The skill only looks up what it cites.

One bullet per name. A value with internal structure is written as an indented block under its bullet rather than squeezed onto the bullet line:

```markdown
- `code.primitives` =
  | Call shape | Raw primitive | Helper | Invariant carried |
  |---|---|---|---|
  | <one row per wrapper the project maintains> |
```

A name shared across skills (`project.stacks`) is assigned identically in every overlay that needs it. There is no inheritance between overlay files.

## Mechanism 2: Workflow Positions

Every `Step N` in a skill body has an implicit `Pre-Step-N` position before it and a `Post-Step-N` position after it. A matching section in the overlay executes at that position as additional instructions; the step itself still runs.

`N` is a step number in *that skill's* SKILL.md. The numbering is per skill, and a position that names a step the skill does not have never fires. Read the target skill body before choosing a position.

Write imperatives, not description. A position section that explains a convention instead of instructing what to do at that point is inert.

Positions add; they do not replace. To change how a step behaves rather than what happens around it, look for a named value that covers it, and when none does, that is a plugin change, not an overlay.

## What Belongs in an Overlay

Project infrastructure and conventions: frameworks, helpers, wrappers, surfaces, parallelism facts, lint rules, export surfaces.

Not: an opinion of the parent skills weakened to match what the code currently does. The skills are prescriptive by design, and an overlay that encodes an existing violation makes the violation permanent. Alignment with existing code is not a goal of the overlay.

Every claim in an overlay is a fact about the current codebase, and drifts when the codebase moves. The setup skill's re-sync mode audits overlays against the code for exactly this reason.

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

A framework such as Symfony sits on top of a language the plugin already carries a reference for. The language reference keeps owning language-level footguns and doc-tool queries; the framework's own conventions enter through `.claude/hook-contexts/writing-code.md`.

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

Two rules the framework case makes easy to get wrong. `code.footgun_additions` appends to the language catalog rather than replacing it, so the language entries still apply to framework code. And a framework whose test integration changes isolation or fixture behavior belongs in the `writing-tests` overlay under `tests.frameworks` and `tests.parallelism` as well. The two overlays do not see each other.

A framework that needs a full footgun catalog and doc-tool query table rather than a handful of rows has outgrown the overlay; that is a plugin-side reference file.

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
