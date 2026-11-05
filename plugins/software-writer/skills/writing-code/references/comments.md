# Code Comments and Doc Comments

## Classification table

| Bucket | Action |
|---|---|
| **Legal** (license header, copyright notice, SPDX identifier, attribution) | Never touch |
| **Commented-out code** | Delete |
| **Redundant with docs** (restates what a documentation surface owns, or another symbol's doc comment) | Cut to the local why plus a stable identifier; for a restated doc comment, the identifier is a reference to that symbol |
| **Explains-what** (paraphrases the identifier or the code below) | Remove, except the regex case below |
| **Tutorial / novice-facing** (narrates the language, the standard library, or control flow) | Remove or compress sharply |
| **Over-specified why** (five lines where one would do) | Tighten, down to the floor below |
| **Load-bearing why** (names the failure mode the code guards against, or carries content from the list below) | **Keep verbatim**; write a new why-comment to name the failure mode, give a concrete instance, and state what the code does to prevent it |
| **Public doc comment** (the API contract on an exported symbol) | Keep, under the doc-comment rules of Step 6 and the contract below |

## Load-bearing by construction

A comment carrying any of these is load-bearing however plainly it is worded: a citation of an external spec, RFC, standard, or ticket; an algorithm choice with its complexity or its trade-off against the obvious alternative; a security or compliance constraint; a thread-safety or lock-ordering requirement; a workaround naming the upstream bug and the condition for removing it; a design decision that forecloses an approach a later reader would otherwise try.

## The negative-invariant shape

A construct that reads as a mistake and is not carries a comment saying why it is deliberate; on a deliberately empty catch block, the comment names which failures it swallows and why discarding each is safe. Write the comment when producing such a construct, and keep it when editing around one.

## The explains-what exception: regular expressions

A regular expression longer than roughly 20 characters, or one using lookaround, backreferences, or named groups, or implementing a named standard, gets a comment stating what it matches with one or two matching examples. A short, self-evident pattern gets nothing.

## Tightening floor

Tighten by cutting sentences that rephrase the point already made, enumerations of cases that all get identical handling, implications that follow from the main clause, and filler. Do not tighten past the point where a fact disappears: an enumeration whose entries each need different handling, a constraint carrying a specific threshold or rule identifier, and a workaround's removal criterion survive at full length.

## Doc-comment contract

A doc comment states the contract a caller cannot infer from the signature: raise/throw behavior, side effects, ordering constraints, preconditions, what absence of an optional value means. It never narrates the body. On a protected declaration the contract is with subclasses: it states what to override and what stays guaranteed. Document a precondition, postcondition, or invariant when it binds the caller and no type enforces it; drop it otherwise.

## Stable identifiers

A comment that refers elsewhere carries its own why first, then a stable identifier: a symbol name, an ADR or ticket number, never a line number or a document heading. A comment whose entire content is a pointer is deleted.
