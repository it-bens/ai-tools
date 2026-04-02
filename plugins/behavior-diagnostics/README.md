# Behavior Diagnostics Plugin

Debug AI tooling behavior (skills, agents, subagents, commands) by analyzing output against source instructions and enabling honest self-diagnosis in misbehaving sessions.

## Overview

When AI tooling produces unexpected results, this plugin provides a two-session diagnostic workflow:

1. **Session A (dev session):** Use the `diagnosing` skill to analyze the unsatisfying output against the tooling's source instructions. It performs root cause analysis and generates targeted introspection questions.

2. **Session B (misbehaving session):** Use the `introspecting` skill with the generated questions. It forces the session to honestly reflect on its reasoning without excuses, corrections, or people-pleasing.

## Skills

### Diagnosing

**Triggers:** "diagnose this output", "debug this behavior", "analyze what went wrong", "perform root cause analysis", "why did the agent do this", pasting unsatisfying AI output

**Capabilities:**
- Identify which skill/agent/subagent produced the output from session context
- Read and analyze all source instructions (SKILL.md, references, CLAUDE.md)
- Perform gap analysis: followed, violated, ambiguous, or missing instructions
- Classify root causes: ambiguity, missing constraints, conflicting rules, weak instructions, etc.
- Generate targeted introspection questions via the prompt-engineering skill
- Copy questions to clipboard for transfer to the misbehaving session

### Introspecting

**Triggers:** "introspect", "answer these questions about your behavior", "explain why you did this", "reflect on your behavior", pasting diagnostic questions

**Capabilities:**
- Answer introspection questions with enforced honesty
- Read referenced source files to ground answers in actual content
- Describe reasoning process at specific decision points
- Acknowledge instruction violations without excuses or deflection

## Usage

### In the dev session (Session A):

```
"Here's the output from the skill — it should have done X instead"
"Debug this behavior: [paste output]"
"Why did the agent produce this?"
```

### In the misbehaving session (Session B):

```
"Introspect on these questions: [paste questions from Session A]"
"Answer these diagnostic questions about your behavior"
```

## Contents

| Path | Purpose |
|------|---------|
| `skills/diagnosing/SKILL.md` | Root cause analysis and question generation |
| `skills/introspecting/SKILL.md` | Honest self-diagnosis constraints |

## License

MIT
