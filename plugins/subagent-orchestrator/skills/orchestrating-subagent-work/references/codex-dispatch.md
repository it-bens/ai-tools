# Codex dispatch

Codex-specific invocation mechanics. The prompt blocks a codex worker receives are worker-shaped, not codex-shaped, and live in `worker-prompts.md`; read that file for what goes into the prompt and this one for how the process is invoked.

## Invocation hygiene

- CLI only: `codex exec` (and `codex exec resume` for re-validation). Never an MCP transport.
- Codex dispatches run sequentially — never two codex processes against the working tree at once. Read-only claude subagents may run in parallel with a background codex run.
- Every invocation passes explicitly: `-m <model>`, `-c model_reasoning_effort=<effort>`, `-c approval_policy=never`, `--sandbox read-only` (reviews) or `--sandbox workspace-write` (implementers), `--disable memories`, `-C <repo root>`. Never rely on `~/.codex/config.toml` defaults.
- `codex.extra_config` supplies additional `-c key=value` flags appended to every invocation; default if not otherwise stated: none — the flags above only. Appends only: reject an assignment that would set `approval_policy`, `sandbox_mode`, `model_reasoning_effort`, the model, or `--disable memories`, since those carry the dispatch's safety and routing contract.
- The prompt is a file piped on stdin.
- Never instruct codex to avoid running shell commands — its file reads are shell commands.

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

A codex-less review checkpoint has no resume equivalent: re-validation there is a fresh independent worker against the same scope, and the trust boundaries in `worker-prompts.md` apply unchanged.
