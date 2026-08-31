# Subagent report shape

Why the definitions name the final message as the report, why a verdict comes last at the sonnet rung, and why haiku shape rules are phrased as what to emit rather than what to avoid. A 25-run experiment across three Claude Code sessions, run against this plugin's own agent definitions.

## What prompted it

Real usage produced reports that read as if a worker had not reported back. Two candidate causes: the worker lacks a tool its instructions demand, or the instructions never name the delivery channel. Both were tested.

## Tool availability is not a cause

Five definitions were probed by attempting the calls, not by asking the worker what it had:

| Definition | Agent tool | Write tool |
|---|---|---|
| `investigate-sonnet-high` | present; spawned a haiku subagent that replied | absent — no schema resolves for the name |
| `design-opus-xhigh` | present; spawned a haiku subagent that replied | absent |
| `implement-sonnet-medium` | present; spawned a haiku subagent that replied | present; the write succeeded |
| `gate-run-haiku` | absent — `InputValidationError: Unknown tool "Agent"` | absent — same error |
| `investigate-sonnet-low` | absent from the session's tool listing | absent |

Every definition holds what its frontmatter grants and nothing more. All 25 spawns delivered a final message; none failed to report.

One recording error surfaced: the session's agent listing showed `investigate-sonnet-high` as excluding the Agent tool while its frontmatter had already dropped that exclusion. The frontmatter governs, and a listing read after an edit but before a restart is stale.

## Sonnet: a verdict placed first gets revised mid-message

`investigate-sonnet-high`, one trivial claim, verdict vocabulary confirmed/refuted:

| Prompt shape | Runs | Result |
|---|---|---|
| No output contract, definition as shipped | 2 | one clean; one opened "Refuted.", deliberated, closed "**Confirmed.**" |
| Prompt contract demanding the verdict first | 1 | contract violated — opened "refuted", corrected mid-message, restated "confirmed" |
| Prompt contract placing the verdict last | 2 | both clean |
| Definition carrying the verdict-last contract | 4 | all clean, including a five-file claim |

These runs finish in five to eight seconds. The worker starts writing before the check has settled, so a contract that demands the verdict first extracts a guess; the correction then lands mid-message. A caller that reads the opening of a flipped report gets the wrong answer, which is worse than a missing report because it is actionable. Placing the verdict after the evidence matches the order the worker generates in.

The definition's own "default to refuted where the evidence is absent" supplies the opening stance that gets revised. That directive earns its place — it is the reason to dispatch an adversarial checker — so the fix moved the verdict rather than removing the default.

Opus does not share the failure. The unedited `investigate-opus-medium` stated its verdict first, correctly, and added a falsifier and a working-tree-versus-HEAD caveat. Verdict-last is therefore applied where it was measured to be needed, not across every rung.

## Haiku ignores a negatively phrased shape rule

`search-haiku` returned correct matches with a preamble ("Now I have all the information needed…"). Two phrasings were tested against that:

| Phrasing | Runs | Result |
|---|---|---|
| "contains nothing but it — no preamble, no narration" | 1 | preamble persisted |
| "its first character is the first character of the first match line" | 4 (2 prompt-side, 2 from the definition) | bare match lines, no preamble |

Naming the first token to emit binds; naming the thing to avoid does not. `gate-run-haiku` and `investigate-haiku` carry the same positive form for consistency of duty wording — `gate-run-haiku` had no shape defect in evidence before or after, and `investigate-haiku` still opened one run with a `## Report` heading, so that definition's edit is unconfirmed.

## Limits

One claim, one search target, and one gate pair across the runs; the sonnet flip rate rests on three baseline runs. Model versions and the harness both move. Re-run the four shapes above after a Claude Code update or a model rev before trusting the directives they produced.
