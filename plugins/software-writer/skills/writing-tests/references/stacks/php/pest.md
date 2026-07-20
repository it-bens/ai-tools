# PHP: Pest

A closure-based test framework with its own CLI, configuration file (`Pest.php`), and plugin ecosystem, executing on PHPUnit underneath. Apply this file to files written in Pest's function style. Both styles can coexist in one suite, so a project running Pest may still hold `TestCase` classes — select the framework per file being edited rather than per project.

**Written against Pest 4.x.** Each Pest major raises the PHPUnit major it requires, so a Pest upgrade inherits PHPUnit's breaking changes on top of its own — when a rule here depends on the underlying PHPUnit behavior, check both constraints in `composer.json`.

## Test shape

`it()` and `test()` take a description and a closure. The description is the behavior sentence, so the single-behavior rule reads directly off it: a description containing "and" means two tests.

```php
it('prices priority shipping at the next-day rate', function () {
    expect(quoteShipment(defaultCatalog(), 'priority')->totalCents)->toBe(1250);
});
```

Expectations chain through `expect()`. Prefer a specific matcher (`toBe`, `toEqual`, `toHaveCount`) over a generic truthiness assertion — `expect($x)->toBeTrue()` on a comparison discards the actual and expected values from the failure output.

## Table idiom

Datasets bound with `->with()`. Keyed datasets name each case, and the name becomes the case's identity in failure output — prefer them over positional arrays whenever the values are not self-describing.

```php
it('prices shipping by speed', function (string $speed, int $expectedCents) {
    expect(quoteShipment(defaultCatalog(), $speed)->totalCents)->toBe($expectedCents);
})->with([
    'priority next-day' => ['priority', 1250],
    'economy ground' => ['economy', 480],
]);
```

Shared datasets belong in the project's dataset directory and are bound by name; inline arrays are for cases local to one test file.

## Error-path idiom

`->throws(ExceptionClass::class)` chained onto the test, optionally with a message fragment as the second argument, or `expect(fn () => ...)->toThrow(...)` when the throwing call is one expectation among several.

```php
it('rejects a route with no waypoints', function () {
    Route::fromWaypoints([]);
})->throws(InvalidRouteException::class, 'at least one waypoint');
```

## Independence: hard constraints

- **Parallel execution is built into the current Pest CLI** (`--parallel`), so treat every test as racing every other unless the project's test command says otherwise. Anything process-wide — environment variables, a shared database, a fixed temp path, a mutated singleton — must be per-test or acquired under a lock.
- **`beforeEach()` / `afterEach()` run per test in the file; `beforeAll()` / `afterAll()` run once per file.** `$this` is not available inside `beforeAll()` / `afterAll()`, so those hooks cannot build per-test instance state — anything a test mutates belongs in `beforeEach()`.
- **State assigned to `$this` in a closure is per test**, but state captured in a file-level variable or a static is shared across the file's tests and leaks in declaration order.
- The underlying PHPUnit constraints still apply: nothing restores globals or static properties between tests by default, and dataset callables are evaluated before any per-test setup, so a dataset cannot depend on state a hook creates.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time()`, `microtime()`, `new \DateTimeImmutable()` without a fixed argument | asserted, or encoded into an asserted value |
| `mt_rand()`, `random_int()`, `random_bytes()` unseeded | feeding an assertion |
| `uniqid()` | asserted by value |
| `getmypid()`, `gethostname()` | asserted |

Skip: fixed date constants; a seeded generator; a clock value passed through opaquely and never asserted.
