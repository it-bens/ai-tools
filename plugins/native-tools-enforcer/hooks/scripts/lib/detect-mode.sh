#!/bin/bash
# native-tools-enforcer: mode-detection library
# =============================================
# Exposes nte_resolve_mode() which sets a global NTE_MODE variable to
# one of: new, classic, pass.
#
# Inputs consulted (in cascade order):
#   1. NATIVE_TOOLS_ENFORCER_FORCE_NEW env var (any non-empty → new)
#   2. uname -s
#   3. command -v bfs && command -v ugrep
#
# No file I/O. No logging. Pure function over probed inputs.

nte_resolve_mode() {
    # 1. Env var override
    if [[ -n "${NATIVE_TOOLS_ENFORCER_FORCE_NEW:-}" ]]; then
        NTE_MODE=new
        return 0
    fi

    # 2. OS detection
    local os
    os="$(uname -s 2>/dev/null || echo unknown)"

    case "$os" in
        CYGWIN*|MINGW*|MSYS*)
            NTE_MODE=classic
            return 0
            ;;
        Darwin|Linux)
            if command -v bfs >/dev/null 2>&1 \
               && command -v ugrep >/dev/null 2>&1; then
                NTE_MODE=new
            else
                NTE_MODE=pass
            fi
            return 0
            ;;
        *)
            NTE_MODE=pass
            return 0
            ;;
    esac
}
