---
name: setting-up-code-comment-writer-extension
description: Use when the user explicitly asks to set up, install, configure, wire up, or create the code-comment-writer plugin's extension for the current project. Do not activate as a side effect of a code-comment-writing task.
---

# Setting Up the code-comment-writer Extension

Create the canonical extension setup for `code-comment-writer:writing-code-comments` in the current project: an overlay content file at `.claude/hook-contexts/writing-code-comments.md` and the two hook entries that deliver it.

## Workflow

### Step 1: Confirm scope

Confirm the current working directory is the project root that should receive the extension. If unclear, ask the user before doing anything else.

### Step 2: Choose the settings target

The settings target is the file that will hold the hook entries. Default: `.claude/settings.json`.

- If only `.claude/settings.json` exists, use it.
- If only `.claude/settings.local.json` exists, use it.
- If both exist, ask the user which one to edit.
- If neither exists, create `.claude/settings.json`.

### Step 3: Gather overlay content

The overlay extends `code-comment-writer:writing-code-comments` through exactly two mechanisms exposed by the parent skill:

1. **Named-value assignments** — overrides for the configuration names documented in the parent plugin's README under "Recognized Named Values". Each name has a default and a documented effect.
2. **Workflow position extensions** — `## Pre-Step-N` or `## Post-Step-N` sections of imperative instructions, where `N` is one of the step numbers or labels in the parent skill's SKILL.md.

When the user invokes this skill without naming specific options, locate the parent plugin's files (Claude Code installs plugins under a discoverable path; if you cannot find them, ask the user). Read the README's Recognized Named Values table and the SKILL.md's step list, present both to the user, and ask which named values to assign and which workflow positions to extend.

When the user describes intent in free form, translate it to the supported mechanisms before writing — the parent skill matches the formal options more precisely than equivalent free text:

- A request that overrides a documented behavior maps to the named-value assignment whose effect matches.
- A request scoped to a specific step's behavior maps to the `Pre-Step-N` or `Post-Step-N` at that step.

If a request cannot be mapped to either mechanism, surface that to the user and ask whether to drop or rephrase it. Do not write content that lies outside the two mechanisms.

### Step 4: Define the hook entries

Two entries are required in the settings target.

`PostToolUse` matcher entry (matcher value: the exact string `Skill`):

```json
{
  "type": "command",
  "command": "jq --rawfile ctx .claude/hook-contexts/writing-code-comments.md 'if .tool_input.skill == \"code-comment-writer:writing-code-comments\" then {hookSpecificOutput: {hookEventName: \"PostToolUse\", additionalContext: $ctx}} else empty end'"
}
```

`UserPromptSubmit` matcher entry (matcher value: empty string `""`):

```json
{
  "type": "command",
  "command": "jq --rawfile ctx .claude/hook-contexts/writing-code-comments.md 'if (.prompt // \"\" | startswith(\"/code-comment-writer:writing-code-comments\")) then {hookSpecificOutput: {hookEventName: \"UserPromptSubmit\", additionalContext: $ctx}} else empty end'"
}
```

The two `command` strings above are the authoritative form. Treat them as opaque — do not reformat, line-wrap, or reorder keys.

### Step 5: Confirm the plan

Present the user with:

- Settings target file.
- Overlay content to be written.
- The two hook entries that will be merged.

Wait for explicit approval before any write. The user may reject or amend the plan; loop back to Step 3 if content changes.

### Step 6: Write the overlay content file

Write `.claude/hook-contexts/writing-code-comments.md` using this template, omitting any section with no entries:

````
## Named-value assignments

- `<name>` = `<value>`
- `<name>` =
    <indented value block, used when the value spans multiple lines>

## Pre-Step-<N>

<imperative instructions>

## Post-Step-<N>

<imperative instructions>
````

One bullet per assigned name under the single `## Named-value assignments` heading; a value that does not fit one line (for example a documentation-surface description) is written as `` - `<name>` = `` on its own line followed by the value as an indented block. One section per workflow position extension, ordered by step number. The body of each `Pre-Step-N` / `Post-Step-N` section is the imperative instruction text confirmed in Step 5.

Create the `.claude/hook-contexts/` directory if it does not exist.

Verify after writing: every section in the file is one of the three template sections above and appears in the order shown.

### Step 7: Merge hook entries

Read the settings target (parse as JSON; if absent, start from `{}`). Ensure:

- `.hooks.PostToolUse` is an array. Find an element whose `matcher` is `"Skill"`. If none, append a new element `{ "matcher": "Skill", "hooks": [] }`. Append the Step 4 PostToolUse entry to that element's `hooks` array *only if* no existing entry in that array has the same `command` string.
- `.hooks.UserPromptSubmit` is an array. Find an element whose `matcher` is `""`. If none, append a new element `{ "matcher": "", "hooks": [] }`. Append the Step 4 UserPromptSubmit entry to that element's `hooks` array *only if* no existing entry has the same `command` string.

Do not modify any unrelated key, matcher, or hook entry. Write the result atomically (temp file in the same directory, then rename).

### Step 8: Verify and report

Confirm in this order:

1. `.claude/hook-contexts/writing-code-comments.md` exists and matches the Step 6 template.
2. The settings target is valid JSON and contains the two Step 4 entries.

Report to the user: settings target chosen, files written, and the next user-facing step (invoke `code-comment-writer:writing-code-comments` to confirm the overlay reaches it).
