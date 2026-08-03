# Claude 4 → Claude 5 Migration Examples

## Purpose

Before/after examples showing how to re-tune existing Claude 4 prompts and LLM-targeted content for Claude 5. Claude 5 exercises more judgment and self-verifies, so scaffolding that helped Claude 4 now over-steers — the migration removes it rather than adding to it.

## Best Used For

- Updating a Claude 4 prompt, skill, agent, or rules file to run well on Claude 5
- Understanding which Claude 4 patterns over-steer Claude 5
- Producing a documented before/after so each change is reviewable

---

## Example 1: Coding Assistant System Prompt

### Before (Claude 4)

```markdown
You are an expert senior software engineer.

CRITICAL: You MUST think step-by-step inside <thinking> tags before every answer.
CRITICAL: You MUST double-check your work and add a verification step at the end.

When fixing a bug, explain the root cause, apply the fix, then re-read your change and
confirm it is correct before responding.
```

API: `thinking: {type: "enabled", budget_tokens: 8000}`, `temperature: 0.2`, assistant response prefilled with `Fix:`.

### After (Claude 5)

```markdown
Fix the reported bug: identify the root cause, apply the fix, and state what changed.
Respond directly, without preamble.
```

API: omit `thinking` (adaptive thinking runs by default); set `effort` (default `high`, lower for cost); no prefill; default sampling.

### Migration Rationale

| Change | Reason |
|--------|--------|
| Dropped the persona opener | "You are an expert…" adds nothing; the task carries the behavior |
| Removed `<thinking>` scaffolding and `budget_tokens` | Adaptive thinking is on by default; `budget_tokens` now returns a 400 error — steer with `effort` |
| Removed "double-check" / "verification step" | Claude 5 self-verifies; carried-over verification causes over-verification |
| Softened `CRITICAL: You MUST` | Aggressive triggers over-fire on Claude 5 |
| Replaced the prefill with "respond directly" | Assistant prefill returns a 400 error on Claude 5 |
| Reset `temperature` to default | Non-default sampling returns a 400 error |

---

## Example 2: LLM-Targeted Content — Comment-Writing Skill

### Before (Claude 4)

```markdown
NEVER write comments that restate the code.
NEVER write multi-line comments.
ALWAYS keep comments under one line.
You MUST follow these rules on every single comment, without exception.

Example of a BAD comment:
    // increment i by one
    i++;
Example of a GOOD comment:
    // offset compensates for the header row
    i++;
```

### After (Claude 5)

```markdown
Write comments that explain why, not what. Match the surrounding file's comment density
and style; a comment earns its place when the reason isn't obvious from the code.
```

### Migration Rationale

| Change | Reason |
|--------|--------|
| Absolute rules → judgment heuristic | "Match the surrounding density" steers Claude 5 better than stacked NEVER/ALWAYS rules |
| Removed the good/bad worked examples | Examples narrow the model's exploration space; the heuristic covers the intent |
| Dropped the "without exception" reinforcement | Repetition to force compliance is Claude 4 scaffolding |

---

## Example 3: Subagent Orchestration Prompt

### Before (Claude 4)

```markdown
For any task, delegate aggressively to subagents to move faster.
After each subagent returns, use another subagent to verify its output.
CRITICAL: summarize your progress every 3 tool calls so the user can follow along.
```

### After (Claude 5)

```markdown
Delegate to a subagent only for large tasks that are genuinely independent and
parallelizable, such as a wide multi-file investigation. Do not delegate work you can
finish in a handful of tool calls, and do not use subagents to verify your own work.
Keep spawn counts low.
```

### Migration Rationale

| Change | Reason |
|--------|--------|
| "Delegate aggressively" → explicit criteria + cap | Claude 5 already delegates readily; unbounded delegation inflates cost (the cap applies to Opus 5; Fable 5 is built to delegate freely) |
| Removed subagent-based verification | Claude 5 self-verifies; a verifier subagent is wasted work |
| Removed forced progress summaries | Claude 5 gives good interim updates on its own |

---

## Migration Checklist

When re-tuning Claude 4 content for Claude 5, remove or replace:

- [ ] Persona / "You are …" identity openers → state the task directly
- [ ] `<thinking>` / `<answer>` scaffolding and `budget_tokens` → adaptive thinking + `effort`
- [ ] "Double-check" / "add a verification step" / verifier subagents → nothing (self-verifies)
- [ ] `CRITICAL: You MUST` and stacked absolutes → "Use … when …" and judgment heuristics
- [ ] Assistant prefill → "respond directly, without preamble" or Structured Outputs
- [ ] Non-default `temperature` / `top_p` / `top_k` → default sampling; steer tone via the prompt
- [ ] Forced progress-update scaffolding → nothing (good updates by default)
- [ ] Worked examples that only narrow behavior → an interface/spec or a judgment heuristic

Then, if the target is Opus 5 (or Fable 5 at high effort), add a concision instruction — those run long; Sonnet 5 calibrates length on its own. Recount tokens against the target model rather than reusing Claude 4 limits.

Full per-model detail: `../references/claude-5-guide.md`.
