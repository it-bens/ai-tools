#!/bin/bash
# Shared functions for the clipboard-copy PreToolUse hook.
#
# Globals set by parse_hook_input:
#   COMMAND - The bash command being checked

# Read the JSON hook input from stdin and extract .tool_input.command.
# Exits 0 (allow) when the command field is empty so we never block on
# malformed/empty input.
parse_hook_input() {
    local input
    input=$(cat)
    COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')
    if [[ -z "$COMMAND" ]]; then
        exit 0
    fi
}

# Block the command with a formatted hint and exit 2 (deny).
# Args:
#   $1 = MCP tool to suggest (e.g. "clipboard_copy")
#   $2 = hint shown to the model
block_clipboard() {
    local tool="$1"
    local hint="$2"

    {
        echo "Use the ${tool} MCP tool instead."
        echo ""
        echo "Bad command detected: ${COMMAND}"
        echo ""
        echo "${hint}"
        echo ""
        echo "The clipboard-copy MCP tool:"
        echo "  - Auto-detects the right backend per OS (pbcopy / wl-copy / xclip / xsel / clip.exe / clip)"
        echo "  - Falls back to OSC 52 over SSH and in headless environments"
    } >&2
    exit 2
}
