# PHP: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Types: `grep -rnE '^[[:space:]]*(final[[:space:]]+|abstract[[:space:]]+|readonly[[:space:]]+)*(class|interface|trait|enum)[[:space:]]+[A-Za-z_]' --include='*.php'`
- Functions and methods: `grep -rnE '^[[:space:]]*((public|protected|private|static|final|abstract)[[:space:]]+)*function[[:space:]]+&?[A-Za-z_]' --include='*.php'`
- Constants: `grep -rnE '^[[:space:]]*((public|protected|private|final)[[:space:]]+)*const[[:space:]]+' --include='*.php'`
- Enum cases, as members: `grep -rnE '^[[:space:]]*case[[:space:]]+[A-Za-z_]' --include='*.php'`; keep only matches inside enums.
- Properties, as members: `grep -rnE '^[[:space:]]*(public|protected|private)[[:space:]]+(static[[:space:]]+|readonly[[:space:]]+)*(\??[A-Za-z_\\|]+[[:space:]]+)?\$[A-Za-z_]' --include='*.php'`
- Files: add a `file` row for every `*.php` file.

## Tools

### shipmonk/dead-code-detector (PHPStan extension)

- **Run:** `vendor/bin/phpstan analyse --error-format=json --no-progress` over the whole codebase; the extension disables itself when only some files are passed. It requires `vendor/shipmonk/dead-code-detector/rules.neon` included in the PHPStan config, or the extension installer. Always pass `--error-format=json`; it is also the isolated form when the project config sets `errorFormat: removeDeadCode`.
- **Never pass:** `--error-format=removeDeadCode`, `--fix`, `--watch`, `--pro`, `--generate-baseline`.
- **Cache:** PHPStan writes its result cache to the configured `tmpDir`, or the system temporary directory when unset. When `tmpDir` points inside the repository at a path that is not git-ignored, skip the tool.
- **Test handling:** usages from every scanned path count, tests included. With `parameters.shipmonkDeadCode.usageExcluders.tests.enabled: true` in the project config, members used only by tests are reported. Do not change the project config; when the excluder is off, classify test-only rows by the evidence search.
- **Read findings:** it reports dead methods, constants, enum cases, and properties (never read or never written); not classes. `@api` marks members, classes, or interfaces as entry points. Read the JSON, not the exit code: 0 no errors, non-zero otherwise.
- **Limits:** no class findings; classify class rows by the evidence search.

### Psalm

- **Run:** `vendor/bin/psalm --find-unused-code --output-format=json --no-progress --no-cache`. Unused-code detection is on by default since Psalm 6 (`findUnusedCode`), unless `psalm.xml` sets it to false.
- **Never pass:** `--alter`, `--init`, `--set-baseline`, `--update-baseline`, `--generate-json-map`, `--generate-stubs`, `--report`. Never run the `psalter` binary.
- **Cache:** `--no-cache` keeps Psalm from writing its cache directory.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** it reports UnusedClass, UnusedMethod, PossiblyUnusedMethod, UnusedProperty, PossiblyUnusedProperty, UnusedParam, and related issues. Read the JSON, not the exit code: 0 no issues, 2 issues found, 1 run failure.
- **Limits:** `@api` or `@psalm-api` on a class exempts its public members, and its protected members unless the class is final; private members are still checked. `@psalm-suppress` only silences a report.

### PHPStan core

- **Run:** findings come from the same `vendor/bin/phpstan analyse --error-format=json --no-progress` run as shipmonk, with the same never-pass flags and `tmpDir` check; without shipmonk installed, that run gives only the core private-member evidence.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** at rule level 4 and above, PHPStan reports unused private members only: `method.unused`, `classConstant.unused`, `property.unused`, and the read/write-only variants `property.neverRead`, `property.onlyWritten`, `property.neverWritten`, `property.onlyRead`. Use these identifiers as evidence for private-member rows.
- **Limits:** private members only, at rule level 4 and above.
