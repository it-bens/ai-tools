---
name: setting-up-commit-message-writer-extension
version: 1.1.2
description: Use when the user explicitly asks to set up, install, configure, wire up, or create the commit-message-writer plugin's extension for the current project. Do not activate as a side effect of a commit-message-writing task.
---

# Setting Up the commit-message-writer Extension

Create the canonical extension setup for `commit-message-writer:writing-commit-messages` in the current project. Both hosts share `.claude/hook-contexts/writing-commit-messages.md`; Claude Code delivers it through hooks, while Codex discovers it through a committed root `AGENTS.override.md`.

## Workflow

### Step 1: Confirm scope

Confirm the current working directory is the project root that should receive the extension. If unclear, ask the user before doing anything else.

Identify the active host. Use the Claude Code path when running in Claude Code and the Codex path when running in Codex. If the host cannot be determined, ask the user.

### Step 2: Choose the delivery target

For Codex, use `AGENTS.override.md` in the project root. This file must be committed with the project so Codex can discover the extension from the project root and its subdirectories.

For Claude Code, default to `.claude/settings.json`:

- If only `.claude/settings.json` exists, use it.
- If only `.claude/settings.local.json` exists, use it.
- If both exist, ask the user which one to edit.
- If neither exists, create `.claude/settings.json`.

### Step 3: Gather overlay content

The overlay extends `commit-message-writer:writing-commit-messages` through exactly two mechanisms exposed by the parent skill:

1. **Named-value assignments** — overrides for the configuration names documented in the parent plugin's README under "Recognized Named Values". Each name has a default and a documented effect.
2. **Workflow position extensions** — `## Pre-Step-N` or `## Post-Step-N` sections of imperative instructions, where `N` is one of the step numbers or labels in the parent skill's SKILL.md.

When the user invokes this skill without naming specific options, locate the installed parent plugin's files through the active host. If you cannot find them, ask the user. Read the README's Recognized Named Values table and the SKILL.md's step list, present both to the user, and ask which named values to assign and which workflow positions to extend.

When the user describes intent in free form, translate it to the supported mechanisms before writing — the parent skill matches the formal options more precisely than equivalent free text:

- A request that overrides a documented behavior maps to the named-value assignment whose effect matches.
- A request scoped to a specific step's behavior maps to the `Pre-Step-N` or `Post-Step-N` at that step.

If a request cannot be mapped to either mechanism, surface that to the user and ask whether to drop or rephrase it. Do not write content that lies outside the two mechanisms.

### Step 4: Define the delivery entries

Claude Code requires two entries in the settings target.

`PostToolUse` matcher entry (matcher value: the exact string `Skill`):

```json
{
  "type": "command",
  "command": "jq --rawfile ctx \"$CLAUDE_PROJECT_DIR/.claude/hook-contexts/writing-commit-messages.md\" 'if .tool_input.skill == \"commit-message-writer:writing-commit-messages\" then {hookSpecificOutput: {hookEventName: \"PostToolUse\", additionalContext: $ctx}} else empty end'"
}
```

`UserPromptSubmit` matcher entry (matcher value: empty string `""`):

```json
{
  "type": "command",
  "command": "jq --rawfile ctx \"$CLAUDE_PROJECT_DIR/.claude/hook-contexts/writing-commit-messages.md\" 'if (.prompt // \"\" | startswith(\"/commit-message-writer:writing-commit-messages\")) then {hookSpecificOutput: {hookEventName: \"UserPromptSubmit\", additionalContext: $ctx}} else empty end'"
}
```

The two `command` strings above are the authoritative Claude Code form. Treat them as opaque — do not reformat, line-wrap, or reorder keys.

For Codex, add this section to the root `AGENTS.override.md`:

```markdown
## Commit Message Writer Extension

Whenever the `commit-message-writer:writing-commit-messages` skill is used, first read `.claude/hook-contexts/writing-commit-messages.md` and apply its project-specific instructions.
```

If a root `AGENTS.md` exists, `AGENTS.override.md` replaces it — Codex does not stack AGENTS files and resolves no `@path` references inside them. Ensure the override begins with an explicit instruction to read `AGENTS.md` (canonical line: "Read AGENTS.md before acting on anything else in this file. This override replaces it; all of its guidance still applies.") so the project's normal guidance remains active.

### Step 5: Confirm the plan

Present the user with:

- Delivery target file.
- Overlay content to be written.
- The host-specific delivery entries that will be merged.

Wait for explicit approval before any write. The user may reject or amend the plan; loop back to Step 3 if content changes.

### Step 6: Write the overlay content file

Write the overlay to `.claude/hook-contexts/writing-commit-messages.md` for both hosts. Use this template, omitting any section with no entries:

````
## Named-value assignments

- `<name>` = `<value>`

## Pre-Step-<N>

<imperative instructions>

## Post-Step-<N>

<imperative instructions>
````

One bullet per assigned name under the single `## Named-value assignments` heading. One section per workflow position extension, ordered by step number. The body of each `Pre-Step-N` / `Post-Step-N` section is the imperative instruction text confirmed in Step 5.

Create `.claude/hook-contexts/` if it does not exist.

Verify after writing: every section in the file is one of the three template sections above and appears in the order shown.

### Step 7: Merge the delivery entries

For Claude Code, read the settings target (parse as JSON; if absent, start from `{}`). Ensure:

- `.hooks.PostToolUse` is an array. Find an element whose `matcher` is `"Skill"`. If none, append a new element `{ "matcher": "Skill", "hooks": [] }`. Append the Step 4 PostToolUse entry to that element's `hooks` array *only if* no existing entry in that array has the same `command` string.
- `.hooks.UserPromptSubmit` is an array. Find an element whose `matcher` is `""`. If none, append a new element `{ "matcher": "", "hooks": [] }`. Append the Step 4 UserPromptSubmit entry to that element's `hooks` array *only if* no existing entry has the same `command` string.

Do not modify any unrelated key, matcher, or hook entry. Write the result atomically (temp file in the same directory, then rename).

For Codex, read the root `AGENTS.override.md`; if absent, start with an empty file. Preserve all unrelated content. If root `AGENTS.md` exists, ensure the Step 4 read-`AGENTS.md` instruction appears once before the extension section. Add the Step 4 extension section only when it is absent; if the heading already exists, update that section to the canonical form without duplicating it (including any earlier form that used `@path` references — Codex reads those as literal strings).

Ensure `AGENTS.override.md` and `.claude/hook-contexts/writing-commit-messages.md` are not ignored by version control. They are project configuration and must be committed. Do not create a commit without the user's explicit approval, but report untracked or uncommitted state as incomplete setup.

### Step 8: Verify and report

Confirm in this order:

1. `.claude/hook-contexts/writing-commit-messages.md` exists and matches the Step 6 template.
2. Claude Code: the settings target is valid JSON and contains both Step 4 hooks.
3. Codex: root `AGENTS.override.md` contains the canonical extension section, retains root `AGENTS.md` through the explicit read instruction when applicable, contains no `@path` references (Codex reads them as literal strings), and both project files are tracked and committed.

Report the delivery target and files written. For Claude Code, invoke `commit-message-writer:writing-commit-messages` to confirm delivery. For Codex, start a new session from the project root or a subdirectory and invoke the writing skill to confirm the override is active.
