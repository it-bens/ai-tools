---
name: writing-code
version: 2.4.0
description: Use when writing or editing implementation code — any change that adds, modifies, or removes logic, signatures, or comments on the lines being written. Also covers reviewing, cleaning up, or improving the comments on code being edited. Do NOT activate for test files and their fixtures (the writing-tests skill owns those).
---

# Writing Code

## Workflow

The workflow below can be extended by content earlier in context. Two shapes are recognized:

1. **Pre-Step / Post-Step instructions.** Before executing Step N, check whether earlier context contains a section headed `## Pre-Step-N`. If it does, execute its content as additional instructions, then continue with Step N. After Step N, do the same check for `## Post-Step-N`.
2. **Named-value assignments.** The skill body cites certain configuration values by backticked name alongside an inline default (for example `` `code.di_pattern` ``). When such a name appears, check whether earlier context assigns a value to it. If yes, use the assigned value; otherwise use the inline default.

Both checks default to no-op. When earlier context contains no matching section or assignment, the skill runs entirely on the defaults documented inline. Extension content may cite project files by path; read a cited file when the step that cites it runs, not before.

```dot
digraph writing_code {
    "Start" [shape=doublecircle];
    "Step 1: Detect stack" [shape=box];
    "Adding a new package dependency?" [shape=diamond];
    "External call in scope?" [shape=diamond];
    "100% certain of signature and semantics?" [shape=diamond];
    "Step 2: Confirm the API call" [shape=box];
    "Step 3: Write the line" [shape=box];
    "New dependency, new export, removed call or reference, replaced implementation, or changed signature?" [shape=diamond];
    "Step 4: Confirm dependencies and surface scope" [shape=box];
    "Step 5: Footgun check" [shape=box];
    "Comment or doc comment written, edited, or kept on the lines being written or edited?" [shape=diamond];
    "Step 6: Comment matches `comments.preserve_patterns` and existed before the edit?" [shape=diamond];
    "Check the comment against the code" [shape=box];
    "Run each claim the comment makes about the language, interpreter, or tool in an isolated probe" [shape=box];
    "Report each claim that could not be run here as unverified" [shape=box];
    "Comment contradicts the code, or a run refutes a claim?" [shape=diamond];
    "Correct the comment or the code, or the refuted part of the claim" [shape=box];
    "Load references/comments.md, classify the comment, and apply the bucket's action; report a corrected comment the action deletes" [shape=box];
    "More to write or edit?" [shape=diamond];
    "Done" [shape=doublecircle];

    "Start" -> "Step 1: Detect stack" -> "Adding a new package dependency?";
    "Adding a new package dependency?" -> "Step 2: Confirm the API call" [label="yes — the existence gate never skips"];
    "Adding a new package dependency?" -> "External call in scope?" [label="no"];
    "External call in scope?" -> "100% certain of signature and semantics?" [label="yes"];
    "External call in scope?" -> "Step 3: Write the line" [label="no"];
    "100% certain of signature and semantics?" -> "Step 3: Write the line" [label="yes"];
    "100% certain of signature and semantics?" -> "Step 2: Confirm the API call" [label="no"];
    "Step 2: Confirm the API call" -> "Step 3: Write the line";
    "Step 3: Write the line" -> "New dependency, new export, removed call or reference, replaced implementation, or changed signature?";
    "New dependency, new export, removed call or reference, replaced implementation, or changed signature?" -> "Step 4: Confirm dependencies and surface scope" [label="yes"];
    "New dependency, new export, removed call or reference, replaced implementation, or changed signature?" -> "Step 5: Footgun check" [label="no"];
    "Step 4: Confirm dependencies and surface scope" -> "Step 5: Footgun check";
    "Step 5: Footgun check" -> "Comment or doc comment written, edited, or kept on the lines being written or edited?";
    "Comment or doc comment written, edited, or kept on the lines being written or edited?" -> "Step 6: Comment matches `comments.preserve_patterns` and existed before the edit?" [label="yes"];
    "Comment or doc comment written, edited, or kept on the lines being written or edited?" -> "More to write or edit?" [label="no"];
    "Step 6: Comment matches `comments.preserve_patterns` and existed before the edit?" -> "More to write or edit?" [label="yes"];
    "Step 6: Comment matches `comments.preserve_patterns` and existed before the edit?" -> "Check the comment against the code" [label="no"];
    "Check the comment against the code" -> "Run each claim the comment makes about the language, interpreter, or tool in an isolated probe";
    "Run each claim the comment makes about the language, interpreter, or tool in an isolated probe" -> "Report each claim that could not be run here as unverified";
    "Report each claim that could not be run here as unverified" -> "Comment contradicts the code, or a run refutes a claim?";
    "Comment contradicts the code, or a run refutes a claim?" -> "Correct the comment or the code, or the refuted part of the claim" [label="yes"];
    "Comment contradicts the code, or a run refutes a claim?" -> "Load references/comments.md, classify the comment, and apply the bucket's action; report a corrected comment the action deletes" [label="no"];
    "Correct the comment or the code, or the refuted part of the claim" -> "Load references/comments.md, classify the comment, and apply the bucket's action; report a corrected comment the action deletes";
    "Load references/comments.md, classify the comment, and apply the bucket's action; report a corrected comment the action deletes" -> "More to write or edit?";
    "More to write or edit?" -> "Adding a new package dependency?" [label="yes"];
    "More to write or edit?" -> "Done" [label="no"];
}
```

### Step 1: Detect stack

Detect the stack from the file(s) being edited: file extension plus project signals such as `go.mod`, `pyproject.toml`, `tsconfig.json`, or `composer.json`. `project.stacks` overrides detection; default if not otherwise stated: detect from the files and project signals.

A shell file is the `bash` stack on the file alone, ahead of every project signal: extension `.sh`, `.bash`, or `.bats`, or an extensionless file whose shebang names `sh` or `bash`.

Load `references/stacks/<stack>.md` for the detected stack (`bash`, `go`, `python`, `typescript`, `php`) — only the matching one. For a stack without a reference file, apply the universal rules plus any project content earlier in context.

### Step 2: Confirm the API call

Before writing or editing a call to any non-builtin symbol, ask: am I 100% certain of this symbol's signature, error and async behavior, and edge-case semantics, or am I pattern-matching from training? If not certain, consult the documentation source the stack reference lists for the question, with the query form it gives.

Skip consultation when the call mechanically repeats an idiom already established in the same file, or when the call already compiles or runs with a passing test exercising it.

**New-dependency gate.** Before adding any new package or module dependency, verify the package exists and the name is exact — against the lockfile, the package registry, or vendored sources. Never add a dependency from memory alone: signature certainty skips consultation for existing symbols, never this existence check.

**In-repo primitives.** When the call touches a domain the project wraps — the rows come from `code.primitives`; default if not otherwise stated: none registered — consult the wrapper before reaching for the raw primitive. Load `references/primitives.md` for the table shape, the decision test, and the missing-wrapper rule.

### Step 3: Write the line

Before writing logic, search for an existing helper that does it and call it. Write the call or edit the line.

**No silent fallback.** Refuse an unrecognized or invalid input with a message before any fallback runs. Logging and then falling back is allowed only where the fallback is the documented behavior. A documented default for an absent optional value is not such a fallback. When an edit makes a function fail where it used to return a value, every place on each call path that swallows or replaces the new failure falls under this paragraph's rule. When one fallback covers both a documented failure and the new one, the new failure gets its own status or error type, and the fallback stays for the documented failure only. Report a fallback on a published surface (Step 4) to the user instead of changing it.

**Validate before the first side effect.** In entry points and functions with side effects, validate every argument before the first bootstrap, write, spawn, or network call. For streaming or incremental input, validate each unit before acting on it.

**Single definition.** Do not add a second copy of a function or a third copy of a block of 3+ lines; copies a project keeps in sync deliberately (generated, or synced by a manifest) are exempt. Parametrize bodies that differ only by a literal. In the lines the edit touches, delete dead guards (a guard no supported version, platform, or input reaches), dead assignments, and wrappers that only forward to another function, except a wrapper registered as a primitive (Step 2) and a symbol on a published surface (Step 4); the orphaned-symbol rule in Step 4 covers the symbols those deletions leave unreferenced.

### Step 4: Confirm dependencies and surface scope

**Dependency entry shape.** When the line introduces a new dependency — a callable, an external service, configuration, a time source, a randomness source, an output stream — it enters via parameter, option, or constructor field; wiring concrete implementations together happens at the composition root, not deep in the call tree. `code.di_pattern` names the project's concrete pattern; default if not otherwise stated: parameter or constructor injection.

**Caller scope.** Every new exported/public symbol needs at least one non-test caller within the same coordinated unit of work — the smallest closed change that ships together. Delete a symbol whose only callers are tests, keep it module-local, or hold the export until the caller is part of the same coordinated change. `code.export_conventions` adds project rules such as a package-index re-export surface; default if not otherwise stated: none.

**Orphaned symbols.** Caller scope runs in reverse when the edit removes a call or reference, replaces an implementation, or changes a signature. Every symbol that lost a reference — the replaced function, its helpers, imports, parameters, types, constants, configuration keys, files — keeps at least one non-test reference, or it is deleted in this edit together with the tests whose only subject it was; deleting such a test stays in this skill, while editing a surviving test belongs to `writing-tests`. Search the plain name, the forms listed in `references/stacks/<stack>-indirect-references.md`, and non-code files (configuration, manifests, templates, CI). Repeat the search for whatever a deletion orphans until a pass deletes nothing. A replaced implementation is deleted in the same change; keep it only when the user asked for it. A symbol on a published surface — a library's public API, a documented CLI flag or route — is reported to the user, not deleted. `code.dead_code_check` names a project command that reports unused code; default if not otherwise stated: none. When it is set, run it after the search and handle its findings in the edited scope the same way.

### Step 5: Footgun check

Scan the line just written against the footguns the project registers in `code.footgun_additions`; default if not otherwise stated: none. With none registered, this step passes without a check.

### Step 6: Check and classify each comment

Where existing code or comments diverge from a rule in this skill, the rule wins: fix the divergence, do not copy it.

Comments split into two tiers, and visibility decides which one applies rather than the syntax used: structured docs on an exported or protected declaration are a contract, the same tags on a private declaration are an implementation comment.

**API/doc comments** follow the doc-comment convention the stack reference names. Compress a doc comment that purely paraphrases the signature to one identifier-prefixed line. Never delete doc comments where project lint requires them; `code.comment_enforcement` names such rules; default if not otherwise stated: none.

**Implementation comments** default to none. Write or keep one only when it carries a point-of-use why the reader cannot infer from the code and types. When deleting code, delete its why-comment too.

Skip a comment that matches a marker or pattern in `comments.preserve_patterns` and existed before the edit: no consistency check, no probe, no classification, no edit; default if not otherwise stated: none. A comment the edit writes goes through this step like any other. Check each remaining comment written, edited, or kept on the lines being written or edited against the code first: a comment that contradicts what the code does is corrected, never left standing and never deleted to resolve the mismatch. Run any claim such a comment makes about the language, the interpreter, or a tool in an isolated probe, never by running the code under edit. A run counts only on the version or platform the claim names; a claim about a version or platform not available here cannot be run here. A claim a run refutes is corrected, limited to the part the run refutes. A claim that cannot be run here stays unchanged and is listed in the report to the user as unverified. Then load `references/comments.md`, classify the comment against its table, and apply the bucket's action. When that action deletes a comment this step corrected, name the deletion and its bucket in the report to the user.

Hold every `TODO`/`FIXME` written or touched to `todo.ticket_format`; default if not otherwise stated: an owner plus a tracking reference. Never swap a term listed in `domain.terms` for a near-synonym while rewriting a comment; default if not otherwise stated: none registered. When `docs.surfaces` is assigned, a comment restating what a listed surface owns is cut to its local why plus a stable identifier instead of duplicating the surface; default if not otherwise stated: comments are judged on their own merits.
