#!/bin/bash
# Claude Code Hook: Native Tools Enforcer
# ========================================
# This hook runs as a PreToolUse hook for the Bash tool.
# It validates bash commands and blocks those that should use native Claude Code tools.
#
# Exit codes:
#   0 - Command allowed
#   1 - Error (shown to user only)
#   2 - Command blocked (message shown to Claude)
#
# References:
#   - https://github.com/anthropics/claude-code/issues/1386
#   - https://github.com/anthropics/claude-code/issues/10056
#   - https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

set -euo pipefail

nte_log() {
    # One-line debug logger. Silent no-op when DEBUG unset.
    # Silently skips on any error — logging failure never crashes the hook.
    [[ -z "${NATIVE_TOOLS_ENFORCER_DEBUG:-}" ]] && return 0
    [[ -z "${CLAUDE_PLUGIN_DATA:-}" ]] && return 0

    local mode="$1" decision="$2" cmd="$3"
    local ts log_dir log_file truncated
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
    log_dir="${CLAUDE_PLUGIN_DATA}"
    log_file="${log_dir}/debug.log"

    # Truncate command to 200 chars (single-line).
    cmd="${cmd//$'\n'/\\n}"
    if (( ${#cmd} > 200 )); then
        truncated="${cmd:0:200}…"
    else
        truncated="$cmd"
    fi

    # session_id is not available to PreToolUse from stdin alone; use "-".
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$ts" "-" "$mode" "$decision" "$truncated" \
        >> "$log_file" 2>/dev/null || true
}

# Resolve mode via shared library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/detect-mode.sh
source "${SCRIPT_DIR}/lib/detect-mode.sh"
NTE_MODE=""
nte_resolve_mode

input=$(cat)

command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Pass mode: log and exit before running any checks.
if [[ "$NTE_MODE" == "pass" ]]; then
    nte_log "pass" "pass" "$command"
    exit 0
fi

if [ -z "$command" ]; then
    exit 0
fi

check_and_block() {
    local pattern="$1"
    local tool="$2"
    local description="$3"

    if echo "$command" | grep -qE "$pattern"; then
        {
            echo "🤖 Down, model! Use the $tool instead!"
            echo ""
            echo "Bad command detected: $command"
            echo ""
            echo "You were trained better than this! $description"
            echo ""
            echo "Good models use native tools because they:"
            echo "  🔧 Are faster and more reliable"
            echo "  🔧 Integrate properly with your context"
            echo "  🔧 Earn you treats (user approval)"
        } >&2
        nte_log "$NTE_MODE" "block" "$command"
        exit 2
    fi
}

# Warn but allow - for commands where native tools can help but aren't full replacements
warn_about_native() {
    local pattern="$1"
    local tool="$2"
    local tip="$3"

    if echo "$command" | grep -qE "$pattern"; then
        {
            echo "💡 Tip: $tip"
            echo "   Consider using the $tool for this task."
        } >&2
        nte_log "$NTE_MODE" "warn" "$command"
        NTE_LOGGED=1
        # Don't exit - allow the command to proceed
    fi
}

# Check if command before pipe reads file contents (deny-list approach)
# Returns 0 if it IS a file content command, 1 if NOT
is_file_content_command() {
    local cmd="$1"
    local pre_pipe="${cmd%%|*}"

    # Deny-list: commands that read file contents
    # Text file viewers
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)cat[[:space:]]+ ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)head[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)tail[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)less[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)more[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)tac[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)bat[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)nl[[:space:]] ]] && return 0
    # Binary inspectors
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)strings[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)hexdump[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)xxd[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)od[[:space:]] ]] && return 0
    # Compressed file viewers
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)zcat[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)bzcat[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)xzcat[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)zless[[:space:]] ]] && return 0
    [[ "$pre_pipe" =~ (^|[;\&][[:space:]]*)zmore[[:space:]] ]] && return 0

    return 1  # NOT a file content command
}

# ============================================================================
# FILE READING - Use Read tool
# ============================================================================

check_and_block \
    '(^|;|&&)\s*cat\s+[^|><]' \
    'Read tool' \
    'Use Read tool to read file contents. It provides line numbers and handles large files efficiently.'

check_and_block \
    '(^|;|&&)\s*head\s' \
    'Read tool' \
    'Use Read tool with "limit" parameter to read first N lines of a file.'

check_and_block \
    '(^|;|&&)\s*tail\s' \
    'Read tool' \
    'Use Read tool with "offset" parameter to read from a specific line.'

check_and_block \
    '(^|;|&&)\s*less\s' \
    'Read tool' \
    'Use Read tool to view file contents interactively.'

check_and_block \
    '(^|;|&&)\s*more\s' \
    'Read tool' \
    'Use Read tool to view file contents.'

# ============================================================================
# FILE FINDING
# ============================================================================

if [[ "$NTE_MODE" == "new" ]]; then
    check_and_block \
        '(^|;|&&)\s*find\s' \
        '`bfs` in Bash' \
        'Use `bfs` in Bash for fast file pattern matching. Example: bfs . -name "*.js"'

    check_and_block \
        '(^|;|&&)\s*locate\s' \
        '`bfs` in Bash' \
        'Use `bfs` in Bash for file pattern matching.'
else  # classic
    check_and_block \
        '(^|;|&&)\s*find\s' \
        'Glob tool' \
        'Use Glob tool with patterns like "**/*.js" or "src/**/*.ts" for fast file pattern matching.'

    check_and_block \
        '(^|;|&&)\s*locate\s' \
        'Glob tool' \
        'Use Glob tool for file pattern matching.'
fi

# ============================================================================
# CONTENT SEARCHING
# ============================================================================

if [[ "$NTE_MODE" == "new" ]]; then
    GREP_TOOL_NAME='`ugrep` in Bash'
    GREP_TOOL_DESC='Use `ugrep` in Bash for content searching. Example: ugrep -r "pattern" .'
    RG_TOOL_DESC='Use `ugrep` in Bash instead of ripgrep. Example: ugrep -r "pattern" .'
    GREP_PIPED_DESC='Use `ugrep` in Bash instead of piping file contents to grep.'
    RG_PIPED_DESC='Use `ugrep` in Bash instead of piping file contents to ripgrep.'
    AG_DESC='Use `ugrep` in Bash instead of silver searcher (ag).'
    ACK_DESC='Use `ugrep` in Bash instead of ack.'
else
    GREP_TOOL_NAME='Grep tool'
    GREP_TOOL_DESC='Use Grep tool for content searching. It supports regex and provides better output formatting.'
    RG_TOOL_DESC='Use Grep tool which is built on ripgrep and provides native integration.'
    GREP_PIPED_DESC='Use Grep tool for content searching instead of piping file contents to grep.'
    RG_PIPED_DESC='Use Grep tool instead of piping file contents to ripgrep.'
    AG_DESC='Use Grep tool instead of silver searcher (ag).'
    ACK_DESC='Use Grep tool instead of ack.'
fi

# Direct grep/rg on files is always blocked
check_and_block \
    '(^|;|&&)\s*grep\s' \
    "$GREP_TOOL_NAME" \
    "$GREP_TOOL_DESC"

check_and_block \
    '(^|;|&&)\s*rg\s' \
    "$GREP_TOOL_NAME" \
    "$RG_TOOL_DESC"

# Piped grep/rg: only block if source reads file contents
if echo "$command" | grep -qE '\|\s*grep\s' && is_file_content_command "$command"; then
    check_and_block \
        '.*' \
        "$GREP_TOOL_NAME" \
        "$GREP_PIPED_DESC"
fi

if echo "$command" | grep -qE '\|\s*rg\s' && is_file_content_command "$command"; then
    check_and_block \
        '.*' \
        "$GREP_TOOL_NAME" \
        "$RG_PIPED_DESC"
fi

check_and_block \
    '(^|;|&&)\s*ag\s' \
    "$GREP_TOOL_NAME" \
    "$AG_DESC"

check_and_block \
    '(^|;|&&)\s*ack\s' \
    "$GREP_TOOL_NAME" \
    "$ACK_DESC"

# ============================================================================
# FILE WRITING - Use Write tool
# ============================================================================

check_and_block \
    'echo\s+.*>\s*["'"'"'a-zA-Z0-9/~._$]' \
    'Write tool' \
    'Use Write tool to create or overwrite files. It handles content safely and tracks changes.'

check_and_block \
    'printf\s+.*>\s*["'"'"'a-zA-Z0-9/~._$]' \
    'Write tool' \
    'Use Write tool to create or overwrite files.'

check_and_block \
    'cat\s*>\s*["'"'"'a-zA-Z0-9/~._$]' \
    'Write tool' \
    'Use Write tool to create files.'

check_and_block \
    '(^|;|&&)\s*cat\s*<<[^|]*($|>)' \
    'Write tool' \
    'Use Write tool instead of heredoc for writing to files. Piping heredoc to commands is allowed.'

check_and_block \
    '\|\s*tee\s' \
    'Write tool' \
    'Use Write tool to write content to files.'

# ============================================================================
# FILE EDITING - Use Edit tool
# ============================================================================

check_and_block \
    '(^|;|&&)\s*sed\s' \
    'Edit tool' \
    'Use Edit tool for file modifications. It provides safe string replacement with context.'

check_and_block \
    '\|\s*sed\s' \
    'Edit tool' \
    'Use Edit tool for text transformations instead of piping to sed.'

check_and_block \
    'sed\s+-i' \
    'Edit tool' \
    'Use Edit tool for in-place file editing. It tracks changes and handles conflicts.'

check_and_block \
    '(^|;|&&)\s*awk\s' \
    'Edit tool' \
    'Use Edit tool for file transformations.'

check_and_block \
    '\|\s*awk\s' \
    'Edit tool' \
    'Use Edit tool for text transformations instead of piping to awk.'

check_and_block \
    'perl\s+-i' \
    'Edit tool' \
    'Use Edit tool for in-place file editing.'

# ============================================================================
# DIRECTORY LISTING
# ============================================================================
# ls remains allowed. In classic mode we warn once, suggesting the Glob tool.
# In new mode there is no Glob tool to suggest — stay silent.

if [[ "$NTE_MODE" == "classic" ]]; then
    warn_about_native \
        '(^|;|&&)\s*ls(\s+-(a|A|R|r|t|S|1)+)*(\s+[^-][^\s]*)?(\s*)$' \
        'Glob tool' \
        'For simple file listing, Glob tool with "*" pattern may be faster and needs no approval.'
fi

if [[ -z "${NTE_LOGGED:-}" ]]; then
    nte_log "$NTE_MODE" "allow" "$command"
fi
exit 0
