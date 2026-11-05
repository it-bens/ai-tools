# Python: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Python files command: `git ls-files -z -- <scope paths> <exclude pathspecs> | while IFS= read -r -d '' f; do [ -f "$f" ] && [ ! -L "$f" ] && printf '%s\0' "$f"; done | xargs -0 env LC_ALL=C awk 'BEGIN { for (i = 1; i < ARGC; i++) { n = split(ARGV[i], p, "/"); b = p[n]; if (b ~ /\.py$/) emit(ARGV[i]); if (b ~ /\./) ARGV[i] = "" } } FNR == 1 { if ($0 ~ /^#![[:space:]]*(\/[^[:space:]]*\/)?(env[[:space:]]+(-[^[:space:]]+[[:space:]]+)*)?python[0-9.]*([[:space:]]|$)/) emit(FILENAME); nextfile } function emit(s) { printf "%s%c", s, 0 }'`. Replace `<exclude pathspecs>` with `':(exclude,glob)**/<entry>/**'` for each `sweep.exclude` entry that names a directory and `':(exclude,glob)**/<entry>'` for each entry that names a file pattern. The output is the NUL-separated list of tracked Python files, called the listed files below.
- Functions: `<Python files command> | xargs -0 grep -nHE '^[[:space:]]*(async[[:space:]]+)?def [A-Za-z_]' --`. Indented under a class makes the match a `method`.
- Types: `<Python files command> | xargs -0 grep -nHE '^[[:space:]]*class [A-Za-z_]' --`
- Module-level constants and variables: `<Python files command> | xargs -0 grep -nHE '^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*(:[^=]*)?=' --`
- Files: add a `file` row for every listed file that is not executable.

## Tools

### vulture

- **Run:** `vulture -- <files>`, where `<files>` are the listed files passed through `xargs -0`. Read `[tool.vulture]` in `pyproject.toml` before the run; it can change `paths`, `exclude`, `min_confidence` and `make_whitelist`. Report which settings applied.
- **Never pass:** no flags listed.
- **Read findings:** stdout lines of the form `file:line: unused <kind> 'name' (NN% confidence)` are the dead-code findings; any other line is not.

### ruff

- **Run:** `ruff check --isolated --no-cache --select F401,F841 --output-format json -- <files>`, where `<files>` are the listed files passed through `xargs -0`. This is the isolated form; use it whatever the project configuration sets.
- **Never pass:** `--fix`, `--unsafe-fixes`, `--fix-only`.
- **Read findings:** F401 (unused import) and F841 (unused local variable) entries of the JSON are the dead-code findings; any other entry is not.

### pylint

- **Run:** `pylint --disable=all --enable=unused-import,unused-variable,unused-argument,unused-private-member --output-format=json2 <files>`, where `<files>` are the listed files, each prefixed with `./`, passed through `xargs -0`.
- **Never pass:** no flags listed.
- **Read findings:** the JSON also carries pylint's own messages (syntax-error, parse-error, fatal), which `--disable=all` does not suppress; they are not evidence. Keep only the four enabled symbols.
