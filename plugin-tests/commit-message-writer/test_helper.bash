#!/usr/bin/env bash

setup_test_repo() {
    TEST_REPO="$(mktemp -d)"
    git -C "$TEST_REPO" init -q
    git -C "$TEST_REPO" config user.email "test@example.com"
    git -C "$TEST_REPO" config user.name "Test"
    git -C "$TEST_REPO" commit -q --allow-empty -m "initial"
}

cleanup_test_repo() {
    if [[ -n "${TEST_REPO:-}" && -d "$TEST_REPO" ]]; then
        rm -rf "$TEST_REPO"
    fi
    rm -f /tmp/commit-msg.* 2>/dev/null || true
}

GATHER_SH="${BATS_TEST_DIRNAME}/../../plugins/commit-message-writer/skills/writing-commit-messages/scripts/gather.sh"
