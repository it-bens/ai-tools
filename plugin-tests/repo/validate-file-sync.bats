#!/usr/bin/env bats
# bats file_tags=repo,file-sync

load '../test_helper/common_setup'

SCRIPT="${REPO_ROOT}/.github/scripts/validate-file-sync.sh"

setup() {
    FIXTURE_ROOT="${BATS_TEST_TMPDIR}/root"
    mkdir -p "${FIXTURE_ROOT}/.github" "${FIXTURE_ROOT}/src" "${FIXTURE_ROOT}/dest"
    printf 'source content\n' > "${FIXTURE_ROOT}/src/a.md"
    printf 'source content\n' > "${FIXTURE_ROOT}/dest/a.md"
    printf '# comment\n\nsrc/a.md dest/a.md\n' > "${FIXTURE_ROOT}/.github/file-sync.manifest"
}

# bats test_tags=check,in-sync
@test "in-sync copy: exit 0 and ok" {
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_success
    assert_output "ok dest/a.md"
}

# bats test_tags=check,drift
@test "drifted copy: exit 1 and DRIFT" {
    printf 'edited\n' > "${FIXTURE_ROOT}/dest/a.md"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_failure 1
    assert_output --partial "DRIFT dest/a.md differs from src/a.md"
}

# bats test_tags=check,missing
@test "missing copy: exit 1 and MISSING" {
    rm "${FIXTURE_ROOT}/dest/a.md"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_failure 1
    assert_output --partial "MISSING dest/a.md"
}

# bats test_tags=fix,drift
@test "--fix repairs a drifted copy and a following check passes" {
    printf 'edited\n' > "${FIXTURE_ROOT}/dest/a.md"
    run "$SCRIPT" --fix --root "$FIXTURE_ROOT"
    assert_success
    assert_output "fixed dest/a.md"
    run cmp "${FIXTURE_ROOT}/src/a.md" "${FIXTURE_ROOT}/dest/a.md"
    assert_success
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_success
    assert_output "ok dest/a.md"
}

# bats test_tags=fix,missing
@test "--fix recreates a missing copy and its parent directory" {
    rm -r "${FIXTURE_ROOT}/dest"
    run "$SCRIPT" --fix --root "$FIXTURE_ROOT"
    assert_success
    assert_output "fixed dest/a.md"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_success
    assert_output "ok dest/a.md"
}

# bats test_tags=input,source
@test "missing source: exit 2 naming the line" {
    rm "${FIXTURE_ROOT}/src/a.md"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_failure 2
    assert_output --partial "file-sync.manifest:3"
    assert_output --partial "source not found: src/a.md"
}

# bats test_tags=input,manifest
@test "malformed line: exit 2 naming the line" {
    printf 'src/a.md\n' >> "${FIXTURE_ROOT}/.github/file-sync.manifest"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_failure 2
    assert_output --partial "file-sync.manifest:4"
}

# bats test_tags=input,manifest
@test "missing manifest: exit 2" {
    rm "${FIXTURE_ROOT}/.github/file-sync.manifest"
    run "$SCRIPT" --root "$FIXTURE_ROOT"
    assert_failure 2
    assert_output --partial "manifest not found"
}

# bats test_tags=input,argument
@test "unknown argument: exit 2 with usage" {
    run "$SCRIPT" --bogus --root "$FIXTURE_ROOT"
    assert_failure 2
    assert_output --partial "unknown argument: --bogus"
    assert_output --partial "Usage:"
}

# bats test_tags=input,argument
@test "empty --root: exit 2" {
    run "$SCRIPT" --root ""
    assert_failure 2
    assert_output --partial "--root"
}

# bats test_tags=input,argument
@test "--root with no value: exit 2" {
    run "$SCRIPT" --root
    assert_failure 2
    assert_output --partial "--root"
}

# bats test_tags=input,argument
@test "--root naming a non-directory: exit 2" {
    run "$SCRIPT" --root "${FIXTURE_ROOT}/src/a.md"
    assert_failure 2
    assert_output --partial "--root"
}
