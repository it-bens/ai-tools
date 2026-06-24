# Code Comment Writer

Code-comment-writing skill that improves comments toward **"why not what"**: removes redundant comments, improves vague ones, condenses verbose ones, preserves valuable ones, and flags inconsistencies — across files, a directory, or git changes.

## "Why" Not "What"

Comments should explain **why** a decision was made, why an approach was chosen, why a workaround exists, or why a constraint matters. They should not restate **what** the code does, what a function is named, or what an obvious operation happens.

## Quick Start

```bash
/plugin install code-comment-writer@itb-ai-tools
```

Invoke by asking in natural language — no slash commands. The skill detects its scope and mode from your request:

```
Clean up the comments in src/Service/
Review comments on my branch vs main
Improve the comments in UserService.php
Check comment quality in HEAD~5..HEAD     # read-only: reports, makes no edits
```

Without project-specific additions, the skill runs on universal defaults: "why not what" categorization, a built-in skip set for vendored/generated/lock files, and an uncertainty pass that surfaces risky edits for verification.

## Skills

### Writing Code Comments

**Triggers:** "review/clean up/improve comments", "condense these docblocks", "audit comment quality", a path, a SHA, a range, or `--git`.

**Scope detection** (inside the skill, from the argument):

| Signal                                  | Scope                |
|-----------------------------------------|----------------------|
| empty / a path                          | files under the path |
| `--git`, "my changes", "branch vs main" | working-tree changes |
| a single SHA / `HEAD` / branch          | one commit           |
| a `..` / `...` range                    | a commit range       |
| two or more SHAs                        | a commit list        |

**Modes:** the default mode applies edits; **read-only mode** (triggered by "check", "analyze", "audit", "report only") presents the same findings without editing.

Deterministic scope resolution — which files are in scope and, for git scopes, which lines changed — is offloaded to `scripts/scope.sh`, so the model only reads what matters.

**Model:** the skill pins `model: sonnet` and `effort: high` in its frontmatter, so it runs on Sonnet with high effort for its turn regardless of the session model. The override applies only while the skill is active. Sonnet's adaptive reasoning concentrates thinking on the failure-sensitive judgments (is a comment redundant or load-bearing, is a docblock a contract, would condensing this drop a content signal) and stays cheap on trivial comments.

## Extension Contract

The skill is extendable in two complementary ways:

1. **Workflow positions.** Each `Step N` in the skill body has an implicit `Pre-Step-N` position immediately before it and a `Post-Step-N` position immediately after. If context contains a `## Pre-Step-N` or `## Post-Step-N` section when Step N runs, the skill executes its content as additional instructions at that position.
2. **Named configuration values.** The skill body references certain values by backticked name (for example `` `todo.ticket_format` ``). If context assigns a value to that name, the skill uses the assignment; otherwise it uses the inline default given in the skill body.

Both shapes are additive. The skill works without any extension.

## Authoring Overlays

Use the companion plugin `code-comment-writer-extension-setup` to provision an overlay in your project. Its `setting-up-code-comment-writer-extension` skill writes the overlay content file and merges the matching hook entries into the project's settings file.

## Recognized Named Values

| Name                         | Default                | Effect                                                                                                                                                     |
|------------------------------|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `paths.ignore`               | (script skip set only) | Extra globs dropped from the scope manifest before review.                                                                                                 |
| `paths.conservative`         | (none)                 | Files requiring extra caution; substantive changes there are at least MEDIUM uncertainty.                                                                  |
| `comments.preserve_patterns` | (none)                 | Regexes/markers whose matching comments are always preserved.                                                                                              |
| `comments.exemption_markers` | (none)                 | Markers whose comments are skipped entirely.                                                                                                               |
| `todo.ticket_format`         | (none)                 | Regex a TODO/FIXME must match to avoid being flagged.                                                                                                      |
| `domain.terms`               | (none)                 | Domain terms whose alteration raises change uncertainty.                                                                                                   |
| `docs.surface`               | (none)                 | The project's documentation surface: where each kind of knowledge lives, plus the invariant that comments hold only local WHY. Drives the Relocate action. |

## Supported Languages

`//` and `/* */` (JavaScript, TypeScript, Java, C/C++, PHP, Go, Rust, Swift, Kotlin), `#` (Python, Ruby, Shell, YAML), `<!-- -->` (HTML, XML, Markdown), `{# #}` (Twig, Jinja), and `--` (SQL, Lua).

## License

MIT
