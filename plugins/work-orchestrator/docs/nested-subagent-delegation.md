# Nested subagent delegation

Which agent definitions may spawn their own subagents, and why the plugin makes that opt-in per dispatch. Most of this file records judgement, not measurement: no experiment was run for the roster split. The enabling fact — Claude Code permits the Agent tool inside a subagent — is a harness capability observed by the maintainer, re-checkable by spawning any definition without `Agent` in `disallowedTools` and asking it to call the tool. The Definition-named spawn invariant below is the exception: it is read directly from Claude Code's shipped internal type declarations (`mods/types/claude-code.d.ts` in `anthropics/claude-code`, `AgentSpawnInput`/`AgentSpec`) and the published `@anthropic-ai/claude-agent-sdk` `.d.ts`, not inferred from behavior.

## The roster

Ten definitions carry the Agent tool; five keep the ban. The split follows each definition's contract, not the model tier.

| Definition | Agent tool | Reason |
|---|---|---|
| `implement-sonnet-medium`, `implement-sonnet-high`, `implement-opus-medium`, `implement-opus-high`, `implement-opus-xhigh` | yes | Implementation contains delegable read-only legwork — locating call sites, tracing reach, sweeping a convention — that otherwise consumes the implementer's context before it writes a line. The fence survives because a spawned subagent is read-only: the worker stays the only writer inside its fence. |
| `investigate-sonnet-high` | yes | Adversarial claim-checking across a repository benefits from search fan-out; the verdict stays with the checker. |
| `investigate-opus-medium`, `investigate-opus-high`, `investigate-opus-xhigh` | yes | Judgement across artifacts sits on top of enumerable evidence-gathering; the evidence chain and the verdict stay with the worker. |
| `design-opus-xhigh` | yes | Designing against unfamiliar code is mostly exploration; fan-out reading serves it, and every decision stays with the designer. |
| `search-haiku`, `investigate-haiku`, `gate-run-haiku` | no | The routing table gives haiku decision-free instructions because it does not recover from its own wrong guesses. Choosing what to spawn, with which prompt and model, is a decision. These are also the leaf duties other workers would spawn. |
| `investigate-sonnet-low` | no | Its contract forbids widening a fixed scope; a spawn is a widening. |
| `investigate-sonnet-medium` | no | Its contract is to read one source end to end itself. A subagent's summary of a chunk substitutes a paraphrase for the reading, which is the failure the definition exists to avoid. |

## Why opt-in and explicit

A spawn multiplies cost and adds an unverified voice, so the orchestrating session — not the worker — decides. The strategy declares nested delegation per checkpoint, on only when the user asked for it in the conversation or the checkpoint's scope makes the delegable legwork plain. Every subagent dispatch then carries one of two directives (`worker-prompts.md` §Nested subagents); the default form is "Spawn no subagents." Silence is never the signal, in either direction — a definition that carries the tool still spawns nothing without the directive.

## Preserved invariants

- **Fence**: a spawned subagent is read-only. Repo writes stay with the dispatched worker, inside its fenced file list plus its report file.
- **Confirmation independence**: a subagent a worker spawned is part of that worker. It never serves as the independent confirmer, and its output relaxes no verification requirement.
- **Non-delegable duties**: verdict, report contract, and gate execution stay with the worker its dispatch named.
- **Definition-named spawn**: each nested spawn sets `subagent_type` to the plugin's own leaf-duty definition for the purpose (`search-haiku`, `investigate-haiku`, `investigate-sonnet-low`, `investigate-sonnet-medium`), never a bare model and never a built-in type. Confirmed against Claude Code's internal `AgentSpawnInput`/`AgentSpec` types: a plugin's own named agent resolves through `subagentType` exactly like a built-in, and `effort` lives only on the static definition, never on the spawn call. So the definition's own effort binds the nested spawn exactly as it would a top-level dispatch — a nested spawn selects a rung by selecting the definition that carries it.
