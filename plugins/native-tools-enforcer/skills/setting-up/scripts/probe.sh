#!/bin/bash
# native-tools-enforcer setup skill — environment probe.
# ======================================================
# Emits a single JSON line describing:
#   - detected OS
#   - package-manager availability
#   - bfs/ugrep availability
#   - current env_var setting from ~/.claude/settings.json
#   - settings.json existence
#   - resolved mode (via shared detect-mode.sh library)
#
# Exits 0 on success, 1 on catastrophic failure (jq missing).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="${SCRIPT_DIR}/../../../hooks/scripts/lib/detect-mode.sh"

if ! command -v jq >/dev/null 2>&1; then
    printf '{"error":"jq not found on PATH"}\n'
    exit 1
fi

if [[ ! -f "$LIB_PATH" ]]; then
    printf '{"error":"detect-mode.sh not found at %s"}\n' "$LIB_PATH"
    exit 1
fi

# OS normalization
raw_os="$(uname -s 2>/dev/null || echo unknown)"
case "$raw_os" in
    Darwin)                  os="macos" ;;
    Linux)                   os="linux" ;;
    CYGWIN*|MINGW*|MSYS*)    os="windows" ;;
    *)                       os="unknown" ;;
esac

# Package manager detection (priority: brew → apt-get → dnf → pacman)
if command -v brew >/dev/null 2>&1; then
    pkg_manager="brew"
elif command -v apt-get >/dev/null 2>&1; then
    pkg_manager="apt"
elif command -v dnf >/dev/null 2>&1; then
    pkg_manager="dnf"
elif command -v pacman >/dev/null 2>&1; then
    pkg_manager="pacman"
else
    pkg_manager="none"
fi

# Binary presence
command -v bfs   >/dev/null 2>&1 && bfs_present=true   || bfs_present=false
command -v ugrep >/dev/null 2>&1 && ugrep_present=true || ugrep_present=false

# Settings.json state
settings_file="${HOME}/.claude/settings.json"
if [[ -f "$settings_file" ]]; then
    settings_file_exists=true
    env_var_value="$(jq -r '.env.NATIVE_TOOLS_ENFORCER_FORCE_NEW // empty' "$settings_file" 2>/dev/null || echo "")"
    if [[ -n "$env_var_value" ]]; then
        env_var_set=true
    else
        env_var_set=false
    fi
else
    settings_file_exists=false
    env_var_value=""
    env_var_set=false
fi

# Resolve mode via shared library (single source of truth).
# Temporarily export the env var state so nte_resolve_mode sees what the hook
# would see at runtime.
if [[ "$env_var_set" == "true" ]]; then
    export NATIVE_TOOLS_ENFORCER_FORCE_NEW="$env_var_value"
else
    unset NATIVE_TOOLS_ENFORCER_FORCE_NEW
fi

# shellcheck source=../../../hooks/scripts/lib/detect-mode.sh
source "$LIB_PATH"
NTE_MODE=""
nte_resolve_mode
resolved_mode="$NTE_MODE"

# Emit JSON (compact, single line — see spec §7.1)
jq -nc \
    --arg os "$os" \
    --arg pkg_manager "$pkg_manager" \
    --argjson bfs_present "$bfs_present" \
    --argjson ugrep_present "$ugrep_present" \
    --argjson env_var_set "$env_var_set" \
    --arg env_var_value "$env_var_value" \
    --arg settings_file "$settings_file" \
    --argjson settings_file_exists "$settings_file_exists" \
    --arg resolved_mode "$resolved_mode" \
    '{
        os: $os,
        pkg_manager: $pkg_manager,
        bfs_present: $bfs_present,
        ugrep_present: $ugrep_present,
        env_var_set: $env_var_set,
        env_var_value: $env_var_value,
        settings_file: $settings_file,
        settings_file_exists: $settings_file_exists,
        resolved_mode: $resolved_mode
    }'
