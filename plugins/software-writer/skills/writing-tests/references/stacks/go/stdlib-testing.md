# Go: stdlib `testing`

The baseline a Go suite sits on when it uses `go test` directly. testify's reference file adds to this one rather than replacing it; Ginkgo brings its own runner and spec shape and stands alone.

**Language-version constraints.** The rules below assume Go 1.22 or later for loop-variable semantics, Go 1.24 or later for `t.Context`, Go 1.25 or later for a generally available `testing/synctest`, and Go 1.26 or later for `errors.AsType`. Check the `go` directive in `go.mod` before applying a version-gated rule; where the project's directive is lower, the older behavior applies and is called out inline.

## Table idiom

Struct slices driven through `t.Run` subtests. Subtests are the idiomatic completion of a table: they give per-case filtering (`go test -run TestQuote/priority`) and per-case parallelism.

```go
func TestQuoteShipment(t *testing.T) {
    cases := []struct {
        name  string
        speed string
        want  int
    }{
        {"priority next-day", "priority", 1250},
        {"economy ground", "economy", 480},
    }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            got := QuoteShipment(defaultCatalog, tc.speed)
            if got.TotalCents != tc.want {
                t.Errorf("TotalCents = %d, want %d", got.TotalCents, tc.want)
            }
        })
    }
}
```

A bare `for` loop asserting in its body without `t.Run` swallows case identity in failure output — always wrap the case in a subtest.

Loop variables are per-iteration in modules declaring `go 1.22` or later, so a subtest closure capturing `tc` is safe. In a module on an older `go` directive the loop variable is shared: add an explicit `tc := tc` shadow inside the loop, or the parallel subtests all observe the final case.

## Error-path idiom

Match sentinel errors with `errors.Is`, and extract typed errors with `errors.As` — never compare error strings. `errors.Is` and `errors.As` both walk the wrap chain, including multi-error `Unwrap() []error` trees. On Go 1.26 and later, `errors.AsType[E](err)` is the generic form and is preferred over `errors.As` for new code.

```go
_, err := ParseManifest(input)
if !errors.Is(err, ErrMalformedManifest) {
    t.Fatalf("err = %v, want ErrMalformedManifest", err)
}
```

The `wantErr` table carve-out is the bounded dispatch shape, and applies only when the success path's assertions are identical across cases:

```go
for _, tc := range cases {
    t.Run(tc.name, func(t *testing.T) {
        _, err := ParseManifest([]byte(tc.input))
        if tc.wantErr {
            if err == nil {
                t.Fatal("expected an error, got nil")
            }
            return
        }
        if err != nil {
            t.Fatalf("unexpected error: %v", err)
        }
    })
}
```

## Independence: hard constraints

- **Nothing runs in parallel unless it asks to.** Within one test binary, top-level tests run sequentially; only tests calling `t.Parallel()` run concurrently, bounded by `-parallel` (default `GOMAXPROCS`). Across packages, `go test ./...` runs different package binaries concurrently by default, so package-level external state (a shared port, a fixed temp path, a real database) races even when no test calls `t.Parallel()`.
- **`t.Parallel()` must be called from the test's own goroutine**, not from a spawned one.
- **`t.Cleanup` restores every global mutation**, running last-added-first. Register the restore immediately after the mutation. `t.Run` blocks until parallel subtests finish, so a parent's cleanup registered before spawning them still runs after they complete.
- **`t.Setenv` cannot be combined with parallelism.** It changes process-wide state, so calling it in a parallel test — or in any test with a parallel ancestor — fails the test. A test that needs both an environment override and parallelism must take the value through an injected seam instead.
- **`t.TempDir` per test** for filesystem state: created fresh, removed when the test and all its subtests complete.
- **Package-level `var`s in test files leak** across test functions, and values initialized in `TestMain` must not be mutated by tests.
- **Subtest closure capture**: an outer variable that one subtest mutates and another reads breaks under `-run` selection of a single subtest.
- Check the suite with `go test -shuffle=on` (randomizes execution order and reports the seed) and with `-run` against a single test.

## Determinism and time

`t.Context()` (Go 1.24+) returns a context canceled just before cleanup functions run — use it instead of hand-rolled cancellation in tests.

For code that sleeps, times out, or coordinates goroutines, `testing/synctest` (generally available in Go 1.25+ as `synctest.Test` plus `synctest.Wait`; experimental in 1.24 behind `GOEXPERIMENT=synctest` with a different API) runs the bubble on a fake clock, so a test can exercise timeouts without wall-clock waiting. Prefer it over sleeping in tests on projects whose `go` directive allows it.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time.Now()`, `time.Since(...)` | asserted, or encoded into an asserted value |
| `math/rand` unseeded, `crypto/rand` | feeding an assertion |
| `uuid.New()` and similar generators | asserted by value |
| `os.Hostname()`, `os.Getpid()` | asserted |

Skip: `time.Date(2024, 1, 1, ...)` fixed values; a deterministically seeded generator; `time.Now()` written into a fixture field the test never asserts on.
