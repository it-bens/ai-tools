# TypeScript: Jest

**Written against Jest 30.x.** Jest's major cadence is irregular — several majors landed in consecutive years, then a multi-year gap before 30 — so a suite may sit far from the current major. Check the constraint in `package.json` before applying a version-gated rule, and check the project's Jest config before relying on any reset behavior (next section).

## Test shape

`describe` groups a surface; `it` or `test` names the behavior as a sentence.

```typescript
it('prices priority shipping at the next-day rate', () => {
  expect(quoteShipment(defaultCatalog, 'priority').totalCents).toBe(1250);
});
```

## Table idiom

`test.each` / `describe.each`, in either the array form or the tagged-template form. Each row reports as its own test; the row's name is its identity in failure output.

```typescript
test.each([
  ['priority', 1250],
  ['economy', 480],
])('quotes %s shipping at %d cents', (speed, expectedCents) => {
  expect(quoteShipment(defaultCatalog, speed).totalCents).toBe(expectedCents);
});

test.each`
  speed         | expectedCents
  ${'priority'} | ${1250}
  ${'economy'}  | ${480}
`('quotes $speed shipping at $expectedCents cents', ({ speed, expectedCents }) => {
  expect(quoteShipment(defaultCatalog, speed).totalCents).toBe(expectedCents);
});
```

The tagged-template form is worth its extra syntax when the columns need names; otherwise the array form is shorter. Manual `for` loops over cases hide which case failed.

## Error-path idiom

Synchronous: `expect(() => Route.fromWaypoints([])).toThrow(InvalidRouteError)`. Asynchronous: `await expect(loadManifest(path)).rejects.toThrow(ManifestError)` — always awaited. Match the error class or the load-bearing message fragment, never the full generated string.

For an async test that must reach the thrown error itself, assert the expected assertion count (`expect.assertions(n)`) so a call that unexpectedly resolves fails instead of passing silently.

## Independence: hard constraints

- **Mock state never resets itself.** `clearMocks`, `resetMocks`, and `restoreMocks` all default off, and the three differ: clearing removes call history, resetting additionally removes the mock implementation, restoring returns a spied method to its original implementation. Restore explicitly with `jest.restoreAllMocks()` in `afterEach`, or enable the flags project-wide — and check `jest.config.*` or the `jest` key in `package.json` before assuming which, since a project that enabled them changes what a test can rely on.
- **Files are isolated; tests within a file are not.** Jest parallelizes across test *files*, distributing them over a pool of child processes (`maxWorkers` defaults to one less than the machine's core count), and each file gets its own module registry. Within a file, tests share that registry and all mock state unless the project enables `resetModules` or the reset flags above.
- **Fake timers persist until switched back.** Pair `jest.useFakeTimers()` with `jest.useRealTimers()`, or the frozen clock leaks into later tests in the file. Prefer an injected clock for domain code.
- **`jest.mock` is hoisted above imports** — its factory cannot reference file-scope variables declared after it. Variables the factory needs must be defined in a way that survives hoisting (a `jest.mock` factory referencing a `const` declared below it fails at runtime).
- **Prefer injection seams over module mocking.** Reach for `jest.mock` / `jest.spyOn` only when injection cannot reach the dependency — and spy-and-assert-called is not a test.
- **Module-level mutable state is shared by every test in the file**, in declaration order. Create per-test state inside `beforeEach` or a factory call, not at module scope.
- A shared store or fake database created in a `describe` body accumulates state across that block's tests.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `Date.now()`, `new Date()` without arguments | asserted, or encoded into an asserted value |
| `Math.random()` | any use in tests |
| `crypto.randomUUID()` | asserted by value |
| Performance timers | asserted |

Skip: fixed date constants; an injected clock returning a constant; generated identifiers asserted for shape or presence rather than value.
