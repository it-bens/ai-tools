---
name: writing-handoff-prompts
version: 3.7.0
description: Use when the user explicitly asks to write a handoff prompt for a fresh, new, separate, or other session — for example to start a spec's implementation, apply review or report fixes, turn review findings into a change proposal, or continue work — in a session that will have none of this session's context. Invoke only on such an explicit request, never proactively. Produces a self-contained handoff prompt (every needed fact stated inline or reachable by an explicit file reference; the work type, branch, commit and verification policy, and scope deduced from context), then offers to save it to a file or copy it to the clipboard.
model: sonnet
user-invocable: false
allowed-tools: Skill(llm-author:prompt-engineering)
---

# Writing Handoff Prompts

The receiving session starts with **zero context**: everything it needs must be in the prompt or in a file the prompt names. Hand off *state, not a transcript* — the operational facts the next session acts on, not the conversation that produced them. A fresh session with a complete handoff outperforms a stale one. Work from this session's context alone — do not open new files or search for more. Craft the prompt with the `llm-author:prompt-engineering` skill, scale its detail to the size of the work, then offer to deliver it.

```dot
digraph handoff {
  start    [shape=doublecircle, label="User asks for a handoff prompt"];
  deduce   [shape=box, label="Deduce the contextual requirements\n(work, sources, branch, commits, verify,\nscope, what's settled, what's uncertain)"];
  craft    [shape=box, label="Craft the prompt with\nllm-author:prompt-engineering"];
  ctx      [shape=diamond, label="Does it stand alone for a zero-context\nreader — every fact inline or in a named file?"];
  val      [shape=diamond, label="Is every hash, path, name, and count\nconcrete and taken from this session?"];
  fix      [shape=box, label="Send it back through prompt-engineering\nwith the gap named"];
  ask      [shape=box, label="Ask the user:\nsave to a file or copy to the clipboard?"];
  deliver  [shape=box, label="Write the file or copy to the clipboard\nper the answer"];
  done     [shape=doublecircle, label="Done"];

  start -> deduce -> craft -> ctx;
  ctx -> fix [label="no"];
  fix -> craft;
  ctx -> val [label="yes"];
  val -> fix [label="no"];
  val -> ask [label="yes"];
  ask -> deliver -> done;
}
```

## Deduce the contextual requirements

Read the current session and the user's request, then settle each dimension from what this session actually did. If the user's request fixes a dimension, follow it exactly; otherwise take the most grounded default.

| Dimension | Resolve from context |
|---|---|
| **Work type** | What the receiver must do: implement a spec, apply review or report fixes, turn review findings into a proposal (re-verify each finding, propose concrete changes, then wait for approval), continue an analysis, or hand off the next phase. |
| **Authoritative sources** | The file(s) that are the contract (spec, review, report, plan) plus the convention, naming, and reference files the receiver must obey. |
| **Branch** | Stay on the current branch, or create a new one and off which base. |
| **Commit policy** | Single commit, one per change bundle, or a fixed count; title-only or full; which skill writes the messages; what must never be staged. |
| **Verification** | The tooling and tests to run and when (before each commit, before done) — mirror what this session used. |
| **Scope** | What is in scope, and explicitly what is out. |
| **Settled vs open** | The decisions already locked, and the open choices the receiver should surface up front rather than guess. |
| **Uncertain** | What this session could not verify or is unsure about, so the receiver re-checks it rather than trusting it. |

## What the handoff must contain

This is the specification you hand to the crafting skill. Include each section the deduced work type needs, in this order.

1. **Mission** — one sentence the receiver can hold the whole task against.
2. **Framing** — it is a fresh session; all context is in the prompt and the referenced files; it should read them first and not re-derive the design.
3. **First action** — the single unambiguous first move (read the spec in full; verify the current branch before editing).
4. **Required reading** — an ordered list; each entry is a file path plus what it authoritatively holds (the contract; the review or report; naming and convention docs; the reference implementation to mirror).
5. **Branch** — where to work, and how to create the branch when it is new.
6. **Build order** — the work as atomic, independently committable units or bundles, in order. Pin the contract precisely, but mark cited `file:line` locations as entry points to re-read before editing, since they drift as commits land.
7. **What is settled, what is open** — the locked decisions and already-verified-sound points the receiver must not re-litigate, and the open questions it should surface up front rather than guess.
8. **Trust the code, not this prompt** — direct the receiver to treat each cited finding or assumption as a hypothesis to re-verify against current code, and call out the known traps this session hit so the receiver does not rediscover them.
9. **Engineering discipline** — the per-change conventions and the verification or tooling gate, exactly as this session applied them; push noisy work (large reads, independent reviews) into subagents to keep the receiver's context clean.
10. **Commit discipline** — commit granularity, where the messages come from, explicit-pathspec staging, and what must never be staged.
11. **Scope** — the in-scope work and, just as explicitly, the out-of-scope items.
12. **Escalation boundary** — the line between deciding autonomously and stopping to surface a question (an ambiguity, or a spec that no longer matches the code), and the requirement to get explicit user consent before any irreversible or shared-state action (push, PR, issue, deletion, deploy).
13. **Definition of done** — evidence-based, testable acceptance criteria the receiver confirms by running the check and showing real output, not by asserting it should work; then stop, report, and write a feedback note back to the originating session.

## Craft it with prompt-engineering

Invoke the `llm-author:prompt-engineering` skill to write the prompt. Give it as the specification: the dimensions you deduced and the section list above, plus these two standing constraints it must honor — the prompt stands alone for a zero-context reader, and every value in it is concrete and from this session. Take its output as the draft, then run the two checks below.

## Make it stand alone for a zero-context reader

Reread the draft as the receiver — a session that knows only what the prompt says. For every decision, value, and rationale it relies on, confirm the prompt states it inline or points to a named file that holds it. Where the draft leans on shared memory ("the analysis we did", "the agreed approach"), name the gap and send it back through prompt-engineering with the statement or file reference supplied.

## Write concrete, real values

Take every commit hash, file path, class or symbol name, line number, and test count from this session's context, and write the exact value — not a vague placeholder ("the config file") and not an invented one that merely looks right. For anything this session does not hold, the prompt must tell the receiver how to obtain it — run the command, read the file. If you find a placeholder or an invented value, send the draft back through prompt-engineering to fix it.

## Ask how to deliver, then deliver

Present the finished prompt in your reply. Then ask whether to save it to a file or copy it to the clipboard — choose neither by default. Deliver it according to the answer.
