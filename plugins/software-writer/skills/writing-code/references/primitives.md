# In-Repo Primitives

The project's wrapper rows arrive via the `code.primitives` named value. Without assigned rows, no wrapper lookup applies.

## Table shape

Each `code.primitives` row names a call shape, the raw primitive an author would reach for, the in-repo helper to use instead, and the invariant the wrapper carries:

| Call shape | Reach for | In-repo helper | Reason the wrapper exists |
|---|---|---|---|

## Decision test

Before writing a call in a wrapped domain, ask:

> Does this call touch one of the domains the project wraps — and does a helper row exist for this case?

- Yes, a helper row exists → use the helper.
- Yes, the domain is wrapped but no helper covers this case → flag it and propose adding a wrapper rather than reaching past the missing one.
- No → the raw primitive is fine.
