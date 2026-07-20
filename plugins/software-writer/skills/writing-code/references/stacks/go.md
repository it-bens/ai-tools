# Go Code Stack

## Doc consultation: `go doc`

Pick the narrowest query that answers the question:

| Need | Command | Typical size |
|---|---|---|
| One symbol (func / const / var / method / field) | `go doc <pkg>.<Symbol>` or `go doc <pkg>.<Type>.<Method>` | ~400-600 B |
| Discover what exists in a package | `go doc -short <pkg>` | ~1 KB (one-liners) |
| Package overview | `go doc <pkg>` | ~2-5 KB |
| Full package dump | `go doc -all <pkg>` | 10 KB+ — avoid |

Escalate to `go doc -src` only when the doc comment leaves behavior unclear — never as a reflex.

Consultation is not required for: builtins (`len`, `append`, `cap`, `make`, `delete`, `copy`); a call that already compiles with a passing test exercising it; mechanically repeating an idiom established in the same file.

## Footgun catalog

Scan every written line against these; apply them even when nearby code does not.

- **Unchecked error returns and error shadowing.** Every returned error is handled or explicitly propagated; a `:=` inside a block that shadows an outer `err` silently drops the outer check.
- **Nil-map writes.** Reading a nil map is safe; writing panics. Initialize with `make` or a literal before any write path can reach the map.
- **Slice aliasing and append sharing.** A subslice shares the backing array; `append` on one alias can overwrite the other's elements or, past capacity, silently diverge. Copy when the callee keeps the slice.
- **Defer in a loop.** Deferred calls run at function exit, not iteration end — resources pile up across iterations. Extract the loop body into a function or release explicitly.
- **Goroutine capture of mutating variables.** Loop variables are per-iteration in modules declaring `go 1.22` or later; in modules on older `go` directives the loop variable is shared and every spawned goroutine observes its final value. Capturing any variable that keeps mutating after the spawn races regardless of version — pass the value as an argument.
- **Interface-nil vs typed-nil.** An interface holding a typed nil pointer is not `== nil`. Return a literal `nil` for the interface type, never a nil concrete pointer through an interface return.

## Doc-comment convention: godoc

A doc comment immediately precedes the declaration, is a complete sentence, and begins with the symbol's name. Minimal-correct example:

```go
// ResolveManifest loads the manifest for dir, applying the project's
// override chain. It returns ErrNoManifest when dir has no manifest file.
func ResolveManifest(dir string) (Manifest, error) {
```

The first line is the contract summary; subsequent lines carry only what the signature cannot say (sentinel errors, side effects, preconditions). A doc comment that would only restate the signature compresses to the single identifier-prefixed line.
