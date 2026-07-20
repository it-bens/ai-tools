# Code Comments and Doc Comments

## Classification table

Classify every comment proposed, kept, or edited into exactly one bucket and apply its action.

| Bucket | Action |
|---|---|
| **Redundant with docs** (70%+ wording overlap with a README or architecture-doc section) | Remove or compress to one line |
| **Explains-what** (paraphrases the identifier or the code below) | Remove |
| **Tutorial / novice-facing** (narrates the language, the standard library, or control flow) | Remove or compress sharply |
| **Over-specified why** (five lines where one would do) | Tighten |
| **Load-bearing why** (names the failure mode the code guards against) | **Keep verbatim**; rewrite new why-comments toward this shape |
| **Public doc comment** (the API contract on an exported symbol) | Keep; compress pure signature paraphrase to one identifier-prefixed line; never delete where project lint requires it |

## Load-bearing why: the worked shape

A load-bearing why-comment names the failure mode, gives a concrete instance, and states what the code does to prevent it. Compare every new why-comment against this shape:

```go
// Prevent a shorter key from consuming a legitimate prefix of a longer one.
// Substituting `{{BASE}}` before `{{BASE_URL}}` would leave `{{BASE}}_URL`
// where `{{BASE_URL}}` was intended. Sorting keys longest-first resolves this.
func applyTemplateKeys(data []byte, keys []TemplateKey) []byte {
    // ... sort by descending key length, then substitute in order.
}
```

The comment names the failure (shorter key consuming a longer one), gives the substitution that triggers it, and identifies the fix. None of those facts is recoverable from the code alone — sorting longest-first looks like a stylistic choice without the comment.

## The negative-invariant shape

The second load-bearing shape justifies why an obvious-looking guard is deliberately omitted, so the next editor does not "fix" the missing guard and break correctness:

```python
# Only single quotes need doubling here: the engine accepts double-quoted
# identifiers, so escaping double quotes as well would corrupt quoted names.
def escape_literal(text: str) -> str:
    return text.replace("'", "''")
```

Without the comment, the missing double-quote escape reads as an oversight; with it, the omission is a documented decision.

## Doc comments: contract, not narration

A doc comment states the contract a caller cannot infer from the signature: raise/throw behavior, side effects, ordering constraints, preconditions, what absence of an optional value means. It never narrates the body.

```
WRONG:   /// Rejects unsupported shapes.
         ///
         /// Opens the catalog, finds views, finds generated columns,
         /// finds self-referential keys, raises if any are present.
CORRECT: /// Fail hard for source shapes a verbatim rebuild cannot reproduce.
         ///
         /// Raises on views, generated columns, and self-referential keys.
```

Prefer making the types say it over commenting it: a discriminated union instead of a comment listing valid combinations; an immutable/readonly field instead of "do not mutate"; a unit-suffixed identifier (`timeoutSeconds`) instead of a parameter comment explaining the unit. The comment is the fallback for what the type system cannot reach.

## Banned patterns

```
WRONG:   // See README §Atomic staging
         stage_file(...)
CORRECT: stage_file(...)
```

Docs point at code, never the reverse. A comment citing a doc heading rots when the heading renames, and the doc is the authoritative narrative while the code is the authoritative behavior — the backlink gets the direction wrong.

```
WRONG:   // see importer.py:147
CORRECT: // see resolve_manifest in importer.py
```

Line numbers shift the moment anyone reformats; symbol names survive edits. Use a line-free symbol reference on the rare occasion a cross-reference is warranted at all.

```
WRONG:   // increment the counter
         skipped_count += 1
CORRECT: skipped_count += 1
```

The explains-what pattern: the code is shorter than the comment.

```
WRONG:   /** @param priceCents - number, the price in cents */
CORRECT: (no tag — the name and type already say both)
```

A doc-comment tag that adds nothing beyond the name and type is signature paraphrase; drop the tag.

```
WRONG:   // CopyManifest copies src to dst. It opens src for reading,
         // creates dst with the same mode, and streams the bytes.
CORRECT: // CopyManifest copies src to dst.
```

A narrated-body doc comment compresses to the one identifier-prefixed contract line.
