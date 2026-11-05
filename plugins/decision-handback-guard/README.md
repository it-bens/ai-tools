# Decision Handback Guard

Stops Claude from handing you decisions that the request, the code, the project rules, or your earlier instructions already settle.

## How It Works

The plugin ships two hooks in `hooks/hooks.json`. It has no scripts and no skills.

| Step | Hook | What it does |
|---|---|---|
| 1. Formalize | `Stop`, `prompt` type, 30-second timeout | At the end of a turn, checks whether Claude's final message hands you a decision in prose. If so, it blocks the stop and tells Claude to ask through the `AskUserQuestion` tool instead. |
| 2. Judge | `PreToolUse` on `AskUserQuestion`, `agent` type, 60-second timeout | Judges each question against built-in criteria and the optional project checklist. A question Claude can answer itself is denied with the derived answer and its source, and Claude decides and continues. A question that is yours to answer passes, and you see the selection dialog. |

**Questions that always pass to you** (built-in criteria):
- Consent for an action that leaves the working tree, such as a push, creating or editing an issue or pull request, publishing, messaging an external service, or deleting data outside the working tree
- A go to start implementation that you have not given
- A change to the scope you set
- Information only you have, such as credentials, external facts, or a preference that nothing in the request, the code, the project rules, the checklist, or your earlier instructions settles
- A subject the checklist lists under `## The user decides`

When Step 2 denies a question, Claude states the decision in one line as `Decided: <decision>, because <reason>.` and keeps working. A question Claude asks again with the same intent after a denial passes to you. Step 1 lets through a stop that ends a continuation a Stop hook started, so it blocks once per hand-back.

**Where each step runs:**
- Step 1 covers the main agent only. The plugin does not hook `SubagentStop`.
- Step 2 also fires for `AskUserQuestion` calls made inside subagents, because hooks from plugins run in subagents too.

## Installation

```bash
/plugin install decision-handback-guard@itb-ai-tools
```

Claude Code only. There is no Codex manifest. The agent hook type is experimental in Claude Code and may change.

## Project Checklist

Create `.claude/extensions/decision-handback-guard/checklist.md` in your project root (optional). You write it and commit it wherever the project tracks `.claude/`. A project whose `.gitignore` excludes `.claude/` must re-include this path to share the file. The plugin ships no default file; without one, only the built-in criteria apply.

The file has two lists, one item per line:

```markdown
## The agent decides

- Test scope follows the project's testing skill.
- CI is the gate; local re-runs need no confirmation.
- Fix PRs carry no version bump.

## The user decides

- Releases
- Schema changes
- Dependency major upgrades
```

Items under `## The agent decides` are answer sources: the hook denies a matching question and names the item as the source. Items under `## The user decides` are extra user-owned criteria: matching questions always pass to you.

## Headless Runs

In `claude -p` runs without a permission host (an Agent SDK `canUseTool` callback or a `--permission-prompt-tool`), Claude Code does not offer `AskUserQuestion` to the agent. After Step 1 blocks, Claude decides what it can derive and ends the turn with the remaining questions in prose. That second stop is final, so a turn gains at most one extra continuation.

The plugin therefore changes agent behavior in headless runs, which matters for skill experiments and scripted comparisons.

## Disabling the Plugin for a Run

- Pass `--bare`. Bare mode skips installed plugins, so the hooks do not load.
- Or disable the plugin in the settings the run uses:

```json
{
  "enabledPlugins": {
    "decision-handback-guard@itb-ai-tools": false
  }
}
```

A project's `.claude/settings.json` that enables the plugin takes precedence over a `false` in `~/.claude/settings.json`. To opt out on one machine, set the entry in `.claude/settings.local.json`.
