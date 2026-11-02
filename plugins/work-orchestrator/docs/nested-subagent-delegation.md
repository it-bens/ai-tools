# Nested subagent delegation

Which agent definitions may spawn their own subagents, and why the plugin makes that opt-in per dispatch. Most of this file records judgement, not measurement: no experiment was run for the roster split. The enabling fact — Claude Code permits the Agent tool inside a subagent — is a harness capability observed by the maintainer, re-checkable by spawning any definition without `Agent` in `disallowedTools` and asking it to call the tool. The Definition-named spawn invariant below is the exception: it is read directly from Claude Code's shipped internal type declarations (`mods/types/claude-code.d.ts` in `anthropics/claude-code`, `AgentSpawnInput`/`AgentSpec`) and the published `@anthropic-ai/claude-agent-sdk` `.d.ts`, not inferred from behavior.

## The roster

Six definitions carry the Agent tool; five keep the ban. The split follows each definition's contract, not the model a spawn runs it on. Until 4.6.0 the plugin shipped one definition per model and effort, and ten of those fifteen carried the tool; 5.0.0 merged them into one definition per duty and kept each duty's side of the split.

| Definition | Agent tool | Reason |
|---|---|---|
| `implement` | yes | Implementation contains delegable read-only legwork — locating call sites, tracing reach, sweeping a convention — that otherwise consumes the implementer's context before it writes a line. The fence survives because a spawned subagent is read-only: the worker stays the only writer inside its fence. |
| `adversarial-check` | yes | Adversarial claim-checking across a repository benefits from search fan-out; the verdict stays with the checker. |
| `escalated-check`, `root-cause`, `source-conflict` | yes | Judgement across artifacts sits on top of enumerable evidence-gathering; the evidence chain and the verdict stay with the worker. |
| `design` | yes | Designing against unfamiliar code is mostly exploration; fan-out reading serves it, and every decision stays with the designer. |
| `search`, `extract`, `gate-run` | no | These duties are decision-free: the routing table runs them on haiku with decision-free instructions, so their output reaches a decision only through verification (`model-routing.md`). Choosing what to spawn, with which prompt and model, is a decision. These are also the leaf duties other workers would spawn. The earlier framing of this row as a haiku recovery trait was never measured — no experiment was run for the roster split. |
| `lookup` | no | Its contract forbids widening a fixed scope; a spawn is a widening. |
| `source-read` | no | Its contract is to read one source end to end itself. A subagent's summary of a chunk substitutes a paraphrase for the reading, which is the failure the definition exists to avoid. |

## Why opt-in and explicit

A spawn multiplies cost and adds an unverified voice, so the orchestrating session — not the worker — decides. The strategy declares nested delegation per checkpoint, on only when the user asked for it in the conversation or the checkpoint's scope makes the delegable legwork plain. Every subagent dispatch then carries one of two directives (`worker-prompts.md` §Nested subagents); the default form is "Spawn no subagents." Silence is never the signal, in either direction — a definition that carries the tool still spawns nothing without the directive.

## Preserved invariants

- **Fence**: a spawned subagent is read-only. Repo writes stay with the dispatched worker, inside its fenced file list plus its report file.
- **Confirmation independence**: a subagent a worker spawned is part of that worker. It never serves as the independent confirmer, and its output relaxes no verification requirement.
- **Non-delegable duties**: verdict, report contract, and gate execution stay with the worker its dispatch named.
- **Definition-named spawn**: each nested spawn sets `subagent_type` to the plugin's own leaf-duty definition for the purpose (`search`, `extract`, `lookup`, `source-read`) and passes the `model` and `effort` that duty's routing-table row carries, never a bare model and never a built-in type. The dispatch directive names all three per purpose, because the worker has no access to the routing table. Confirmed against Claude Code's internal `AgentSpawnInput`/`AgentSpec` types: a plugin's own named agent resolves through `subagentType` exactly like a built-in. The same check found `effort` only on the static definition, not on the spawn call; that finding predates Claude Code 2.1.292, which added `effort` to the Agent tool, and the 2026-11-02 checks in `claude-effort-mechanism.md` show a spawn-time `effort` taking effect and overriding a definition's.
