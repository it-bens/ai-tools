#!/usr/bin/env bats

load ../../.bats/bats-support/load
load ../../.bats/bats-assert/load
load test_helper

setup() {
    setup_test_repo
}

teardown() {
    cleanup_test_repo
}

@test "gather.sh: rejects invocation outside a git repository" {
    cd "$BATS_TEST_TMPDIR"
    run "$GATHER_SH"
    [ "$status" -eq 2 ]
    [[ "$output" == *"not inside a git repository"* ]]
}

@test "gather.sh: reports no changes when the working tree is clean" {
    cd "$TEST_REPO"
    run "$GATHER_SH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no changes to summarize"* ]]
}

@test "gather.sh: rejects invalid git range expressions" {
    cd "$TEST_REPO"
    run "$GATHER_SH" "not-a-valid-range^^^"
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid git range"* ]]
}

@test "gather.sh: produces a TOC with every expected section for a staged change" {
    cd "$TEST_REPO"
    echo "hello" > a.txt
    git add a.txt

    run "$GATHER_SH" --cached

    [ "$status" -eq 0 ]
    [[ "$output" == *"TMPFILE=/tmp/commit-msg."* ]]
    [[ "$output" == *"SECTION plugins"* ]]
    [[ "$output" == *"SECTION status"* ]]
    [[ "$output" == *"SECTION shortstat"* ]]
    [[ "$output" == *"SECTION numstat"* ]]
    [[ "$output" == *"SECTION diff"* ]]
    [[ "$output" == *"DIFF_FILE a.txt"* ]]
}

@test "gather.sh: falls back to the working-tree diff when no range argument is given" {
    cd "$TEST_REPO"
    echo "hello" > a.txt && git add a.txt && git commit -q -m "add a"
    echo "world" >> a.txt

    run "$GATHER_SH"

    [ "$status" -eq 0 ]
    [[ "$output" == *"TMPFILE=/tmp/commit-msg."* ]]
    [[ "$output" == *"DIFF_FILE a.txt"* ]]
}

@test "gather.sh: includes a log section for a range expression spanning commits" {
    cd "$TEST_REPO"
    echo "a" > a.txt && git add a.txt && git commit -q -m "add a"
    echo "b" > b.txt && git add b.txt && git commit -q -m "add b"

    run "$GATHER_SH" HEAD~1..HEAD

    [ "$status" -eq 0 ]
    [[ "$output" == *"SECTION log"* ]]
}

@test "gather.sh: handles a rewrite-mode range against a root commit" {
    local repo
    repo="$(mktemp -d)"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    cd "$repo"
    echo "hello" > a.txt
    git add a.txt
    git commit -q -m "root content"
    ROOT_SHA="$(git rev-parse HEAD)"

    run "$GATHER_SH" "${ROOT_SHA}^..${ROOT_SHA}"
    local rc="$status"
    local out="$output"

    rm -rf "$repo"

    [ "$rc" -eq 0 ]
    [[ "$out" == *"TMPFILE=/tmp/commit-msg."* ]]
    [[ "$out" == *"DIFF_FILE a.txt"* ]]
    [[ "$out" == *"SECTION log"* ]]
}

# Regression guard: tmpfile prefix must stay commit-msg.XXXXXX. A prior port
# from cc-port used cc-port-commit.XXXXXX; this test prevents accidental
# revert when the script is re-touched.
@test "gather.sh: writes its tmpfile with the commit-msg.XXXXXX prefix" {
    cd "$TEST_REPO"
    echo "hello" > a.txt && git add a.txt

    run "$GATHER_SH" --cached

    [ "$status" -eq 0 ]
    [[ "$output" =~ TMPFILE=/tmp/commit-msg\.[A-Za-z0-9]+ ]]
}
