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
- **Read findings:** the output is a stream of JSON objects, one per problem. Entries of check U1000 are the dead-code findings; diagnostics of category `compile` and `config` are not evidence.

### deadcode

- **Run:** `deadcode -json ./...` for programs.
- **Never pass:** no flags listed.
- **Read findings:** read stdout. Every function it lists is a dead-code finding, unreachable from `main` and `init` of the `main` packages.
