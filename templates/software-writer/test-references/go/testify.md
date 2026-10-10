# testify: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `SetupSuite`, `SetupTest`, `TearDownTest`, `SetupSubTest`, and `Test*` methods are run by `suite.Run` with no call naming them.
