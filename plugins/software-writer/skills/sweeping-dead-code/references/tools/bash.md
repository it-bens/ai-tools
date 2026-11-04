# Bash: definition patterns and tools

## Definition patterns

Run each command from the repository root. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Shell files: write every tracked shell file in scope, NUL-separated, to `<shell files>` = `${TMPDIR:-/tmp}/sweeping-dead-code-<timestamp>-shell-files`. Choose `<timestamp>` here; the Step 3 ledger uses the same one. `<scope paths>` is the paths of a Path scope, or `.` for a Repository or Branch scope. Add one `':(exclude,glob)<pattern>'` per `sweep.exclude` entry: `**/<dir>/**` for a directory, `**/<entry>` for any other entry. Drop a listed file whose header marks it as generated. Name every untracked file of a Path scope in the report as not swept. `git ls-files -z -- <scope paths> <exclude pathspecs> | xargs -0 sh -c 'for f do if [ -f "$f" ] && [ ! -L "$f" ]; then printf "%s\0" "$f"; fi; done' sh | xargs -0 awk 'FNR==1 { l=$0; sub(/\r$/,"",l); if (FILENAME ~ /\.(sh|bash|bats)$/ || (FILENAME !~ /\.[^\/]*$/ && l ~ /^#![[:space:]]*(\/[^[:space:]]*\/)?(env[[:space:]]+(-[A-Za-z]+[[:space:]]+)*)?(ba)?sh([[:space:]]|$)/)) printf "%s%c", FILENAME, 0; nextfile }' > <shell files>`
- Functions: `xargs -0 grep -nHE '^[[:space:]]*(function[[:space:]]+[A-Za-z_][A-Za-z0-9_:-]*|[A-Za-z_][A-Za-z0-9_:-]*[[:space:]]*\(\))' < <shell files>`
- Variables: `xargs -0 grep -nHE '^[[:space:]]*((declare|typeset|readonly|export|local)([[:space:]]+-[A-Za-z]+)*[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' < <shell files>`
- Files: add a `file` row for every file in `<shell files>` that is not a test file and is not executable. In Step 5, a `source`, `.`, `load`, or `bats_load_library` line that names the file, with or without its extension, is a reference to it.

A test file is a `.bats` file, or any other file under a directory that holds `.bats` files, unless production code sources or runs it.

## Tools

### ShellCheck

- **Run:** `xargs -0 shellcheck -i SC2034,SC2317,SC2329 -x -f json1 < <shell files>`. xargs can split a long list into several calls, so read every JSON document the run prints. `-x` follows `source` statements; findings stay limited to the files given.
- **Never pass:** no flags listed.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** SC2034 is an unused variable, SC2317 an unreachable command, SC2329 a function never invoked. SC2329 exists from v0.11.0; older versions report nothing for it. Read the JSON, not the exit code: 0 no issues, 1 issues found, 2 some files not processed, 3 bad syntax, 4 bad options.
- **Limits:** `-i` also hides parse errors, so a clean result does not prove the file parses; run `bash -n <file>` for that. SC2034 does not resolve `${!name}`, `eval`, or `declare -n`; SC2317 and SC2329 flag functions called by variable or from a trap. Neither proves a symbol dead.
