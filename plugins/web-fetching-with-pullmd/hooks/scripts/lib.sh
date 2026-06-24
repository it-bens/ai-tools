#!/bin/bash
# Shared functions for the pullmd hook scripts.
# Sourced by pre-webfetch.sh and session-start.sh — not executed directly.
#
# Naming convention:
#   UPPERCASE  — env vars (CLAUDE_PLUGIN_DATA), config globals (PULLMD_*), SCRIPT_DIR
#   lowercase  — script-local and function-local variables

# --- Config defaults ---
# instance has NO default: when unset everywhere, the WebFetch hook is a no-op.
PULLMD_DEFAULTS='{"enabled":true,"mcp_tool":"mcp__pullmd__read_url","escape_after":2,"allow_hosts":[],"debug":false}'

# Hosts always allowed through WebFetch (never redirected to PullMD).
# PullMD is the wrong tool for GitHub — these stay on WebFetch / gh.
PULLMD_BUILTIN_ALLOW=$'github.com\nwww.github.com\nraw.githubusercontent.com\ngist.github.com'

# Globals set by load_config:
#   PULLMD_INSTANCE       base URL of the PullMD service ("" = unconfigured)
#   PULLMD_ENABLED        "true" | "false"
#   PULLMD_MCP_TOOL       MCP tool name to recommend in deny messages
#   PULLMD_ESCAPE_AFTER   integer ≥ 1 — allow the Nth attempt of a URL through
#   PULLMD_ALLOW_HOSTS    newline-separated extra allowed hosts (lowercased)
#   PULLMD_DEBUG          "true" | "false"

# Read a JSON file's contents, or "{}" if missing/unreadable/invalid.
# Args: $1 = path (may be empty)
read_json_or_empty() {
    local file="$1"
    if [[ -n "$file" && -f "$file" ]] && jq empty "$file" 2>/dev/null; then
        cat -- "$file"
    else
        printf '%s' '{}'
    fi
}

# Resolve config from user level + project level, project overriding user.
# Args: $1 = project directory (CLAUDE_PROJECT_DIR or cwd; may be empty)
# Sets the PULLMD_* globals.
load_config() {
    local project_dir="$1"
    local user_cfg="${HOME}/.claude/pullmd.json"
    local project_cfg=""

    if [[ -n "$project_dir" ]]; then
        local loc
        for loc in ".claude/pullmd.json" "pullmd.json"; do
            if [[ -f "${project_dir}/${loc}" ]]; then
                project_cfg="${project_dir}/${loc}"
                break
            fi
        done
    fi

    local user_json project_json merged
    user_json=$(read_json_or_empty "$user_cfg")
    project_json=$(read_json_or_empty "$project_cfg")
    # defaults * user * project — later operands win, per key (project precedence).
    merged=$(jq -n \
        --argjson d "$PULLMD_DEFAULTS" \
        --argjson u "$user_json" \
        --argjson p "$project_json" \
        '$d * $u * $p' 2>/dev/null) || merged="$PULLMD_DEFAULTS"

    # PULLMD_* globals are consumed by the scripts that source this file.
    # shellcheck disable=SC2034
    {
        IFS= read -r PULLMD_INSTANCE
        IFS= read -r PULLMD_ENABLED
        IFS= read -r PULLMD_MCP_TOOL
        IFS= read -r PULLMD_ESCAPE_AFTER
        IFS= read -r PULLMD_DEBUG
    } < <(printf '%s' "$merged" | jq -r '
        (.instance // ""),
        (if .enabled == false then "false" else "true" end),
        (.mcp_tool // "mcp__pullmd__read_url"),
        (.escape_after // 2),
        (if .debug == true then "true" else "false" end)
    ')

    PULLMD_ALLOW_HOSTS=$(printf '%s' "$merged" | jq -r '(.allow_hosts // [])[] | ascii_downcase' 2>/dev/null || true)

    # Coerce escape_after to a positive integer.
    if ! [[ "$PULLMD_ESCAPE_AFTER" =~ ^[0-9]+$ ]] || [[ "$PULLMD_ESCAPE_AFTER" -lt 1 ]]; then
        PULLMD_ESCAPE_AFTER=2
    fi
}

# --- Debug logging ---
debug_log() {
    if [[ "${PULLMD_DEBUG:-false}" == "true" ]]; then
        printf '[pullmd] %s\n' "$1" >&2
    fi
}

# --- MCP server registration check ---

# Derive the MCP server name from a tool name of the form mcp__<server>__<tool>.
# Prints the server name, or empty when the tool name is not in that form.
# Args: $1 = tool name
mcp_server_from_tool() {
    local tool="$1" rest
    case "$tool" in
        mcp__*__*)
            rest="${tool#mcp__}"
            printf '%s' "${rest%%__*}"
            ;;
        *)
            printf '%s' ''
            ;;
    esac
}

# Best-effort check: is an MCP server named $1 registered in the standard
# Claude Code config locations? Checks ~/.claude.json (top-level mcpServers and
# every projects[].mcpServers) and <project_dir>/.mcp.json. Returns 0 if found,
# 1 otherwise. Detects configured-ness only — NOT whether the server is
# connected or authenticated (an OAuth server can be registered yet unauthed).
# Args: $1 = server name, $2 = project directory (may be empty)
mcp_server_configured() {
    local server="$1" project_dir="$2" user_cfg project_mcp
    if [[ -z "$server" ]]; then
        return 1
    fi

    user_cfg="${HOME}/.claude.json"
    if [[ -f "$user_cfg" ]] && jq -e --arg n "$server" '
        ([ .mcpServers // {} ] + [ (.projects // {}) | to_entries[]? | .value.mcpServers // {} ])
        | map(has($n)) | any
    ' "$user_cfg" >/dev/null 2>&1; then
        return 0
    fi

    project_mcp="${project_dir%/}/.mcp.json"
    if [[ -n "$project_dir" && -f "$project_mcp" ]] && jq -e --arg n "$server" '
        (.mcpServers // {}) | has($n)
    ' "$project_mcp" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# --- Host extraction ---
# Extract the lowercased host from a URL (strips scheme, userinfo, path, query,
# fragment, and port). Tolerates URLs with no scheme.
# Args: $1 = url
extract_host() {
    local url="$1" host
    host="${url#*://}"   # strip scheme
    host="${host%%/*}"   # strip path/query/fragment
    host="${host%%\?*}"  # strip query when there is no path
    host="${host%%#*}"   # strip fragment when there is no path
    host="${host##*@}"   # strip userinfo
    host="${host%%:*}"   # strip port
    printf '%s' "$host" | tr '[:upper:]' '[:lower:]'
}

# Test whether a host is allowed through WebFetch (builtin allow + configured
# allow_hosts). Matches exact host or any subdomain of an allowed host.
# Args: $1 = host (lowercased)
# Returns 0 if allowed, 1 otherwise.
host_allowed() {
    local host="$1" entry
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        if [[ "$host" == "$entry" || "$host" == *".$entry" ]]; then
            return 0
        fi
    done < <(printf '%s\n%s\n' "$PULLMD_BUILTIN_ALLOW" "${PULLMD_ALLOW_HOSTS:-}")
    return 1
}

# --- Escape-hatch state I/O ---
# State lives at ${CLAUDE_PLUGIN_DATA}/<session_id>/webfetch-attempts.json
# shape: {"urls": {"<url>": <attempt-count>}}

# Args: $1 = session_id
state_path() {
    printf '%s' "${CLAUDE_PLUGIN_DATA}/${1}/webfetch-attempts.json"
}

# Args: $1 = session_id
session_dir() {
    printf '%s' "${CLAUDE_PLUGIN_DATA}/${1}"
}

# Load state JSON, or an empty tracker if missing/corrupt.
# Args: $1 = path
load_state() {
    local path="$1"
    if [[ -f "$path" ]] && jq empty "$path" 2>/dev/null; then
        cat -- "$path"
    else
        printf '%s' '{"urls":{}}'
    fi
}

# Save state JSON atomically via tmp + mv.
# Args: $1 = path, $2 = json
save_state() {
    local path="$1" json="$2" dir tmp
    dir="$(dirname -- "$path")"
    mkdir -p "$dir"
    tmp=$(mktemp "${dir}/.pullmd-tmp.XXXXXX")
    printf '%s\n' "$json" > "$tmp" && mv -- "$tmp" "$path"
}
