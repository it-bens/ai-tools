# Python: pytest

**Written against pytest 9.1.x.** pytest ships behavior changes in minor releases, not only majors, so check the version pinned in the project's dependency manifest before applying a version-gated rule below. Two changes make pytest 8-era material actively wrong: since 9.0, removal-warnings are errors by default rather than warnings, and since 9.1, fixture-override resolution follows visibility in the collection tree rather than registration order.

## Table idiom

`@pytest.mark.parametrize`, with `pytest.param(..., id="...")` when a case deserves a descriptive id (a regression marker, a semantic label). Manual `for` loops over cases in a test body are the smell — parametrize reports each case as its own test.

```python
@pytest.mark.parametrize(("weight", "expected_cents"), [
    (1, 480),
    (5, 1250),
    pytest.param(30, 4100, id="heaviest_accepted_boundary"),
])
def test_quote_by_weight(weight, expected_cents):
    assert quote_shipment(default_catalog, parcel(weight=weight)).total_cents == expected_cents
```

`argvalues` must be a concrete collection — a list or tuple. Generators, iterators, and other one-shot iterables are deprecated: they are exhausted after the first collection, so tests silently skip on a re-run.

Stack `@pytest.mark.parametrize` decorators only when the full cartesian product is wanted; otherwise build the case list explicitly.

For cases whose values are not known at collection time, the built-in `subtests` fixture is the alternative to parametrize. Prefer parametrize whenever the values are known statically — it reports each case as a separate test and supports selection by id.

## Error-path idiom

`with pytest.raises(ExcType, match="fragment")` — the block is the act. `match` is applied with `re.search`, so it matches anywhere in the exception's string representation; it pins the load-bearing fragment, never the full generated message. Regex metacharacters in the fragment must be escaped (or passed through `re.escape`).

```python
def test_route_rejects_empty_waypoints():
    with pytest.raises(ValueError, match="at least one waypoint"):
        Route(waypoints=[])
```

Bind the context manager (`as excinfo`) only when the test asserts on the exception object itself, through `excinfo.value`.

## Independence: hard constraints

- **`monkeypatch` for any process-wide change** — `setattr`, `setenv` / `delenv`, `setitem`, `syspath_prepend`, `chdir`. Every modification is undone when the requesting test or fixture finishes; direct mutation of `os.environ` or `sys.path` leaks to later tests. `with monkeypatch.context() as m:` scopes a patch to a block inside the test.
- **Fixture scope is per-test (`function`) by default — keep it there for anything mutable.** The wider scopes are `class`, `module`, `package`, and `session`.
- **Under `pytest-xdist`, `session` scope is per worker process, not per run.** Each worker collects and runs its own subset, so a session-scoped fixture executes once per worker. Sharing mutable state through it is unsafe and misleading; a genuinely run-once setup needs an explicit cross-process lock, and a per-worker resource needs the `worker_id` fixture. xdist distributes by test (`--dist load`) unless the project selects `loadfile`, `loadscope`, or `loadgroup`.
- **A fixture above `function` scope documents the invariant that justifies it** (read-only, idempotent, teardown-only) in its docstring, so a later editor does not add a mutation.
- **Module-level mutable state in test files leaks** within a worker and diverges across workers.
- **`unittest.mock.patch` started without a matching stop leaks** — use the context-manager or decorator form, or `monkeypatch.setattr`.
- Class-scoped fixtures defined as plain instance methods are deprecated: they set attributes on a different instance than the test methods use.
- Docstrings on tests: cut those that paraphrase the test name; keep only a docstring that documents a why (regression context, a load-bearing assumption).

## CLI rendering

Output captured from a Click or Typer `CliRunner` is rendered text. Typer renders help and errors through Rich and forces color when CI environment variables (`GITHUB_ACTIONS`, `FORCE_COLOR`, `PY_COLORS`) are set; style resets can split long-option tokens (`--flag`), so a substring assertion passes locally and fails in CI. Run every output assertion through `click.unstyle()` first; `invoke(color=False)` and `NO_COLOR` do not prevent the token splitting.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time.time()`, `datetime.now()`, `time.perf_counter()` | asserted, or encoded into an asserted value |
| `random.*` unseeded, `secrets.token_*` | feeding an assertion |
| `uuid.uuid4()` | asserted by value |
| `socket.gethostname()`, `os.getpid()` | asserted |

Skip: `datetime(2024, 1, 1, tzinfo=timezone.utc)` fixed values; `random.Random(seed)` with a fixed seed; a wall-clock value passed through opaquely and never asserted.

## Property-based complement

Hypothesis is a library layered on the runner, not a competing framework: `@given(...)` decorates a test that pytest still executes. Properties complement example tests — the examples encode the specification's anchor values, the properties encode the invariants. Pin regressions found by a property with its explicit-example mechanism rather than relying on a replayed seed.
