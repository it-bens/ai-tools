# Bash: BATS

**Written against bats-core 1.11.x, bats-support 0.3.x, and bats-assert 2.1.x.** Check the versions the project installs (a setup script, a submodule, or a package manifest) before applying a rule below; where they differ, the project's version wins. bats-core runs each `@test` as a Bash function under `set -e`; the `assert_*` helpers come from bats-assert, loaded with `load` or `bats_load_library`.

## Table idiom

BATS has no parametrize construct. For a fixed case table, write one helper that runs the act and asserts, and call it from one thin `@test` per case, with the distinguishing input in the test name, so each case reports as its own test and a failure names its input.

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

For cases that mirror a production registry, register one test per entry in a loop at file level with `bats_test_function --description "<name>" -- <function> <args>` (bats-core 1.11.0 and later), so a new registry entry gets its test without a test edit. The `--` before the function is required, and bats passes the description through `eval`, so give it as a single-quoted literal that names the variable (`'quote with carrier $carrier'`): the variable's value is then substituted as text, while a registry value interpolated into a double-quoted description runs as code. Read the registry with a checked command substitution: a failing `$(…)` at file level fails the run, while a failing `< <(…)` registers no tests and the run still exits 0. Check the captured list before the loop, so an empty registry fails the run instead of registering nothing or a blank case.

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

## Assertions

- Match the fragment the behavior depends on with `--partial` only when that fragment cannot match a wrong value; otherwise assert the full line with `assert_line` (any one line equal to the text) or `assert_output` (the whole output). `assert_output --partial "-vv"` also passes on `-vvv`, so a verbosity flag needs its full line.
- No `--index` unless the line's position is the contract; `assert_line --index 1` breaks when an unrelated line is added above it.
- `assert_success` and `assert_failure` read `$status`, which only `run` sets. `run` executes in a subshell, so a test that needs a function's variable assignments calls it directly and captures its status with `|| code=$?`; assert on `code`, because `assert_success` there reads the status of an earlier `run`, or errors when no `run` has executed.

```bash
# WRONG: assert_success reads the status of the earlier run, not of load_rates
run validate_rates "$fixture"
code=0
load_rates "$fixture" || code=$?
assert_success

# CORRECT
code=0
load_rates "$fixture" || code=$?
assert_equal "$code" 0
```

## Independence: hard constraints

- **Fixture `git` runs isolated from the developer's configuration.** Export `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, and an explicit identity (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`) in `setup`, so a developer's `commit.gpgsign` or hooks do not reach the test. Without the global configuration, git derives an identity from the machine's user and host names, which differs per machine.
- **Never `source` a file that sets shell options (`set -euo pipefail`) into the bats process.** The options stay set for the rest of the test and its `teardown`. Source it inside `run bash -c "source '<file>'; <function> <args>"`, a separate Bash process whose options end with it.
- **ShellCheck disables go per line, never per file.** Put `# shellcheck disable=SC<code>` on the line above the one command it covers; a directive between the shebang and the first command disables the check for the whole file.
