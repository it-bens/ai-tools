# `node:test`: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `node --test` with no arguments selects test-source files by name pattern (`*.test.*`, `*-test.*`, `*_test.*`, `test-*.*`, `test.*`) and test-source files under a `test/` directory.
