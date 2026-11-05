# Plugin Tests

BATS tests for Claude Code plugin hook scripts.

`plugin-tests/decision-handback-guard/` is the exception: it holds a manual harness, `run-checks.sh`, that starts live `claude -p` runs on the developer's credentials. Neither `bats` nor CI runs it. The header of `run-checks.sh` states its usage.

## Quick Start

### Setup

```bash
./.github/scripts/setup-bats.sh
```

### Run Tests

```bash
# All tests
.bats/bats-core/bin/bats plugin-tests/**/*.bats

# Specific plugin
.bats/bats-core/bin/bats plugin-tests/native-tools-enforcer/*.bats

# With timing
.bats/bats-core/bin/bats --timing plugin-tests/**/*.bats

# Filter by tag
.bats/bats-core/bin/bats --filter-tags blocking plugin-tests/
```

### Available Tags

| Tag | Description |
|-----|-------------|
| `blocking` | Tests that verify commands are blocked (exit 2) |
| `warning` | Tests that verify warnings shown but allowed (exit 0) |
| `allow` | Tests that verify commands are allowed without output |
| `input` | Tests for input validation edge cases |

## Directory Structure

```
plugin-tests/
├── README.md
├── test_helper/
│   └── common_setup.bash              # Shared core fixtures
└── native-tools-enforcer/
    ├── native_tools.bats              # Test cases
    └── test_helper/
        └── common_setup.bash          # Plugin-specific fixtures
```

## Adding Tests

1. Create directory: `plugin-tests/<plugin-name>/`
2. Create helper: `test_helper/common_setup.bash`
3. Add test files: `<feature>.bats`

### Helper Template

```bash
#!/bin/bash
load "${BATS_TEST_DIRNAME}/../test_helper/common_setup"
SCRIPTS_DIR="${REPO_ROOT}/plugins/<plugin-name>/hooks/scripts"
```

### Test Template

```bash
#!/usr/bin/env bats
# bats file_tags=<plugin-name>

load 'test_helper/common_setup'

# bats test_tags=blocking
@test "blocks forbidden command" {
    run_hook "check-script.sh" "forbidden-command"
    assert_failure 2
    assert_output --partial "Use proper tool"
}

# bats test_tags=warning
@test "warns on discouraged command" {
    run_hook "check-script.sh" "discouraged-command"
    assert_success
    assert_output --partial "Consider using"
}

# bats test_tags=allow
@test "allows safe command" {
    run_hook "check-script.sh" "safe-command"
    assert_success
    refute_output
}
```

## Dependencies

- bash (4.0+)
- jq
- git
