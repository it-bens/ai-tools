#!/bin/bash
# Mock helpers for clipboard backend-detection tests.
# =====================================================
# Replaces PATH with the mock directory ONLY so that `command -v <util>`
# in the lib sees exactly what the test stubbed and nothing more. The
# helper itself captures absolute paths to coreutils at init time so it
# can still write stubs without relying on PATH.
#
# Usage in a .bats setup():
#     load 'test_helper/common_setup'
#     load 'test_helper/backend_setup'
#     setup() { backend_setup_init; ... }
#     teardown() { backend_setup_cleanup; }

backend_setup_init() {
    BACKEND_MOCK_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/clipboard_mock.XXXXXX")"
    BACKEND_ORIG_PATH="$PATH"
    # Capture absolute paths before PATH is locked down.
    BACKEND_CAT="$(command -v cat)"
    BACKEND_CHMOD="$(command -v chmod)"
    BACKEND_RM="$(command -v rm)"
    BACKEND_UNAME="$(command -v uname)"
    export BACKEND_MOCK_DIR BACKEND_ORIG_PATH \
        BACKEND_CAT BACKEND_CHMOD BACKEND_RM BACKEND_UNAME

    # PATH is the mock dir only. Anything the lib looks up via
    # `command -v` is exactly what we stubbed.
    export PATH="${BACKEND_MOCK_DIR}"
    unset WAYLAND_DISPLAY DISPLAY TMUX
}

backend_setup_cleanup() {
    if [[ -n "${BACKEND_MOCK_DIR:-}" && -d "${BACKEND_MOCK_DIR}" ]]; then
        "${BACKEND_RM}" -rf -- "${BACKEND_MOCK_DIR}"
    fi
    if [[ -n "${BACKEND_ORIG_PATH:-}" ]]; then
        export PATH="${BACKEND_ORIG_PATH}"
    fi
    unset WAYLAND_DISPLAY DISPLAY TMUX
}

# Configure mocks. Positional key=value args (defaults all 0 / unset):
#   os=<Darwin|Linux|CYGWIN_NT-10.0|MINGW64_NT-10.0|MSYS_NT-10.0|UnknownOS>
#   pbcopy=<0|1>      wl_copy=<0|1>      xclip=<0|1>      xsel=<0|1>
#   clip_exe=<0|1>    clip=<0|1>
#   wayland=<0|1>     display=<0|1>
backend_set() {
    local os="" pbcopy=0 wl_copy=0 xclip=0 xsel=0 clip_exe=0 clip=0
    local wayland=0 display=0
    local arg
    for arg in "$@"; do
        case "$arg" in
            os=*)        os="${arg#os=}" ;;
            pbcopy=*)    pbcopy="${arg#pbcopy=}" ;;
            wl_copy=*)   wl_copy="${arg#wl_copy=}" ;;
            xclip=*)     xclip="${arg#xclip=}" ;;
            xsel=*)      xsel="${arg#xsel=}" ;;
            clip_exe=*)  clip_exe="${arg#clip_exe=}" ;;
            clip=*)      clip="${arg#clip=}" ;;
            wayland=*)   wayland="${arg#wayland=}" ;;
            display=*)   display="${arg#display=}" ;;
            *) echo "backend_set: unknown arg: $arg" >&2; return 1 ;;
        esac
    done

    if [[ -n "$os" ]]; then
        "${BACKEND_CAT}" > "${BACKEND_MOCK_DIR}/uname" <<EOF
#!/bin/bash
if [[ \$# -eq 0 || "\$1" == "-s" ]]; then
    printf '%s\n' '${os}'
else
    exec "${BACKEND_UNAME}" "\$@"
fi
EOF
        "${BACKEND_CHMOD}" +x "${BACKEND_MOCK_DIR}/uname"
    fi

    _backend_stub() {
        local name="$1" enable="$2"
        if [[ "$enable" == "1" ]]; then
            printf '#!/bin/bash\nexit 0\n' > "${BACKEND_MOCK_DIR}/${name}"
            "${BACKEND_CHMOD}" +x "${BACKEND_MOCK_DIR}/${name}"
        else
            "${BACKEND_RM}" -f "${BACKEND_MOCK_DIR}/${name}"
        fi
    }

    _backend_stub pbcopy   "$pbcopy"
    _backend_stub wl-copy  "$wl_copy"
    _backend_stub xclip    "$xclip"
    _backend_stub xsel     "$xsel"
    _backend_stub clip.exe "$clip_exe"
    _backend_stub clip     "$clip"

    if [[ "$wayland" == "1" ]]; then
        export WAYLAND_DISPLAY="wayland-0"
    else
        unset WAYLAND_DISPLAY
    fi
    if [[ "$display" == "1" ]]; then
        export DISPLAY=":0"
    else
        unset DISPLAY
    fi
}
