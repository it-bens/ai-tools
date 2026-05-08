#!/usr/bin/env bats
# bats file_tags=clipboard-copy,detect

load 'test_helper/common_setup'
load 'test_helper/backend_setup'

setup() {
    backend_setup_init
    # _clipboard_detect_backend doesn't call log, but defining a no-op
    # keeps the lib safe to source standalone if other helpers are added later.
    log() { :; }
    source "${LIB_DIR}/clipboard.sh"
}

teardown() {
    backend_setup_cleanup
}

# =============================================================================
# macOS
# =============================================================================

# bats test_tags=detect,darwin
@test "Darwin with pbcopy → pbcopy" {
    backend_set os=Darwin pbcopy=1
    run _clipboard_detect_backend
    assert_success
    assert_output "pbcopy"
}

# bats test_tags=detect,darwin
@test "Darwin without pbcopy → osc52" {
    backend_set os=Darwin pbcopy=0
    run _clipboard_detect_backend
    assert_success
    assert_output "osc52"
}

# =============================================================================
# Linux — WSL takes priority over Wayland/X11
# =============================================================================

# bats test_tags=detect,linux,wsl
@test "Linux with clip.exe (WSL) wins over wl-copy and xclip" {
    backend_set os=Linux clip_exe=1 wl_copy=1 xclip=1 wayland=1 display=1
    run _clipboard_detect_backend
    assert_success
    assert_output "clip-exe"
}

# bats test_tags=detect,linux,wayland
@test "Linux Wayland with wl-copy → wl-copy" {
    backend_set os=Linux wl_copy=1 wayland=1
    run _clipboard_detect_backend
    assert_success
    assert_output "wl-copy"
}

# bats test_tags=detect,linux,wayland
@test "Linux WAYLAND_DISPLAY set but no wl-copy → falls through to next branch" {
    # Without DISPLAY set and without wl-copy, the cascade falls through
    # to the headless fallback section, then to osc52.
    backend_set os=Linux wayland=1
    run _clipboard_detect_backend
    assert_success
    assert_output "osc52"
}

# bats test_tags=detect,linux,x11
@test "Linux X11 prefers xclip over xsel" {
    backend_set os=Linux xclip=1 xsel=1 display=1
    run _clipboard_detect_backend
    assert_success
    assert_output "xclip"
}

# bats test_tags=detect,linux,x11
@test "Linux X11 falls back to xsel when xclip is missing" {
    backend_set os=Linux xsel=1 display=1
    run _clipboard_detect_backend
    assert_success
    assert_output "xsel"
}

# bats test_tags=detect,linux,headless
@test "Headless Linux still picks wl-copy when present" {
    # No WAYLAND_DISPLAY, no DISPLAY — but wl-copy installed.
    backend_set os=Linux wl_copy=1
    run _clipboard_detect_backend
    assert_success
    assert_output "wl-copy"
}

# bats test_tags=detect,linux,headless
@test "Headless Linux with no clipboard utility → osc52" {
    backend_set os=Linux
    run _clipboard_detect_backend
    assert_success
    assert_output "osc52"
}

# =============================================================================
# Windows-style shells
# =============================================================================

# bats test_tags=detect,windows
@test "CYGWIN with clip → clip" {
    backend_set os=CYGWIN_NT-10.0 clip=1
    run _clipboard_detect_backend
    assert_success
    assert_output "clip"
}

# bats test_tags=detect,windows
@test "MINGW with clip → clip" {
    backend_set os=MINGW64_NT-10.0 clip=1
    run _clipboard_detect_backend
    assert_success
    assert_output "clip"
}

# bats test_tags=detect,windows
@test "MSYS without clip → osc52" {
    backend_set os=MSYS_NT-10.0 clip=0
    run _clipboard_detect_backend
    assert_success
    assert_output "osc52"
}

# =============================================================================
# Unknown / fallback
# =============================================================================

# bats test_tags=detect,fallback
@test "unknown OS → osc52" {
    backend_set os=Plan9
    run _clipboard_detect_backend
    assert_success
    assert_output "osc52"
}
