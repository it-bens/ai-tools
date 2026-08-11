# Subagent report delivery — findings

Why the skill dispatches workers without a name, and where the recovery path for a missing report comes from. Statements here describe what was measured on 2026-08-06; the directives built on top live in `skills/orchestrating-subagent-work/SKILL.md`.

The failure this documents is quiet by construction. A worker that never delivers still finishes, still goes idle, and still leaves a complete report behind — just not anywhere the dispatcher reads. Nothing errors, so an orchestrator that does not check for arrival will close the checkpoint on a report it never saw.

## Three dispatch shapes, two of which deliver

| Shape | Report reaches the dispatcher |
|---|---|
| Unnamed spawn | yes, automatically |
| Named spawn, report block silent about sending | no |
| Named spawn, report block naming the send as the final action | yes |

A name is what changes the contract. An unnamed spawn is a delegated subtask whose final text is returned to whoever dispatched it. A named spawn is an addressable teammate: its final text is its own, and reaching anyone requires it to call a message-sending tool. The worker is not told this in a way it acts on — both shapes produce a report, and only one of them produces a delivery.

## The runs

Five dispatches of the shipped `gate-run-haiku` definition against the same small task, varying only whether the spawn carried a name and, for the named runs, whether the REPORT block contracted a send.

| Run | Shape | Execution | Outcome |
|---|---|---|---|
| 1 | unnamed | synchronous | report arrived, no send performed |
| 2 | unnamed | background | report arrived, no send performed |
| 3 | named | — | complete report as final text, nothing delivered |
| 4 | named | — | complete report as final text, nothing delivered |
| 5 | named, send contracted in the REPORT block | — | report delivered on the first pass |

Runs 3 and 4 were then poked with a follow-up message reading `Report.` Each regenerated its report as final text and again delivered nothing. Re-prompting a named worker is therefore not a recovery path — it reproduces the same non-delivery at the cost of a second run.

## The sending tool has to be loaded before it can be called

The message-sending tool was not among the tools loaded by default in the worker's session. The one worker that delivered had to look up the tool's schema before it could call it. That inserts a step between intending to report and reporting, and a worker that fails at that step has no signal that it failed: it wrote a report, it believes it reported, and it says so. A worker's claim to have sent a report is therefore evidence about the worker's intent, never evidence that the report exists on the other end.

This also settles what the unnamed runs prove. A definition that grants a worker no tools at all cannot call a sending tool under any circumstances, so a report arriving from such a worker cannot have been sent by the worker — the automatic return path carried it. This is a deduction from the tool grant rather than a separate measurement; the runs above used a definition with tools, and no send was observed in runs 1 and 2.

## The idle signal carries a summary only when a send happened

When a worker goes idle, the signal reaching the dispatcher carries a summary field only in the case where a send actually occurred. Its presence is a positive indicator that something was delivered; its absence is consistent with a worker that finished with an undelivered report. Treat it as a check on arrival, not as the report — the summary is not the report's content.

## Recovering a report that never arrived

A worker's session persists under `~/.claude/projects/<project-slug>/<session-id>/subagents/`, and the report a non-delivering worker wrote is its final assistant block there. Extract that block only. These transcripts hold the worker's entire run, which is precisely the material the dispatch existed to keep out of the orchestrator's context; reading one whole spends more context than the dispatch saved. The path layout was confirmed on disk; the extraction itself was not exercised as part of these five runs.

## Limits

Stated because they bound what the table above supports.

One agent definition, one small task, five runs — the definition and the task were held constant across all five, so the runs establish nothing about a different definition or a larger task, though there is no mechanism suggested by these runs that would make either behave differently.

The decisive difference was visible in the dispatch acknowledgement itself, not only in the outcomes. The acknowledgement for a named spawn describes a different relationship from the one for an unnamed spawn. So these runs corroborate a distinction the dispatch surface already makes rather than discovering a hidden one, which raises confidence in the direction of the finding and lowers the value of the sample size as independent evidence.

Runs 3 and 4 are the only observations of the follow-up poke, and both were on the same definition. That a re-prompt reproduces non-delivery is a two-run result.
