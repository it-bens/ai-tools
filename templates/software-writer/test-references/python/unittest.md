# `unittest`: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `setUp`, `tearDown`, `setUpClass`, `tearDownClass`, and `test*` methods are called by the runner by name convention.
- `mock.patch("pkg.module.Name")` names a production symbol by string; it is a test-only reference.
