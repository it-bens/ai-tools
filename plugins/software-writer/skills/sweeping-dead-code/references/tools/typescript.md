# TypeScript: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Top-level declarations: `grep -rnE '^[[:space:]]*(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(function\*?|class|interface|type|enum|const|let|var|namespace)[[:space:]]+[A-Za-z_$]' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs'`
- Class and enum members, as `method` or `member`: `grep -rnE '^[[:space:]]+((public|private|protected|static|readonly|async|abstract|override|get|set)[[:space:]]+)*#?[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(\(|[?!]?:|=)' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.mjs' --include='*.cjs'`. Drop `if`, `for`, `while`, `switch`, `return`, `catch`, and other keywords when the row is read.
- Files: add a `file` row for every source file.
- Dependencies: add a `dependency` row for every key under `dependencies`, `devDependencies`, and `peerDependencies` in each `package.json`.

## Tools

### knip

- **Run:** `knip --reporter json`. It prints one line of JSON with an `issues` array to stdout.
- **Never pass:** `--fix`, `-f`, `--fix-type`, `--allow-remove-files`, `--format`, `--cache`. `--cache` writes `node_modules/.cache/knip`.
- **Test handling:** for test-only detection add `--production`, which drops plugin-defined test, Storybook, and config entry files and devDependencies; exports used only by those files can then be reported, unless tagged `@internal`.
- **Read findings:** knip reports unused files, dependencies, exports, exported types, exported enum members, and exported namespace members. Read the JSON, not the exit code: 0 no issues, 1 issues found, 2 bad input or internal error; `--no-exit-code` and `--max-issues` change this.
- **Limits:** `@public` on an export stops knip from reporting it.
