---
name: content-editing
version: 3.9.0
description: Evaluates proposed changes to LLM-targeted content (skills, agents, commands) and guides toward corrections over additions. MUST invoke when editing SKILL.md files, modifying agent markdown in agents/, updating command markdown in commands/, adding new sections or instructions, expanding skill content, user says "is this too long", "content bloat", "should I add this", or improving/enhancing skills.
---

# Content Editing for LLM

Enforce the principle: **prefer correcting existing content over adding new instructions**.

## Core Principle

Undesired behavior stems from **incorrect** information, not missing information. Shorter is better.

## Decision Framework

```dot
digraph content_editing {
    "Proposed change to LLM-targeted content" [shape=doublecircle];
    "Existing content addresses this incorrectly?" [shape=diamond];
    "Correct the existing content" [shape=box];
    "Fixable by clarifying or rewording?" [shape=diamond];
    "Modify existing wording" [shape=box];
    "Would adding create redundancy or conflict?" [shape=diamond];
    "Consolidate or remove conflicting content first" [shape=box];
    "All three add-conditions met?" [shape=diamond];
    "Add — orthogonal, via progressive disclosure" [shape=box];
    "Do not add" [shape=octagon style=filled fillcolor=red];

    "Proposed change to LLM-targeted content" -> "Existing content addresses this incorrectly?";
    "Existing content addresses this incorrectly?" -> "Correct the existing content" [label="yes"];
    "Existing content addresses this incorrectly?" -> "Fixable by clarifying or rewording?" [label="no"];
    "Fixable by clarifying or rewording?" -> "Modify existing wording" [label="yes"];
    "Fixable by clarifying or rewording?" -> "Would adding create redundancy or conflict?" [label="no"];
    "Would adding create redundancy or conflict?" -> "Consolidate or remove conflicting content first" [label="yes"];
    "Consolidate or remove conflicting content first" -> "All three add-conditions met?";
    "Would adding create redundancy or conflict?" -> "All three add-conditions met?" [label="no"];
    "All three add-conditions met?" -> "Add — orthogonal, via progressive disclosure" [label="yes"];
    "All three add-conditions met?" -> "Do not add" [label="no"];
}
```

Walk the checks in order.

- **Existing content addresses this incorrectly?** Undesired behavior usually traces to a wrong instruction, not a missing one — correct that instruction.
- **Fixable by clarifying or rewording?** A vague or ambiguous instruction is modified in place, not supplemented.
- **Would adding create redundancy or conflict?** Consolidate or remove the conflicting guidance first.

Add new content only when **all three** hold: the capability genuinely doesn't exist, existing content cannot reasonably be extended, and the addition is a distinct, orthogonal concern. Otherwise, do not add.

## When Addition is Warranted

If adding is truly necessary:
- Consider **progressive disclosure** — move detailed content to `references/`
- Consider **agent delegation** — split responsibilities into focused agents
- Keep additions **orthogonal** — distinct from existing content

Additions are appropriate when they fill genuine gaps.
