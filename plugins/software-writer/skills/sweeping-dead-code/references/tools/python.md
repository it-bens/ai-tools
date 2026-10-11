# Python: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Functions: `grep -rnE '^[[:space:]]*(async[[:space:]]+)?def [A-Za-z_]' --include='*.py'`. Indented under a class makes the match a `method`.
- Types: `grep -rnE '^[[:space:]]*class [A-Za-z_]' --include='*.py'`
- Module-level constants and variables: `grep -rnE '^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(:[^=]*)?=' --include='*.py'`
- Files: add a `file` row for every `*.py` file.

## Tools

### vulture

- **Run:** `vulture <paths>`. Vulture reads `pyproject.toml` `[tool.vulture]` from the working directory automatically, and that section can change `paths`, `exclude`, `min_confidence`, and `make_whitelist`; read it before the run and report which settings applied. `--config <file>` points vulture at a different configuration file.
- **Never pass:** no flags listed. Vulture never writes files.
- **Test handling:** it counts uses in every file it is given, so passing tests makes test-only code look used. Run once without the test paths, or with `--exclude` (comma-separated globs matched case-insensitively against absolute paths), to find test-only code.
- **Read findings:** stdout lines of the form `file:line: unused <kind> 'name' (NN% confidence)`. Confidence: arguments and unreachable code 100%, imports 90%, attributes, classes, functions, methods, properties, and variables 60%. Read stdout, not the exit code: 0 no dead code, 3 dead code found (also when some files failed to parse), 1 invalid input with no findings, 2 invalid arguments.
- **Limits:** suppressions in the project hide findings: whitelist files, `--ignore-names`, `--ignore-decorators` (the decorated name only). `--min-confidence N` hides findings below N%.

### ruff

- **Run:** `ruff check --isolated --no-cache --select F401,F841 --output-format json <paths>`. `--isolated` ignores project configuration, so a project `fix` or `fix-only` setting cannot rewrite files. This is the isolated form; use it whatever the project configuration sets.
- **Never pass:** `--fix`, `--unsafe-fixes`, `--fix-only`.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** F401 is an unused import, F841 an unused local variable (not unpacked assignments). Read the JSON; it exits 1 when violations are found.
- **Limits:** per file only; it says nothing about cross-module use.

### pylint

- **Run:** `pylint --disable=all --enable=unused-import,unused-variable,unused-argument,unused-private-member --output-format=json2 <paths>`
- **Never pass:** no flags listed.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** the JSON also carries pylint's own messages (syntax-error, parse-error, fatal), which `--disable=all` does not suppress; keep only the four enabled symbols. Read the JSON, not the exit code, which is a bit mask (warnings set bit 4; errors and fatals add bits 2 and 1).
