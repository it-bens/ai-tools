#!/usr/bin/env bats
# bats file_tags=native-tools-enforcer,detect

load 'test_helper/common_setup'
load 'test_helper/mode_setup'

setup() {
    mode_setup_init
    # Source the library fresh each test (resets NTE_MODE)
    LIB_PATH="${REPO_ROOT}/plugins/native-tools-enforcer/hooks/scripts/lib/detect-mode.sh"
}

teardown() {
    mode_setup_cleanup
}

# bats test_tags=detect,env-var
@test "env var set → new (regardless of OS)" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0 force_new=1
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "new" ]]
}

# bats test_tags=detect,env-var
@test "env var empty string → falls through cascade" {
    mode_set os=Darwin bfs=0 ugrep=0 force_new=0
    export NATIVE_TOOLS_ENFORCER_FORCE_NEW=""
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    # Darwin without binaries → pass (not new, not classic)
    [[ "$NTE_MODE" == "pass" ]]
}

# bats test_tags=detect,env-var,docs-pin
@test "env var '0' is treated as set → new (documented quirk)" {
    # README: 'Values like "false" or "0" are treated as set (any non-empty
    # string)'. If someone tightens the cascade to == "1", this test fails and
    # docs need updating in lockstep.
    mode_set os=Darwin bfs=0 ugrep=0
    export NATIVE_TOOLS_ENFORCER_FORCE_NEW="0"
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "new" ]]
}

# bats test_tags=detect,env-var,docs-pin
@test "env var 'false' is treated as set → new (documented quirk)" {
    mode_set os=Darwin bfs=0 ugrep=0
    export NATIVE_TOOLS_ENFORCER_FORCE_NEW="false"
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "new" ]]
}

# bats test_tags=detect,windows
@test "MINGW64_NT + no binaries → classic" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "classic" ]]
}

# bats test_tags=detect,windows
@test "CYGWIN_NT + no binaries → classic" {
    mode_set os=CYGWIN_NT-10.0 bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "classic" ]]
}

# bats test_tags=detect,windows
@test "MSYS_NT + no binaries → classic" {
    mode_set os=MSYS_NT-10.0 bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "classic" ]]
}

# bats test_tags=detect,unknown
@test "UnknownOS → pass" {
    mode_set os=WeirdOS bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "pass" ]]
}

# bats test_tags=detect,macos
@test "Darwin + bfs + ugrep → new" {
    mode_set os=Darwin bfs=1 ugrep=1
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "new" ]]
}

# bats test_tags=detect,linux
@test "Linux + bfs + ugrep → new" {
    mode_set os=Linux bfs=1 ugrep=1
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "new" ]]
}

# bats test_tags=detect,macos
@test "Darwin + only bfs → pass" {
    mode_set os=Darwin bfs=1 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "pass" ]]
}

# bats test_tags=detect,macos
@test "Darwin + only ugrep → pass" {
    mode_set os=Darwin bfs=0 ugrep=1
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "pass" ]]
}

# bats test_tags=detect,macos
@test "Darwin + neither → pass" {
    mode_set os=Darwin bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "pass" ]]
}

# bats test_tags=detect,linux
@test "Linux + neither → pass" {
    mode_set os=Linux bfs=0 ugrep=0
    NTE_MODE=""
    source "$LIB_PATH"
    nte_resolve_mode
    [[ "$NTE_MODE" == "pass" ]]
}
