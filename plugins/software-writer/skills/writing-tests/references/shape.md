# Test Shape

## AAA structure

Tests with 5+ statements separate arrange, act, and assert phases. Assertions live after the final act, not interspersed.

Skip: tests under 5 statements; table-driven or parametrized case bodies of 2-3 statements; error-path tests — an expect-raises block wrapping the act is a two-phase shape (arrange → expect + act), which is fine.

```python
# WRONG: assertions scattered through the body
def test_quote_for_priority_shipping(tmp_path):
    catalog = load_catalog(tmp_path / "rates.json")
    assert catalog is not None                 # trivial mid-arrange assertion
    quote = quote_shipment(catalog, parcel(weight=5), speed="priority")
    assert quote.total > 0                     # weak mid-act assertion
    assert quote.currency == "EUR"

# CORRECT: arrange, act, assert
def test_quote_for_priority_shipping(tmp_path):
    catalog = load_catalog(tmp_path / "rates.json")

    quote = quote_shipment(catalog, parcel(weight=5), speed="priority")

    assert quote.total == 1250
    assert quote.currency == "EUR"
```

Comment banners are optional; blank lines between phases are enough. When a fixture helper carries the wiring, the arrange shrinks below the threshold and banners drop out entirely.

## No conditional logic in tests

Test bodies do not contain conditional logic that picks between assertions.

Prohibited: `if`/`else` selecting which assertion runs; `switch`/`match` dispatching on expectations; loops with per-iteration branching on expectations; ternaries for assertion control flow.

Not violations:

| Pattern | Why |
|---|---|
| An expect-raises / expect-error construct for error paths | Idiomatic dispatch for error-vs-success. Bounded, single shape. |
| The loop that drives table-driven cases | The loop drives cases, not assertion branching. Each case must report as its own test: a loop that registers one test per case satisfies this, a loop that asserts inside a single test body does not. Where the framework offers a parametrized construct, use it; where it offers none, the registering loop is the idiom. |
| A platform or environment skip at the top of the test | Environment gate, not assertion logic. |
| A precondition check that aborts the test before the act | Not an author-written conditional on expectations. |

The error-vs-success carve-out applies **only** when the success path's assertions are identical across cases. If cases need different positive assertions, split into two tables or two tests.

```python
# WRONG: the branch picks between two different positive assertions
@pytest.mark.parametrize(("speed", "is_express", "expected_days"), [
    ("priority", True, 1),
    ("economy", False, None),
])
def test_delivery_estimate(speed, is_express, expected_days):
    estimate = estimate_delivery(parcel(), speed)
    if is_express:
        assert estimate.days == expected_days
    else:
        assert estimate.days >= 3

# CORRECT: two tables, two tests — the expectation is data, not control flow
@pytest.mark.parametrize(("speed", "expected_days"), [("priority", 1), ("express", 2)])
def test_express_speeds_promise_exact_days(speed, expected_days):
    assert estimate_delivery(parcel(), speed).days == expected_days

def test_economy_promises_a_minimum_window():
    assert estimate_delivery(parcel(), "economy").days >= 3
```

## Assertion scope

Multiple assertions in a test body are acceptable only when they verify a single logical behavior. Unrelated claims in one body are Assertion Roulette: when the test fails, the reader cannot tell which behavior broke.

Acceptable clusters: multiple properties of one returned object; before/after state of one operation; related aspects of one behavior.

Not acceptable: create + persist + format + log in one test; asserting the primary effect and an unrelated subsystem's output together.

## Assertion strength

Assert the behavior, not an implementation snapshot. An assertion that fails when unrelated code changes — while the behavior under test still holds — is brittle and trains the next author to update the number without reading the test.

Brittle, replace with a behavioral check:

- Exact size of a volatile collection (`assert len(all_rules()) == 92` breaks on the next added rule). Assert a lower bound plus known members.
- Exact length or full value of a generated identifier. Assert the shape.
- Exact match on a generated or rendered message. Match the load-bearing fragment.
- Snapshotting a whole result object — breaks on any added field. Assert the fields the behavior is about.

Exact values that are part of a specification are not brittle — keep them: exit codes, status codes, spec-anchored numbers, fixture-driven counts (a one-violation fixture yielding exactly one finding is a specification, not brittleness).

## One outcome per assertion

Each assertion verifies a single expected outcome. An assertion that accepts several outputs cannot distinguish a correct result from a wrong one, so it passes even when the behavior is broken.

Flagged:

- Boolean OR over outputs: `assert "cached" in out or "Using cache" in out`. Assert the message the code actually emits.
- Membership in a set of "acceptable" values when exactly one is correct for the scenario.
- A range assertion where the specification fixes a value.
- A regex loose enough to match wrong output where a specific string is expected.

Genuine ranges are the exception: an invariant assertion like `0 <= score <= 100` is the behavior itself, not looseness.

## Asserting on CLI output

A command's behavior is its exit code and its effects, not the bytes it renders. Assert in this order and stop at the first level that captures the behavior under test:

1. **Exit code** — a real contract, not rendering.
2. **The effect** — a file written, a record persisted. Assert the effect itself, not the log line announcing it.
3. **A fragment of the text** — the load-bearing token, never the whole rendered block. Rendered text is the most volatile subject: whitespace, wrapping, color, and wording shift with no behavioral change.

When the command emits machine-readable output (JSON, NDJSON), parse it and assert on the parsed value — field presence, type, or value at a path — never substring-match the serialized string. For an event stream, split on newlines and assert per parsed record.

```python
# WRONG: substring-matches serialized JSON — breaks on key order, spacing, or an added field
assert '"status": "delivered"' in result.output

# CORRECT: parse, then assert on structure
payload = json.loads(result.output)
assert payload["parcels"][0]["status"] == "delivered"
```

Strip ANSI styling before any substring or structural assertion on rendered CLI text — CLI frameworks colorize output under CI environment variables, and style resets can split a matched token so the assertion passes locally and fails only in the pipeline. Use the CLI framework's unstyle/strip helper (the framework reference names it where one exists).

## Naming and ordering

### Business-language names

Name after what the code does, not how.

```python
# WRONG
def test_regex_matches_priority_flag(): ...
def test_process_returns_list(): ...

# CORRECT
def test_priority_parcels_load_before_standard(): ...
def test_manifest_rejects_duplicate_parcel_ids(): ...
```

### Order: happy → variation → config → edge → error

Within a file, order tests and table cases happy → variation → config → edge → error. Soft convention; reorder only when adding new tests, not as a cleanup pass.

| Category | Indicators |
|---|---|
| Happy | Positive verb, no edge/error language in the name |
| Variation | `with`, `using`, `for` modifiers |
| Config | `mode`, `option`, `flag`, `setting` |
| Edge | `empty`, `null`, `zero`, `max`, `min`, `boundary` |
| Error | `rejects`, `fails`, `invalid`, `raises`, `throws` |

### Execution time

A unit test that takes seconds is a signal, not a feature. Check for unintended network or subprocess calls, oversized fixtures, real timers, or unbounded iteration.
