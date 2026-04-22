A PreToolUse hook in this session blocks Bash commands that should use Claude Code native tools or the native-build Bash helpers `bfs`/`ugrep`.

- **Read / Write / Edit** tools — replace `cat`, `head`, `tail`, `less`, `more`, `echo >`, `printf >`, `cat >`, `| tee`, `sed`, `awk`, `perl -i`, heredoc-to-file.
- **`bfs`** in Bash — replaces `find`, `locate`. Example: `bfs . -name "*.ts"`.
- **`ugrep`** in Bash — replaces `grep`, `rg`, `ag`, `ack`. Example: `ugrep -r "pattern" .`.

Piping command output to `grep`/`ugrep` is allowed (`git log | grep feat`, `ps aux | grep node`). Piping file contents (`cat file | grep ...`) is blocked — let `ugrep` open the file directly.
