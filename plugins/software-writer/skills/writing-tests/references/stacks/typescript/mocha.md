# TypeScript: Mocha (with Chai)

A test runner that ships neither assertions nor test doubles: Mocha structures and executes, Chai (or another assertion library) asserts, and Sinon (or equivalent) supplies spies, stubs, and fake timers. Every rule below that mentions an assertion assumes Chai's `expect` interface; adapt the call, not the rule, if the project uses a different library.

**Pin the majors.** Mocha and Chai ship breaking majors on an irregular cadence — historically near-annual, more recently multi-year gaps — and Chai's move to ESM-only in a recent major breaks CommonJS suites outright. Check both constraints in `package.json` before applying a version-gated rule.

## Test shape

`describe` groups a surface; `it` names the behavior as a sentence. Arrow functions are conventional, but a test that needs Mocha's context object (`this.timeout(...)`, `this.retries(...)`) must use a `function` expression — an arrow function has no such binding.

```typescript
describe('quoteShipment', () => {
  it('prices priority shipping at the next-day rate', () => {
    expect(quoteShipment(defaultCatalog, 'priority').totalCents).to.equal(1250);
  });
});
```

## Table idiom

Mocha has **no built-in parametrized-test helper**. Loop over the cases and call `it()` once per case, so each reports independently:

```typescript
for (const { speed, expectedCents } of [
  { speed: 'priority', expectedCents: 1250 },
  { speed: 'economy', expectedCents: 480 },
]) {
  it(`prices ${speed} shipping at ${expectedCents} cents`, () => {
    expect(quoteShipment(defaultCatalog, speed).totalCents).to.equal(expectedCents);
  });
}
```

Generate the cases at module scope, not inside a test body: Mocha collects tests before running them, so an `it()` registered inside another test's callback never runs.

## Error-path idiom

Chai's `.throw()` takes an error constructor, a message substring, or a regex: `expect(() => Route.fromWaypoints([])).to.throw(InvalidRouteError, 'at least one waypoint')`. Note that the subject must be a *function*, not a call — `expect(Route.fromWaypoints([]))` throws during argument evaluation and the assertion never runs.

Chai has no native rejection matcher. For an async rejection, either await the call inside a try/catch and assert on the caught error, or use a promise-assertion plugin if the project already depends on one:

```typescript
it('rejects a manifest with no parcels', async () => {
  try {
    await loadManifest(emptyPath);
    expect.fail('expected loadManifest to reject');
  } catch (error) {
    expect(error).to.be.instanceOf(EmptyManifestError);
  }
});
```

The explicit `expect.fail` is mandatory: without it, a call that unexpectedly resolves passes the test silently.

## Independence: hard constraints

- **Parallel mode is opt-in** (`--parallel`), and it changes the execution model rather than just its speed: files are distributed across worker processes, each worker running its files sequentially.
- **Root hooks do not propagate across files in parallel mode.** Each file gets its own Mocha instance, so a root-level `beforeEach` defined in one file does not run for others — shared setup must move into a root-hook plugin.
- **`.only` is prohibited in parallel mode**, `--bail` becomes best-effort, and file ordering options are unsupported, so a suite that depends on file order breaks the moment parallelism is enabled.
- **Nothing is reset between tests.** Mocha has no mock, spy, or timer state of its own, so every double the test installs must be restored in `afterEach` — with Sinon, a per-test sandbox restored in `afterEach` is the reliable shape, since a forgotten manual restore leaks a stub into every later test in the process.
- Variables declared in a `describe` body are shared by that block's tests: assign them in `beforeEach` rather than at declaration.
- Arrow-function test bodies cannot reach Mocha's context; a test needing a longer timeout must be a `function` expression.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `Date.now()`, `new Date()` without arguments | asserted, or encoded into an asserted value |
| `Math.random()` | any use in tests |
| `crypto.randomUUID()` | asserted by value |
| Performance timers | asserted |

Skip: fixed date constants; an injected clock returning a constant; a fake-timer clock installed and uninstalled within the same test.
