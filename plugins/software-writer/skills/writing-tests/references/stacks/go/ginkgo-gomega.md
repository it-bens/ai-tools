# Go: Ginkgo and Gomega

A genuinely separate structural framework: Ginkgo supplies a BDD container/spec DSL and its own CLI runner, Gomega supplies the matchers. Unlike testify, it replaces the table-driven `go test` shape rather than layering on it. Apply this file instead of the stdlib table idiom when a project's suites are written in Ginkgo, and keep the universal rules (single behavior, arrange sourcing, independence, redundancy) unchanged.

Written against Ginkgo v2 (import path ends in `/ginkgo/v2`). Ginkgo v1 predates the v2 DSL and needs migration, not adaptation: v1 content will not run under v2.

## Spec shape

Containers (`Describe`, `Context`, `When`) group; `It` is the spec. The spec description is the behavior sentence — the same single-behavior rule applies, so a description containing "and" means two specs.

```go
var _ = Describe("ShipmentQuote", func() {
    It("prices priority shipping at the next-day rate", func() {
        quote := QuoteShipment(defaultCatalog, "priority")
        Expect(quote.TotalCents).To(Equal(1250))
    })
})
```

The suite is bootstrapped once per package by a single `TestXxx(t *testing.T)` entry point calling `RunSpecs`.

## Table idiom

`DescribeTable` plus `Entry` is Ginkgo's parametrized form; each `Entry` reports as its own spec, so entry descriptions carry case identity the way subtest names do.

```go
DescribeTable("shipment pricing",
    func(speed string, wantCents int) {
        Expect(QuoteShipment(defaultCatalog, speed).TotalCents).To(Equal(wantCents))
    },
    Entry("priority next-day", "priority", 1250),
    Entry("economy ground", "economy", 480),
)
```

## Error-path idiom

`Expect(err).To(MatchError(target))` — `MatchError` accepts a sentinel error value (compared through the wrap chain), a string, or a nested matcher. `Expect(err).To(HaveOccurred())` is the unspecific form, acceptable only when "it rejects" is the whole behavior. `Expect(err).NotTo(HaveOccurred())` is the precondition form.

## Setup, cleanup, and ordering

`BeforeEach` / `AfterEach` run per spec; `DeferCleanup` registers teardown at the point of setup and is preferred over a matching `AfterEach` because the pair stays visible in one place. `BeforeAll` / `AfterAll` exist only inside an `Ordered` container.

`Ordered` containers make specs run in declaration order and let earlier specs leak state into later ones by design. That trades away independence: use it only where the ordering is genuinely part of the system under test, never as a workaround for a shared-state leak.

## Independence: hard constraints

- **Ginkgo's parallelism is not `t.Parallel()`.** The `ginkgo` CLI distributes specs across separate OS processes (`ginkgo -p`); stdlib parallel-execution advice does not transfer. Each process runs its own suite bootstrap, so anything built in a suite-level setup exists once per process, not once per run.
- **Randomization is built in.** Ginkgo randomizes container order by default and can randomize all specs; a suite that only passes in declaration order is broken, not lucky.
- Closure variables declared in a container body are shared across the specs in that container: assign them in `BeforeEach` rather than at declaration, or one spec's mutation reaches the next.

## Assertions and asynchrony

Gomega's `Eventually` and `Consistently` poll rather than sleep — use them for asynchronous behavior instead of a fixed wait, and always with an explicit timeout and polling interval. A fixed sleep in a spec is a flake waiting to happen.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `time.Now()`, `time.Since(...)` | asserted, or encoded into an asserted value |
| `math/rand` unseeded, `crypto/rand` | feeding an assertion |
| `uuid.New()` and similar generators | asserted by value |
| `os.Hostname()`, `os.Getpid()` | asserted |

Skip: `time.Date(2024, 1, 1, ...)` fixed values; a deterministically seeded generator; `time.Now()` written into a fixture field the spec never asserts on.
