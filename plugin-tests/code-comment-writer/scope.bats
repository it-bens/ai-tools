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

@test "scope.sh: missing scope type exits 2" {
    run "$SCOPE_SH"
    [ "$status" -eq 2 ]
    [[ "$output" == *"missing scope type"* ]]
}

@test "scope.sh: unknown scope type exits 2" {
    run "$SCOPE_SH" bogus
    [ "$status" -eq 2 ]
    [[ "$output" == *"unknown scope type"* ]]
}

@test "scope.sh: git scope outside a repository exits 2" {
    cd "$BATS_TEST_TMPDIR"
    run "$SCOPE_SH" commit HEAD
    [ "$status" -eq 2 ]
    [[ "$output" == *"not inside a git repository"* ]]
}

@test "scope.sh: path scope enumerates source files and skips vendor/lock/generated" {
    cd "$TEST_REPO"
    mkdir -p src vendor node_modules
    echo "<?php // x" > src/Service.php
    echo "// lib" > vendor/lib.php
    echo "// dep" > node_modules/dep.js
    echo "lock" > yarn.lock
    printf '// @generated\nconst x = 1;\n' > src/gen.js
    echo "binary" > src/image.png

    run "$SCOPE_SH" path .

    [ "$status" -eq 0 ]
    [[ "$output" == *"Service.php"* ]]
    [[ "$output" != *"vendor/lib.php"* ]]
    [[ "$output" != *"node_modules"* ]]
    [[ "$output" != *"yarn.lock"* ]]
    [[ "$output" != *"gen.js"* ]]
    [[ "$output" != *"image.png"* ]]
}

@test "scope.sh: path scope marks whole-file review with a dash range" {
    cd "$TEST_REPO"
    echo "// note" > only.php
    run "$SCOPE_SH" path only.php
    [ "$status" -eq 0 ]
    [[ "$output" == *"FILE only.php -"* ]]
}

@test "scope.sh: path scope on a nonexistent path exits 2" {
    cd "$TEST_REPO"
    run "$SCOPE_SH" path does/not/exist
    [ "$status" -eq 2 ]
    [[ "$output" == *"no such file or directory"* ]]
}

@test "scope.sh: path scope with no source files exits 1" {
    cd "$TEST_REPO"
    mkdir -p empty
    echo "data" > empty/file.bin
    run "$SCOPE_SH" path empty
    [ "$status" -eq 1 ]
    [[ "$output" == *"no in-scope files"* ]]
}

@test "scope.sh: commit scope emits changed file with added-line ranges" {
    cd "$TEST_REPO"
    printf 'line1\nline2\n' > a.php && git add a.php && git commit -q -m "add a"
    printf 'line1\nline2\nline3\nline4\n' > a.php && git add a.php && git commit -q -m "extend a"

    run "$SCOPE_SH" commit HEAD

    [ "$status" -eq 0 ]
    [[ "$output" == *"FILE a.php 3-4"* ]]
}

@test "scope.sh: commit scope rejects an unresolvable sha" {
    cd "$TEST_REPO"
    git commit -q --allow-empty -m "seed"
    run "$SCOPE_SH" commit deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid commit reference"* ]]
}

@test "scope.sh: commit scope handles a root (parentless) commit" {
    cd "$TEST_REPO"
    printf 'a\nb\n' > root.php && git add root.php && git commit -q -m "root"
    root_sha="$(git rev-parse HEAD)"

    run "$SCOPE_SH" commit "$root_sha"

    [ "$status" -eq 0 ]
    [[ "$output" == *"FILE root.php 1-2"* ]]
}

@test "scope.sh: commit-range spans commits" {
    cd "$TEST_REPO"
    git commit -q --allow-empty -m "seed"
    echo "x" > a.php && git add a.php && git commit -q -m "a"
    echo "y" > b.php && git add b.php && git commit -q -m "b"

    run "$SCOPE_SH" commit-range HEAD~2..HEAD

    [ "$status" -eq 0 ]
    [[ "$output" == *"a.php"* ]]
    [[ "$output" == *"b.php"* ]]
}

@test "scope.sh: commit-range rejects an invalid range" {
    cd "$TEST_REPO"
    git commit -q --allow-empty -m "seed"
    run "$SCOPE_SH" commit-range 'bogus..bogus..bogus'
    [ "$status" -eq 2 ]
    [[ "$output" == *"invalid git range"* ]]
}

@test "scope.sh: commit-list unions files across commits" {
    cd "$TEST_REPO"
    echo "x" > a.php && git add a.php && git commit -q -m "a"
    a_sha="$(git rev-parse HEAD)"
    echo "y" > b.php && git add b.php && git commit -q -m "b"
    b_sha="$(git rev-parse HEAD)"

    run "$SCOPE_SH" commit-list "$a_sha" "$b_sha"

    [ "$status" -eq 0 ]
    [[ "$output" == *"a.php"* ]]
    [[ "$output" == *"b.php"* ]]
}

@test "scope.sh: git-worktree reports uncommitted changes vs HEAD" {
    cd "$TEST_REPO"
    printf 'one\n' > w.php && git add w.php && git commit -q -m "seed w"
    printf 'one\ntwo\n' > w.php

    run "$SCOPE_SH" git-worktree

    [ "$status" -eq 0 ]
    [[ "$output" == *"FILE w.php 2-2"* ]]
}
