# Go: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Go files command: `git ls-files -z -- <scope paths> <exclude pathspecs> | while IFS= read -r -d '' f; do [ -f "$f" ] && [ ! -L "$f" ] && case "$f" in *.go) printf '%s\0' "$f";; esac; done`. Replace `<exclude pathspecs>` with `':(exclude,glob)**/<entry>/**'` for each `sweep.exclude` entry that names a directory and `':(exclude,glob)**/<entry>'` for each entry that names a file pattern. The output is the NUL-separated list of tracked Go files, called the listed files below.
- Functions: `<Go files command> | xargs -0 grep -nHE '^func ' --`. A receiver in parentheses makes the match a `method`.
- Single declarations: `<Go files command> | xargs -0 grep -nHE '^(type|const|var) [A-Za-z_]' --`
- Grouped declarations (types, constants, variables): `<Go files command> | xargs -0 awk '/^(type|const|var) \($/{g=$1;next} g&&/^\)/{g="";next} g&&/^\t[A-Za-z_]/{print FILENAME":"FNR": "g" "$1}'`

## Tools

### staticcheck (U1000)

- **Run:** `staticcheck -checks U1000 -f json ./...`
- **Never pass:** no flags listed.
- **Read findings:** the output is a stream of JSON objects, one per problem. Entries of check U1000 are the dead-code findings; diagnostics of category `compile` and `config` are not evidence.

### deadcode

- **Run:** `deadcode -json ./...` for programs. Without a `main` package it fails with `no main packages`; skip it and say why.
- **Never pass:** no flags listed.
- **Read findings:** read stdout. Every function it lists is a dead-code finding, unreachable from `main` and `init` of the `main` packages.
