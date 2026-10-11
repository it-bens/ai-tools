# Go: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Functions: `grep -rnE '^func ' --include='*.go'`. A receiver in parentheses makes the match a `method`.
- Single declarations: `grep -rnE '^(type|const|var) [A-Za-z_]' --include='*.go'`
- Grouped declarations (types, constants, variables): `find <scope> -name '*.go' -exec awk '/^(type|const|var) \($/{g=$1;next} g&&/^\)/{g="";next} g&&/^\t[A-Za-z_]/{print FILENAME":"FNR": "g" "$1}' {} +`

## Tools

### staticcheck (U1000)

- **Run:** `staticcheck -checks U1000 -f json ./...`
- **Never pass:** no flags listed.
- **Test handling:** tests are analyzed by default, so test-only use counts as use. Run again with `-tests=false` to find test-only code.
- **Read findings:** the output is one JSON object per problem, a stream, not an array. Diagnostics of category `compile` and `config` are still reported; ignore them as dead-code evidence. With default options, exported package-level identifiers, exported methods of used types, and exported struct fields count as used; U1000 reports unexported identifiers and what sits beneath an unused type. Read the stream, not the exit code: 1 when it reports problems from checks in `-fail` (default all), 2 on usage, config, or matrix errors, 0 when clean.
- **Limits:** a caller in a file excluded by the build configuration makes the callee look unused. Pass `-tags` for the project's tags, or `-matrix` with the build configurations on stdin — never both. Suppressions in the project: `//lint:ignore U1000 <reason>` directly above a declaration, `//lint:file-ignore U1000 <reason>` for the whole file.

### deadcode

- **Run:** `deadcode -json ./...` for programs. It reports functions unreachable from `main` and `init` of the `main` packages. Without a `main` package it fails with `no main packages`.
- **Never pass:** no flags listed.
- **Test handling:** with `-test`, test executables are roots and a finding means "unreachable from the tests", which is not the same as dead.
- **Read findings:** read stdout. It exits 0 even with findings, 1 on load errors and fatal conditions, 2 on usage. `-whylive=<pkgpath.Func>` explains why a function is live; the qualified name is required.
- **Limits:** it does not understand `//go:linkname` aliasing. Results hold for one GOOS/GOARCH/`-tags` configuration.
