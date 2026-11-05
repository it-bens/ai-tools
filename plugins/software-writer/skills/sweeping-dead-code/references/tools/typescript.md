# TypeScript: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- TypeScript files command: `git ls-files -z -- <scope paths> <exclude pathspecs> | while IFS= read -r -d '' f; do [ -f "$f" ] && [ ! -L "$f" ] && case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts) printf '%s\0' "$f";; esac; done`. Replace `<exclude pathspecs>` with `':(exclude,glob)**/<entry>/**'` for each `sweep.exclude` entry that names a directory and `':(exclude,glob)**/<entry>'` for each entry that names a file pattern. The output is the NUL-separated list of tracked TypeScript files, called the listed files below.
- Top-level declarations: `<TypeScript files command> | xargs -0 grep -nHE '^[[:space:]]*(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(function\*?|class|interface|type|enum|const|let|var|namespace)[[:space:]]+[A-Za-z_$]'`
- Class and enum members, as `method` or `member`: `<TypeScript files command> | xargs -0 grep -nHE '^[[:space:]]+((public|private|protected|static|readonly|async|abstract|override|get|set)[[:space:]]+)*#?[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(\(|[?!]?:|=)'`.
- Files: add a `file` row for every listed file.
- Dependencies: add a `dependency` row for every key under `dependencies`, `devDependencies`, and `peerDependencies` in each `package.json`.

## Tools

### knip

- **Run:** `knip --reporter json`
- **Never pass:** `--fix`, `-f`, `--fix-type`, `--allow-remove-files`, `--format`, `--cache`.
- **Read findings:** unused files, dependencies, exports, exported types, exported enum members and exported namespace members are the dead-code findings; knip reports them in its JSON output.
