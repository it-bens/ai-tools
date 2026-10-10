# PHP: PHPUnit

The substrate for PHP testing; other PHP frameworks execute on top of it.

**Written against PHPUnit 13.x.** PHPUnit ships one major per year, each removing APIs that the previous major hard-deprecated, so version-gated rules matter here more than in most stacks. Check the constraint in the project's `composer.json` before applying one. The load-bearing transition: attributes were introduced alongside doc-comment annotations in 10, annotations were deprecated in 11, and **annotations were removed in 12** — `@dataProvider`, `@test`, and the rest no longer work at all on 12 and later.

## Table idiom

The `#[DataProvider('providerName')]` attribute (`PHPUnit\Framework\Attributes\DataProvider`). The provider method is `public static` and returns an iterable of argument arrays; string keys name the cases and become their identity in failure output.

```php
public static function quoteProvider(): array
{
    return [
        'priority next-day' => ['priority', 1250],
        'economy ground' => ['economy', 480],
    ];
}

#[DataProvider('quoteProvider')]
public function testQuotesShipmentBySpeed(string $speed, int $expectedCents): void
{
    self::assertSame($expectedCents, $this->calculator->quote(Parcel::withWeight(5), $speed)->totalCents());
}
```

By convention the provider sits below the test method that uses it, with a mirrored name.

## Error-path idiom

`expectException()` is declared **before** the act, so the shape is arrange → expect → act rather than arrange → act → assert. Pin the load-bearing message fragment with `expectExceptionMessage()` (substring match) or `expectExceptionMessageMatches()` (regex) — never the full generated string.

```php
public function testRejectsEmptyWaypoints(): void
{
    $this->expectException(InvalidRouteException::class);
    $this->expectExceptionMessage('at least one waypoint');

    Route::fromWaypoints([]);
}
```

Because the expectation precedes the act, put nothing after the act in the body — a statement after a throwing call never executes.

## Independence: hard constraints

- **Data providers run before `setUpBeforeClass()` and before the first `setUp()`, and cannot access properties of the test-case instance.** Provider rows must be built from literals and static construction only; a provider that reaches for fixture state set up in `setUp()` is broken by construction, not merely fragile.
- **Tests run sequentially in one process by default.** PHPUnit has no built-in parallelism; a project gets it by adding ParaTest and invoking that runner. Do not assume parallel isolation exists, and do not assume it does not — check the project's test command.
- **`backupGlobals` and `backupStaticProperties` are off by default.** Nothing restores globals or static properties between tests unless the project explicitly enables the backup options in its XML configuration or on the command line. Restore what you mutate.
- **`tearDown()` restores every process-wide change**: capture the previous value in `setUp()` and restore it (`putenv($key . '=' . $previous)`), reset error handlers (`restore_error_handler()`), and reassign mutated `static` properties. `tearDownAfterClass()` covers class-level setup.
- **`static` properties on a test class leak** across test methods unless bounded to a single method or reset in `tearDown()`.
- **Committed fixture files are read-only at test time** — a test that rewrites a fixture on disk poisons every later test that parses it.
- **Do not reach for process isolation to paper over leakage.** Running a test in a separate process hides the leak instead of fixing it; it is a last resort for code that genuinely cannot be cleaned up.

## Test doubles

`createStub()` for a collaborator that only needs to return canned values (no interaction assertions); `createMock()` only when verifying communication is genuinely the behavior under test. Asserting that a double was called is a change-detector: prefer a stub plus an assertion on the observable result. On PHPUnit 13, the unconstrained `any()` matcher is hard-deprecated — express the real expectation (`once()`, `exactly()`) or drop to a stub.

Version-gated API removals worth knowing when reading older tests: `setMethods()` was removed in 10 (split into `onlyMethods()` and `addMethods()`), `getMockBuilder()` and `addMethods()` are deprecated from 11 onward, mocking abstract classes and traits directly was removed in 12, and `assertRegExp()` gave way to `assertMatchesRegularExpression()`.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time()`, `microtime()`, `new \DateTimeImmutable()` without a fixed argument | asserted, or encoded into an asserted value |
| `mt_rand()`, `random_int()`, `random_bytes()` unseeded | feeding an assertion |
| `uniqid()` | asserted by value |
| `getmypid()`, `gethostname()` | asserted |

Skip: `new \DateTimeImmutable('2024-01-01')` fixed values; a seeded generator; a clock value passed through opaquely and never asserted.
