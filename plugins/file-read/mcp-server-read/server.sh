#!/usr/bin/env bash
# File Read MCP server.

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$(cd -- "${SCRIPT_DIR}/../shared" && pwd)"

MCP_CONFIG_FILE="${SCRIPT_DIR}/config.json"
MCP_TOOLS_LIST_FILE="${SCRIPT_DIR}/tools.json"
MCP_LOG_FILE="${FILE_READ_LOG_FILE:-${CODEX_READ_LOG_FILE:-/dev/null}}"

export SCRIPT_DIR SHARED_DIR MCP_CONFIG_FILE MCP_TOOLS_LIST_FILE MCP_LOG_FILE

# shellcheck disable=SC1091
source "${SHARED_DIR}/mcpserver_core.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/read_file.sh"

trap 'log "ERROR" "Unexpected error on line ${LINENO}"' ERR

log "INFO" "======================================"
log "INFO" "File Read MCP Server starting"
log "INFO" "Script dir: ${SCRIPT_DIR}"
log "INFO" "Working dir: ${PWD}"
log "INFO" "======================================"

run_mcp_server "$@"
