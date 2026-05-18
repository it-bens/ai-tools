## Named-value assignments

- `footer.template` = `""` (empty string; suppresses the Claude co-authoring footer line)

## Pre-Step-10

Apply this content-selection rule before crafting the subject and body.

When the commit type is not `test` or `docs`, do not mention test or documentation changes in the subject or body. They are supporting work, not the focus, and the message describes the focus only.

- Tests: paths matching `*_test.*`, `*.bats`, `tests/`, or `test/`.
- Docs: paths matching `*.md`, `README*`, `docs/`, plus comment-only diffs.
- When a test or doc change reveals or explains the focus behavior (for example, a test isolates the bug being fixed), describe the behavior, not the test or doc artifact.
- Do not append phrases like "and tests", "+ docs", or "with documentation" to the subject. Do not add a body paragraph that enumerates test or doc files.
