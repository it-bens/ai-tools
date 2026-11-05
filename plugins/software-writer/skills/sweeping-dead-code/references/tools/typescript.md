# TypeScript: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Top-level declarations: `grep -rnE '^[[:space:]]*(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(function\*?|class|interface|type|enum|const|let|var|namespace)[[:space:]]+[A-Za-z_$]' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs' --include='*.mts' --include='*.cts'`
- Class and enum members, as `method` or `member`: `grep -rnE '^[[:space:]]+((public|private|protected|static|readonly|async|abstract|override|get|set)[[:space:]]+)*#?[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(\(|[?!]?:|=)' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs' --include='*.mts' --include='*.cts'`.
- Files: add a `file` row for every source file.
- Dependencies: add a `dependency` row for every key under `dependencies`, `devDependencies`, and `peerDependencies` in each `package.json`.

## Tools

### knip

- **Run:** `knip --reporter json`
- **Never pass:** `--fix`, `-f`, `--fix-type`, `--allow-remove-files`, `--format`, `--cache`.
- **Read findings:** read the `issues` array of the JSON. Entries for unused files, dependencies, exports, exported types, exported enum members and exported namespace members are the dead-code findings; any other issue type is not.
