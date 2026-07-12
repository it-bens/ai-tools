# Commit Message Writer

Commit-message-writing skill for Conventional Commits. Mode detection (staged / squash / rewrite), a deterministic gather-script-driven workflow, anti-slop validation via the `human-author:ai-slop-writing-fixer` subagent, and validation mode.

Claude Code installs the `human-author` plugin dependency automatically. Codex users must manually install the matching `human-author:ai-slop-writing-fixer` custom agent before using this skill.

## Quick Start

```bash
/plugin install commit-message-writer@itb-ai-tools
```

For Codex, install the required custom agent first, then install `commit-message-writer` from the Codex marketplace.

Without project-specific additions, the skill runs with universal defaults: Conventional Commits format, scope inferred from changed-file directories, kebab-case scope naming, 72-character subject cap, and a `Co-Authored-By: Claude {model}` footer.

## Skills

### Writing Commit Messages

**Triggers:** "write a commit message", "generate a commit message", "what should I commit this as", "validate this commit", invocation with a SHA or range expression.

**Modes:**
- **Staged**: operates on `git diff --cached` (or working tree fallback) for uncommitted changes.
- **Squash**: operates on `<base>..HEAD` to summarize a branch.
- **Rewrite**: operates on `<sha>^..<sha>` to regenerate a single commit's message.

Mode detection happens inside the skill based on arguments and message context. No slash commands.

**Model:** The skill pins `model: sonnet` and `effort: high` in its frontmatter, so it runs on Sonnet with high effort for its turn regardless of the session model. The override applies only while the skill is active; the session model resumes on the next prompt. Sonnet's adaptive reasoning concentrates thinking on the failure-sensitive parts (commit-type classification, intent inference from an ambiguous diff, breaking-change detection, multi-concern squash) and stays cheap on trivial diffs.

## Extension Contract

The skill is extendable in two complementary ways:

1. **Workflow positions.** Each `Step N` in the skill body has an implicit `Pre-Step-N` position immediately before it and a `Post-Step-N` position immediately after. If context contains a `## Pre-Step-N` or `## Post-Step-N` section when Step N runs, the skill executes its content as additional instructions at that position.
2. **Named configuration values.** The skill body references certain values by backticked name (for example `` `subject.max_length` ``). If context assigns a value to that name, the skill uses the assignment; otherwise it uses the inline default given in the skill body.

Both shapes are additive. The skill works without any extension; defaults produce a sane Conventional Commits message.

## Authoring Overlays

Use the companion plugin `commit-message-writer-extension-setup` to provision an overlay in your project. Its `setting-up-commit-message-writer-extension` skill writes the overlay content file and merges the matching hook entries into the project's settings file.

## Recognized Named Values

| Name                           | Default                                                  | Effect                                                                                                                                     |
|--------------------------------|----------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `modes.squash.default_base`    | `main`                                                   | Base ref used when summarizing a branch in squash mode without an explicit range argument.                                                 |
| `scope.naming_convention`      | `kebab-case`                                             | Allowed character set for an inferred scope. Scopes that violate the convention warn during validation.                                    |
| `subject.max_length`           | `72`                                                     | Hard cap on subject length, including the `type(scope): ` prefix. Drafts exceeding the cap are rewritten shorter.                          |
| `body.breaking_change_handoff` | (none)                                                   | String appended to the body whenever a `BREAKING CHANGE:` footer is emitted. Useful for delegating migration notes to a separate workflow. |
| `footer.template`              | `Co-Authored-By: Claude {model} <noreply@anthropic.com>` | Footer line template. `{model}` substitutes the active model's name. Set to the empty string to suppress the line.                         |
| `footer.extra_lines`           | (none)                                                   | Additional footer lines emitted after the template, one per entry. Use for trailers like `Refs: TICKET-123`.                               |

In the footer template, `{model}` is substituted at runtime with the active model's name. To suppress the footer template line, assign `footer.template` the empty string; `footer.extra_lines` still emits when present.

## License

MIT
