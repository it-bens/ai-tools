# Go: testify

An assertion and mocking layer on top of stdlib `testing`, not a separate framework: there is no runner and no discovery mechanism, and every test is still `func TestX(t *testing.T)` executed by `go test`. Apply the stdlib `testing` reference for table shape, parallelism, and cleanup; this file covers only what testify adds.

No version pin needed: the v1 API has been stable for years and the maintainers have ruled out a breaking v2.

## `require` versus `assert`

- **`require.*` for preconditions and for anything the rest of the test depends on.** It calls `t.FailNow()`, so the test stops at the first failure instead of cascading into nil-dereference noise.
- **`assert.*` for behavioral claims after the act**, when collecting several independent failures in one run is useful. It returns a bool and lets the test continue.
- **Never call `require.*` from a goroutine other than the test's own.** It ends the test via `t.FailNow()`, which is only valid on the test goroutine — the same restriction as `t.Fatal`. Use `assert.*` there, or channel the result back to the test goroutine.

A `require.NoError(t, err)` before the act is a **precondition**, not a trivial assertion on the act's result.

## Table idiom

Identical to the stdlib shape — struct slice plus `t.Run` — with testify calls in the body:

```go
for _, tc := range cases {
    t.Run(tc.name, func(t *testing.T) {
        got := QuoteShipment(defaultCatalog, tc.speed)
        assert.Equal(t, tc.want, got.TotalCents)
    })
}
```

## Error-path idiom

`require.ErrorIs` and `require.ErrorAs` wrap `errors.Is` and `errors.As`, so they match anywhere in the error's wrap chain. Match sentinel errors and typed errors through them; never assert on the error's rendered string.

```go
_, err := ParseManifest(input)
require.ErrorIs(t, err, ErrMalformedManifest)

var pathErr *fs.PathError
require.ErrorAs(t, err, &pathErr)
```

`require.Error` alone is acceptable only when the test's behavior is "it rejects", with the specific error irrelevant to that behavior.

## Assertions that prove nothing

`assert.IsType` or `assert.Implements` against a function with a single concrete return type is trivially true under the type system. Delete it or replace it with a claim about the returned value.

## Mocks: the same rules apply

`testify/mock` and generated mocks make it easy to write change-detector tests. Asserting that a mock was called verifies the implementation, not the behavior — reach for a mock only at a genuine boundary, and assert on the observable result rather than on the interaction. When a project generates interface mocks, the maintained module is `go.uber.org/mock`; the older `golang/mock` is archived.

## Suites

`suite.Suite` offers xUnit-style `SetupTest` / `TearDownTest` / `SetupSuite` / `TearDownSuite` hooks as an alternative to `t.Cleanup`. It is a stylistic choice, not a capability: prefer plain functions plus `t.Cleanup` unless the project already standardizes on suites, since suite state is shared across the suite's methods and reintroduces the ordering coupling `t.Cleanup` avoids.
