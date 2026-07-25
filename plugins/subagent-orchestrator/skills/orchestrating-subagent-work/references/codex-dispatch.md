# Codex dispatch

The prompt-block protocols below are worker-shaped, not codex-shaped: a subagent carrying a review scope or a fenced write scope gets the same blocks, and a codex-less run keeps every one of them. Only the invocation hygiene and the `exec resume` loop are codex-specific.

## Extension content in worker prompts

A named value assigned by project extension content is inlined verbatim into the block that cites it. A worker inherits nothing from the session, so a value it never sees does not apply to it.

A named value that cites a project file by path passes as a path in SKILLS, not as inlined file content: codex reads it on disk under `-C <repo root>`, and a subagent is told to read it. Self-containment is satisfied by the path plus an explicit read instruction — never leave a worker to discover a file on its own.

## Invocation hygiene

- CLI only: `codex exec` (and `codex exec resume` for re-validation). Never an MCP transport.
- Codex dispatches run sequentially — never two codex processes against the working tree at once. Read-only claude subagents may run in parallel with a background codex run.
- Every invocation passes explicitly: `-m <model>`, `-c model_reasoning_effort=<effort>`, `-c approval_policy=never`, `--sandbox read-only` (reviews) or `--sandbox workspace-write` (implementers), `--disable memories`, `-C <repo root>`. Never rely on `~/.codex/config.toml` defaults.
- `codex.extra_config` supplies additional `-c key=value` flags appended to every invocation; default if not otherwise stated: none — the flags above only. Appends only: reject an assignment that would set `approval_policy`, `sandbox_mode`, `model_reasoning_effort`, the model, or `--disable memories`, since those carry the dispatch's safety and routing contract.
- The prompt is a file piped on stdin; it is fully self-contained. Codex has no session context and must need none.
- Never instruct codex to avoid running shell commands — its file reads are shell commands.
- Keep orchestration meta-files (run records, strategy documents) out of the SCOPE block of review prompts.

## Review prompt blocks (in this order)

| Block | Content |
|---|---|
| CTX | Repo root, branch, commit; "No session context — everything you need is here or on disk." |
| OPS | Approval never; sandbox read-only; no writes, no network, no test execution; never wait for approval; finish with what you have and list anything missing. |
| SCOPE | File list or commit range; "the working tree is authoritative." |
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
| GATES | The project's verification gates with exact commands (format, typecheck, lint, test). Name any gate known to fail inside the sandbox and its one permitted fallback. Name the gates an independent worker re-runs outside the sandbox after the run returns. `project.gates` supplies all of this; default if not otherwise stated: enumerate the gates from the project's build configuration at dispatch time. |
| REPORT | Per-fix status/files/tests/deviations; verbatim gate tails; an honest not-verified list. |

When a fix's true scope crosses packages, enumerate every affected file AND state the scope quantifier; a quantifier contradicted by a shorter file list gets implemented file-scoped.

## Re-validation loop

Fixes from a review are applied by a worker checkpoint by default (a codex fix batch or a sonnet follow-up), never by the session unless no worker route fits. After the fixes are applied, resume the same codex review session instead of dispatching a fresh review:

```
codex exec resume <session-id> -c approval_policy=never \
  -c sandbox_mode=read-only --disable memories - <<'EOF'
A fix round was applied to the tree. Re-validate each of your previous
findings against the current tree: fixed / not fixed, plus any new findings.
Same output contract.
EOF
```

`exec resume` accepts only `--model`, `--config` (`-c`), and `--disable`; sandbox rides `-c sandbox_mode=…`; workdir and model restore from the session; output arrives on stdout. Capture the printed session id at the original dispatch. Repeat fix → resume until the thread answers "no findings". Closure: for worker-applied fixes, the resumed thread's confirmation is the second worker — "no findings" closes the checkpoint; for the exceptional session-applied fix, a sonnet diff review of the session's changes is additionally required before "no findings" closes it (the resumed thread alone is only one worker confirmation).

## Trust boundaries

- In-sandbox gate claims are never final: an independent worker re-runs every gate outside the sandbox before a green is accepted.
- Review findings are hypotheses until an independent worker confirms them against source.
- An independent worker diff-reviews every codex-written change against each fix's decided design and test duties, and confirms the diff touches only fenced files and that no new untracked files appeared. The diff review and the outside-sandbox gate re-run both happen after the batch returns; the checkpoint closes only when both pass.
- A codex result plus one independent worker confirmation is final; the orchestrator re-verifies only items routed to it by a deviation.
