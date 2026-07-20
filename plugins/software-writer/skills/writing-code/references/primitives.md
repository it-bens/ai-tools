# In-Repo Primitives

Standard-library calls that look right in isolation often violate an invariant the project enforces only through a wrapper. The project's wrapper rows arrive via the `code.primitives` named value; this reference carries the table shape and the decision procedure. Without assigned rows, no wrapper lookup applies.

## Table shape

Each `code.primitives` row names a call shape, the raw primitive an author would reach for, the in-repo helper to use instead, and the invariant the wrapper carries:

| Call shape | Reach for | In-repo helper | Reason the wrapper exists |
|---|---|---|---|
| Substring rewrite of a path-shaped string | the language's plain string replace | *(project helper)* | Plain replace corrupts paths sharing a prefix: `/a/box` inside `/a/box-extras` produces a mangled sibling. Boundary-aware matching is required. |
| Edit a key in a user-owned config file | a parse/serialize round-trip | *(project helper)* | A round-trip destroys key order, indentation, and trailing newlines. The user-owned file's formatting is data; preserve it. |
| Line-scan an untrusted byte stream | the default line scanner | *(project helper)* | Default buffer limits truncate long lines silently; adversarial input needs an explicit cap. |

The rows above illustrate the shape; the real rows are project content and come only from `code.primitives`.

## Decision test

Before writing a call in a wrapped domain, ask:

> Does this call touch one of the domains the project wraps — and does a helper row exist for this case?

- Yes, a helper row exists → use the helper.
- Yes, the domain is wrapped but no helper covers this case → flag it and propose adding a wrapper rather than reaching past the missing one; a raw call in a wrapped domain silently drops the invariant the wrapper exists to carry.
- No → the raw primitive is fine.

## What the lookup is not

The table is not exhaustive and not definitional — it captures the categories where missed routing through a helper has caused a recurring class of bug in the project. If a call sits clearly outside the registered categories, the table does not apply.
