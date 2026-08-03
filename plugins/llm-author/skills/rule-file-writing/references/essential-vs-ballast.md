# Essential vs Ballast (Pass 1 Reference)

The unit of analysis is a single paragraph or bullet.

## The Per-Paragraph Decision Test

> **"Does this change a token-level decision the assistant will make at generation time, or does it justify the rule to a human reader?"**

- Behavior-changing → **keep**.
- Justification → **cut**.

## Essential — Always Keep

| Category | Why |
|---|---|
| **CRITICAL opener** (1–2 sentences) | Sets the frame in the first ~30 tokens loaded. |
| **Decision Tests / pre-action gates** | Single-question gates that fire before a triggering action. Highest-leverage lever in a rules file. |
| **WRONG/CORRECT code pairs** | Highest-fidelity directive: exact pattern to avoid, exact replacement. |
| **Operational tables** (input → response, classification, routing) | Compress many directives into one scannable block. |
| **Red Flags table** | Intercepts rationalizations at the moment they appear in the assistant's reasoning. |
| **WHY clauses inline** (one short clause per rule) | Lets the assistant generalize the rule to edge cases instead of following it mechanically. |
| **Allowed exceptions / escape hatches** (narrow and gated) | Without explicit gates, an absolute rule gets ignored at the first plausible exception. |
| **Subagent delegation directives** (verbatim text) | Some rules must propagate to spawned agents that won't see the parent file. The verbatim block is the only place that text lives. |

## Ballast — Cut on Sight

| Category | Why it's not pulling weight |
|---|---|
| **Citations and stats** | Provenance for a human reader; doesn't change generation. |
| **"Why" essays** that restate a rule with reasoning | Duplicates the inline WHY clause. |
| **"Remember" / "In summary" epilogues** | Closing rhetoric; the body already established the point. |
| **Restate paragraphs** between rule and table | "The above means that..." re-explanations. The table is enough. |
| **Framework enumerations** ("applies to PHPUnit, Vitest, Jest, pytest...") | Reassurance for a human reader. |
| **Verification / "how to check this rule works" sections** | Meta-commentary not consulted at generation time. |
| **Source lists at the bottom** | Same as citations. |
| **Soft prefaces** ("This is important because...") | Wasted tokens before the actual directive. |
| **Bullets that restate the section heading** | The heading is the bullet. |

## What NOT To Cut (Guards Against Contrarian Over-Cutting)

| Don't cut | Why |
|---|---|
| **Single-carrier bullets** | The only place a directive appears. Cutting removes the directive. |
| **WHY clauses** | Removing them leaves mechanical rule-following that fails at edge cases. |
| **Verbatim subagent directive blocks** | Designed to be copy-pasted into spawned agents. Paraphrasing breaks function. |
| **Allowed Exceptions gate conditions** | Removing them makes the rule absolute (ignored at first exception) or weakens it (bypassed routinely). |
| **Three-angle redundancy** | Looks like restate, isn't. Each angle catches a different failure mode. |
| **Anti-contrarian guardrails on sycophancy-shaped files** | Suppressing one failure mode tends to produce the inverse. |

## Calibrated-Honesty Gate for the Optimizer

Before accepting a proposed cut:

> **"Am I cutting this because it carries no directive, or because cutting feels productive?"**

If the second, put it back. If a file is already optimal, the honest report is 0% reduction — not manufactured cuts.
