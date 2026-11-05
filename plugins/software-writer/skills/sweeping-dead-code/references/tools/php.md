# PHP: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- PHP files command: `git ls-files -z -- <scope paths> <exclude pathspecs> | while IFS= read -r -d '' f; do [ -f "$f" ] && [ ! -L "$f" ] && case "$f" in *.php) printf '%s\0' "$f";; esac; done`. Replace `<exclude pathspecs>` with `':(exclude,glob)**/<entry>/**'` for each `sweep.exclude` entry that names a directory and `':(exclude,glob)**/<entry>'` for each entry that names a file pattern. The output is the NUL-separated list of tracked PHP files, called the listed files below.
- Types: `<PHP files command> | xargs -0 grep -nHE '^[[:space:]]*(final[[:space:]]+|abstract[[:space:]]+|readonly[[:space:]]+)*(class|interface|trait|enum)[[:space:]]+[A-Za-z_]'`
- Functions and methods: `<PHP files command> | xargs -0 grep -nHE '^[[:space:]]*((public|protected|private|static|final|abstract)[[:space:]]+)*function[[:space:]]+&?[A-Za-z_]'`
- Constants: `<PHP files command> | xargs -0 grep -nHE '^[[:space:]]*((public|protected|private|final)[[:space:]]+)*const[[:space:]]+'`
- Enum cases, as members: `<PHP files command> | xargs -0 grep -nHE '^[[:space:]]*case[[:space:]]+[A-Za-z_]'`; keep only matches inside enums.
- Properties, as members: `<PHP files command> | xargs -0 grep -nHE '^[[:space:]]*(public|protected|private)[[:space:]]+(static[[:space:]]+|readonly[[:space:]]+)*(\??[A-Za-z_\\|]+[[:space:]]+)?\$[A-Za-z_]'`
- Files: add a `file` row for every listed file.

## Tools

### PHPStan with shipmonk/dead-code-detector

- **Run:** `vendor/bin/phpstan analyse --error-format=json --no-progress` over the whole codebase; the extension disables itself when only some files are passed. The extension requires `vendor/shipmonk/dead-code-detector/rules.neon` included in the PHPStan config, or the extension installer; without it the run reports only the core identifiers. Always pass `--error-format=json`; it is also the isolated form when the project config sets `errorFormat: removeDeadCode`.
- **Never pass:** `--error-format=removeDeadCode`, `--fix`, `--watch`, `--pro`, `--generate-baseline`.
- **Cache:** PHPStan writes its result cache to the configured `tmpDir`, or the system temporary directory when unset. When `tmpDir` points inside the repository at a path that is not git-ignored, skip the tool.
- **Read findings:** the dead-code findings are the shipmonk errors for dead methods, constants, enum cases and properties, and the core identifiers for unused private members: `method.unused`, `classConstant.unused`, `property.unused`, `property.neverRead`, `property.onlyWritten`, `property.neverWritten`, `property.onlyRead`. Every other PHPStan error is not a dead-code finding.

### Psalm

- **Run:** `vendor/bin/psalm --find-unused-code --output-format=json --no-progress --no-cache`. Unused-code detection is off when `psalm.xml` sets `findUnusedCode` to false; report that setting.
- **Never pass:** `--alter`, `--init`, `--set-baseline`, `--update-baseline`, `--generate-json-map`, `--generate-stubs`, `--report`. Never run the `psalter` binary.
- **Cache:** `--no-cache` keeps Psalm from writing its cache directory.
- **Read findings:** the dead-code findings are the issue types UnusedClass, UnusedMethod, PossiblyUnusedMethod, UnusedProperty, PossiblyUnusedProperty and UnusedParam; every other issue type is not.
