# Commit Message Writer

Commit-message-writing skill for Conventional Commits. Mode detection (staged / squash / rewrite), a deterministic gather-script-driven workflow, an anti-slop ruleset, and validation mode.

## Quick Start

```bash
/plugin install commit-message-writer@itb-ai-tools
```

Without project-specific additions, the skill runs with universal defaults: Conventional Commits format, scope inferred from changed-file directories, kebab-case scope naming, 72-character subject cap, and a `Co-Authored-By: Claude {model}` footer.

## Skills

### Writing Commit Messages

**Triggers:** "write a commit message", "generate a commit message", "what should I commit this as", "validate this commit", invocation with a SHA or range expression.

**Modes:**
- **Staged**: operates on `git diff --cached` (or working tree fallback) for uncommitted changes.
- **Squash**: operates on `<base>..HEAD` to summarize a branch.
- **Rewrite**: operates on `<sha>^..<sha>` to regenerate a single commit's message.

Mode detection happens inside the skill based on arguments and message context. No slash commands.

## Extension Contract

The skill is extendable in two complementary ways:

1. **Workflow positions.** Each `Step N` in the skill body has an implicit `Pre-Step-N` position immediately before it and a `Post-Step-N` position immediately after. If context contains a `## Pre-Step-N` or `## Post-Step-N` section when Step N runs, the skill executes its content as additional instructions at that position.
2. **Named configuration values.** The skill body references certain values by backticked name (for example `` `subject.max_length` ``). If context assigns a value to that name, the skill uses the assignment; otherwise it uses the inline default given in the skill body.

Both shapes are additive. The skill works without any extension; defaults produce a sane Conventional Commits message.

## Authoring Overlays

Overlay files are injected verbatim into agent context. Nothing in the file is read by a human at runtime. Write only matchable content — `## Pre-Step-N` / `## Post-Step-N` sections and named-value assignments. Do not add a file title, a "this overlay extends X" preamble, or any orientation prose; unmatched lines consume agent attention without behavioral effect.

Minimal correct overlay:

````markdown
## Named-value assignments

- `footer.template` = `""` (suppresses the co-authoring footer line)

## Pre-Step-10

When the commit type is not `test` or `docs`, do not mention test or documentation changes in the subject or body.
````

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
