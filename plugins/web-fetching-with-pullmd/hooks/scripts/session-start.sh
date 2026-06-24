#!/bin/bash
# SessionStart hook:
#   1. Wipe the WebFetch escape-hatch state (startup + compact) so per-URL
#      attempt counters never carry across sessions.
#   2. On startup, if a PullMD instance is configured but no matching MCP
#      server is registered in Claude Code, add context nudging the user to set
#      the server up — otherwise the redirect would point at a missing tool.
# Matcher: startup, compact
#
# Exit codes:
#   0 - Always (SessionStart hooks must not block)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

input=$(cat)

{
    IFS= read -r session_id
    IFS= read -r cwd
    IFS= read -r start_source
} < <(printf '%s' "$input" | jq -r '
    (.session_id // ""),
    (.cwd // ""),
    (.source // "")
')

# 1. Wipe escape-hatch state for this session.
if [[ -n "$session_id" && -n "${CLAUDE_PLUGIN_DATA:-}" ]]; then
    dir=$(session_dir "$session_id")
    if [[ -d "$dir" ]]; then
        rm -f "${dir}/webfetch-attempts.json" "${dir}"/.pullmd-tmp.*
    fi
fi

# 2. Registration nudge — startup only, so it does not re-fire on compaction.
if [[ "$start_source" == "startup" ]]; then
    project_dir="${CLAUDE_PROJECT_DIR:-$cwd}"
    load_config "$project_dir"

    if [[ "$PULLMD_ENABLED" == "true" && -n "$PULLMD_INSTANCE" ]]; then
        server=$(mcp_server_from_tool "$PULLMD_MCP_TOOL")
        if [[ -n "$server" ]] && ! mcp_server_configured "$server" "$project_dir"; then
            context="A PullMD instance is configured (${PULLMD_INSTANCE}) but no MCP server named \"${server}\" is registered in Claude Code, so the PullMD read_url tool is unavailable. If the user asks to read or fetch web content, tell them to register and authenticate it — run \`claude mcp add --transport http ${server} ${PULLMD_INSTANCE%/}/mcp --scope user\`, then \`/mcp\` to authenticate if the instance requires it (see the plugin's MCP Server Setup). Until then, web pages fall back to WebFetch; documents and YouTube have no fallback."
            jq -n --arg c "$context" '{
                hookSpecificOutput: {
                    hookEventName: "SessionStart",
                    additionalContext: $c
                }
            }'
        fi
    fi
fi

exit 0
