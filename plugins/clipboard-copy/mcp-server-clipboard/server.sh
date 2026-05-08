#!/usr/bin/env bash
# Cross-platform clipboard MCP server.
# Provides the clipboard_copy tool, dispatching to the right backend per environment.

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$(cd "${SCRIPT_DIR}/../shared" && pwd)"

MCP_CONFIG_FILE="${SCRIPT_DIR}/config.json"
MCP_TOOLS_LIST_FILE="${SCRIPT_DIR}/tools.json"
MCP_LOG_FILE="${SCRIPT_DIR}/server.log"

export SCRIPT_DIR SHARED_DIR MCP_CONFIG_FILE MCP_TOOLS_LIST_FILE MCP_LOG_FILE

source "${SHARED_DIR}/mcpserver_core.sh"
source "${SCRIPT_DIR}/lib/clipboard.sh"

trap 'log "ERROR" "Unexpected error on line ${LINENO}"' ERR

log "INFO" "======================================"
log "INFO" "Clipboard MCP Server starting"
log "INFO" "Script dir: ${SCRIPT_DIR}"
log "INFO" "OS: $(uname -s)"
log "INFO" "Detected backend: $(_clipboard_detect_backend)"
log "INFO" "======================================"

run_mcp_server "$@"
