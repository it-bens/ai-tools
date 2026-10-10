# stdlib `testing`: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `TestMain`, `Example*`, `Benchmark*`, and `Fuzz*` functions are run by `go test` by naming convention; an `Example` function's name encodes the identifier it documents (`ExampleFoo_bar`).
