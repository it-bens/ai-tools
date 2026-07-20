# Behavior Under Test

## Behavior, not implementation, trivial, or internal

Tests verify observable behavior of the public API.

### Do test

- Return values and raised/returned errors
- Observable state changes (files written, records persisted, events emitted, streams closed)
- Computed or derived values (ordering, deduplication, formatting, aggregation)
- Validation logic — the explicit rejection paths a caller can trigger

### Do NOT test

- Calls into dependencies. The return value or observable effect already proves the call happened. A test that mocks a dependency to assert "the mock was called once" is a change-detector: it verifies the implementation, breaks on any refactor, and passes while the real integration is broken.
- Private/internal helpers via a dedicated test when the public API covers the behavior.
- Internal call order or algorithmic decomposition. "First it filters, then it sorts" is not a behavior; "the output is sorted by severity descending" is.
- Logic-free constructors and value-object round-trips (`thing = Thing(field=x); assert thing.field == x`). Test a constructor when it validates or transforms input.
- Accessors that return a field directly; test when the accessor computes a derived value.
- Setters that only assign; test when the setter validates or has side effects.
- Trivial type or enum assertions (`assert isinstance(result, Finding)`, `assert Status.ACTIVE.value == "active"`). The type system already guarantees these; test the behavior the type drives instead.
- Pure delegation: a wrapper that forwards to a dependency without transforming input or output. Test when the wrapper transforms or branches.

### Carve-outs

- **Validating constructors.** A constructor that rejects bad input or normalizes its arguments has behavior; test the rejection and the normalization.
- **Error-path tests where the expectation is the act.** An expect-raises block wrapping the call *is* the act phase of an error-path test, not a structural violation.
- **Drift-guard registry-parity tests.** A test that iterates two registries and asserts index-alignment or set-equality is a valid behavior test of the registry contract — the behavior is "registry A and registry B stay in sync as entries land". Assert through the public registry surface, not internal state.

### Worked examples

```python
# WRONG: value-object round-trip — proves only that assignment assigns
def test_shipment_stores_fields():
    shipment = Shipment(origin="warehouse-north", destination="pier-4")
    assert shipment.origin == "warehouse-north"
    assert shipment.destination == "pier-4"

# WRONG: pure delegation with a mock-was-called assertion
def test_dispatch_service_calls_repository(mocker):
    repo = mocker.Mock(return_value=[])
    DispatchService(repo).pending()
    repo.find_pending.assert_called_once()   # the return value already proves the call

# CORRECT: constructor with validation
def test_route_rejects_empty_waypoints():
    with pytest.raises(ValueError, match="at least one waypoint"):
        Route(waypoints=[])

# CORRECT: derived behavior on the public API
def test_manifest_orders_parcels_heaviest_first():
    manifest = Manifest([parcel(weight=2), parcel(weight=9), parcel(weight=5)])
    assert [p.weight for p in manifest.loading_order()] == [9, 5, 2]
```

## Seam patterns when the behavior is not observable

When the behavior is real but the current public API hides it, four production-code seams are legitimate paths to observability. Each survives in production for reasons unrelated to the test — a real injection point the production caller already wants. Choose the seam that matches what production wants; if none fits without contorting production code, the behavior is implementation detail: reframe or delete the test.

| Pattern | Production-code shape | Test usage |
|---|---|---|
| Writer / output parameter | The function takes an output stream or writer parameter instead of writing to the process's stdout; the live caller wires the real stream. | The test passes an in-memory buffer and asserts on its contents. |
| Constructor-field injection | Ambient dependencies (clock, environment reader, process lister) enter as constructor parameters or fields; the composition site supplies the live implementations. | The test constructs the unit with fakes: a fixed clock, a canned environment. |
| Exported pure helper | Inline logic is extracted into a public pure function that the production caller and the test both invoke. | The test exercises the helper directly without staging the surrounding pipeline. |
| Swappable function indirection | A module-level function variable or attribute that production calls through (a deletion function, a clock function). | The test swaps the function and restores it in cleanup — always paired with the framework's restore mechanism. |

Anti-pattern: introducing a seam no production caller needs, only to make a test pass. That is the internal-test smell dressed in dependency injection.

## Single behavior per test

Each test exercises exactly one behavior. Violation signs:

- The name contains "and"
- Comment banners split the body into phases (`# create`, `# update`, `# delete`)
- Multiple unrelated assertions follow distinct act steps — the Eager Test smell

```python
# WRONG: three behaviors in one test
def test_parcel_lifecycle(tmp_path):
    ledger = Ledger(tmp_path)
    ledger.register(parcel("box-1"))
    assert ledger.count() == 1            # registration
    ledger.dispatch("box-1")
    assert ledger.in_transit("box-1")     # dispatch
    ledger.deliver("box-1")
    assert ledger.history("box-1")        # delivery history
```

Split into one test per behavior — each test fails for exactly one reason. If several assertions are aspects of one behavior ("the finding correctly locates the violation"), keep them together; the single-behavior question is "what would force a split?", the assertion-scope question in `Step 4` is "given one behavior, how many assertions cover it?".

## Test redundancy

Every case (table row, parametrized case) and every top-level test covers a unique code path, boundary value, or regression. Key on why the case exists, not on what the input looks like.

A case earns its slot if at least one holds:

- **Unique code path**: it triggers a branch no other case triggers.
- **Boundary value**: it sits at the exact threshold where behavior changes.
- **Regression**: it prevents a specific bug from returning; the citation lives in its name, id, or a comment.

If none hold, merge the case into an existing test or delete it.

### Preservation check

Before consolidating a case as redundant, scan for preservation indicators:

| Indicator | Pattern |
|---|---|
| Regression marker in the name or id | `regression`, `bug`, `issue`, `#\d+` |
| Issue-tracker reference | `GH-`, `PR-`, a commit SHA |
| Comment at the site | "regression for #123", "prevents the ..." |
| Table-row or case id key | a case id citing a ticket or incident |

If present, keep the case and add an explanatory comment. If absent, consolidate.

```python
# WRONG: three cases exercise the same branch with different magnitudes
@pytest.mark.parametrize("weight", [100, 10, 2])
def test_overweight_parcel_is_rejected(weight): ...

# CORRECT: each case justifies itself by a distinct branch or boundary
@pytest.mark.parametrize(("weight", "accepted"), [
    (30, True),                                          # under the limit
    (31, False),                                         # first rejected value — the boundary
    pytest.param(0, False, id="zero_weight_regression_#87"),
])
def test_parcel_weight_limit(weight, accepted): ...
```

## Guard-clause isolation

When a test targets one early-return in a function with multiple sequential guards, the arrange must satisfy every guard above the targeted one so the tested guard is the only possible exit. Otherwise the test may pass because a different guard fired first; the outcome looks right and the test proves nothing.

1. Read the public function the test exercises.
2. Enumerate its sequential guard clauses.
3. If the function has 2+ guards and the test targets one, verify the arrange satisfies all guards above it.
4. If another guard would short-circuit with the current arrange, fix the arrange.

Does not apply when: the function has one guard; the test explicitly covers the all-preconditions-absent path; the guards produce distinguishable outcomes that the assertion discriminates.

```python
# Ledger.dispatch has guards:
#   g1: unknown parcel id        -> UnknownParcelError
#   g2: parcel already delivered -> AlreadyDeliveredError
#   g3: no carrier assigned      -> NoCarrierError

# WRONG: targets g3, but g1 fires first — the parcel was never registered
def test_dispatch_requires_carrier(ledger):
    with pytest.raises(NoCarrierError):
        ledger.dispatch("box-1")          # actually raises UnknownParcelError

# CORRECT: g1 and g2 satisfied; only g3 can fire
def test_dispatch_requires_carrier(ledger):
    ledger.register(parcel("box-1"))      # satisfies g1; not delivered, satisfies g2
    with pytest.raises(NoCarrierError):
        ledger.dispatch("box-1")
```
