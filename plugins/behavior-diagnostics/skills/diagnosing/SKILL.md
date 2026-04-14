---
name: diagnosing
version: 1.0.0
description: |
  This skill should be used when the user asks to "diagnose this output", "debug this
  behavior", "analyze what went wrong", "perform root cause analysis", "why did the
  agent do this", mentions unexpected AI tooling output, or needs to understand why a
  skill, agent, or command deviated from its intended behavior. Provides gap analysis
  and targeted introspection questions against source instructions.
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash, Skill
model: opus
---

# Behavior Diagnosing

Analyze AI tooling output against its source instructions to identify why behavior deviated from intent, then generate targeted introspection questions for the misbehaving session.

## Workflow

### Phase 1: Receive Input

The user pastes unsatisfying output, optionally with a description of what they expected instead. Extract and hold:
- The actual output or behavior being questioned
- Any stated expectations ("it should have done X")
- Implicit expectations derivable from session context (what was the user working on?)

### Phase 2: Identify the Tooling

Determine which skill, agent, subagent, or command produced the output. Use session context — recently discussed files, working directory, conversation history — to infer this. If the tooling cannot be identified with confidence, ask the user.

### Phase 3: Read Source Instructions

Load everything that defines the intended behavior:
- SKILL.md or agent markdown file
- All files in `references/` directory (if present)
- CLAUDE.md files in the plugin directory
- Any referenced configuration or templates

Read thoroughly. The quality of the analysis depends on understanding the full instruction set, not just the top-level file.

### Phase 4: Gap Analysis

Compare the actual output against the source instructions. For each instruction or behavioral rule, classify it:

- **Followed** — the output correctly implements this instruction
- **Violated** — the output contradicts or ignores this instruction
- **Ambiguous** — the instruction is vague enough that both the intended and actual behavior are valid interpretations
- **Missing** — the intended behavior has no corresponding instruction

Focus on violations and ambiguities — these are the diagnostic targets. For each, note the specific instruction passage and the corresponding output behavior. These pairs feed directly into Phase 5 and Phase 6.

### Phase 5: Root Cause Analysis

Classify the likely cause(s) behind each violation or ambiguity:

| Category | Description |
|----------|-------------|
| **Instruction ambiguity** | The instruction can be read multiple ways; the model chose a valid but unintended interpretation |
| **Missing constraint** | The intended behavior was never explicitly stated |
| **Conflicting rules** | Two instructions pull in opposite directions; the model resolved the conflict differently than intended |
| **Over-broad scope** | The instruction is too general, allowing the model to take unwanted liberties |
| **Weak instruction** | The instruction exists but lacks enforcement strength; model tendencies override it |
| **Instruction burial** | The instruction exists but is buried in dense text, reducing its salience |
| **Context overflow** | Too many instructions compete for attention; critical ones get deprioritized |

### Phase 6: Generate Introspection Questions

Invoke `llm-author:prompt-engineering` with:
- The violation/ambiguity pairs from Phase 4 (instruction passage + observed behavior)
- The root cause classifications from Phase 5
- The instruction to craft questions optimized for honest LLM self-reflection

The generated questions must:
- Quote the specific instruction passage being probed
- Ask the misbehaving session to describe its reasoning at the decision point where it diverged
- Probe one violation or ambiguity per question — compound questions dilute answers
- Provide enough context for meaningful answers without leading toward specific conclusions

Include a preamble block with the questions that sets the behavioral frame for the answering session: answer honestly, no excuses, no fixes, no deflection.

### Phase 7: Offer Clipboard

Ask the user if they want the questions copied to clipboard. If yes, pipe the full question block (preamble + questions) to `pbcopy` via Bash.

## Key Constraints

- Proceed directly to analysis when the intended behavior is clear from session context and source instructions. Only ask the user what's wrong when the gap genuinely cannot be determined.
- Output is diagnosis only — never propose fixes, rewrites, or improvements.
- State findings directly. If an instruction is poorly written, say so.
- Always quote specific instruction passages when identifying violations. "The skill says to do X" is insufficient — cite the actual text.
