#!/bin/bash
# Test fixtures for file-read plugin tests.

load "${BATS_TEST_DIRNAME}/../test_helper/common_setup"

PLUGIN_DIR="${REPO_ROOT}/plugins/file-read"
LIB_DIR="${PLUGIN_DIR}/mcp-server-read/lib"
# Used by read_file.bats after this helper is loaded.
# shellcheck disable=SC2034
SERVER_DIR="${PLUGIN_DIR}/mcp-server-read"

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    TEST_PROJECT_DIR="${TEST_TEMP_DIR}/project"
    mkdir -p "$TEST_PROJECT_DIR"

    # read_file.sh calls log through the MCP server; tests provide a no-op shim.
    # shellcheck disable=SC2329
    log() { :; }
    # shellcheck disable=SC1091
    source "${LIB_DIR}/read_file.sh"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}
