#!/usr/bin/env bash
# Gather all git data for writing-commit-messages into one /tmp file and
# print a TOC describing what lives where. The skill uses the TOC to issue
# targeted Read and Grep operations against the file instead of streaming
# large diffs through the conversation.

set -euo pipefail

RANGE="${1-}"
RANGE_ARGS=()
LOG_RANGE_ARGS=()
if [[ -n "$RANGE" ]]; then
    RANGE_ARGS+=("$RANGE")
    LOG_RANGE_ARGS+=("$RANGE")
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
    echo "gather.sh: not inside a git repository" >&2
    exit 2
fi

# Rewrite-mode range "<sha>^..<sha>" targeting a root commit: <sha>^ does not
# resolve. Diff against git's empty-tree object; restrict the log to <sha>.
if [[ -n "$RANGE" && "$RANGE" =~ ^([^.]+)\^\.\.([^.]+)$ ]]; then
    LEFT_REF="${BASH_REMATCH[1]}"
    RIGHT_REF="${BASH_REMATCH[2]}"
    if [[ "$LEFT_REF" == "$RIGHT_REF" ]] \
        && ! git -C "$REPO_ROOT" rev-parse --verify "${LEFT_REF}^" >/dev/null 2>&1; then
        EMPTY_TREE='4b825dc642cb6eb9a060e54bf8d69288fbee4904'
        RANGE="${EMPTY_TREE}..${RIGHT_REF}"
        RANGE_ARGS=("$RANGE")
        LOG_RANGE_ARGS=("-1" "$RIGHT_REF")
    fi
fi

set +e
git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --quiet 2>/dev/null
DIFF_RC=$?
set -e

case $DIFF_RC in
    0)
        echo "gather.sh: no changes to summarize for range: ${RANGE:-<working tree>}" >&2
        exit 1
        ;;
    1) ;;
    *)
        echo "gather.sh: invalid git range: ${RANGE:-<working tree>}" >&2
        exit 2
        ;;
esac

find /tmp -maxdepth 1 -name 'commit-msg.*' -type f -mmin +360 -delete 2>/dev/null || true

TMPFILE="$(mktemp /tmp/commit-msg.XXXXXX)"

add_marker() { printf '=== SECTION: %s ===\n' "$1" >>"$TMPFILE"; }

add_marker plugins
(cd "$REPO_ROOT" && ls plugins/ 2>/dev/null) >>"$TMPFILE" || true

add_marker status
git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --find-renames --name-status >>"$TMPFILE" || true

add_marker shortstat
git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --shortstat >>"$TMPFILE" || true

add_marker numstat
git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --find-renames --numstat >>"$TMPFILE" || true

LOG_OUTPUT="$(git -C "$REPO_ROOT" --no-pager log ${LOG_RANGE_ARGS[@]+"${LOG_RANGE_ARGS[@]}"} --no-color --format='%H%n%s%n%b%n---' 2>/dev/null || true)"
if [[ -n "$LOG_OUTPUT" ]]; then
    add_marker log
    printf '%s\n' "$LOG_OUTPUT" >>"$TMPFILE"
fi

add_marker diff
git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --find-renames >>"$TMPFILE" || true

printf '=== END ===\n' >>"$TMPFILE"

printf 'TMPFILE=%s\n\n' "$TMPFILE"

awk '
/^=== SECTION: / {
    if (prev != "") printf "SECTION %-12s %d-%d\n", prev, start, NR - 1
    prev = $3
    start = NR + 1
    next
}
/^=== END ===/ {
    if (prev != "") printf "SECTION %-12s %d-%d\n", prev, start, NR - 1
    exit
}
' "$TMPFILE"

DIFF_START="$(awk '/^=== SECTION: diff ===/ { print NR; exit }' "$TMPFILE")"
DIFF_END="$(awk -v s="$DIFF_START" 'NR > s && /^=== / { print NR - 1; exit }' "$TMPFILE")"

if [[ -n "$DIFF_START" && -n "$DIFF_END" && "$DIFF_END" -ge "$DIFF_START" ]]; then
    mapfile -t FILES < <(git -C "$REPO_ROOT" --no-pager diff ${RANGE_ARGS[@]+"${RANGE_ARGS[@]}"} --no-color --find-renames --name-only 2>/dev/null)
    mapfile -t MARKS < <(awk -v s="$DIFF_START" -v e="$DIFF_END" '
        NR > s && NR <= e && /^diff --git / { print NR }
    ' "$TMPFILE")

    n=${#MARKS[@]}
    if (( n > 0 )); then
        printf '\n'
        for (( i = 0; i < n; i++ )); do
            mark_start="${MARKS[i]}"
            if (( i + 1 < n )); then
                mark_end=$(( ${MARKS[i + 1]} - 1 ))
            else
                mark_end="$DIFF_END"
            fi
            path="${FILES[i]-???}"
            printf 'DIFF_FILE %-60s %d-%d\n' "$path" "$mark_start" "$mark_end"
        done
    fi
fi
