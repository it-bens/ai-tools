# Test Shape

## AAA structure

Tests with 5+ statements separate arrange, act, and assert phases. Assertions live after the final act, not interspersed.

Skip: tests under 5 statements; table-driven or parametrized case bodies of 2-3 statements; error-path tests — an expect-raises block wrapping the act is a two-phase shape (arrange → expect + act), which is fine.

## No conditional logic in tests

Test bodies do not contain conditional logic that picks between assertions.

Prohibited: `if`/`else` selecting which assertion runs; `switch`/`match` dispatching on expectations; loops with per-iteration branching on expectations; ternaries for assertion control flow.

Not violations:

| Pattern | Why |
|---|---|
| An expect-raises / expect-error construct for error paths | Idiomatic dispatch for error-vs-success. Bounded, single shape. |
| The loop that drives table-driven cases | Each case must report as its own test: a loop that registers one test per case satisfies this, a loop that asserts inside a single test body does not. Use the table construct the framework reference names. |
| A platform or environment skip at the top of the test | Environment gate, not assertion logic. |
| A precondition check that aborts the test before the act | Not an author-written conditional on expectations. |

The error-vs-success carve-out applies **only** when the success path's assertions are identical across cases. If cases need different positive assertions, split into two tables or two tests.

## One outcome per assertion

Each assertion verifies a single expected outcome. Flagged:

- Boolean OR over outputs. Assert the message the code actually emits.
- Membership in a set of "acceptable" values when exactly one is correct for the scenario.
- A range assertion where the specification fixes a value.
- A regex loose enough to match wrong output where a specific string is expected.
- Checking only the first entry of a call log (a stub's recorded invocations). Assert every logged call.

A range that is itself the specified invariant is the exception.

## Refusal assertions

Pin a refusal by its error identity, by its type plus its message, or by a message pattern; a bare type is enough only when no test double can produce that type.

## Asserting on CLI output

Assert in this order and stop at the first level that captures the behavior under test:

1. **Exit code.**
2. **The effect** — a file written, a record persisted. Assert the effect itself, not the log line announcing it.
3. **A fragment of the text** — the load-bearing token, never the whole rendered block.

A refusal does not stop at the exit code when a test double can fail with the same status: assert the guard's own message or error identity as well (see Refusal assertions).

When the command emits machine-readable output (JSON, NDJSON), parse it and assert on the parsed value, never substring-match the serialized string. For an event stream, split on newlines and assert per parsed record.

Strip ANSI styling before any substring or structural assertion on rendered CLI text, with the CLI framework's unstyle or strip helper where one exists.
