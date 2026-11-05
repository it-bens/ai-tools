# Decision Handback Guard

Stops Claude from handing you decisions that the request, the code, the project rules, or your earlier instructions already settle.

## How It Works

The plugin ships two hooks in `hooks/hooks.json`. It has no scripts and no skills.

| Step | Hook | What it does |
|---|---|---|
| 1. Formalize | `Stop`, `prompt` type, 30-second timeout | At the end of a turn, checks whether Claude's final message hands you a decision in prose. If so, it blocks the stop and tells Claude to ask through the `AskUserQuestion` tool instead. |
| 2. Judge | `PreToolUse` on `AskUserQuestion`, `agent` type, 60-second timeout | Judges each question against built-in criteria and the optional project checklist. A call that holds a question Claude can answer itself is denied with the derived answer and its source, and Claude decides and continues. A call in which every question is yours to answer passes, and you see the selection dialog. When a call mixes both kinds, it is denied whole and Claude asks the questions that are yours again in a call of their own. |

**Questions Claude never decides** (built-in criteria):
- Consent for an action that leaves the working tree, such as a push, creating or editing an issue or pull request, publishing, messaging an external service, or deleting data outside the working tree
- A go to start implementation that you have not given
- A change to the scope you set
- Information only you have, such as credentials, external facts, or a preference that nothing in the request, the code, the project rules, the checklist, or your earlier instructions settles
- A subject the checklist lists under `## The user decides`

When Step 2 denies a question, Claude states the decision in one line as `Decided: <decision>, because <reason>.` and keeps working. A question Claude asks again with the same intent after a denial passes to you. Step 1 checks only the first hand-back of each continuation: while a continuation that a Stop hook started is running, Claude Code reports `stop_hook_active` as true, and Step 1 lets every later stop of that continuation through. If the Step 2 hook times out (60 seconds) or returns no verdict, the question goes through unjudged.

**Where each step runs:**
- Step 1 covers the main agent only. The plugin does not hook `SubagentStop`.
- Step 2 judges the main agent's questions. Claude Code does not offer `AskUserQuestion` to subagents spawned through the Agent tool, so no question from a subagent reaches the hook. If Claude Code offered the tool there, the hook would apply to those calls too.

## Installation

```bash
/plugin install decision-handback-guard@itb-ai-tools
```

Claude Code only. There is no Codex manifest. The agent hook type is experimental in Claude Code and may change.

## Project Checklist

Create `.claude/extensions/decision-handback-guard/checklist.md` in your project root (optional). You write it and commit it wherever the project tracks `.claude/`. A project whose `.gitignore` excludes `.claude/` must change that entry to the two lines below to share the file, because git does not re-include a path inside an excluded directory:

```gitignore
.claude/*
!.claude/extensions/
```

The plugin ships no default file; without one, only the built-in criteria apply.

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

Items under `## The agent decides` are answer sources: the hook denies a matching question and names the item as the source, unless the question also meets a user-owned criterion (see the list above), in which case it passes. Items under `## The user decides` are extra user-owned criteria: Claude never decides matching questions.

## Headless Runs

In `claude -p` runs without a permission host (an Agent SDK `canUseTool` callback or a `--permission-prompt-tool`), Claude Code does not offer `AskUserQuestion` to the agent. After Step 1 blocks, Claude decides what it can derive and ends the turn with the remaining questions in prose. Step 1 does not check that second stop, so a turn gains at most one extra continuation.

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
