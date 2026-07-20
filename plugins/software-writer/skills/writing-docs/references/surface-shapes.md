# Surface Shapes

Each prose surface has a fixed shape that is not yours to refine mid-edit.

## Root README

**Sections:** pitch, install, usage/quick-start, pointers into deeper docs.

**Delegate, don't expand.** Deeper structure delegates to the architecture document (system design) and the module READMEs (contracts and detail). The root README does not re-explain module contracts, full flag sets, or cross-cutting policies; it points and stops.

## Module README

**Sections:** Purpose / Public API / Contracts / Quirks / Tests.

**Short shape:** Purpose / Public API / Tests is the entire README when the module owns no invariant. Do not pad with a Contracts or Quirks section that says "none".

### §Contracts skeleton — Handled / Refused / Not covered

Use this skeleton verbatim for every genuine hard invariant the module owns:

```markdown
## Contracts

### {Invariant name}

**Handled.** {What the module does to satisfy the invariant.}

- {Case 1.}
- {Case 2.}

**Refused.** {What the module rejects rather than handle. The refusal is part of the contract.}

- {Refused case, with the error the caller sees.}

**Not covered.** {What the module does not address. The residual risk the caller carries.}

- {Uncovered case, with the consequence if the caller hits it.}
```

The triple is a residual-risk decomposition: every invariant in scope has rows in all three buckets. An explicit "none" is a contract; an absent bucket is a gap.

### §Limitations anti-pattern

A §Limitations heading is a §Contracts entry in disguise whenever the named constraint is actively enforced by code. The signal: a paragraph saying "does not handle X" right next to a code path that detects, refuses, or skips X — the detection is the contract, and "limitation" is the wrong frame.

```
WRONG:   ## Limitations
         - Compiled bundle files are not scanned.

CORRECT: ## Quirks
         ### Compiled-file handling
         Files under build output directories are detected and skipped,
         because bundled output mixes in third-party code the author
         cannot fix.
```

§Limitations stays correct only when the named case is genuinely out of scope: no code path detects it, no contract addresses it, and the caller carries the residual risk unconditionally.

## Architecture document

**Job:** cross-module narrative plus invariant ownership index.

**Shape:** the system-overview narrative; an invariant-to-owner index with one row per hard invariant, each row a *link* to the owning module README's §Heading, never a restatement — the index says "X is enforced by module Y, see §Z" and the contract lives at §Z; cross-cutting policies as tagged sections only when no single module owns the invariant.

**Visual floor when diagrams are used:** C4 Context and Container levels. Go deeper (component-level and below) only when a table cannot express the relationship.

## Changelog

Only when the project registers one via `docs.changelog`. Follow Keep a Changelog discipline: one entry per released version plus an Unreleased section; entries grouped under Added / Changed / Deprecated / Removed / Fixed / Security; entries describe user-observable change, not commit-by-commit history; newest version first.
