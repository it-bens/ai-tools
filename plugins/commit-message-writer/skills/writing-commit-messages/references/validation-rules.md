# Validation Rules

Checks run in validation mode (Step V). Each rule has a category (Format Compliance, Consistency, Body Quality), a check description, and a verdict (`PASS`, `WARN`, `FAIL`). All three categories run by default.

## Format Compliance

| Check | Verdict |
|---|---|
| Type is in the Conventional Commits allowlist (feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert) | FAIL if not |
| Scope (if present) matches `scope.naming_convention` | WARN if not |
| Subject does not end with a period | FAIL if it does |
| First word of subject after the colon is lowercase | WARN if not |
| Subject length is within `subject.max_length` (including the `type(scope): ` prefix) | FAIL if exceeded |
| Breaking-change marker (`!`) is paired with a `BREAKING CHANGE:` footer | FAIL if marker without footer |
| No PR number in subject (`(#NNN)` pattern) | WARN if present (GitHub adds during merge) |
| No AI/tool attribution in subject | WARN if "Claude", "AI", "Generated with" appear |

## Consistency

| Check | Verdict |
|---|---|
| Type matches the diff signal (e.g., `fix` declared but no behavior change visible) | WARN |
| Scope matches the affected files (e.g., scope `dal` declared but no `DataAbstractionLayer/` files touched) | WARN |
| Subject describes the actual change (heuristic: at least one noun in the subject appears in the diff hunks) | WARN if no overlap |
| Breaking-change marker present iff the diff contains breaking signals (removed exports, signature changes) | WARN on mismatch |

## Body Quality

| Check | Verdict |
|---|---|
| Body is present when breaking-change marker is set | FAIL if missing |
| Body is present when the diff touches 5+ files | WARN if missing |
| Blank line between subject and body | FAIL if missing |
| Body lines are single continuous paragraphs (no hard-wrapping at 72) | WARN if any paragraph spans multiple lines |
| Body does not restate the diff (heuristic: no file-name listing pattern, no implementation-walkthrough phrasing) | WARN |
| Body contains motivation indicators ("because", "caused", "previously", "root cause", or before/after framing) | WARN if absent |
| No em dashes (`—`) anywhere | FAIL if found (literal character check) |
| No banned vocabulary from the `human-author:ai-slop-writing-fixer` agent's vocabulary list | WARN, one entry per match |

## Report Format

Each category gets a verdict line. WARN/FAIL items list specific failures with line references. PASS categories show a single line. If any check is FAIL, the overall verdict is FAIL; otherwise WARN if any check WARN, otherwise PASS.

Example:

```
Format Compliance: PASS
Consistency: WARN
  - Scope `dal` declared but no DataAbstractionLayer/ files touched
Body Quality: FAIL
  - Em dash found at body line 3, column 47
  - Body restates the diff (file listing pattern detected)

Overall: FAIL
```

The skill optionally generates a rewrite suggestion using Steps 8-12 against the actual diff and presents it side-by-side with the existing message.
