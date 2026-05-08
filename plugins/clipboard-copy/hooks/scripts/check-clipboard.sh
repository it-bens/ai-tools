#!/bin/bash
# Claude Code Hook: clipboard-copy MCP enforcer
# ==============================================
# Blocks native clipboard-write Bash commands in favor of the
# clipboard_copy / clipboard_copy_file MCP tools.
#
# Read-only invocations of xclip/xsel (-o / --output) are NOT blocked —
# this hook targets only writes to the system clipboard. pbpaste,
# wl-paste, and similar paste utilities are likewise not touched.
#
# Exit codes:
#   0 - command allowed
#   2 - command blocked (message shown to Claude)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

parse_hook_input

HINT="Use clipboard_copy with the text directly, or clipboard_copy_file with an absolute path when the content is already on disk."

# pbcopy (macOS) — always writes to clipboard.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*pbcopy(\s|$)'; then
    block_clipboard "clipboard_copy" "$HINT"
fi

# wl-copy (Linux Wayland) — always writes to clipboard.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*wl-copy(\s|$)'; then
    block_clipboard "clipboard_copy" "$HINT"
fi

# clip.exe (WSL) — always writes to clipboard.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*clip\.exe(\s|$)'; then
    block_clipboard "clipboard_copy" "$HINT"
fi

# clip (Windows Cygwin/MSYS) — always writes to clipboard.
# Anchored to the start of a command segment to avoid matching unrelated
# binaries like 'clipper' or paths containing 'clip-'.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*clip(\s|$)'; then
    block_clipboard "clipboard_copy" "$HINT"
fi

# xclip — defaults to writing the PRIMARY/clipboard selection from stdin.
# Allow only when -o or -out is present (paste mode). [^|;&]* keeps the
# search within this command segment so a later 'xsel -o' can't excuse
# an earlier 'xclip -i'.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*xclip(\s|$)'; then
    if ! echo "$COMMAND" | grep -qE 'xclip[^|;&]*\s-o(ut)?(\s|$)'; then
        block_clipboard "clipboard_copy" \
            "$HINT (xclip -o / -out for paste is allowed.)"
    fi
fi

# xsel — defaults to writing PRIMARY from stdin.
# Allow only when -o or --output is present (paste mode).
if echo "$COMMAND" | grep -qE '(^|;|&&|\|)\s*xsel(\s|$)'; then
    if ! echo "$COMMAND" | grep -qE 'xsel[^|;&]*\s(-o|--output)(\s|$)'; then
        block_clipboard "clipboard_copy" \
            "$HINT (xsel -o / --output for paste is allowed.)"
    fi
fi

exit 0
