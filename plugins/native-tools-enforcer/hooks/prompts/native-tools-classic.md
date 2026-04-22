A PreToolUse hook in this session blocks Bash commands that should use Claude Code native tools.

- **Read / Write / Edit** tools — replace `cat`, `head`, `tail`, `less`, `more`, `echo >`, `printf >`, `cat >`, `| tee`, `sed`, `awk`, `perl -i`, heredoc-to-file.
- **Glob** tool — replaces `find`, `locate`. Patterns: `**/*.ts`, `src/**/*.py`.
- **Grep** tool — replaces `grep`, `rg`, `ag`, `ack`. Supports regex; searches files on disk.

Piping command output to `grep` is allowed (`git log | grep feat`, `ps aux | grep node`). Piping file contents (`cat file | grep ...`) is blocked — use the Grep tool directly on the file.
