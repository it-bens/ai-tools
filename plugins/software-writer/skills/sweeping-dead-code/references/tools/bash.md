# Bash: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Shell files command: `git ls-files -z -- <scope paths> ':(exclude)<entry>' | while IFS= read -r -d '' f; do [ -f "$f" ] && [ ! -L "$f" ] && printf '%s\0' "$f"; done | xargs -0 awk 'BEGIN { for (i = 1; i < ARGC; i++) { n = split(ARGV[i], p, "/"); b = p[n]; if (b ~ /\.(sh|bash|bats)$/) emit(ARGV[i]); if (b ~ /\./) ARGV[i] = "" } } FNR == 1 { if ($0 ~ /^#![[:space:]]*(\/[^[:space:]]*\/)?(env[[:space:]]+(-[^[:space:]]+[[:space:]]+)*)?(ba)?sh([[:space:]]|$)/) emit(FILENAME); nextfile } function emit(s) { printf "%s%c", s, 0 }'`. Repeat the `':(exclude)<entry>'` pathspec for each `sweep.exclude` entry. The output is the NUL-separated list of tracked shell files, called the listed files below.
- Functions: `<Shell files command> | xargs -0 grep -nHE '^[[:space:]]*(function[[:space:]]+[A-Za-z_][A-Za-z0-9_:.-]*|[A-Za-z_][A-Za-z0-9_:.-]*[[:space:]]*\(\))'`
- Variables: `<Shell files command> | xargs -0 grep -nHE '^[[:space:]]*((declare|typeset|readonly|export|local)([[:space:]]+-[A-Za-z]+)*[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*='`
- Files: add a `file` row for every listed file that is not a test file and not executable. A `source`, `.`, `load` or `bats_load_library` line naming it is a reference to it.
- A bats test file is a `.bats` file, or another file under a directory that holds `.bats` files, unless production code sources or runs it.

## Tools

### ShellCheck

- **Run:** `shellcheck -i SC2034,SC2317,SC2329 -x -f json1 <files>`, where `<files>` are the listed files passed through `xargs -0`.
- **Never pass:** no flags listed.
- **Read findings:** SC2034 (unused variable), SC2317 (unreachable command) and SC2329 (function never invoked) are the dead-code findings; the run enables no other code.
