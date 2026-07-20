# Test Independence

The independence question: would randomized order, running a single test alone, or parallel execution change the outcome? If yes, the test depends on state outside its body, and it will fail — or worse, pass — non-deterministically.

## Shared mutable state

Tests do not share mutable state across test functions, cases, or fixtures. Four leak vectors:

1. **Package/module-level mutable state** in a test file, written by one test and read by another. Each test owns its state; a fixture or factory produces it fresh.
2. **Closure or fixture capture across cases**, where an outer scope mutates a variable later cases read — the second case fails when run alone.
3. **Unrestored globals**: environment variables, working directory, default clients, module attributes, mocked functions, mocked system time. Every mutation of process-wide state is paired with restoration in the framework's cleanup mechanism.
4. **Wall clock or randomness feeding an assertion** (next section).

Do NOT flag:

- Read-only values loaded once (a compiled regex, a parsed golden file, a shipped default configuration) that no test mutates.
- Values produced fresh per test by a helper or fixture.
- Lazily initialized immutable data behind a once-guard.

```python
# WRONG: the second test depends on the first
inventory = []

def test_register_adds_parcel():
    inventory.append(parcel("box-1"))
    assert len(inventory) == 1

def test_inventory_starts_empty():
    assert inventory == []          # fails whenever the other test ran first

# CORRECT: each test owns its state
def test_inventory_starts_empty():
    assert Inventory().count() == 0
```

## Restoration discipline

Prefer injection over global mutation: when a seam can reach the dependency (an injected clock, an injected environment reader), use the seam and skip the global entirely. When a global must be mutated, restore it through the framework's scoped mechanism — never by hand at the end of the test body, where an assertion failure skips the restore. The framework reference names the mechanism and its hard constraints.

## Non-deterministic inputs

Values that change each run do not feed into assertions. Non-determinism is acceptable only when the value is an opaque pass-through the test never asserts on.

### Flag

| Source | Context |
|---|---|
| Wall clock (now, elapsed time) | as an asserted value, or encoded into one |
| Unseeded random generators | any use that feeds an assertion |
| Generated UUIDs / unique ids | asserted by value |
| Hostname, process id | asserted |

### Skip

| Source | Context |
|---|---|
| Wall clock | only in fixture constructors whose value is never asserted |
| A fixed date constant | always fine |
| A seeded random generator | deterministic, repeatable |

```python
# WRONG: asserts against the real clock — flaky under load
def test_dispatch_stamps_time(ledger):
    entry = ledger.dispatch("box-1")
    assert abs(entry.dispatched_at.timestamp() - time.time()) < 5

# CORRECT: inject the clock, assert the exact value
def test_dispatch_stamps_the_injected_clock(ledger_with_fixed_clock):
    entry = ledger_with_fixed_clock.dispatch("box-1")
    assert entry.dispatched_at == datetime(2024, 1, 1, tzinfo=timezone.utc)
```

## Hermetic by default

A test depends on nothing outside its own body and its declared fixtures: no network, no shared external services, no shared databases, no reads from the developer's machine state. A test that needs an external resource either injects a fake at a production seam or belongs to an explicitly marked integration tier the project defines.

Shared external resources that must be touched (a container daemon, a device) are acquired and released within the test's own scope; a suite-level sweep that cleans up leaked resources is a safety net, not the isolation contract.

## Fixture scope

Give fixtures the smallest scope that satisfies the test. Larger scopes amortize setup cost but enable cross-test contamination — and under parallel runners, suite-wide scopes are often per-worker, which makes sharing through them both unsafe and misleading.

| Scope | When |
|---|---|
| Per-test (default) | Anything mutable: temp state, built objects, mocked state. The default for a reason. |
| Per-module / per-file | Read-only setup expensive enough to share, with no chance of mutation. |
| Per-session / per-worker | Read-only or teardown-only concerns (a cleanup sweep). |

A fixture above per-test scope documents the invariant that justifies the scope (read-only, idempotent, teardown-only) so a later editor does not add a mutation.
