# Ginkgo and Gomega: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `BeforeEach`, `AfterEach`, `JustBeforeEach`, and `It` closures are stored during tree construction and run by the runner; the suite starts from `RunSpecs` in an ordinary `Test*` function.
