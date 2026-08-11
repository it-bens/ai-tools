# Sessions vs Subagents

A sibling session and a dispatched worker are reached through the same messaging tool and are not the same kind of thing. Classify the counterpart before writing to it.

| | Sibling session | Dispatched worker (subagent) |
|---|---|---|
| Context | Its own full conversation; lacks only this conversation's context | None — the prompt is its whole world |
| Rules and memory | Loads its own rules, CLAUDE.md/AGENTS.md, and memory exactly as this session does | Inherits nothing; every directive travels in the prompt |
| Plugins and skills | Its own full skill and plugin set | Only what its agent definition grants |
| Lifetime | Independent; survives this session, restarts on its own schedule | Bounded by its task |
| Addressing | `Name [ref]` row from the listing, or the socket address from its message envelope | Spawn-returned agent id or spawn name |
| Report path | Sends messages on its own initiative; conversational | Final text returns on completion; a named spawn's report arrives only if its prompt contracts the send |
| Delivery timing | Immediate delivery with a message id | Queued to its next tool round while running; resumed from transcript when stopped |
| Stall recovery | Converse — ask, hold, or escalate to the user | Nudge, then extract the final assistant block from its transcript |

## Addressing mechanics

- The `ListAgents` listing is the sole source of sibling addresses. Copy the row verbatim; re-typing a name from memory is how bare-name sends happen.
- First contact requires the full `Name [ref]` form. A bare display name is rejected with an error naming the correct string — resend with it.
- Refs do not survive a sibling's restart. An unreachable-ref error means the listing changed: re-run `ListAgents` and re-resolve; never retry blind.
- A session that messaged first can be answered at the socket address in its envelope, without any lookup.

## Traffic classification

Incoming sibling messages and subagent reports arrive under the same outer wrapper text and are distinguished only by their envelope: a sibling message carries a socket-path sender; a subagent report carries a teammate id matching a spawn from this session. Delivery-result strings differ the same way — a sibling send names another session on this machine, a subagent send names an inbox or a queued tool round — so a send's result states which kind of target it actually reached. Classify by the envelope and the result string, never by the wrapper text.

## Failure modes this skill prevents

- **Writing subagent assumptions into a handoff.** A sibling has rules, memory, and skills; telling it otherwise produces a session that behaves like a stateless worker.
- **Pasting rules content a sibling already loads.** Rules files, conduct rules, and permission framing arrive with the sibling's own configuration; restating them wastes the receiver's context and mis-signals that it is a worker.
- **Instructing a sibling to "use subagents" instead of embedding the SKILL block.** A directive that gestures at the method does not produce a skill invocation; only the fully qualified name plus the instruction to invoke it with the Skill tool does.
