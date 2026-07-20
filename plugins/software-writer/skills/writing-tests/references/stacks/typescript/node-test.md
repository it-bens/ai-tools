# TypeScript: `node:test` (built-in runner)

Node's built-in test runner, stable since Node 20. No dependency to install; TypeScript files need whatever transpilation or type-stripping the project's Node version supports.

**Pin to a Node major.** The runner core is stable, but several sub-features remain lower-stability and change between releases — watch mode, module mocking, randomized execution order, coverage, and test tags among them. Check the project's Node engine constraint before relying on one of those.

## Test shape

```javascript
import test from 'node:test';
import assert from 'node:assert/strict';

test('prices priority shipping at the next-day rate', () => {
  assert.strictEqual(quoteShipment(defaultCatalog, 'priority').totalCents, 1250);
});
```

Nested `t.test()` calls create subtests; a parent test finishes only once its subtests settle, so return or await them.

## Table idiom

The runner has **no built-in parametrized-test helper**. The idiomatic form is a loop that calls `test()` (or a subtest) per case, so each case reports independently with the case in its name:

```javascript
for (const { speed, expectedCents } of [
  { speed: 'priority', expectedCents: 1250 },
  { speed: 'economy', expectedCents: 480 },
]) {
  test(`prices ${speed} shipping at ${expectedCents} cents`, () => {
    assert.strictEqual(quoteShipment(defaultCatalog, speed).totalCents, expectedCents);
  });
}
```

The loop must produce one `test()` per case. A single test asserting inside a loop collapses every case into one result and stops at the first failure.

## Error-path idiom

`node:assert`'s `assert.throws(fn, expected)` for synchronous throws, and `await assert.rejects(promiseOrAsyncFn, expected)` for rejections. The `expected` argument may be an error class, a regex against the message, or an object of properties to match — match the load-bearing fragment, never the full generated message.

```javascript
assert.throws(() => Route.fromWaypoints([]), { name: 'InvalidRouteError', message: /at least one waypoint/ });

await assert.rejects(loadManifest(missingPath), { code: 'ENOENT' });
```

Import from `node:assert/strict` so equality assertions are strict by default; the loose default of the plain `node:assert` entry point passes on type coercion.

## Independence: hard constraints

- **The CLI and the programmatic API have different concurrency defaults.** `node --test` runs test *files* in parallel, defaulting to one less than the machine's available parallelism. The programmatic `run()` API defaults to no concurrency, running files one at a time. A suite that passes under one can fail under the other — check how the project actually invokes the runner before reasoning about races.
- **Tests within a file run sequentially** unless a parent test is given an explicit concurrency option.
- **Context-scoped mocks restore themselves; the global mock object does not.** Mocks created through the test context (`t.mock`) are undone when that test finishes. Anything created through the module-level `mock` object persists until an explicit reset, so it leaks into later tests in the same file.
- Fake timers are scoped to the test context that installed them; install them per test rather than at file level.
- File-level mutable state is shared by every test in that file, in declaration order.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `Date.now()`, `new Date()` without arguments | asserted, or encoded into an asserted value |
| `Math.random()` | any use in tests |
| `crypto.randomUUID()` | asserted by value |
| `process.hrtime`, performance timers | asserted |

Skip: fixed date constants; an injected clock returning a constant; generated identifiers asserted for shape or presence rather than value.
