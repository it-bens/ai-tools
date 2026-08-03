# Code Comments and Doc Comments

## Consistency comes first

Check every comment against the code beside it before classifying it. A comment that contradicts the code is worse than no comment: readers trust it and derive a wrong model from it. Correct the comment, or the code when the comment documents the intent and the code drifted away from it. Never leave a standing contradiction on a line you are already editing, and never resolve one by deleting the comment — the comment may be the only record of what the code was supposed to do.

What counts: a described return that the signature contradicts, an inverted condition, a name the comment no longer matches, an exception the code no longer raises, a documented validation the code only logs, a "temporary" workaround whose trigger is long gone.

What does not: a synonym (`fetch` for `get`), a comment pitched one abstraction above the code, or a comment carrying context the code cannot. All three are accurate.

## Classification table

Classify every comment proposed, kept, or edited into exactly one bucket and apply its action.

| Bucket | Action |
|---|---|
| **Contradicts the code** (describes behavior the code does not have) | Correct it; never delete it to resolve the mismatch |
| **Legal** (license header, copyright notice, SPDX identifier, attribution) | Never touch |
| **Commented-out code** | Delete — version control already holds it |
| **Redundant with docs** (restates what a documentation surface owns) | Cut to the local why plus a stable identifier |
| **Explains-what** (paraphrases the identifier or the code below) | Remove — except the regex case below |
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

Content that is load-bearing by construction, however plainly it is worded: a citation of an external spec, RFC, standard, or ticket; an algorithm choice with its complexity or its trade-off against the obvious alternative; a security or compliance constraint; a thread-safety or lock-ordering requirement; a workaround naming the upstream bug and the condition for removing it; a design decision that forecloses an approach a later reader would otherwise try. Removing any of these discards information the code cannot carry, so a comment that looks obvious but carries one of them stays.

## The negative-invariant shape

The second load-bearing shape justifies why an obvious-looking guard is deliberately omitted, so the next editor does not "fix" the missing guard and break correctness:

```python
# Only single quotes need doubling here: the engine accepts double-quoted
# identifiers, so escaping double quotes as well would corrupt quoted names.
def escape_literal(text: str) -> str:
    return text.replace("'", "''")
```

Without the comment, the missing double-quote escape reads as an oversight; with it, the omission is a documented decision.

Every construct that reads as a mistake and is not belongs to this shape, and the comment is what separates the two: an intentional switch fall-through, a deliberately empty catch block, a discarded return value kept for its side effect, a statement not folded into the one below it. Write the comment when producing such a construct, and keep it when editing around one — several linters and style guides only suppress their diagnostic because the comment is there.

## The explains-what exception: regular expressions

A non-trivial pattern is the one place where describing *what* the code matches beats describing why. Reading the pattern back out of the syntax costs minutes; the comment costs seconds.

```python
# Matches E.164 phone numbers: +[country][subscriber], 7-15 digits total.
# Valid: +14155552671, +442071234567
phone_pattern = r'^\+[1-9]\d{1,14}$'
```

Apply it when the pattern runs past roughly 20 characters, uses lookaround, backreferences, or named groups, or implements a named standard — and give one or two matching examples. A short, self-evident pattern gets nothing.

## Tightening an over-specified why

Keep the reasoning, cut the restatement. What goes: sentences that rephrase the point already made, exhaustive enumerations of cases that all get identical handling, implications that follow directly from the main clause, and filler (`in order to` → `to`, `for the purpose of` → `to`, drop `this ensures that ... regardless of ...` entirely).

```
WRONG:   // Normalize the path to match stored URL patterns. Routes are persisted
         // with a leading slash and no trailing slash. This normalization ensures
         // consistent matching regardless of how the client formats the path.
CORRECT: // Normalize the path to match stored URL patterns (leading slash, no trailing).
```

Do not tighten past the point where a fact disappears. An enumeration whose entries each need different handling, a constraint carrying a specific threshold or rule identifier, and a workaround's removal criterion all survive at full length. Preserve the project's own vocabulary while tightening: `domain.terms` names terms that must not be swapped for a near-synonym, because a term that reads as a synonym often is not one.

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

Visibility decides which tier applies, not the syntax used. Structured tags on an exported or protected declaration are a contract — for a protected one, the contract is with subclasses, so it states what to override and what stays guaranteed. The same tags on a private declaration have no external consumer: treat that comment as an implementation comment and hold it to the rules above, which usually means deleting it. A private helper whose body is one self-describing expression needs no comment at all.

Prefer making the types say it over commenting it: a discriminated union instead of a comment listing valid combinations; an immutable/readonly field instead of "do not mutate"; a unit-suffixed identifier (`timeoutSeconds`) instead of a parameter comment explaining the unit. The comment is the fallback for what the type system cannot reach — which is also the test for a precondition, postcondition, or invariant: document it when it binds the caller and no type enforces it, drop it otherwise.

## Markers

A `TODO` or `FIXME` without an owner and a tracking reference is indistinguishable from an abandoned one, and it is never actionable by the person who finds it. Write markers with both, plus enough specificity to act on; `todo.ticket_format` names the shape the project requires.

```
WRONG:   // TODO: fix this
CORRECT: // TODO(sarah): reject amounts over the BR-2019 ceiling — JIRA-456
```

A deprecation notice is a migration instruction. It names the replacement, the version or date of removal, and how to get from one to the other. A bare `@deprecated` with no replacement tells a caller only that they have a problem.

## Banned patterns

```
WRONG:   // See README §Atomic staging
         stage_file(...)
CORRECT: stage_file(...)
```

A comment whose entire content is a pointer carries no local why, and the heading it cites rots the moment anyone renames it. What survives is a stable identifier attached to a why that reads on its own: `// Queue-dispatched so a downstream outage cannot block checkout — ADR-0007.` This is also how a comment that restates a documentation surface gets cut — down to the local why plus the identifier, never expanded to duplicate what the surface owns. Docs point at code; a code comment earns a doc reference only by carrying its own reason first.

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

```
WRONG:   // def old_implementation():
         //     return legacy_behavior()
CORRECT: (delete — the history is in version control)
```

Commented-out code leaves every later reader guessing whether it is coming back. The one exception is a deliberate, short-lived disable that says so and names its owner: `// TODO(sam): re-enable before merge — validateInput(data);`
