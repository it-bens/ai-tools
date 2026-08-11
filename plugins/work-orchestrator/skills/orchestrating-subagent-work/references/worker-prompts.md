# Worker prompts

Every dispatched worker gets these blocks, whatever runs it. A codex worker and a subagent carrying the same scope get the same blocks and the same content; only the phrasing adapts to the model family the actor belongs to, per the ruleset derived for this task. A codex-less run keeps every block. Codex invocation mechanics live in `codex-dispatch.md`; nothing here is codex-specific.

Every prompt is fully self-contained. A worker has no session context and must need none.

## Extension content in worker prompts

A named value assigned by project extension content is inlined verbatim into the block that cites it. A worker inherits nothing from the session, so a value it never sees does not apply to it.

A named value that cites a project file by path passes as a path in SKILLS, not as inlined file content: codex reads it on disk under `-C <repo root>`, and a subagent is told to read it. Self-containment is satisfied by the path plus an explicit read instruction — never leave a worker to discover a file on its own.

## Review prompt blocks (in this order)

| Block | Content |
|---|---|
| CTX | Repo root, branch, commit; "No session context — everything you need is here or on disk." |
| OPS | Approval never; read-only; no writes, no network, no test execution; never wait for approval; finish with what you have and list anything missing. |
| SCOPE | File list or commit range; "the working tree is authoritative." Keep orchestration meta-files (run records, strategy documents) out of this block. |
| CONTRACT | The governing spec contract, quoted verbatim. |
| ADJ | Every adjudicated decision relevant to the scope, phrased: "documented accepted decisions — do not re-report unless the documented rationale no longer holds." The list must be complete for the scope; append every accepted-decision triage outcome to it and carry it into every subsequent review prompt. |
| SKILLS | Project skill files as required reading, when the scope warrants them. `project.skill_files` names them with the scope condition that warrants each; default if not otherwise stated: none registered. |
| LENS | Three to four named review lenses for the scope. `project.review_lenses` adds project lenses; default if not otherwise stated: none — name the lenses per scope. |
| OUT | Output contract: findings as `file:line — severity (blocking \| non-blocking) — what and why`, ranked, or an explicit "no findings"; no fix proposals beyond naming the defect. |

OUT and ADJ are mandatory in every review prompt.

## Implementer prompt blocks (in this order)

| Block | Content |
|---|---|
| CTX | Repo root, branch, commit, tree state (clean, or the dirty-tree fence). |
| FENCE | Named allowed files; no commit/stage/push; banned git verbs on a dirty tree; protected paths (`project.protected_paths`; default if not otherwise stated: none registered — name them per dispatch); banned command classes (`project.banned_commands`; default if not otherwise stated: e2e suites, containers, device tooling, deployments — assignments append to that list). |
| SKILLS | Project skill files as required reading, per `project.skill_files` as above. |
| RULES | Verbatim extracts of the project's conduct rules: fail-hard (no silent fallbacks), calibrated honesty (never claim an unrun gate passed), doc drift (every touched doc claim verified in the same change). `project.conduct_rules` adds further rules; default if not otherwise stated: those three — assignments append. |
| DESIGN | Per fix: defect with evidence, the decided design, explicit test duties, and the stop-and-report clause: "if the decided design contradicts what you find, STOP that item and report the contradiction; do not invent an alternative." |
| GATES | The project's verification gates with exact commands (format, typecheck, lint, test). Name any gate known to fail inside a worker sandbox and its one permitted fallback. Name the gates an independent worker re-runs after the run returns. `project.gates` supplies all of this; default if not otherwise stated: enumerate the gates from the project's build configuration at dispatch time. |
| REPORT | Per-fix status/files/tests/deviations; verbatim gate tails; an honest not-verified list. |

When a fix's true scope crosses packages, enumerate every affected file AND state the scope quantifier; a quantifier contradicted by a shorter file list gets implemented file-scoped.

## Trust boundaries

- A worker's own gate claim is never final, whatever produced it: an independent worker re-runs every gate before a green is accepted. For a codex implementer that re-run happens outside its sandbox.
- Review findings are hypotheses until an independent worker confirms them against source.
- An independent worker diff-reviews every worker-written change against each fix's decided design and test duties, and confirms the diff touches only fenced files and that no new untracked files appeared. The diff review and the independent gate re-run both happen after the batch returns; the checkpoint closes only when both pass.
- A worker result plus one independent worker confirmation is final; the orchestrator re-verifies only items routed to it by a deviation.
