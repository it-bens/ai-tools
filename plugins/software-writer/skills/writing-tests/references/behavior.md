# Behavior Under Test

## Behavior, not implementation, trivial, or internal

Tests verify observable behavior of the public API.

### Do test

- Return values and raised/returned errors
- Observable state changes (files written, records persisted, events emitted, streams closed)
- Computed or derived values (ordering, deduplication, formatting, aggregation)
- Validation logic — the explicit rejection paths a caller can trigger

### Do NOT test

- Calls into dependencies. The return value or observable effect already proves the call happened.
- Private/internal helpers via a dedicated test when the public API covers the behavior.
- Internal call order or algorithmic decomposition.
- Logic-free constructors and value-object round-trips. Test a constructor when it validates or transforms input.
- Accessors that return a field directly; test when the accessor computes a derived value.
- Setters that only assign; test when the setter validates or has side effects.
- Trivial type or enum assertions; test the behavior the type drives instead.
- Pure delegation: a wrapper that forwards to a dependency without transforming input or output. Test when the wrapper transforms or branches.

### Carve-outs

- **Validating constructors.** A constructor that rejects bad input or normalizes its arguments has behavior; test the rejection and the normalization.
- **Error-path tests where the expectation is the act.** An expect-raises block wrapping the call *is* the act phase of an error-path test, not a structural violation.
- **Drift-guard registry-parity tests.** A test that iterates two registries and asserts index-alignment or set-equality is a valid behavior test of the registry contract. Assert through the public registry surface, not internal state.

## Seam patterns when the behavior is not observable

| Pattern | Production-code shape | Test usage |
|---|---|---|
| Writer / output parameter | The function takes an output stream or writer parameter instead of writing to the process's stdout; the live caller wires the real stream. | The test passes an in-memory buffer and asserts on its contents. |
| Constructor-field injection | Ambient dependencies (clock, environment reader, process lister) enter as constructor parameters or fields; the composition site supplies the live implementations. | The test constructs the unit with fakes: a fixed clock, a canned environment. |
| Exported pure helper | Inline logic is extracted into a public pure function that the production caller and the test both invoke. | The test exercises the helper directly without staging the surrounding pipeline. |
| Swappable function indirection | A module-level function variable or attribute that production calls through (a deletion function, a clock function). | The test swaps the function and restores it in the framework's teardown or cleanup hook. |

## Single behavior per test

Each test exercises exactly one behavior; several assertions that are aspects of one behavior stay together. Split a test that shows any of these signs:

- The name contains "and"
- Comment banners split the body into phases (`# create`, `# update`, `# delete`)
- Multiple unrelated assertions follow distinct act steps

## Preservation check

Before consolidating a case as redundant, scan for preservation indicators. If one is present, keep the case.

| Indicator | Pattern |
|---|---|
| Regression marker in the name or id | `regression`, `bug`, `issue`, `#\d+` |
| Issue-tracker reference | `GH-`, `PR-`, a commit SHA |
| Comment at the site | "regression for #123", "prevents the ..." |
| Table-row or case id key | a case id citing a ticket or incident |

## Guard-clause isolation

When a test targets one early-return in a function with multiple sequential guards, the arrange satisfies every guard above the targeted one so the tested guard is the only possible exit.

1. Read the public function the test exercises.
2. Enumerate its sequential guard clauses.
3. If the function has 2+ guards and the test targets one, verify the arrange satisfies all guards above it.
4. If another guard would short-circuit with the current arrange, fix the arrange.

Does not apply when: the function has one guard; the test explicitly covers the all-preconditions-absent path; the guards produce distinguishable outcomes that the assertion discriminates.
