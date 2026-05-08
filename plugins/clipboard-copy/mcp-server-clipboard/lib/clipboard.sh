#!/usr/bin/env bash
# Cross-platform clipboard tools for the clipboard-copy MCP server.
# Tools: clipboard_copy, clipboard_copy_file

# Detect the best available clipboard backend for the current environment.
# Echoes one of: pbcopy, wl-copy, xclip, xsel, clip-exe, clip, osc52
_clipboard_detect_backend() {
    case "$(uname -s)" in
        Darwin)
            command -v pbcopy >/dev/null 2>&1 && { echo "pbcopy"; return 0; }
            ;;
        Linux)
            # WSL exposes Windows clip.exe on PATH
            if command -v clip.exe >/dev/null 2>&1; then
                echo "clip-exe"; return 0
            fi
            if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
                echo "wl-copy"; return 0
            fi
            if [[ -n "${DISPLAY:-}" ]]; then
                command -v xclip >/dev/null 2>&1 && { echo "xclip"; return 0; }
                command -v xsel  >/dev/null 2>&1 && { echo "xsel";  return 0; }
            fi
            # Headless Linux without DISPLAY/WAYLAND_DISPLAY: still try wl-copy/xclip/xsel
            # in case one is installed and configured for the current session.
            command -v wl-copy >/dev/null 2>&1 && { echo "wl-copy"; return 0; }
            command -v xclip   >/dev/null 2>&1 && { echo "xclip";   return 0; }
            command -v xsel    >/dev/null 2>&1 && { echo "xsel";    return 0; }
            ;;
        CYGWIN*|MINGW*|MSYS*)
            command -v clip >/dev/null 2>&1 && { echo "clip"; return 0; }
            ;;
    esac

    echo "osc52"
}

# Base64-encode stdin without line wrapping. Handles GNU base64 (-w 0),
# BSD/macOS base64 (no -w but emits a single line for small input — strip newlines),
# and falls back to openssl when base64 is missing.
_clipboard_b64() {
    if command -v base64 >/dev/null 2>&1; then
        if base64 -w 0 </dev/null >/dev/null 2>&1; then
            base64 -w 0
        else
            base64 | tr -d '\r\n'
        fi
    elif command -v openssl >/dev/null 2>&1; then
        openssl base64 -A
    else
        echo "Error: neither base64 nor openssl available for OSC 52 encoding" >&2
        return 1
    fi
}

# Read stdin and forward it to the given backend.
# For OSC 52, buffers stdin, base64-encodes, and writes the escape sequence
# to /dev/tty (not stdout) so it stays out of the MCP JSON-RPC channel.
# Wraps the sequence in a tmux DCS pass-through when $TMUX is set.
_clipboard_send_stdin() {
    local backend="$1"
    case "${backend}" in
        pbcopy)   pbcopy ;;
        wl-copy)  wl-copy ;;
        xclip)    xclip -selection clipboard ;;
        xsel)     xsel --clipboard --input ;;
        clip-exe) clip.exe ;;
        clip)     clip ;;
        osc52)
            local b64
            b64=$(_clipboard_b64) || return 1
            local seq
            if [[ -n "${TMUX:-}" ]]; then
                seq=$'\ePtmux;\e\e]52;c;'"${b64}"$'\a\e\\'
            else
                seq=$'\e]52;c;'"${b64}"$'\a'
            fi
            if [[ ! -w /dev/tty ]]; then
                echo "Error: /dev/tty is not writable; OSC 52 fallback cannot reach the terminal" >&2
                return 1
            fi
            printf '%s' "${seq}" >/dev/tty
            ;;
    esac
}

# Copy text to the system clipboard using the auto-detected backend.
# Args: $1 = JSON arguments object with required '.text'
tool_clipboard_copy() {
    local args="$1"

    local text
    text=$(echo "${args}" | jq -r '.text // empty')

    if [[ -z "${text}" ]]; then
        echo "Error: text is required and must be a non-empty string"
        return 1
    fi

    local backend
    backend=$(_clipboard_detect_backend)

    log "INFO" "clipboard_copy: backend=${backend} bytes=${#text}"

    printf '%s' "${text}" | _clipboard_send_stdin "${backend}" || return 1
    echo "Copied ${#text} bytes to clipboard via ${backend}"
}

# Copy the contents of a file at an absolute path to the system clipboard.
# Args: $1 = JSON arguments object with required '.path' (absolute filesystem path)
tool_clipboard_copy_file() {
    local args="$1"

    local path
    path=$(echo "${args}" | jq -r '.path // empty')

    if [[ -z "${path}" ]]; then
        echo "Error: path is required"
        return 1
    fi
    if [[ "${path}" != /* ]]; then
        echo "Error: path must be absolute (start with '/'), got: ${path}"
        return 1
    fi
    if [[ ! -e "${path}" ]]; then
        echo "Error: file not found: ${path}"
        return 1
    fi
    if [[ ! -f "${path}" ]]; then
        echo "Error: not a regular file: ${path}"
        return 1
    fi
    if [[ ! -r "${path}" ]]; then
        echo "Error: file not readable: ${path}"
        return 1
    fi

    local backend size
    backend=$(_clipboard_detect_backend)
    size=$(wc -c < "${path}" | tr -d ' ')

    log "INFO" "clipboard_copy_file: backend=${backend} path=${path} bytes=${size}"

    _clipboard_send_stdin "${backend}" < "${path}" || return 1
    echo "Copied ${size} bytes from ${path} to clipboard via ${backend}"
}
