@README.md

## Directory & File Structure

```
plugins/native-tools-enforcer/
├── README.md
├── CLAUDE.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json                       # SessionStart + PreToolUse hooks
│   ├── prompts/
│   │   ├── native-tools-new.md          # SessionStart directives (new mode)
│   │   └── native-tools-classic.md      # SessionStart directives (classic mode)
│   └── scripts/
│       ├── session-start.sh             # SessionStart entry — picks prompt by mode
│       ├── check-native-tools.sh        # PreToolUse entry — resolves mode, branches
│       └── lib/
│           └── detect-mode.sh           # nte_resolve_mode() — shared library
└── skills/
    └── setting-up/
        ├── SKILL.md                     # LLM-facing instructions
        └── scripts/
            └── probe.sh                 # Environment probe (JSON out)
```

## Key Functions

### `nte_resolve_mode()` (in `lib/detect-mode.sh`)
Sets `NTE_MODE` to one of `new|classic|pass` from env var + `uname -s` + `command -v bfs`/`ugrep`. Pure function.

### `check_and_block(pattern, tool, description)` (in `check-native-tools.sh`)
Exits 2 with a formatted message if `$command` matches `$pattern`. Calls `nte_log` before exit.

### `warn_about_native(pattern, tool, tip)`
Writes a tip to stderr but exits 0. Calls `nte_log` before returning.

### `nte_log(mode, decision, command)`
Silent no-op when `NATIVE_TOOLS_ENFORCER_DEBUG` is unset. Appends one TSV line to `$CLAUDE_PLUGIN_DATA/debug.log`.

## Navigation

| Task | File |
|---|---|
| Change detection cascade | `hooks/scripts/lib/detect-mode.sh` |
| Change per-mode block messages | `hooks/scripts/check-native-tools.sh` — per-section mode-branches |
| Change SessionStart injected directives | `hooks/prompts/native-tools-{new,classic}.md` |
| Change SessionStart emit logic (drain, JSON wrap, pass-through) | `hooks/scripts/session-start.sh` |
| Change probe JSON schema | `skills/setting-up/scripts/probe.sh` + `skills/setting-up/SKILL.md` (update field docs) |
| Extend skill workflow | `skills/setting-up/SKILL.md` |
| Adjust hook timeout | `hooks/hooks.json` |

## Testing

BATS tests in `plugin-tests/native-tools-enforcer/`:

```bash
# Setup (first time only)
./.github/scripts/setup-bats.sh

# Run all tests
.bats/bats-core/bin/bats plugin-tests/native-tools-enforcer/*.bats

# Filter by tag
.bats/bats-core/bin/bats --filter-tags detect   plugin-tests/native-tools-enforcer/*.bats
.bats/bats-core/bin/bats --filter-tags messages-new plugin-tests/native-tools-enforcer/*.bats
.bats/bats-core/bin/bats --filter-tags logging plugin-tests/native-tools-enforcer/*.bats
.bats/bats-core/bin/bats --filter-tags probe   plugin-tests/native-tools-enforcer/*.bats
.bats/bats-core/bin/bats --filter-tags session-start plugin-tests/native-tools-enforcer/*.bats
```

### Mocking

`plugin-tests/native-tools-enforcer/test_helper/mode_setup.bash` provides `mode_set os=... bfs=1 ugrep=1 force_new=0 debug=0` for PATH-based mocking. Call `mode_setup_init` in `setup()` and `mode_setup_cleanup` in `teardown()`.

## Manual Test Checklist for the Skill

Run the `setting-up` skill and walk each path:

- [ ] Fresh macOS with no bfs/ugrep → skill offers `brew install bfs ugrep`, runs on confirmation, re-probes, reports ready.
- [ ] macOS with bfs+ugrep already installed → skill reports ready, no config needed.
- [ ] User asks to pin force-new when ready → skill writes env var, shows diff, `jq` validates.
- [ ] Linux (any distro) with apt/dnf/pacman → skill prints install command, does not run sudo.
- [ ] Windows (detected) → skill reports classic mode, advises not to set env var.
- [ ] Malformed `~/.claude/settings.json` → skill reports jq error, makes no changes.
- [ ] User asks to unset env var → skill runs `jq 'del(...)'`, cleans up empty `.env`.

## Related Issues

- https://github.com/anthropics/claude-code/issues/1386
- https://github.com/anthropics/claude-code/issues/10056
- Claude Code 2.1.117 changelog: native macOS/Linux builds use embedded bfs/ugrep via Bash.
