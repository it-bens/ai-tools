# Research & Knowledge Base — Session Handoff & Feedback Skills

Background and provenance for the `writing-handoff-prompts` and `writing-session-feedback` skills. This file is documentation, not loaded into context at runtime — per the project's "no provenance in skill content" rule, the citations and rationale live here, while the `SKILL.md` bodies carry only the distilled, imperative result.

Two inputs shaped the skills:

1. **Web research** on real-world experience with session/agent handoffs (Part 1).
2. **Knowledge provided by the maintainer** about prompt writing and context engineering, plus the invariants extracted from the `shopware/shopware` sessions that originated this work (Part 2).

Part 3 maps each finding to the skill element it produced.

---

## Part 1 — Web research (distilled)

### 1.1 The core pattern: reset + structured handoff beats compaction

- A **context reset** (clear the window, start a fresh agent) **plus a structured handoff artifact** that carries the prior agent's state and next steps is *better* than compaction. Compaction preserves continuity but does not give a clean slate, so "context anxiety" (the model wrapping up prematurely as it nears its limit) persists. A reset removes that, "at the cost of the handoff artifact having enough state for the next agent to pick up the work cleanly." [Anthropic]
- **A fresh session with a complete handoff outperforms a stale, compacted one** — it starts with a clean context budget instead of fragmented, summarized history. [CyPack, jdhodges]
- **Hand off *state*, not the transcript.** Raw chat history mixes correct decisions, discarded ideas, and dead ends; a handoff separates *state* from *history*. "Structure beats elegance" — structured fields beat polished prose. [Prompt Handoff Pattern]
- **Model capability shifts how much handoff scaffolding is needed.** Claude Sonnet 4.5 exhibited context anxiety strongly enough that resets were essential; Opus 4.5/4.6 could drop them. Lesson: "every harness component encodes an assumption about what the model can't do… strip stale scaffolding" as models improve. [Anthropic]

### 1.2 What a handoff should contain (convergent across sources)

- **Lightweight template:** Goal · Current state · Decisions made (locked) · Open questions · Next step · References. Each field has a distinct job — Goal prevents drift, Current state prevents duplicate work, Decisions prevents re-litigation, Open questions marks where thinking remains, Next step gives momentum. [Prompt Handoff Pattern]
- **Heavyweight community protocol (12 sections):** smart context loading (3-layer auto/mandatory/on-demand manifest), service health, master scope (in/out), layered strategy with success criteria, serialized task state, triggers, references (file paths, endpoints, performance baselines, known bugs), **evidence-based success definition**, open decisions, start command. Insists on **no placeholders — every value concrete and real**, and "'Should work' is NOT valid evidence. RUN the command, show output, THEN claim." [CyPack]
- **Define "done" before the work, but don't over-specify implementation.** Anthropic's generator/evaluator "negotiated a sprint contract" on what *done* looked like before any code was written; their planner stayed high-level because over-specified technical detail "cascades into the downstream implementation" when wrong. Implication: pin the *contract* precisely, but mark granular `file:line` details as entry points to re-verify against current code. [Anthropic]

### 1.3 Handoff & feedback failure modes

- **Three recurring failures:** (1) **lost state** — work restarts without durable context; (2) **weak escalation design** — risky / low-confidence actions routed poorly; (3) **unclear uncertainty signals** — confidence hidden or badly verbalized, so reviewers cannot vary scrutiny. [Augment]
- **Plausible incorrectness:** "the agent returns code with no uncertainty signal; reviewer burden is identical whether the output is correct or subtly broken." Surface confidence so scrutiny can vary by risk. "Trust is better calibrated when systems make their limits as legible as their capabilities" (Lee & See, 2004). [Augment]
- **Escalation / high-risk action gates:** irreversible operations (file deletion, DB migration, deploy) should pause for explicit approval; cap retries/actions and escalate on exceed. [Augment, citing OpenAI; LangGraph interrupts; Microsoft AG-UI]
- **Self-evaluation leniency (the strongest finding for feedback):** "agents tend to respond by confidently praising the work — even when, to a human observer, the quality is obviously mediocre." A QA agent would "identify legitimate issues, then talk itself into deciding they weren't a big deal and approve the work anyway." Tuning a *separate* evaluator to be skeptical is far more tractable than making a generator critical of its own work. [Anthropic]
- **Context Completeness Score** — "whether the receiving party can continue without re-investigation" — is the quality metric for a handoff. [Augment]

### 1.4 In-the-loop vs on-the-loop

In-the-loop reviewers fix the artifact; **on-the-loop** reviewers "change the system that produced it." The feedback skill targets the on-the-loop mode: it exists to improve the upstream session's *next* spec or review, not just to report this one. [Augment, citing Fowler]

### 1.5 When to hand off

Before a context reset, before switching from research to implementation, before pausing, before changing tools or models, or "if resuming the task would take more than ten minutes of reconstruction." Do it *before* context degrades (well before the auto-compaction threshold). [Prompt Handoff Pattern, jdhodges]

### Sources

- Anthropic — *Harness design for long-running application development*: <https://www.anthropic.com/engineering/harness-design-long-running-apps>
- Anthropic — *Effective context engineering for AI agents*: <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>
- *The Prompt Handoff Pattern* (DEV Community): <https://dev.to/novaelvaris/the-prompt-handoff-pattern-make-ai-work-survive-session-resets-and-team-handoffs-5bf0>
- Augment Code — *Agent Handoff Patterns: Human-Agent Interface Guide*: <https://www.augmentcode.com/guides/agent-handoff-patterns-human-agent-interface>
- CyPack — *Claude Code Session Handoff Protocol* (12-section community protocol): <https://github.com/CyPack/claude-session-handoff>
- jdhodges — *Claude Handoff Prompt: How to Keep Context Across Sessions*: <https://www.jdhodges.com/blog/ai-session-handoffs-keep-context-across-conversations/>

Access note: direct Reddit threads were not retrievable (WebSearch blocks `reddit.com` and no Reddit MCP was available in the authoring session); the experiential angle came from practitioner write-ups and the community protocol above.

---

## Part 2 — Maintainer-provided knowledge (prompt writing & context engineering)

These principles were supplied by the maintainer during design, or extracted from the `shopware/shopware` sessions that the skills are modeled on. They are the load-bearing design constraints; the web research sharpened the content within them.

### 2.1 The zero-context invariant (the spine of the handoff)

A fresh session has **none** of the originating session's context. Every relevant fact must be either stated inline in the prompt or reachable through an explicit file reference. This invariant appeared verbatim across the maintainer's own handoff prompts ("the session won't have any of the information you gathered… information must either be given directly or indirectly by referencing a file that contains it").

### 2.2 Two directions, two purposes

- **Handoff = forward.** Package a defined unit of work for a fresh, zero-context session to execute.
- **Feedback = backward.** Report to the **upstream** session that defined the work (it wrote the spec, performed the review, or made the plan) so it can (a) confirm the work was done correctly and (b) **calibrate** its future specs and reviews. The feedback's value is the *calibration*, not the status report.

### 2.3 Abstraction over the kind of work

Stay abstract. The dominant historical case was spec implementation, but the skills must also cover applying review/report fixes, turning review findings into a proposal, continuing an analysis, and handing off the next phase. Deduce the work type, branch, commit and verification policy, scope, and recipient from context — do not harden the spec case into the spine.

### 2.4 Triggering and invocation

- **Model-invoked, not a user slash command** (`user-invocable: false`): hidden from the `/` menu, but Claude can invoke it.
- **Narrow, not proactive:** invoke *only* when the user explicitly asks for a handoff prompt or feedback for another session. Narrowness is enforced by the description wording, not a frontmatter field.
- **Description-only:** `when_to_use` is concatenated onto `description` in the skill listing, so the trigger cues live in `description` and `when_to_use` is omitted.

### 2.5 Delivery: ask, don't assume

The maintainer's source prompts said "copy to the clipboard," but that must **not** be the default. After producing the artifact, ask the user (via `AskUserQuestion`) and offer to save it to a file *or* copy it to the clipboard.

### 2.6 Craft via the prompt-engineering skill (nested skills)

The handoff/feedback is itself an LLM-targeted prompt, so each skill crafts its output by invoking `llm-author:prompt-engineering` (nested skill use) rather than hand-writing it, then applies its own checks to the draft.

### 2.7 Positive framing

State positively what to **do** and what to **write**. Do not author "what NOT to do" / fabricated anti-pattern lists up front; such lists are only justified later, as targeted fixes once a real unaligned behavior is observed.

### 2.8 Tool-restriction facts (harness/context-engineering knowledge, verified against docs)

- `allowed-tools` **grants per-use auto-approval; it does not restrict** — "every tool remains callable." It declares a skill's working toolset, it does not fence it.
- `disallowed-tools` is the field that **removes** tools from the pool; there is no documented all-tools wildcard, and the restriction clears on the next user message.
- `model:` accepts `opus` / `sonnet` / `haiku` / `inherit`. A skill may invoke another skill via `allowed-tools: Skill(plugin:skill-name)`.
- These skills use `allowed-tools: Skill(llm-author:prompt-engineering), AskUserQuestion, Write` and `model: sonnet`.

### 2.9 Calibrated honesty

Confirm what is sound, flag what is not; be neither sycophantic nor reflexively contrarian. This is the maintainer's standing principle and is the behavioral backbone of the feedback skill (reinforced by the self-evaluation-leniency research in 1.3).

### 2.10 Keep it lean

Prefer corrections over additions; shorter is better. The skills deliberately do not adopt the community protocol's full 12 sections / 50+ triggers — they encode only the high-value elements, and stay abstract so they survive model improvements.

---

## Part 3 — How research + knowledge map to the skills

| Source finding / principle | Skill element |
|---|---|
| Zero-context invariant (2.1); Context Completeness Score (1.3) | Handoff "stand alone for a zero-context reader" gate; framing line |
| Hand off state, not transcript (1.1) | Handoff intro framing |
| Mission / first action / next step (1.2) | Handoff sections 1–3 (mission, framing, first action) |
| Locked decisions; open questions (1.2); don't over-specify, mark details re-verifiable (1.2) | Handoff "what is settled, what is open" + "trust the code, not this prompt" + `file:line` drift note |
| Escalation / high-risk action gates (1.3) | Handoff "escalation boundary" section |
| Evidence-based "done"; "should work is not evidence" (1.2) | Handoff "definition of done" (testable, run-and-show) |
| No placeholders + no invention (1.2, 2.7) | Handoff "write concrete, real values" check |
| Self-evaluation leniency (1.3) | Feedback intro + "keep every item a calibration" (default to scrutiny) |
| Unclear uncertainty signals; plausible incorrectness (1.3) | Feedback per-item confidence/uncertainty tags; "carry real evidence and a confidence signal" check |
| On-the-loop calibration (1.4) | Feedback purpose; "under-specified by you" + "open questions back" sections |
| Two directions, two purposes (2.2) | The two separate skills |
| Narrow model-only triggering (2.4) | `user-invocable: false` + explicit-request description |
| Ask, don't default to clipboard (2.5) | Both skills' "ask how to deliver, then deliver" step |
| Craft via prompt-engineering (2.6) | Both skills' "craft it with prompt-engineering" step |
| Keep lean (1.1, 2.10) | Deliberate non-adoption of the 12-section / 50+ trigger protocol |
