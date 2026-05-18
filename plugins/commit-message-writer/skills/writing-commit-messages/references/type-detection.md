# Type Detection

Determine conventional commit type from diffs with confidence-based analysis.

## Decision Tree

Apply in priority order:

1. Reverting commit? → `revert`
2. Only docs (*.md, comments, README)? → `docs`
3. Only formatting/whitespace? → `style`
4. Only test files (`*_test.*`, `*.bats`, `tests/`, `test/`)? → `test`
5. Only build/deps (`pyproject.toml`, `uv.lock`, `package.json`, `package-lock.json`, `Cargo.toml`, `go.mod`)? → `build`
6. Only CI configs (`.github/workflows/`, `.github/scripts/`, `.gitlab-ci.yml`, `.circleci/`)? → `ci`
7. New component, file, or capability added in a source directory? → `feat`
8. Fixes broken behavior in existing component? → `fix`
9. Performance improvements? → `perf`
10. Code restructuring without behavior change? → `refactor`
11. Otherwise → `chore`

Additional rows for this decision tree may appear in earlier context. Apply those rows after the universal tree above; additions refine the tree but do not replace it.

## Confidence Levels

**HIGH**: Single type clearly dominates
- New skill file + references → feat
- Only `*.bats` files → test
- Only `.github/workflows/` → ci

**MEDIUM**: Primary type clear with minor secondary changes
- New feature + updated README → feat (README is incidental)
- Bug fix + added test for the fix → fix

**LOW**: Multiple types equally valid → ask user with `AskUserQuestion`
- New feature + bug fix equally present
- refactor + feat ambiguous

## Breaking Change Detection

Mark as breaking (`!`) when:
- Public API signature changes (exported function/method renamed, params changed, return type changed)
- Public symbol removed (exported function, class, type, constant)
- Module or package renamed or removed
- Hook event type changed
- Schema or on-disk layout changes that existing data won't match

NOT breaking:
- New public API added (additive)
- New optional parameter added
- Internal-only refactor with unchanged public surface
