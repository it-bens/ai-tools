#!/usr/bin/env bash
# Resolve a review scope into a manifest of in-scope files (and, for git scopes,
# the changed line ranges) on stdout. Offloads deterministic scope resolution
# and skip-file filtering from the skill so the model only reads what matters.
#
# Usage: scope.sh <type> [args...]
#   path         <path> [<path>...]   source files under each file/dir
#   git-worktree [<base>]             working-tree changes vs base (default HEAD)
#   commit       <sha>                files + ranges changed by one commit
#   commit-range <range>              files + ranges across a literal git range
#   commit-list  <sha> [<sha>...]     union of files + ranges across commits
#
# Output (stdout): one line per in-scope file:
#   FILE <path> <ranges>
#   <ranges> is "-" for path scope (review the whole file), or comma-separated
#   added-line ranges "a-b,c-d" for git scopes (review only changed lines).
#
# Exit codes: 0 success; 1 no in-scope files; 2 invalid args / not a git repo.

set -euo pipefail

TYPE="${1-}"
if [[ -z "$TYPE" ]]; then
    printf 'scope.sh: missing scope type\n' >&2
    exit 2
fi
shift

SOURCE_EXTS=(js jsx ts tsx mjs cjs java c cc cpp cxx h hpp hxx php go rs swift
    kt kts py rb sh bash yaml yml html htm xml md twig jinja jinja2 sql lua vue
    svelte scala groovy)

# Return 0 if the path should be skipped (vendored, generated, or a lock file).
skip_path() {
    case "$1" in
        vendor/*|*/vendor/*|node_modules/*|*/node_modules/*) return 0 ;;
        dist/*|*/dist/*|build/*|*/build/*|.git/*|*/.git/*) return 0 ;;
        *.lock|package-lock.json|*/package-lock.json) return 0 ;;
        *.min.js|*.min.css) return 0 ;;
    esac
    return 1
}

# Return 0 if the file carries an @generated marker in its first 10 lines.
is_generated() {
    head -n 10 -- "$1" 2>/dev/null | grep -q '@generated'
}

# Print source files under a file or directory (no filtering; no exit).
enumerate_path() {
    local root="$1"
    if [[ -f "$root" ]]; then
        printf '%s\n' "$root"
        return 0
    fi
    local name_expr=()
    local ext
    for ext in "${SOURCE_EXTS[@]}"; do
        name_expr+=(-name "*.${ext}" -o)
    done
    unset 'name_expr[${#name_expr[@]}-1]'
    find "$root" \
        \( -name vendor -o -name node_modules -o -name dist -o -name build -o -name .git \) -prune -o \
        -type f \( "${name_expr[@]}" \) -print
}

# Parse a `git diff --unified=0` stream on stdin into "path<TAB>ranges" lines.
parse_diff_ranges() {
    awk '
        /^\+\+\+ / {
            p = substr($0, 5)
            sub(/^b\//, "", p)
            cur = (p == "/dev/null") ? "" : p
            next
        }
        /^@@ / {
            if (cur == "") next
            plus = ""
            for (i = 1; i <= NF; i++) {
                if (substr($i, 1, 1) == "+") { plus = substr($i, 2); break }
            }
            n = split(plus, a, ",")
            start = a[1] + 0
            cnt = (n > 1) ? a[2] + 0 : 1
            if (cnt == 0) next
            end = start + cnt - 1
            ranges[cur] = ranges[cur] (ranges[cur] == "" ? "" : ",") start "-" end
        }
        END { for (f in ranges) print f "\t" ranges[f] }
    '
}

REPO_ROOT=""
require_repo() {
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -z "$REPO_ROOT" ]]; then
        printf 'scope.sh: not inside a git repository\n' >&2
        exit 2
    fi
}

require_commit() {
    if ! git -C "$REPO_ROOT" rev-parse --verify --quiet "$1^{commit}" >/dev/null; then
        printf 'scope.sh: invalid commit reference: %s\n' "$1" >&2
        exit 2
    fi
}

# Emit a single-commit diff, handling a root (parentless) commit.
diff_for_commit() {
    local sha="$1"
    if git -C "$REPO_ROOT" rev-parse --verify --quiet "${sha}^^{commit}" >/dev/null; then
        git -C "$REPO_ROOT" --no-pager diff --unified=0 --no-color "${sha}^..${sha}"
    else
        git -C "$REPO_ROOT" --no-pager show --unified=0 --no-color --format= "$sha"
    fi
}

# RAW holds newline-separated candidates; format differs by scope family:
#   path scopes     -> "<file>"
#   git scopes      -> "<file><TAB><ranges>"
RAW=""
GIT_SCOPE=0
case "$TYPE" in
    path)
        [[ $# -gt 0 ]] || set -- "."
        for p in "$@"; do
            if [[ ! -e "$p" ]]; then
                printf 'scope.sh: no such file or directory: %s\n' "$p" >&2
                exit 2
            fi
        done
        RAW="$( { for p in "$@"; do enumerate_path "$p"; done; } | sort -u )"
        ;;
    git-worktree)
        require_repo
        BASE="${1:-HEAD}"
        require_commit "$BASE"
        GIT_SCOPE=1
        RAW="$(git -C "$REPO_ROOT" --no-pager diff --unified=0 --no-color "$BASE" | parse_diff_ranges | sort)"
        ;;
    commit)
        require_repo
        [[ $# -ge 1 ]] || { printf 'scope.sh: commit requires a sha\n' >&2; exit 2; }
        require_commit "$1"
        GIT_SCOPE=1
        RAW="$(diff_for_commit "$1" | parse_diff_ranges | sort)"
        ;;
    commit-range)
        require_repo
        [[ $# -ge 1 ]] || { printf 'scope.sh: commit-range requires a range\n' >&2; exit 2; }
        if ! git -C "$REPO_ROOT" --no-pager diff --unified=0 --no-color "$1" >/dev/null 2>&1; then
            printf 'scope.sh: invalid git range: %s\n' "$1" >&2
            exit 2
        fi
        GIT_SCOPE=1
        RAW="$(git -C "$REPO_ROOT" --no-pager diff --unified=0 --no-color "$1" | parse_diff_ranges | sort)"
        ;;
    commit-list)
        require_repo
        [[ $# -ge 1 ]] || { printf 'scope.sh: commit-list requires at least one sha\n' >&2; exit 2; }
        for sha in "$@"; do require_commit "$sha"; done
        GIT_SCOPE=1
        RAW="$( { for sha in "$@"; do diff_for_commit "$sha"; done; } | parse_diff_ranges | sort)"
        ;;
    *)
        printf 'scope.sh: unknown scope type: %s\n' "$TYPE" >&2
        exit 2
        ;;
esac

# Filter in the current shell (here-string, not a pipeline) so OUT accumulates.
OUT=""
if [[ "$GIT_SCOPE" -eq 1 ]]; then
    while IFS=$'\t' read -r path ranges; do
        [[ -n "$path" ]] || continue
        skip_path "$path" && continue
        OUT+="FILE ${path} ${ranges}"$'\n'
    done <<< "$RAW"
else
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        skip_path "$f" && continue
        is_generated "$f" && continue
        OUT+="FILE ${f} -"$'\n'
    done <<< "$RAW"
fi

if [[ -z "$OUT" ]]; then
    printf 'scope.sh: no in-scope files for: %s %s\n' "$TYPE" "$*" >&2
    exit 1
fi

printf '%s' "$OUT"
