#!/usr/bin/env bash

setup_test_repo() {
    TEST_REPO="$(mktemp -d)"
    git -C "$TEST_REPO" init -q
    git -C "$TEST_REPO" config user.email "test@example.com"
    git -C "$TEST_REPO" config user.name "Test"
}

cleanup_test_repo() {
    if [[ -n "${TEST_REPO:-}" && -d "$TEST_REPO" ]]; then
        rm -rf "$TEST_REPO"
    fi
}

SCOPE_SH="${BATS_TEST_DIRNAME}/../../plugins/code-comment-writer/skills/writing-code-comments/scripts/scope.sh"
