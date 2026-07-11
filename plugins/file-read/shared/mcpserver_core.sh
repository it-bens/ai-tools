#!/usr/bin/env bash
# MCP Server Core - JSON-RPC 2.0 protocol handler.
# Requires: bash 4+, jq

set -euo pipefail

: "${MCP_CONFIG_FILE:=config.json}"
: "${MCP_TOOLS_LIST_FILE:=tools.json}"
: "${MCP_LOG_FILE:=/dev/null}"
: "${MCP_EXTRA_LOG_FILE:=}"

log() {
    local level="${1}"
    local message="${2}"
    local line
    line="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
    printf '%s\n' "${line}" >> "${MCP_LOG_FILE}"
    [[ -n "${MCP_EXTRA_LOG_FILE}" ]] && printf '%s\n' "${line}" >> "${MCP_EXTRA_LOG_FILE}"
    return 0
}

read_json_file() {
    local file="${1}"
    if [[ -f "${file}" ]]; then
        cat -- "${file}"
    else
        log "ERROR" "File not found: ${file}"
        printf '{}\n'
    fi
}

create_response() {
    local id="${1}"
    local result="${2}"

    jq -n -c \
        --argjson id "${id}" \
        --argjson result "${result}" \
        '{"jsonrpc": "2.0", "id": $id, "result": $result}'
}

create_error_response() {
    local id="${1}"
    local code="${2}"
    local message="${3}"

    jq -n -c \
        --argjson id "${id}" \
        --argjson code "${code}" \
        --arg message "${message}" \
        '{"jsonrpc": "2.0", "id": $id, "error": {"code": $code, "message": $message}}'
}

handle_initialize() {
    local id="${1}"

    log "INFO" "Handling initialize request"

    local config
    config=$(read_json_file "${MCP_CONFIG_FILE}")

    local result
    result=$(jq -n -c \
        --argjson config "${config}" \
        '{
            "protocolVersion": ($config.protocolVersion // "2024-11-05"),
            "serverInfo": ($config.serverInfo // {"name": "mcp-server", "version": "1.0.0"}),
            "capabilities": ($config.capabilities // {"tools": {}})
        }')

    create_response "${id}" "${result}"
}

handle_tools_list() {
    local id="${1}"

    log "INFO" "Handling tools/list request"

    local tools_config
    tools_config=$(read_json_file "${MCP_TOOLS_LIST_FILE}")

    local tools
    tools=$(jq -c '.tools // []' <<<"${tools_config}")

    local result
    result=$(jq -n -c --argjson tools "${tools}" '{"tools": $tools}')

    create_response "${id}" "${result}"
}

handle_tools_call() {
    local id="${1}"
    local params="${2}"

    local tool_name
    local arguments
    {
        IFS= read -r tool_name
        IFS= read -r arguments
    } < <(jq -r '(.name // ""), (.arguments // {} | @json)' <<<"${params}")

    log "INFO" "Handling tools/call: ${tool_name}"

    if [[ ! "${tool_name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        create_error_response "${id}" -32602 "Invalid tool name: ${tool_name}"
        return
    fi

    local func_name="tool_${tool_name}"
    if ! type "${func_name}" &>/dev/null; then
        create_error_response "${id}" -32601 "Tool not found: ${tool_name}"
        return
    fi

    local output
    local exit_code=0
    output=$("${func_name}" "${arguments}" 2>&1) || exit_code=$?

    if [[ ${exit_code} -ne 0 ]]; then
        log "ERROR" "Tool ${tool_name} failed with exit code ${exit_code}"
        local error_result
        error_result=$(jq -n -c \
            --arg text "Error executing ${tool_name}: ${output}" \
            '{"content": [{"type": "text", "text": $text}], "isError": true}')
        create_response "${id}" "${error_result}"
        return
    fi

    local result
    result=$(jq -n -c \
        --arg text "${output}" \
        '{"content": [{"type": "text", "text": $text}], "isError": false}')

    create_response "${id}" "${result}"
}

process_request() {
    local request="${1}"

    if ! jq -e '.' >/dev/null 2>&1 <<<"${request}"; then
        log "ERROR" "Invalid JSON received"
        create_error_response "null" -32700 "Parse error: Invalid JSON"
        return
    fi

    local jsonrpc id method params
    {
        IFS= read -r jsonrpc
        IFS= read -r id
        IFS= read -r method
        IFS= read -r params
    } < <(jq -r '
        (.jsonrpc // ""),
        (.id // null | @json),
        (.method // ""),
        (.params // {} | @json)
    ' <<<"${request}")

    if [[ "${jsonrpc}" != "2.0" ]]; then
        log "ERROR" "Invalid JSON-RPC version: ${jsonrpc}"
        create_error_response "${id}" -32600 "Invalid Request: jsonrpc must be 2.0"
        return
    fi

    if [[ "${id}" == "null" ]]; then
        log "INFO" "Received notification: ${method}"
        return
    fi

    case "${method}" in
        "initialize")
            handle_initialize "${id}"
            ;;
        "tools/list")
            handle_tools_list "${id}"
            ;;
        "tools/call")
            handle_tools_call "${id}" "${params}"
            ;;
        "notifications/initialized")
            log "INFO" "Client initialized"
            ;;
        "ping")
            create_response "${id}" '{}'
            ;;
        *)
            log "ERROR" "Unknown method: ${method}"
            create_error_response "${id}" -32601 "Method not found: ${method}"
            ;;
    esac
}

run_mcp_server() {
    log "INFO" "MCP Server starting..."

    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ -z "${line}" ]] && continue

        log "INFO" "Received: ${line:0:100}..."

        local response
        response=$(process_request "${line}")

        if [[ -n "${response}" ]]; then
            log "RESPONSE" "${response:0:100}..."
            printf '%s\n' "${response}"
        fi
    done

    log "INFO" "MCP Server shutting down"
}
