# Bash Code Stack

## Documentation sources

- Shell builtin help: `help <name>` for a builtin or reserved word, after `type -a <name>` shows what the name actually runs.
- Man pages: `man <cmd> | col -b | grep -n 'PATTERN'` for an external command.
- The bash NEWS file: `https://tiswww.case.edu/php/chet/bash/NEWS`, searched for the version that introduced a construct.
- The ShellCheck wiki: `https://www.shellcheck.net/wiki/SC<code>` for a ShellCheck code.

## Doc-comment convention

Google Shell Style Guide function header on every function that is not both obvious and short and on every function in a sourced library: a description line, then only the applicable fields of `Globals:`, `Arguments:`, `Outputs:`, `Returns:`.
