# Bash: definition patterns and tools

## Definition patterns

Run each command from the repository root over the scope paths. The patterns over-match on purpose: drop a match that is not a definition when its row is read in Step 5.

- Functions: `grep -rnE '^[[:space:]]*(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_:-]*[[:space:]]*\(\)' --include='*.sh' --include='*.bash'`
- Variables: `grep -rnE '^[[:space:]]*(declare|readonly|export|local)?[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' --include='*.sh' --include='*.bash'`
- Files: add a `file` row for every `*.sh` or `*.bash` file that is not executable and is sourced by nothing.

## Tools

### ShellCheck

- **Run:** `shellcheck -i SC2034,SC2317,SC2329 -x -f json1 <files>`. `-x` follows `source` statements; findings stay limited to the files given.
- **Never pass:** no flags listed.
- **Test handling:** classify test-only rows by the evidence search.
- **Read findings:** SC2034 is an unused variable, SC2317 an unreachable command, SC2329 a function never invoked. SC2329 exists from v0.11.0; older versions report nothing for it. Read the JSON, not the exit code: 0 no issues, 1 issues found, 2 some files not processed, 3 bad syntax, 4 bad options.
- **Limits:** `-i` also hides parse errors, so a clean result does not prove the file parses; run `bash -n <file>` for that. SC2034 does not resolve `${!name}`, `eval`, or `declare -n`; SC2317 and SC2329 flag functions called by variable or from a trap. Neither proves a symbol dead.
