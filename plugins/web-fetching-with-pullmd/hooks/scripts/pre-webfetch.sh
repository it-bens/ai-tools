#!/bin/bash
# PreToolUse WebFetch hook: redirect WebFetch of normal pages to the PullMD MCP
# tool for clean Markdown. Allows the configured PullMD instance host, GitHub,
# and configured allow_hosts. A per-URL escape hatch lets a repeated attempt
# through after `escape_after` tries (for JSON APIs or when PullMD can't help).
#
# No-op when disabled (enabled: false). Fails hard — blocks the WebFetch — when
# enabled but no PullMD instance is configured anywhere (user or project
# pullmd.json). The hook only runs when the plugin was deliberately activated,
# so a missing instance is a setup error, not a reason to fall through.
#
# Exit codes:
#   0 - Allow the WebFetch
#   2 - Block the WebFetch (deny message on stderr)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

input=$(cat)

{
    IFS= read -r session_id
    IFS= read -r cwd
    IFS= read -r url
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.cwd // ""),
    (.tool_input.url // "")
')

if [[ -z "$url" ]]; then
    exit 0
fi

load_config "${CLAUDE_PROJECT_DIR:-$cwd}"

# Explicit opt-out: master switch off → do nothing.
if [[ "$PULLMD_ENABLED" != "true" ]]; then
    debug_log "ALLOW ${url} — disabled (enabled=${PULLMD_ENABLED})"
    exit 0
fi

# Enabled but no instance configured anywhere → fail hard. The hook only runs
# when the plugin was deliberately activated, so a missing instance is a setup
# error, not a reason to silently fall back to WebFetch.
if [[ -z "$PULLMD_INSTANCE" ]]; then
    debug_log "DENY ${url} — no PullMD instance configured"
    {
        printf '🤖 PullMD: this plugin is active but no PullMD instance is configured.\n'
        printf '\n'
        printf 'Set "instance" in a pullmd.json — user level (~/.claude/pullmd.json) or\n'
        printf 'project level (<project>/.claude/pullmd.json or <project>/pullmd.json):\n'
        printf '\n'
        printf '    { "instance": "https://pullmd.example.com" }\n'
        printf '\n'
        printf 'Then register the PullMD MCP server so its read_url tool is available\n'
        printf '(see the plugin README, MCP Server Setup). To opt out instead, set\n'
        printf '"enabled": false in pullmd.json.\n'
    } >&2
    exit 2
fi

host=$(extract_host "$url")
instance_host=$(extract_host "$PULLMD_INSTANCE")

# Allow the PullMD instance itself (share links, /api results, direct pages).
if [[ -n "$instance_host" && "$host" == "$instance_host" ]]; then
    debug_log "ALLOW ${url} — PullMD instance host"
    exit 0
fi

# Allow GitHub and any configured allow_hosts.
if host_allowed "$host"; then
    debug_log "ALLOW ${url} — allowed host (${host})"
    exit 0
fi

# Cannot track the escape hatch without a data dir → fail open (never deadlock).
if [[ -z "${CLAUDE_PLUGIN_DATA:-}" ]]; then
    debug_log "ALLOW ${url} — CLAUDE_PLUGIN_DATA unset (cannot track escape hatch)"
    exit 0
fi

state_file=$(state_path "$session_id")
state=$(load_state "$state_file")

count=$(printf '%s' "$state" | jq -r --arg u "$url" '.urls[$u] // 0')
count=$(( count + 1 ))

state=$(printf '%s' "$state" | jq -c --arg u "$url" --argjson c "$count" '.urls[$u] = $c')
save_state "$state_file" "$state"

# Escape hatch: once attempts reach the threshold, let it through.
if [[ "$count" -ge "$PULLMD_ESCAPE_AFTER" ]]; then
    debug_log "ALLOW ${url} — escape hatch (attempt ${count}/${PULLMD_ESCAPE_AFTER})"
    exit 0
fi

remaining=$(( PULLMD_ESCAPE_AFTER - count ))
debug_log "DENY ${url} — redirect to ${PULLMD_MCP_TOOL} (attempt ${count}/${PULLMD_ESCAPE_AFTER})"

{
    printf '🤖 PullMD: read this URL as clean Markdown via %s, not WebFetch.\n' "$PULLMD_MCP_TOOL"
    printf '\n'
    printf 'URL: %s\n' "$url"
    printf '\n'
    printf '%s returns structured Markdown — it handles JS-heavy pages, PDFs, Office\n' "$PULLMD_MCP_TOOL"
    printf 'docs, YouTube, and Reddit, and is far cleaner than WebFetch raw HTML.\n'
    printf 'Configured PullMD instance: %s\n' "$PULLMD_INSTANCE"
    printf '\n'
    printf 'Escape hatch: if %s cannot handle this URL (e.g. a JSON API, or PullMD\n' "$PULLMD_MCP_TOOL"
    printf 'failed), retry the same WebFetch — it is allowed once attempts reach %s (%s to go).\n' "$PULLMD_ESCAPE_AFTER" "$remaining"
} >&2
exit 2
