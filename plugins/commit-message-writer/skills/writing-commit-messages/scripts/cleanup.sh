#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
    printf '%s\n' 'cleanup.sh: expected exactly one tmpfile path' >&2
    exit 2
fi

TMPFILE="$1"

case "${TMPFILE}" in
    /tmp/commit-msg.*) ;;
    *)
        printf 'cleanup.sh: refusing path outside /tmp/commit-msg.*: %s\n' "${TMPFILE}" >&2
        exit 2
        ;;
esac

SUFFIX="${TMPFILE#/tmp/commit-msg.}"
if [[ -z "${SUFFIX}" || "${SUFFIX}" == */* ]]; then
    printf 'cleanup.sh: refusing invalid tmpfile path: %s\n' "${TMPFILE}" >&2
    exit 2
fi

if [[ ! -e "${TMPFILE}" && ! -L "${TMPFILE}" ]]; then
    exit 0
fi

if [[ -L "${TMPFILE}" || ! -f "${TMPFILE}" || ! -O "${TMPFILE}" ]]; then
    printf 'cleanup.sh: refusing non-regular, symlinked, or unowned tmpfile: %s\n' "${TMPFILE}" >&2
    exit 2
fi

rm -f -- "${TMPFILE}"
