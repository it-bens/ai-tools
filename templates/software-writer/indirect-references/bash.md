# Bash: References a name search misses

A plain-name search misses or misattributes these references. Check them before concluding that a symbol has no production caller; references from test files do not count as callers.

- `eval`, indirect expansion (`${!name}`, `${!prefix*}`), and namerefs (`declare -n`) reach variables without their name at the use site.
- `trap 'fn' EXIT` stores the handler as a string.
- A function called through a variable (`"$handler" args`, `"${prefix}_run"`) has no literal call site.
- `source` and `.` accept a computed path, and `.` resolves a bare filename through `PATH`.
- `export -f` and `export` hand functions and variables to child processes, possibly another script that never sources this file.
- Non-shell files reference scripts by path: CI workflows, hook manifests (`hooks.json`), Makefiles, `package.json` scripts.
- ShellCheck SC2034 does not resolve `${!name}`, `eval`, or `declare -n` indirection, and SC2317 flags functions called by variable or from a trap as unreachable; neither warning proves a symbol dead.
