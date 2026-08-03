# System Prompts and Role Prompting

The system parameter defines the task, constraints, and output requirements. Do not use it for personas: they do not improve factual correctness, their per-question effects are unpredictable, and the style they imply is better stated as explicit requirements the model cannot misread.

### Use Explicit Requirements Instead of a Persona

**Persona-implied (don't):**
```
System: You are the General Counsel of a Fortune 500 tech company.

User: Analyze this software licensing agreement for potential risks.
```
The persona adds no accuracy. The tone, depth, and audience it *implies* are left for the model to guess.

**Explicit (do):**
```
System: Analyze contracts for legal risk. Your reader is an executive
deciding whether to sign.

User: We're considering this software licensing agreement for our core
data infrastructure. Analyze it for potential risks, focusing on
indemnification, liability, and IP ownership.

Requirements:
- For each risk: cite the clause, explain the exposure, recommend a change
- Order risks by severity
- Use precise legal terminology; no hedging summaries
- End with a sign / negotiate / reject recommendation
```
Everything the General Counsel persona was supposed to evoke — depth, audience, professional register, a concrete opinion — is stated directly.

### What Improves Domain Performance Instead

- **Task context**: what the output is for, who reads it, what happens next
- **Domain material**: reference documents, definitions, and data in the prompt (see [Long Context Tips](long-context.md))
- **Output requirements**: format, depth, terminology, length, structure
- **Grounding and verification**: quote-first analysis, source citation (see [Reduce Hallucinations](reduce-hallucinations.md))

### The Only Exception: Character Roleplay

A persona that *is* the requested output (fiction, simulation, practice conversations) stays — it is the deliverable, not a prompting technique. Identity openers like "You are a TDD enforcement agent" are not an exception: they restate the task without adding a constraint. Delete them and state the task directly.
