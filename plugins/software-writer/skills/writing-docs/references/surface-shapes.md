# Surface Shapes

## Root README

**Sections:** pitch, install, usage/quick-start, pointers into deeper docs. Deeper structure delegates to the architecture document and the module READMEs; the root README points and stops.

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

**Refused.** {What the module rejects rather than handles.}

- {Refused case, with the error the caller sees.}

**Not covered.** {What the module does not address; the residual risk the caller carries.}

- {Uncovered case, with the consequence if the caller hits it.}
```

Every invariant in scope has rows in all three buckets. An explicit "none" is a contract; an absent bucket is a gap.

A §Limitations heading is a §Contracts entry in disguise whenever code detects, refuses or skips the named case ("Compiled bundle files are not scanned" next to a skip path): document it under §Contracts or §Quirks, and keep §Limitations for cases no code path touches.

## Architecture document

**Shape:** the system-overview narrative; an invariant-to-owner index with one row per hard invariant, each row a link to the owning module README's §Heading, never a restatement; cross-cutting policies as tagged sections only when no single module owns the invariant.

**Visual floor when diagrams are used:** C4 Context and Container levels.

## Changelog

Keep a Changelog discipline: one entry per released version plus an Unreleased section, newest first, grouped under Added / Changed / Deprecated / Removed / Fixed / Security, describing user-observable change rather than commit history.
