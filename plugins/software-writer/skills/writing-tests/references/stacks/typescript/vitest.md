# TypeScript: Vitest

**Written against Vitest 4.x, with the 5.x change noted where it lands.** Vitest ships a breaking major every six to nine months and has changed execution defaults across them — the worker pool default moved from threads to forks in 2.x, so material written for 1.x states the wrong model. Check the constraint in `package.json` before applying a version-gated rule.

## Test shape

`describe` groups a surface; `it` or `test` names the behavior as a sentence. Fixtures come from `test.extend`, which initializes lazily — setup runs only for tests that destructure the fixture, which makes it a better default than an unconditional `beforeEach`.

```typescript
it('prices priority shipping at the next-day rate', () => {
  expect(quoteShipment(defaultCatalog, 'priority').totalCents).toBe(1250);
});
```

## Table idiom

`it.each` / `test.each`. Each row reports as its own test, and the printf-style name is the row's identity in failure output.

```typescript
it.each([
  ['priority', 1250],
  ['economy', 480],
])('quotes %s shipping at %d cents', (speed, expectedCents) => {
  expect(quoteShipment(defaultCatalog, speed).totalCents).toBe(expectedCents);
});
```

Manual `for` loops over cases hide which case failed — use `it.each`.

## Error-path idiom

Synchronous: `expect(() => Route.fromWaypoints([])).toThrow('at least one waypoint')`. Asynchronous: `await expect(loadManifest(path)).rejects.toThrow(ManifestError)` — always awaited. Match the load-bearing message fragment or the error class, never the full generated string.

## Independence: hard constraints

- **Files are isolated; tests within a file are not.** Test files run in parallel, each in an isolated environment (`isolate` and `fileParallelism` both default on, with a forked-process pool). Within a file, tests run sequentially and Vitest carries state between them: module-level mutable state, a shared in-memory fake, an installed fake timer, and mock implementations all persist test to test.
- **Mock state never resets itself.** On Vitest 4.x, `clearMocks`, `mockReset`, `restoreMocks`, `unstubGlobals`, and `unstubEnvs` all default off, so call history, mock implementations, stubbed globals, and stubbed environment variables all survive into the next test in the file. Restore explicitly with `vi.restoreAllMocks()` / `vi.unstubAllGlobals()` in `afterEach`, or enable the corresponding config flags project-wide. (Vitest 5 flips `clearMocks` on by default, which clears recorded history only — implementations still persist, so the explicit restore stays correct either way.)
- **`vi.setSystemTime` persists until `vi.useRealTimers()`** — pair them, or the frozen clock leaks into every later test in the file. For domain code, prefer an injected `now` function over fake timers; reserve fake timers for third-party code with no injection point.
- **`vi.mock` is hoisted above all imports** — its factory cannot reference file-scope variables; use `vi.hoisted` for values the factory needs. The "cannot access before initialization" error is this footgun.
- **Prefer injection seams over module mocking**: a factory that takes its dependencies, an injected repository, an injected clock. Reach for `vi.mock` / `vi.spyOn` only when injection cannot reach the dependency — and spy-and-assert-called is not a test.
- **Opting into concurrency within a file removes the sequential guarantee.** `describe.concurrent` and `it.concurrent` run their tests simultaneously in the same environment, so any shared mock or module state they touch races. Concurrent tests must use the `expect` bound to their own test context.
- A shared store or fake database created in a `describe` body accumulates state across tests; create it fresh per test via a factory call or a `test.extend` fixture.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `Date.now()`, `new Date()` without arguments | asserted, or encoded into an asserted value |
| `Math.random()` | any use in tests |
| `crypto.randomUUID()` | asserted by value |
| Performance timers | asserted |

Skip: fixed date constants; an injected clock returning a constant; generated identifiers asserted for shape or presence rather than value.
