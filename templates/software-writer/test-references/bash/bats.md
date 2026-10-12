# BATS: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `load 'name'` sources a file relative to the test file's directory, trying `name.bash` before `name`, and `bats_load_library 'name'` sources `name` or `name/load.bash` from a `BATS_LIB_PATH` directory; neither names the extension or the functions the file defines.
- `setup`, `teardown`, `setup_file`, and `teardown_file` in a test file, and `setup_suite` and `teardown_suite` in a `setup_suite.bash` beside the first test file (or the file `--setup-suite-file` names), run with no call naming them.
- `run <function>` passes a function to `run` by name, `run bash -c "source '<file>'; <function>"` names a function and a script inside a string, and a script under test is usually reached through a path built from `$BATS_TEST_DIRNAME`; all are test-only references.
- `bats --filter <regex>` in CI, a Makefile, or a `package.json` script selects tests by matching their names; renaming or deleting a test can leave a filter that matches nothing.
