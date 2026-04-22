#!/bin/bash
# Mock helpers for mode-detection tests
# =====================================
# Usage in a .bats setup():
#     load 'test_helper/common_setup'
#     load 'test_helper/mode_setup'
#     setup() { mode_setup_init; }
#     teardown() { mode_setup_cleanup; }
#
# Then in a test:
#     mode_set os=Darwin bfs=1 ugrep=1 force_new=0

mode_setup_init() {
    MODE_MOCK_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/mode_mock.XXXXXX")"
    export MODE_MOCK_DIR
    MODE_ORIG_PATH="$PATH"
    export MODE_ORIG_PATH
    # Replace PATH (do not prepend) so that absence of a stub for bfs/ugrep
    # really means absence. Prepending leaks system binaries like
    # /opt/homebrew/bin/bfs past `bfs=0`, defeating the probe tests.
    # Minimal PATH covers what the library (uname) and helper (cat/rm/chmod/
    # mktemp) need.
    export PATH="${MODE_MOCK_DIR}:/usr/bin:/bin:/usr/sbin:/sbin"
}

mode_setup_cleanup() {
    if [[ -n "${MODE_MOCK_DIR:-}" && -d "${MODE_MOCK_DIR}" ]]; then
        rm -rf -- "${MODE_MOCK_DIR}"
    fi
    if [[ -n "${MODE_ORIG_PATH:-}" ]]; then
        export PATH="${MODE_ORIG_PATH}"
    fi
    unset NATIVE_TOOLS_ENFORCER_FORCE_NEW
    unset NATIVE_TOOLS_ENFORCER_DEBUG
}

# Configure mocks. Positional-style key=value args:
#   os=<Darwin|Linux|MINGW64_NT-10.0|CYGWIN_NT-10.0|UnknownOS>
#   bfs=<0|1>            (1 creates a stub on PATH)
#   ugrep=<0|1>
#   force_new=<0|1>      (1 sets NATIVE_TOOLS_ENFORCER_FORCE_NEW=1)
#   debug=<0|1>          (1 sets NATIVE_TOOLS_ENFORCER_DEBUG=1)
#   pkg_manager=<brew|apt|dnf|pacman|none>  (stubs the matching binary;
#                                            clears all others; default: none)
mode_set() {
    local os="" bfs="0" ugrep="0" force_new="0" debug="0" pkg_manager="none"
    local arg
    for arg in "$@"; do
        case "$arg" in
            os=*)          os="${arg#os=}" ;;
            bfs=*)         bfs="${arg#bfs=}" ;;
            ugrep=*)       ugrep="${arg#ugrep=}" ;;
            force_new=*)   force_new="${arg#force_new=}" ;;
            debug=*)       debug="${arg#debug=}" ;;
            pkg_manager=*) pkg_manager="${arg#pkg_manager=}" ;;
            *) echo "mode_set: unknown arg: $arg" >&2; return 1 ;;
        esac
    done

    # Stub uname if OS specified
    if [[ -n "$os" ]]; then
        cat > "${MODE_MOCK_DIR}/uname" <<EOF
#!/bin/bash
# If -s (or no args), print the OS; otherwise pass through.
if [[ \$# -eq 0 || "\$1" == "-s" ]]; then
    printf '%s\n' '${os}'
else
    exec /usr/bin/uname "\$@"
fi
EOF
        chmod +x "${MODE_MOCK_DIR}/uname"
    fi

    # Stub bfs / ugrep
    if [[ "$bfs" == "1" ]]; then
        printf '#!/bin/bash\nexit 0\n' > "${MODE_MOCK_DIR}/bfs"
        chmod +x "${MODE_MOCK_DIR}/bfs"
    else
        rm -f "${MODE_MOCK_DIR}/bfs"
    fi

    if [[ "$ugrep" == "1" ]]; then
        printf '#!/bin/bash\nexit 0\n' > "${MODE_MOCK_DIR}/ugrep"
        chmod +x "${MODE_MOCK_DIR}/ugrep"
    else
        rm -f "${MODE_MOCK_DIR}/ugrep"
    fi

    if [[ "$force_new" == "1" ]]; then
        export NATIVE_TOOLS_ENFORCER_FORCE_NEW=1
    else
        unset NATIVE_TOOLS_ENFORCER_FORCE_NEW
    fi

    if [[ "$debug" == "1" ]]; then
        export NATIVE_TOOLS_ENFORCER_DEBUG=1
    else
        unset NATIVE_TOOLS_ENFORCER_DEBUG
    fi

    # Stub package manager (clear all first, then create the chosen one).
    # probe.sh detects via: brew | apt-get | dnf | pacman
    rm -f \
        "${MODE_MOCK_DIR}/brew" \
        "${MODE_MOCK_DIR}/apt-get" \
        "${MODE_MOCK_DIR}/dnf" \
        "${MODE_MOCK_DIR}/pacman"
    local pm_bin=""
    case "$pkg_manager" in
        brew)   pm_bin="brew" ;;
        apt)    pm_bin="apt-get" ;;
        dnf)    pm_bin="dnf" ;;
        pacman) pm_bin="pacman" ;;
        none|"") pm_bin="" ;;
        *)
            echo "mode_set: unknown pkg_manager: $pkg_manager" >&2
            return 1
            ;;
    esac
    if [[ -n "$pm_bin" ]]; then
        printf '#!/bin/bash\nexit 0\n' > "${MODE_MOCK_DIR}/${pm_bin}"
        chmod +x "${MODE_MOCK_DIR}/${pm_bin}"
    fi
}
