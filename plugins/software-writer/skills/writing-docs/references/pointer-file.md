# LLM Pointer File

The pointer file (`CLAUDE.md` or `AGENTS.md`, per `docs.pointer_file`) is a pointer-only map into the adjacent module README. The README is the human-facing reference; the pointer file is the LLM-facing map an agent reads before editing the module. No summaries — a summary restates the README, so it duplicates the fact and drifts from it. Every bullet is a pointer `(README §Heading)` or it gets deleted.

The ≤30-line ceiling and pointer-only rule are deliberate context economy: the file loads into every session that touches the module, so every non-pointer line taxes every future session.

## Existence gate

A module qualifies for a pointer file when it owns at least one hard cross-cutting constraint an editor must know before changing code — a contract with residual risk, a banned primitive, a required call bracket, a two-step registration.

A ceremonial pointer file is noise: the agent loads it expecting a warning and finds none, so the next pointer file it loads carries less weight too. A module without a qualifying constraint gets no pointer file. Absence is a positive signal.

## Skeleton

```markdown
# <module>: agent notes

<one short line of orientation; optional>

## Before editing

- <highest-stakes invariant in one line> (README §<heading>)
- <next invariant> (README §<heading>)

## Navigation

- <subdirectory or key file>: <one-line role>
```

Hard ceiling: 30 lines, 3-8 bullets per section. `## Before editing` carries the warnings; `## Navigation` is a flat map of where to find what — one line per entry, no nesting.

## Bullet discipline (`## Before editing`)

- Every bullet ends with `(README §<heading name>)` pointing at a real heading in the adjacent README. The bullet states the rule; the README carries the why.
- **No motivation in the bullet.** Motivation lives in the README; the pointer file only points at it.
- **Front-load by stakes.** The first bullet carries the most attention weight; order by stakes, not by source-file order.
- **Cross-refs use `§<heading name>`, never line numbers, never anchor links.** Headings survive edits; line numbers don't.
- **Identifiers mirror the code.** Abbreviating an identifier to tighten a bullet defeats grep and breaks the pointer-to-README coupling.
- **A root-level pointer file names the target file**: `(modules/parser/README.md §Boundary rules)`. The `(README §X)` shorthand applies only inside a module.

## Per-bullet decision test

Three questions, one bullet at a time:

1. **Shape.** Does the bullet end with `(README §<heading name>)` pointing at a real heading, without explaining why in the bullet itself?
2. **Provenance.** Does the rule trace to a real incident, a recurring bug class the module already corrected, or a load-bearing invariant? "We might want this someday" is not provenance.
3. **Visibility.** Would a violation produce a visible failure — a test breaks, a guarantee voids, a contract refuses — rather than a style preference?

Outcomes: all three pass → keep. No pointer → delete or rewrite as a pointer. Explains motivation → move the motivation to the README, leave rule + pointer. Pointer targets a vague or missing heading → fix the README heading first, then repoint. No provenance → do not add the rule. Invisible violation → drop the rule; the section is for warnings, not preferences.

## Worked WRONG / CORRECT

```
WRONG:   - History snapshots are opaque because rewriting the binary
           payload would corrupt image data, as we learned during the
           export work.
CORRECT: - History snapshots are opaque bytes. No module inspects or
           rewrites them. (README §History policy)
```

The WRONG version explains the why (corruption risk, project history); that belongs in the README section the bullet points at.

```
WRONG:   - Lock contract: see lock/README.md:42
CORRECT: - Wrap every mutating command body in the lock helper before
           any write. (README §Concurrency guard)
```

Line numbers shift on any reformat; heading names survive until a rename — which the cross-ref integrity gate then catches.

## Companion-file rule

When the project maintains both pointer-file conventions, `AGENTS.md` owns the content and `CLAUDE.md` is a one-line include of it (`@AGENTS.md`). Never the reverse: only Claude Code resolves `@path` includes — Codex reads them as literal strings, so an `AGENTS.md` that is only an include delivers nothing there. Create and delete the pair together; never author content in both.

## Common rationalizations to refuse

| Thought | Reality |
|---|---|
| "I'll add a one-line summary so readers don't need the README" | The summary will drift. The pointer is the discipline. |
| "Every module should have a pointer file for consistency" | Absence is a positive signal. A pointer file with no hard rule is noise. |
| "I'll stub one with plausible wiring rules now" | Invented constraints are misinformation. Write the rule when real evidence surfaces. |
| "I'll go a few lines over the ceiling just this once" | The ceiling is the mechanism that keeps the file pointer-only. Cut the lowest-stakes bullet instead. |
