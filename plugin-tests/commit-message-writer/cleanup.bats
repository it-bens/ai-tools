#!/usr/bin/env bats

load ../../.bats/bats-support/load
load ../../.bats/bats-assert/load
load test_helper

setup() {
    TMPFILE="$(mktemp /tmp/commit-msg.XXXXXX)"
    OUTSIDE_FILE="${BATS_TEST_TMPDIR}/outside.tmp"
    NESTED_DIR="${TMPFILE}.dir"
    SYMLINK_TARGET="${BATS_TEST_TMPDIR}/symlink-target"
}

teardown() {
    rm -f -- "${TMPFILE}" "${OUTSIDE_FILE}" "${SYMLINK_TARGET}"
    rm -rf -- "${NESTED_DIR}"
}

@test "cleanup.sh: deletes an owned regular commit-message tmpfile" {
    run "${CLEANUP_SH}" "${TMPFILE}"

    [ "${status}" -eq 0 ]
    [ ! -e "${TMPFILE}" ]
}

@test "cleanup.sh: succeeds when the valid tmpfile is already absent" {
    rm -f -- "${TMPFILE}"

    run "${CLEANUP_SH}" "${TMPFILE}"

    [ "${status}" -eq 0 ]
}

@test "cleanup.sh: rejects paths outside the commit-message tmpfile prefix" {
    printf '%s\n' 'keep' > "${OUTSIDE_FILE}"

    run "${CLEANUP_SH}" "${OUTSIDE_FILE}"

    [ "${status}" -eq 2 ]
    [[ "${output}" == *"refusing path outside /tmp/commit-msg.*"* ]]
    [ -f "${OUTSIDE_FILE}" ]
}

@test "cleanup.sh: rejects nested paths below the commit-message tmpfile prefix" {
    mkdir -p -- "${NESTED_DIR}"
    local nested_file="${NESTED_DIR}/nested"
    printf '%s\n' 'keep' > "${nested_file}"

    run "${CLEANUP_SH}" "${nested_file}"

    [ "${status}" -eq 2 ]
    [[ "${output}" == *"refusing invalid tmpfile path"* ]]
    [ -f "${nested_file}" ]
}

@test "cleanup.sh: rejects symlinks without deleting their target" {
    rm -f -- "${TMPFILE}"
    printf '%s\n' 'keep' > "${SYMLINK_TARGET}"
    ln -s -- "${SYMLINK_TARGET}" "${TMPFILE}"

    run "${CLEANUP_SH}" "${TMPFILE}"

    [ "${status}" -eq 2 ]
    [[ "${output}" == *"refusing non-regular, symlinked, or unowned tmpfile"* ]]
    [ -L "${TMPFILE}" ]
    [ -f "${SYMLINK_TARGET}" ]
}

@test "cleanup.sh: rejects directories" {
    rm -f -- "${TMPFILE}"
    mkdir -- "${TMPFILE}"

    run "${CLEANUP_SH}" "${TMPFILE}"

    [ "${status}" -eq 2 ]
    [[ "${output}" == *"refusing non-regular, symlinked, or unowned tmpfile"* ]]
    [ -d "${TMPFILE}" ]

    rmdir -- "${TMPFILE}"
}

@test "cleanup.sh: rejects extra arguments without deleting the tmpfile" {
    run "${CLEANUP_SH}" "${TMPFILE}" "/tmp/commit-msg.extra"

    [ "${status}" -eq 2 ]
    [[ "${output}" == *"expected exactly one tmpfile path"* ]]
    [ -f "${TMPFILE}" ]
}
