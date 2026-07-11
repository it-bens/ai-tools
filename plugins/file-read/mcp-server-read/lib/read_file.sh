#!/usr/bin/env bash
# File-reading tool for the file-read MCP server.
# Tool: read_file

FILE_READ_DEFAULT_MAX_BYTES=262144
FILE_READ_DEFAULT_MAX_OUTPUT_TOKENS=25000
FILE_READ_TOKEN_TO_BYTE_RATIO=4

_read_positive_int() {
    local value="${1}"
    local field="${2}"

    if [[ ! "${value}" =~ ^[0-9]+$ ]] || (( 10#${value} < 1 )); then
        printf 'Error: %s must be a positive integer\n' "${field}"
        return 1
    fi
}

_read_effective_max_bytes() {
    local arg_max_bytes="${1}"
    local max_bytes max_tokens token_bytes

    if [[ -n "${arg_max_bytes}" ]]; then
        _read_positive_int "${arg_max_bytes}" "max_bytes" || return 1
        max_bytes="${arg_max_bytes}"
    else
        max_bytes="${FILE_READ_MAX_BYTES:-${CODEX_READ_MAX_BYTES:-${FILE_READ_DEFAULT_MAX_BYTES}}}"
        _read_positive_int "${max_bytes}" "FILE_READ_MAX_BYTES" || return 1
    fi

    max_tokens="${FILE_READ_MAX_OUTPUT_TOKENS:-${CODEX_READ_MAX_OUTPUT_TOKENS:-${FILE_READ_DEFAULT_MAX_OUTPUT_TOKENS}}}"
    _read_positive_int "${max_tokens}" "FILE_READ_MAX_OUTPUT_TOKENS" || return 1

    token_bytes=$(( 10#${max_tokens} * FILE_READ_TOKEN_TO_BYTE_RATIO ))
    if (( token_bytes < 10#${max_bytes} )); then
        max_bytes="${token_bytes}"
    fi

    printf '%s\n' "${max_bytes}"
}

_read_resolve_path() {
    local file_path="${1}"
    local cwd="${2}"
    local candidate dir base

    if [[ "${file_path}" == /* ]]; then
        candidate="${file_path}"
    else
        if [[ -z "${cwd}" ]]; then
            cwd="${PWD}"
        fi
        if [[ "${cwd}" != /* ]]; then
            printf 'Error: cwd must be absolute when provided, got: %s\n' "${cwd}"
            return 1
        fi
        candidate="${cwd%/}/${file_path}"
    fi

    if [[ ! -e "${candidate}" ]]; then
        printf 'Error: file not found: %s\n' "${candidate}"
        return 1
    fi
    if [[ ! -f "${candidate}" ]]; then
        printf 'Error: not a regular file: %s\n' "${candidate}"
        return 1
    fi
    if [[ ! -r "${candidate}" ]]; then
        printf 'Error: file not readable: %s\n' "${candidate}"
        return 1
    fi

    dir="$(dirname -- "${candidate}")"
    base="$(basename -- "${candidate}")"

    local resolved_dir
    if ! resolved_dir=$(cd -- "${dir}" 2>/dev/null && pwd -P); then
        printf 'Error: unable to resolve directory: %s\n' "${dir}"
        return 1
    fi

    printf '%s/%s\n' "${resolved_dir}" "${base}"
}

_read_binary_extension() {
    local path="${1}"
    local lower
    lower=$(tr '[:upper:]' '[:lower:]' <<<"${path}")

    case "${lower}" in
        *.7z|*.a|*.apk|*.app|*.avi|*.bmp|*.bz2|*.class|*.dll|*.dmg|*.doc|*.docx|*.dylib|*.eot|*.exe|*.gif|*.gz|*.heic|*.ico|*.iso|*.jar|*.jpeg|*.jpg|*.lockb|*.mov|*.mp3|*.mp4|*.o|*.obj|*.otf|*.pdf|*.png|*.pyc|*.rar|*.so|*.sqlite|*.sqlite3|*.tar|*.tgz|*.ttf|*.wasm|*.webm|*.webp|*.woff|*.woff2|*.xls|*.xlsx|*.xz|*.zip)
            return 0
            ;;
    esac

    return 1
}

_read_has_nul_byte() {
    local path="${1}"
    local sample_hex

    if command -v head >/dev/null 2>&1; then
        sample_hex=$(head -c 8192 -- "${path}" 2>/dev/null | od -An -t x1 2>/dev/null || true)
    else
        sample_hex=$(dd if="${path}" bs=8192 count=1 2>/dev/null | od -An -t x1 2>/dev/null || true)
    fi

    [[ " ${sample_hex} " == *" 00 "* ]]
}

_read_total_lines() {
    local path="${1}"
    LC_ALL=C awk '
        NR == 1 {
            bom = sprintf("%c%c%c", 239, 187, 191)
            sub("^" bom, "")
        }
        { sub(/\r$/, "") }
        END { print NR }
    ' "${path}"
}

_read_print_range() {
    local path="${1}"
    local start_line="${2}"
    local end_line="${3}"
    local max_bytes="${4}"

    LC_ALL=C awk -v start="${start_line}" -v end="${end_line}" -v max_bytes="${max_bytes}" '
        BEGIN {
            bom = sprintf("%c%c%c", 239, 187, 191)
            used = 0
            truncated = 0
        }
        NR == 1 {
            sub("^" bom, "")
        }
        {
            sub(/\r$/, "")
        }
        NR >= start && NR <= end {
            line = $0
            line_bytes = length(line) + 1
            if (used + line_bytes > max_bytes) {
                remaining = max_bytes - used
                if (remaining > 0) {
                    printf "%6d\t%s\n", NR, substr(line, 1, remaining)
                }
                truncated = 1
                exit
            }
            printf "%6d\t%s\n", NR, line
            used += line_bytes
        }
        END {
            if (truncated) {
                printf "\n[Output truncated: read_file reached %d byte output limit. Use offset and limit to read a smaller range.]\n", max_bytes
            }
        }
    ' "${path}"
}

tool_read_file() {
    local args="${1}"
    local file_path cwd offset_raw limit_raw max_bytes_raw
    {
        IFS= read -r file_path
        IFS= read -r cwd
        IFS= read -r offset_raw
        IFS= read -r limit_raw
        IFS= read -r max_bytes_raw
    } < <(jq -r '
        (.file_path // ""),
        (.cwd // ""),
        (if has("offset") then (.offset | tostring) else "" end),
        (if has("limit") then (.limit | tostring) else "" end),
        (if has("max_bytes") then (.max_bytes | tostring) else "" end)
    ' <<<"${args}")

    if [[ -z "${file_path}" ]]; then
        printf 'Error: file_path is required\n'
        return 1
    fi

    if [[ -n "${offset_raw}" ]]; then
        _read_positive_int "${offset_raw}" "offset" || return 1
    else
        offset_raw=1
    fi

    if [[ -n "${limit_raw}" ]]; then
        _read_positive_int "${limit_raw}" "limit" || return 1
    fi

    local max_bytes
    max_bytes=$(_read_effective_max_bytes "${max_bytes_raw}") || {
        printf '%s\n' "${max_bytes}"
        return 1
    }

    local path
    path=$(_read_resolve_path "${file_path}" "${cwd}") || {
        printf '%s\n' "${path}"
        return 1
    }

    if _read_binary_extension "${path}" || _read_has_nul_byte "${path}"; then
        printf 'Error: binary file detected: %s\n' "${path}"
        return 1
    fi

    local total_lines start_line end_line num_lines
    total_lines=$(_read_total_lines "${path}")
    start_line=$(( 10#${offset_raw} ))

    if (( total_lines == 0 )); then
        printf 'File: %s\n' "${path}"
        printf 'Lines: 0 of 0\n'
        return 0
    fi

    if (( start_line > total_lines )); then
        printf 'File: %s\n' "${path}"
        printf 'Lines: %d-0 of %d\n\n' "${start_line}" "${total_lines}"
        printf 'No lines in requested range.\n'
        return 0
    fi

    if [[ -n "${limit_raw}" ]]; then
        end_line=$(( start_line + 10#${limit_raw} - 1 ))
        if (( end_line > total_lines )); then
            end_line="${total_lines}"
        fi
    else
        end_line="${total_lines}"
    fi

    num_lines=$(( end_line - start_line + 1 ))

    log "INFO" "read_file: path=${path} start=${start_line} lines=${num_lines} total=${total_lines}"

    printf 'File: %s\n' "${path}"
    printf 'Lines: %d-%d of %d\n\n' "${start_line}" "${end_line}" "${total_lines}"

    _read_print_range "${path}" "${start_line}" "${end_line}" "${max_bytes}"
}
