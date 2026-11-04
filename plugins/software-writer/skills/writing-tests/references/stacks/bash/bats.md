# Bash: BATS

**Written against bats-core 1.14.x, bats-support 0.3.x, and bats-assert 2.2.x.** Check the versions the project installs (a setup script, a submodule, or a package manifest) before applying a rule below; where they differ, the project's version wins. bats-core runs each `@test` body as a Bash function under `set -e`; a function the body calls through `run` does not run under `set -e` (`f(){ false; echo after; }; run f` gives status 0 and output `after`) unless `bats --errexit` (1.14.0) is passed. The `assert_*` helpers come from bats-assert, loaded with `load` or `bats_load_library`; flags on `run` need `bats_require_minimum_version 1.5.0` at file level, or bats prints warning BW02.

## Table idiom

BATS has no parametrize construct, and a `for` loop around `@test` runs only with one iteration: with two or more the file aborts with `Duplicate test name(s) in file` before any test runs, even when the name uses the loop variable, because names are fixed at preprocessing. For a fixed case table, write one helper that runs the act and asserts, and call it from one thin `@test` per case, with the distinguishing input in the test name, so each case reports as its own test and a failure names its input.

```bash
assert_quote() {
    local weight="$1" expected="$2"
    run "$SHIP" quote --weight "$weight"
    assert_success
    assert_output "$expected"
}

@test "quote for a 1 kg parcel" { assert_quote 1 "total: 4.80 EUR"; }
@test "quote for a 30 kg parcel, the heaviest accepted" { assert_quote 30 "total: 41.00 EUR"; }
```

For cases that mirror a production registry, register one test per entry in a loop at file level with `bats_test_function --description "<name>" -- <function> <args>` (bats-core 1.11.0 and later), so a new registry entry gets its test without a test edit. The `--` before the function is required, and bats passes the description through `eval`, so give it as a single-quoted literal that names the variable (`'quote with carrier $carrier'`): the variable's value is then substituted as text, while a registry value interpolated into a double-quoted description runs as code. Read the registry with a checked command substitution: a failing `$(…)` at file level fails the run, while a failing `< <(…)` registers no tests: the run exits 0 when the file has other tests, and fails with `Found no tests` when it has none. Check the captured list before the loop, so an empty registry fails the run instead of registering nothing or a blank case.

```bash
assert_carrier_quotes() {
    run "$SHIP" quote --carrier "$1" --weight 1
    assert_success
}

carriers=$("$SHIP" carriers)
[[ -n $carriers ]] || { printf 'registry "%s carriers" returned no entries\n' "$SHIP" >&2; exit 1; }
while IFS= read -r carrier; do
    bats_test_function --description 'quote with carrier $carrier' -- assert_carrier_quotes "$carrier"
done <<< "$carriers"
```

Two `@test` names, or two `bats_test_function` calls with the same function and arguments (whatever their descriptions), abort the whole file with `Duplicate test name(s) in file`, so a distinguishing input belongs in every `@test` name and in the arguments of every `bats_test_function` call. A loop inside one `@test` stops at the first failing case, never runs the later ones, and `assert_output` does not name the loop variable; loop only when the body names the case on failure (`echo "case w=$w" >&2` before the assertion, since bats prints stderr for a failing test), and write one `@test` per case when the cases are independent.

## Error-path idiom

`run -<N> cmd` fails unless the status is exactly N (`expected exit code 2, got 3`), and `run ! cmd` accepts any status from 1 to 255; both need bats-core 1.5.0. Follow a refusal with an assertion that pins the message, because another failure can return the same status.

```bash
@test "quote refuses a 31 kg parcel" {
    run -2 "$SHIP" quote --weight 31
    assert_output --partial "weight above 30 kg"
}
```

- For an external command, `run -0 cmd` adds nothing over calling `cmd` directly, since the body runs under `set -e`; write it only to assert on `$output` afterwards. For a function, `run` suppresses errexit inside it, so `run -0 f` can pass where a direct `f` fails; use it on a function only for an assertion on `$output`, and do not read the pass as proof that every command in `f` succeeded.
- A missing command passes `refute nosuchcmd`, `run ! nosuchcmd`, and `run nosuchcmd; assert_failure`, because 127 is non-zero. Assert the exact status with `run -<N>`; bats warns BW01 on a bare `run` that exits 127.
- Without `--separate-stderr`, `$output` and `${lines[@]}` merge both streams. `run --separate-stderr` (1.5.0) fills `$output` with stdout only and `$stderr` and `${stderr_lines[@]}` with stderr; `assert_stderr`, `refute_stderr`, `assert_stderr_line`, and `refute_stderr_line` need bats-assert 2.2.0 and that flag.

## Assertions

- Match the fragment the behavior depends on with `--partial` only when that fragment cannot match a wrong value; otherwise assert the full line with `assert_line` (any one line equal to the text) or `assert_output` (the whole output). `assert_output --partial "-vv"` also passes on `-vvv`, so a verbosity flag needs its full line.
- Assert absence with `refute_output`, `refute_line` (`--partial`, `--regexp`, `--index`), or `refute_regex`.
- No `--index` unless the line's position is the contract; `assert_line --index 1` breaks when an unrelated line is added above it.
- `assert_success` and `assert_failure` read `$status`, which only `run` sets. `run` executes in a subshell, so a test that needs a function's variable assignments calls it directly. Capture its status with `|| code=$?` only when the function propagates its own failures (`cmd || return`), and assert on `code`, because `assert_success` there reads the status of an earlier `run`, or errors when no `run` has executed. `||` turns errexit off for the whole body, so a failing command in the middle is skipped over and `code` holds only the last command's status; without propagation, call the function bare and let the body's errexit fail the test.

```bash
# WRONG: assert_success reads the status of the earlier run, not of load_rates
run validate_rates "$fixture"
code=0
load_rates "$fixture" || code=$?
assert_success

# CORRECT: load_rates propagates its failures (cmd || return)
code=0
load_rates "$fixture" || code=$?
assert_equal "$code" 0
```

## Independence: hard constraints

- **Fixture `git` runs isolated from the developer's configuration.** Export `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, and an explicit identity (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`) in `setup`, so a developer's `commit.gpgsign` or hooks do not reach the test. Without the global configuration, git derives an identity from the machine's user and host names, which differs per machine.
- **Restore through `teardown` and `teardown_file`.** They run after the test even when it fails, so put every restore of state outside the temporary directories there, never as the last line of the body, where a failed assertion skips it.
- **Use the temporary directories bats provides** (1.4.0 and later): `BATS_TEST_TMPDIR` is per test, `BATS_FILE_TMPDIR` is shared by the tests of one file, so writes there couple them by order, and `BATS_SUITE_TMPDIR` is shared across files. bats removes them after the run unless `--no-tempdir-cleanup` is passed.
- **From `setup_file` and `setup_suite`, only exported variables reach the tests**; a non-exported assignment is unset in them. `setup_suite` (1.7.0 and later) lives in `setup_suite.bash` beside the test files, and bats warns BW03 when a `.bats` file defines it.
- **Parallel runs.** `--jobs N` needs `flock` or `shlock` (macOS ships `shlock`) for any N above 1, and GNU parallel or rush as well unless `--no-parallelize-across-files` is passed (without one, `parallel: command not found`, no test runs, and the run fails). With `--no-parallelize-across-files` the files run one after another and a file's tests run in parallel under bats' own lock. Order is not guaranteed under `--jobs`. A file whose tests share state opts out with `export BATS_NO_PARALLELIZE_WITHIN_FILE=true` in `setup_file` or at file level; `--no-parallelize-within-files` does the same for every file from the command line.
- **Never set an `EXIT` trap in the test shell.** A test body or `setup` that sets `trap … EXIT` and then fails prints neither `ok` nor `not ok`, and the run ends with `Executed N-1 instead of expected N tests`. Run trap-setting code in `( … )`, under `run`, or in a separate script; a trap in `teardown` or `setup_file` is harmless.
- **A test that makes a write fail with file modes is wrong as root.** A write to a `chmod 444` file and a removal from a `chmod 555` directory succeed for root. Make the write fail another way (a directory at the target path fails with `Is a directory` for root too), or `if (( EUID == 0 )); then skip "root ignores file modes"; fi`.
- **Never `source` a file that sets shell options (`set -euo pipefail`) into the bats process.** The options stay set for the rest of the test and its `teardown`. Source it inside `run bash -c "source '<file>'; <function> <args>"`, a separate Bash process whose options end with it.
- **ShellCheck disables go per line, never per file.** Put `# shellcheck disable=SC<code>` on the line above the one command it covers; a directive between the shebang and the first command disables the check for the whole file.

## Test doubles

- `run` executes in a subshell, so a double that records its calls into a variable loses them. A function override reaches sourced code but not `bash script.sh`, unless it is exported with `export -f name`. A shim on `PATH` (`PATH="$BATS_TEST_TMPDIR/bin:$PATH"`) reaches every subprocess. Overrides and `PATH` changes made in a test do not leak into the next test.
- Prefer a `PATH` shim for an external command a script runs, and a function override for a function in code the test sourced.

## Helpers and temp directories

Put helpers shared by several test files in one file, `test_helper/common.bash`, and call `load 'test_helper/common'` in `setup`. `load` resolves a relative name against the test file's own directory and tries `name.bash` before `name`, so a test file in a subdirectory loads `../test_helper/common`; a missing file fails the test. A helper used by one file stays in that file.

## Non-deterministic calls to flag

| Call | Flag when |
|---|---|
| `date`, `$RANDOM`, `mktemp` names | asserted, or encoded into an asserted value |
| `$$` (the bats process, `$BASHPID` in a subshell) | asserted |
| glob, `find`, or `ls` order | the order is asserted |
| `sort` under the default locale | asserted order of mixed-case input (`a A b B` under `en_US.UTF-8`, `A B a b` under `LC_ALL=C` or an unset locale) |
| `HOME` and the user's git configuration | a fixture command reads them |
| network | any call |

Skip: a fixed value passed through opaquely and never asserted; `LC_ALL=C sort` with the locale pinned in the command.
