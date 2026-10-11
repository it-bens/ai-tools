#!/usr/bin/env bash
# Verify or refresh files that are kept identical across the repository.
# ===================================================================
# Reads .github/file-sync.manifest: one "<source> <copy>" pair per line,
# paths relative to the repo root. Check mode reports drift; --fix copies
# the source over every drifted or missing copy.
#
# Usage: validate-file-sync.sh [--fix] [--root DIR]
# Exit:  0 in sync (or fixed), 1 drift or missing copy, 2 usage or input error

set -euo pipefail

usage() {
    echo "Usage: validate-file-sync.sh [--fix] [--root DIR]" >&2
}

fix=0
root=""
root_given=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            fix=1
            shift
            ;;
        --root)
            if [[ $# -lt 2 ]]; then
                echo "error: --root requires a directory" >&2
                usage
                exit 2
            fi
            root="$2"
            root_given=1
            shift 2
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if [[ $root_given -eq 1 ]]; then
    if [[ -z "$root" ]]; then
        echo "error: --root requires a non-empty directory" >&2
        usage
        exit 2
    fi
    if [[ ! -d "$root" ]]; then
        echo "error: --root is not a directory: ${root}" >&2
        exit 2
    fi
else
    if ! root="$(git rev-parse --show-toplevel)"; then
        echo "error: cannot determine repo root with git rev-parse --show-toplevel" >&2
        exit 2
    fi
fi

manifest="${root}/.github/file-sync.manifest"
if [[ ! -f "$manifest" ]]; then
    echo "error: manifest not found: ${manifest}" >&2
    exit 2
fi

drift=0
line_no=0

while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi

    read -r -a fields <<< "$line"
    if [[ ${#fields[@]} -ne 2 ]]; then
        echo "error: ${manifest}:${line_no}: expected '<source> <copy>', got: ${line}" >&2
        exit 2
    fi
    source_rel="${fields[0]}"
    copy_rel="${fields[1]}"
    source_path="${root}/${source_rel}"
    copy_path="${root}/${copy_rel}"

    if [[ ! -f "$source_path" ]]; then
        echo "error: ${manifest}:${line_no}: source not found: ${source_rel}" >&2
        exit 2
    fi

    if [[ -f "$copy_path" ]] && cmp -s "$source_path" "$copy_path"; then
        if [[ $fix -eq 0 ]]; then
            echo "ok ${copy_rel}"
        fi
        continue
    fi

    if [[ $fix -eq 1 ]]; then
        mkdir -p "$(dirname "$copy_path")"
        cp "$source_path" "$copy_path"
        echo "fixed ${copy_rel}"
    elif [[ -e "$copy_path" ]]; then
        echo "DRIFT ${copy_rel} differs from ${source_rel}"
        drift=1
    else
        echo "MISSING ${copy_rel}"
        drift=1
    fi
done < "$manifest"

exit "$drift"
