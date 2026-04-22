#!/usr/bin/env bats
# bats file_tags=native-tools-enforcer,probe

load 'test_helper/common_setup'
load 'test_helper/mode_setup'

PROBE="${REPO_ROOT}/plugins/native-tools-enforcer/skills/setting-up/scripts/probe.sh"

setup() {
    mode_setup_init
    # Isolate HOME so settings.json probing is deterministic.
    TEST_HOME="$(mktemp -d "${BATS_TMPDIR:-/tmp}/probe_home.XXXXXX")"
    export HOME="$TEST_HOME"
    mkdir -p "${TEST_HOME}/.claude"
}

teardown() {
    mode_setup_cleanup
    rm -rf -- "$TEST_HOME"
}

# bats test_tags=probe,json
@test "probe emits valid JSON" {
    mode_set os=Darwin bfs=1 ugrep=1
    run bash "$PROBE"
    assert_success
    run bash -c "printf '%s' '$output' | jq empty"
    assert_success
}

# bats test_tags=probe,macos
@test "Darwin + both binaries → os=macos, resolved_mode=new" {
    mode_set os=Darwin bfs=1 ugrep=1
    run bash "$PROBE"
    assert_success
    assert_output --partial '"os":"macos"'
    assert_output --partial '"bfs_present":true'
    assert_output --partial '"ugrep_present":true'
    assert_output --partial '"resolved_mode":"new"'
}

# bats test_tags=probe,linux
@test "Linux + no binaries → os=linux, resolved_mode=pass" {
    mode_set os=Linux bfs=0 ugrep=0
    run bash "$PROBE"
    assert_success
    assert_output --partial '"os":"linux"'
    assert_output --partial '"bfs_present":false'
    assert_output --partial '"resolved_mode":"pass"'
}

# bats test_tags=probe,windows
@test "MINGW → os=windows, resolved_mode=classic" {
    mode_set os=MINGW64_NT-10.0 bfs=0 ugrep=0
    run bash "$PROBE"
    assert_success
    assert_output --partial '"os":"windows"'
    assert_output --partial '"resolved_mode":"classic"'
}

# bats test_tags=probe,settings
@test "missing settings.json → settings_file_exists=false, env_var_set=false" {
    mode_set os=Darwin bfs=1 ugrep=1
    run bash "$PROBE"
    assert_success
    assert_output --partial '"settings_file_exists":false'
    assert_output --partial '"env_var_set":false'
}

# bats test_tags=probe,settings
@test "settings.json with force-new env var → env_var_set=true, resolved_mode=new" {
    mode_set os=Darwin bfs=0 ugrep=0
    printf '{"env":{"NATIVE_TOOLS_ENFORCER_FORCE_NEW":"1"}}' \
        > "${TEST_HOME}/.claude/settings.json"
    run bash "$PROBE"
    assert_success
    assert_output --partial '"env_var_set":true'
    assert_output --partial '"env_var_value":"1"'
    assert_output --partial '"resolved_mode":"new"'
}

# bats test_tags=probe,settings
@test "malformed settings.json → exits 0, env_var_set=false" {
    mode_set os=Darwin bfs=1 ugrep=1
    printf '{this is not json' > "${TEST_HOME}/.claude/settings.json"
    run bash "$PROBE"
    assert_success
    assert_output --partial '"env_var_set":false'
}

# bats test_tags=probe,pkg_manager
@test "macOS + brew stub → pkg_manager=brew" {
    mode_set os=Darwin bfs=1 ugrep=1 pkg_manager=brew
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"brew"'
}

# bats test_tags=probe,pkg_manager
@test "Linux + apt-get stub → pkg_manager=apt" {
    mode_set os=Linux bfs=0 ugrep=0 pkg_manager=apt
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"apt"'
}

# bats test_tags=probe,pkg_manager
@test "Linux + dnf stub → pkg_manager=dnf" {
    mode_set os=Linux bfs=0 ugrep=0 pkg_manager=dnf
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"dnf"'
}

# bats test_tags=probe,pkg_manager
@test "Linux + pacman stub → pkg_manager=pacman" {
    mode_set os=Linux bfs=0 ugrep=0 pkg_manager=pacman
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"pacman"'
}

# bats test_tags=probe,pkg_manager
@test "no pkg manager stubbed → pkg_manager=none" {
    mode_set os=Darwin bfs=1 ugrep=1 pkg_manager=none
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"none"'
}

# bats test_tags=probe,pkg_manager
@test "brew + apt-get both stubbed → brew wins (priority)" {
    # mode_set clears all pkg managers and sets only the one specified.
    # To test priority, write both stubs manually after mode_set.
    mode_set os=Darwin bfs=1 ugrep=1 pkg_manager=brew
    printf '#!/bin/bash\nexit 0\n' > "${MODE_MOCK_DIR}/apt-get"
    chmod +x "${MODE_MOCK_DIR}/apt-get"
    run bash "$PROBE"
    assert_success
    assert_output --partial '"pkg_manager":"brew"'
}
