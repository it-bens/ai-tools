#!/usr/bin/env bats
# bats file_tags=file-read,session-start
bats_require_minimum_version 1.11.0

load 'test_helper/common_setup'

SESSION_SCRIPT="${REPO_ROOT}/plugins/file-read/hooks/scripts/session-start.sh"

run_session_start() {
    run bash -c 'printf "%s\n" "{}" | bash "$1"' _ "${SESSION_SCRIPT}"
}

extract_context() {
    jq -r '.hookSpecificOutput.additionalContext' <<<"${output}"
}

# bats test_tags=output
@test "outputs valid SessionStart additionalContext" {
    run_session_start
    assert_success
    jq -e '
        .hookSpecificOutput.hookEventName == "SessionStart" and
        (.hookSpecificOutput.additionalContext | type == "string" and length > 0)
    ' <<<"${output}" >/dev/null
}

# bats test_tags=content
@test "directive prefers read_file over Bash file readers" {
    run_session_start
    assert_success
    local context
    context=$(extract_context)
    [[ "${context}" == *"ALWAYS"*"file-read MCP tool"* ]]
    [[ "${context}" == *"NEVER"*"Bash"* ]]
    [[ "${context}" == *"read_file("* ]]
    [[ "${context}" == *"cat"* ]]
    [[ "${context}" == *"sed -n"* ]]
    [[ "${context}" == *"head"* ]]
    [[ "${context}" == *"tail"* ]]
}

# bats test_tags=fallback
@test "silently succeeds when prompt template is absent" {
    cp "${SESSION_SCRIPT}" "${BATS_TEST_TMPDIR}/session-start.sh"
    run bash -c 'printf "%s\n" "{}" | bash "$1"' _ "${BATS_TEST_TMPDIR}/session-start.sh"
    assert_success
    assert_output ""
}
