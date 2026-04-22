---
name: setting-up
version: 2.1.1
description: Configure the native-tools-enforcer plugin on this machine. Detects OS, package manager, and whether bfs/ugrep are installed. Offers to install missing binaries (brew on macOS; prints the sudo install command on Linux). Persists a setting so the plugin always enforces native tools, on request. Use when the user says "set up native-tools-enforcer", "install bfs ugrep", "configure native tools enforcer", or "why is native-tools-enforcer not blocking find/grep".
model: haiku
---

# Setting Up native-tools-enforcer

Help the user configure this plugin for their environment. The plugin has three runtime modes:

- **new** — blocks find/grep family in Bash, recommends `bfs`/`ugrep`.
- **classic** — blocks find/grep family, recommends the Claude Code Grep/Glob tools.
- **pass** — silent, no enforcement.

Your job is to run the probe, interpret the result, and help the user reach their preferred state without creating loops.

## Step 1 — Run the probe

Invoke the probe script and parse its JSON output:

    bash "${CLAUDE_PLUGIN_ROOT}/skills/setting-up/scripts/probe.sh"

The output is one JSON line with these fields:

- `os` — `"macos" | "linux" | "windows" | "unknown"`
- `pkg_manager` — `"brew" | "apt" | "dnf" | "pacman" | "none"`
- `bfs_present`, `ugrep_present`, `env_var_set`, `settings_file_exists` — boolean
- `env_var_value` — string (e.g. `"1"`, `"true"`) or empty when unset
- `settings_file` — absolute path to `~/.claude/settings.json`
- `resolved_mode` — `"new" | "classic" | "pass"`

If the script exits non-zero or emits `{"error": "..."}`, stop and report the error to the user.

## Step 2 — Classify the state and act

Match in this order, so explicit user intent always wins over state:

1. **If the user stated an intent** — "pin force-new", "unset force-new", "install bfs/ugrep" — match the intent-driven case first: D, E, or F.
2. **Otherwise** match the state-driven case: A, B, or C.

Apply only one case per invocation.

### Case A — Ready, no action needed

**When:** `os ∈ {macos, linux}` AND `bfs_present=true` AND `ugrep_present=true`.

**Action:** The plugin is already in a working state. Branch on `env_var_set`:

- `env_var_set=false`: tell the user the plugin will auto-activate new mode — no configuration needed. Offer to pin behavior by setting `NATIVE_TOOLS_ENFORCER_FORCE_NEW=1` in `~/.claude/settings.json` (optional, Case E). If they decline, stop.
- `env_var_set=true`: tell the user the plugin is already pinned to new mode and both binaries are present — nothing to do. Only offer to remove the pin (Case F) if the user asks.

### Case B — Binaries missing on macOS/Linux

**When:** `os ∈ {macos, linux}` AND (`bfs_present=false` OR `ugrep_present=false`).

**Action:** First, branch on `env_var_set`:

- `env_var_set=false`: the plugin currently resolves to `pass` mode (no enforcement). Offer to install bfs/ugrep; once installed, the plugin auto-activates new mode.
- `env_var_set=true`: **stale pin** — the hook currently resolves to `new` mode and will recommend binaries that do not exist on this machine, so every `find`/`grep` block points the user at tools they cannot run. Tell the user plainly, then offer two paths:
  1. Install bfs/ugrep to make the pin correct (continue below).
  2. Unset the pin via Case F — plugin falls back to `pass` mode, no enforcement.

Do not write anything to `settings.json` until the user picks.

Then install based on `pkg_manager`:

- `brew`: propose `brew install bfs ugrep`. On confirmation:
  1. Run `brew install bfs ugrep` via Bash.
  2. Re-run the probe (Step 1) — the state has changed.
  3. Re-classify against the cases and continue from the new match. Do not stop before reporting a final state to the user.
- `apt`: print `sudo apt-get install -y bfs ugrep` for the user to run. Do not run it yourself. Ask them to re-invoke the skill when done (say "set up native-tools-enforcer" again, or run `/native-tools-enforcer:setting-up`).
- `dnf`: print `sudo dnf install -y bfs ugrep`. Same instructions.
- `pacman`: print `sudo pacman -S --needed bfs ugrep`. Same instructions.
- `none`: print upstream URLs and stop:
  - bfs: https://tavianator.com/projects/bfs.html
  - ugrep: https://github.com/Genivia/ugrep

If the install fails because a package is not in the distro's repos (most common for `ugrep` on older Ubuntu/Debian), redirect the user to the upstream URLs listed in the `pkg_manager=none` path above.

Do not run `sudo` commands yourself.

### Case C — Windows

**When:** `os=windows`.

**Action:** Explain that on Windows the plugin stays in classic mode (Grep/Glob tools work). Warn that setting `NATIVE_TOOLS_ENFORCER_FORCE_NEW` would force new-mode messages suggesting `bfs`/`ugrep`, which are typically not installed on Windows and would cause block loops. Advise against setting the env var.

If `env_var_set=true` (stale pin from a prior macOS/Linux setup, a synced dotfile, or a mistake), the hook is right now suggesting `bfs`/`ugrep` on a machine where they do not exist. Offer to unset the pin via Case F so the plugin returns to classic mode. Stop.

### Case D — User explicitly asks to force new mode, but binaries are missing

**When:** User asks to set `NATIVE_TOOLS_ENFORCER_FORCE_NEW=1`, AND (`bfs_present=false` OR `ugrep_present=false`).

**Action:** Refuse to write the env var. Explain the loop risk. Redirect to Case B to install binaries first.

### Case E — Force-new pin requested and binaries are present

**When:** User wants to set the env var, AND `bfs_present=true` AND `ugrep_present=true`.

**Action:** Merge the env entry into `~/.claude/settings.json` using the write procedure in Step 3. Show the diff before writing.

### Case F — User asks to remove the env var

**When:** User asks to unset `NATIVE_TOOLS_ENFORCER_FORCE_NEW`.

**Action:** Remove the key via `jq 'del(.env.NATIVE_TOOLS_ENFORCER_FORCE_NEW) | if .env == {} then del(.env) else . end'`. Show the diff before writing. Follow the write procedure in Step 3.

## Step 3 — Writing settings.json

**Before running any write block below:**

1. Show the user the exact JSON that will result from the write.
2. Wait for explicit confirmation ("yes", "go ahead", "ok").
3. Only then execute the write block.

No silent writes. If the user has not confirmed, stop and ask — even if a previous turn implied consent.

Always preserve every existing key. Always write atomically.

**To set the env var:**

    settings="${HOME}/.claude/settings.json"
    tmp="$(mktemp "${settings}.XXXXXX")"
    if [[ -f "$settings" ]]; then
        jq '.env.NATIVE_TOOLS_ENFORCER_FORCE_NEW = "1"' "$settings" > "$tmp"
    else
        mkdir -p "$(dirname "$settings")"
        printf '{"env":{"NATIVE_TOOLS_ENFORCER_FORCE_NEW":"1"}}' | jq '.' > "$tmp"
    fi
    mv "$tmp" "$settings"

**To remove the env var:**

    settings="${HOME}/.claude/settings.json"
    tmp="$(mktemp "${settings}.XXXXXX")"
    jq 'del(.env.NATIVE_TOOLS_ENFORCER_FORCE_NEW) | if .env == {} then del(.env) else . end' "$settings" > "$tmp"
    mv "$tmp" "$settings"

**If `jq` fails** (malformed JSON, syntax error), stop. Report the error to the user and ask them to fix settings.json manually. Do not overwrite a malformed file.

## Step 4 — End with a summary

Always close with one or two sentences naming:
- The mode the plugin will now resolve to.
- Whether the user needs to restart Claude Code (required if settings.json was modified or bfs/ugrep were freshly installed).

## Red flags — do not do these

- Do not run `sudo` commands yourself.
- Do not write `NATIVE_TOOLS_ENFORCER_FORCE_NEW` when bfs or ugrep are missing (Case D).
- Do not write to `settings.json` without first showing the user the resulting JSON and getting explicit confirmation.
- Do not write to the project-level `.claude/settings.json` — this skill is user-level (`~/.claude/settings.json`) only.
- Do not rewrite settings.json. Always merge via `jq`.
- Do not create a `.bak` file. The atomic `mv` is the safety net.
