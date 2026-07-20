# Python: `unittest` (stdlib)

The standard library's xUnit framework. Apply this file when the project's suite is built on `unittest.TestCase` — typically stdlib-only packages, or an existing suite that predates pytest. For a new suite with a free choice of runner, pytest is the mainstream default; do not port an existing `unittest` suite as a side effect of an unrelated change.

**Version constraint: Python 3.12 removed the long-deprecated `TestCase` method aliases** — `assertEquals`, `assertNotEquals`, `assertAlmostEquals`, `assertNotAlmostEquals`, `assertRegexpMatches`, `assertRaisesRegexp`, `assertNotRegexpMatches`, `failUnless`, `failIf`, and the rest of the `failUnless*` / `failIf*` family, plus `assert_`. Use the canonical names (`assertEqual`, `assertRegex`, `assertRaisesRegex`, `assertTrue`). Check the project's minimum Python version before applying a version-gated rule; `unittest` tracks the CPython release cycle rather than shipping its own.

## Table idiom

`subTest` is the parametrized form: each iteration reports independently, so one failing case does not stop the rest, and the failure output names the parameters that produced it.

```python
class QuoteTest(unittest.TestCase):
    def test_quote_by_weight(self):
        for weight, expected_cents in [(1, 480), (5, 1250), (30, 4100)]:
            with self.subTest(weight=weight):
                quote = quote_shipment(default_catalog, parcel(weight=weight))
                self.assertEqual(expected_cents, quote.total_cents)
```

Pass the varying values as keyword arguments to `subTest` — they become the case's identity in failure output. A bare loop without `subTest` stops at the first failure and hides which case broke.

## Error-path idiom

`assertRaises` as a context manager is the act; bind it only when the test asserts on the exception object. `assertRaisesRegex` matches the message with a regex — pin the load-bearing fragment, never the full generated string.

```python
class LedgerTest(unittest.TestCase):
    def setUp(self):
        self.ledger = Ledger()

    def test_route_rejects_empty_waypoints(self):
        with self.assertRaisesRegex(ValueError, "at least one waypoint"):
            Route(waypoints=[])

    def test_dispatch_reports_the_offending_parcel(self):
        with self.assertRaises(UnknownParcelError) as caught:
            self.ledger.dispatch("box-1")
        self.assertEqual("box-1", caught.exception.parcel_id)
```

## Independence: hard constraints

- **`addCleanup` over `tearDown` for anything set up conditionally.** Cleanups run after `tearDown` in last-in-first-out order, and — unlike `tearDown` — they still run when `setUp` itself raised partway through. Register each cleanup immediately after the acquisition it undoes.
- **`enterContext` registers a context manager's exit as a cleanup**, which is the concise form for patchers, temp directories, and open handles.
- **`addClassCleanup` pairs with `setUpClass`**; class-level setup is shared state by construction, so keep it read-only.
- **Class attributes and module-level state leak** across test methods: one method's mutation is visible to every method that runs after it, and the default execution order is alphabetical by method name, not declaration order.
- **`unittest.mock.patch` must be scoped** — the decorator or context-manager form, or `addCleanup(patcher.stop)` immediately after `patcher.start()`. A `start()` without a matching `stop()` leaks into every later test in the process.
- **The default runner executes tests sequentially in one process**, so parallelism is not the default hazard here; ordering and leaked global state are. Verify independence by running a single test in isolation (`python -m unittest module.Class.test_name`).

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time.time()`, `datetime.now()`, `time.perf_counter()` | asserted, or encoded into an asserted value |
| `random.*` unseeded, `secrets.token_*` | feeding an assertion |
| `uuid.uuid4()` | asserted by value |
| `socket.gethostname()`, `os.getpid()` | asserted |

Skip: fixed date constants; a seeded generator; a wall-clock value passed through opaquely and never asserted.

## Doctest complement

`doctest` verifies that interactive examples in docstrings still produce what they claim. It is a documentation-drift guard, not a test framework: fold it into the suite through `doctest.DocTestSuite()` rather than treating a docstring example as coverage for a behavior.
