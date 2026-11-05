# LLM Pointer File

The pointer file (`CLAUDE.md` or `AGENTS.md`, per `docs.pointer_file`) is a pointer-only map into the adjacent module README. The README is the human-facing reference; the pointer file is the LLM-facing map an agent reads before editing the module. No summaries.

## Existence gate

A module qualifies for a pointer file when it owns at least one hard cross-cutting constraint an editor must know before changing code.

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

## Per-bullet decision test

Two questions, one bullet at a time:

1. **Provenance.** Does the rule trace to a real incident, a recurring bug class the module already corrected, or a load-bearing invariant?
2. **Visibility.** Would a violation produce a visible failure rather than a style preference?

Both pass → keep. No provenance → do not add the rule. Invisible violation → drop the rule. A pointer to a vague or missing heading → fix the README heading first, then repoint.

## Companion-file rule

When the project maintains both pointer-file conventions, `AGENTS.md` owns the content and `CLAUDE.md` is a one-line include of it (`@AGENTS.md`). Never the reverse: Codex reads `@path` includes as literal strings. Create and delete the pair together; never author content in both.
