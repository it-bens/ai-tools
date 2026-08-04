# ITB AI Tools

A collection of AI coding and productivity tools — skills, agents, hooks, and more — for Claude Code, Codex, and other AI coding assistants.

## Installation

### Claude Code

Add this marketplace to Claude Code:

```bash
/plugin marketplace add it-bens/ai-tools
```

Then browse and install plugins:

```bash
/plugin
```

### Codex

Add the repository as a Codex plugin marketplace:

```bash
codex plugin marketplace add it-bens/ai-tools
```

Then start Codex, open `/plugins`, and install any plugin marked as compatible below.

## Available Plugins

| Plugin | Description | Category | Codex compatibility |
|---|---|---|:---:|
| [behavior-diagnostics](./plugins/behavior-diagnostics/) | Debug AI tooling behavior with root cause analysis and honest self-diagnosis across sessions | Development | ❌ |
| [clipboard-copy](./plugins/clipboard-copy/) | Bash-based MCP server with cross-platform clipboard tools — `clipboard_copy` for inline text and `clipboard_copy_file` for an absolute file path; auto-detects pbcopy / wl-copy / xclip / xsel / clip.exe with an OSC 52 fallback, plus shared Claude Code/Codex hooks that prime the agent with MCP tool directives and block native clipboard-write Bash commands | Productivity | ✅ |
| [codex-integration](./plugins/codex-integration/) | Claude Code integration that consults OpenAI Codex for fresh perspective — auto-escalation when stuck, on-demand second opinions, and web research | Development | ❌ |
| [commit-message-writer](./plugins/commit-message-writer/) | Commit-message-writing skill for Conventional Commits. Mode detection (staged / squash / rewrite), a deterministic gather-script-driven workflow, anti-slop validation via the `human-author:ai-slop-writing-fixer` subagent (auto-installed by Claude Code and packaged separately for Codex), and validation mode. Extendable at every step via Pre-Step-N / Post-Step-N positions and via recognized named configuration values | Development | ✅ ([custom agent](./codex-subagents/) required) |
| [commit-message-writer-extension-setup](./plugins/commit-message-writer-extension-setup/) | One-time setup skill that provisions the shared overlay content and host-specific delivery configuration needed to extend the commit-message-writer plugin in Claude Code or Codex. Long plugin and skill names prevent accidental invocation | Development | ✅ |
| [dependency-update-triage](./plugins/dependency-update-triage/) | Read-only assessment of a single dependency update before adoption. Three prongs: required code changes, enabled improvements (including testability), and latent-bug reach from an upstream fix, each grounded in host-codebase call sites. Bounds large changesets into changed/added/fixed-bug inventories with criticality ranking and per-candidate disposition, routes work across cheap/mid/strong model tiers, detects ecosystem/forge/updater bot at runtime, and delivers the assessment to the clipboard | Development | ✅ (fan-out runs inline) |
| [explore-with-opus-enforcer](./plugins/explore-with-opus-enforcer/) | Enforces Opus model for Explore subagent for maximum exploration accuracy | Guardrails | ❌ |
| [explore-with-sonnet-enforcer](./plugins/explore-with-sonnet-enforcer/) | Enforces Sonnet model for Explore subagent to prevent lossy Haiku summaries | Guardrails | ❌ |
| [file-read](./plugins/file-read/) | Portable MCP `read_file` tool for local text files with `file_path`, `offset`, and `limit` arguments, returning line-numbered output so coding agents can avoid shell readers such as `cat`, `head`, `tail`, or `sed -n` | Development | ✅ |
| [human-author](./plugins/human-author/) | Author content that reads like a human wrote it — currently ships the ai-slop-writing-fixer subagent that scrubs LLM-pattern violations and returns the fixed prose with a structured change report | Productivity | ❌ |
| [llm-author](./plugins/llm-author/) | Author LLM-targeted content — prompts, skills, agents, rules files, plus session handoff and feedback prompts (model-invoked on explicit request, crafted via prompt-engineering) — for Claude 5 and Claude 4, GPT-5.6 (OpenAI), GLM 4.7, and Gemini 3 | Productivity | ✅ |
| [native-tools-enforcer](./plugins/native-tools-enforcer/) | Enforces native search tools (Grep/Glob on classic builds, bfs/ugrep on native macOS/Linux) via PreToolUse hook; SessionStart hook primes Claude with mode-appropriate directives; setup skill installs binaries and configures mode | Guardrails | ❌ |
| [plan-with-opus-enforcer](./plugins/plan-with-opus-enforcer/) | Enforces Opus model for Plan subagent for maximum reasoning depth | Guardrails | ❌ |
| [plan-with-sonnet-enforcer](./plugins/plan-with-sonnet-enforcer/) | Enforces Sonnet model for Plan subagent to ensure thorough architectural reasoning | Guardrails | ❌ |
| [project-communication](./plugins/project-communication/) | Turn repository activity into platform-formatted posts — currently ships changelog-summarizing for Discord and Slack with scope grouping and anti-AI-slop validation via the `human-author:ai-slop-writing-fixer` subagent (auto-installed via `dependencies`) | Productivity | ❌ |
| [python-plan-optimizer](./plugins/python-plan-optimizer/) | Analyze Python code in planning documents for design principles and improvement opportunities | Development | ❌ |
| [reddit-research](./plugins/reddit-research/) | Disciplined Reddit research via reddit-buddy MCP — call budget, truncation awareness, query craft, proactive opt-in | Development | ❌ |
| [redundant-read-blocker](./plugins/redundant-read-blocker/) | Prevent wasteful re-reads of unchanged files with smart range tracking and context decay | Guardrails | ❌ |
| [reviewing-plans-with-opus-enforcer](./plugins/reviewing-plans-with-opus-enforcer/) | Enforces Opus model for the reviewing-plans skill (from superpowers-additions); blocks invocation on non-Opus sessions via PreToolUse hook on Skill | Guardrails | ❌ |
| [software-writer](./plugins/software-writer/) | Three universal, opinionated skills for writing software — writing-code (API-consultation gate, dependency shape, stack footgun check, code-comment consistency gate, two-tier comment policy), writing-tests (classicist behavior-first workflow), and writing-docs (single-owner surfaces, pointer-file discipline, anti-slop validation via the `human-author:ai-slop-writing-fixer` subagent) — with per-stack references for Go, Python, TypeScript, and PHP. Extendable at every step via Pre-Step-N / Post-Step-N positions, recognized named values, and reference-like citations of project docs; ships the hooks that deliver a project's extension files wrapped in a structural envelope | Development | ✅ ([custom agent](./codex-subagents/) required for writing-docs anti-slop; extension delivery via `AGENTS.override.md`) |
| [software-writer-extension-setup](./plugins/software-writer-extension-setup/) | One-time setup skill that explores a project's codebase, drafts project-specific extension content conversationally, and writes the per-skill extension files for the software-writer plugin (Claude Code delivery ships with software-writer 2.x; Codex delivery via a committed `AGENTS.override.md`), with a re-sync mode that audits extension files for drift and migrates v1 setups. Long plugin and skill names prevent accidental invocation | Development | ✅ |
| [subagent-orchestrator](./plugins/subagent-orchestrator/) | Orchestrate implementation and review work through dispatched workers — Codex CLI (GPT-5.6) and Claude subagents — with a task-strategy workflow, evidence-based model routing, fenced write scopes, and independent two-worker verification. Extendable at five workflow positions via Pre-/Post- sections and recognized named configuration values; ships the hooks that deliver a project's extension file. The consent gate and dual-confirmation closure are deliberately fenced off from the contract | Development | ❌ |
| [subagent-orchestrator-extension-setup](./plugins/subagent-orchestrator-extension-setup/) | One-time setup skill that explores a project's gates, protected paths, conduct rules, and recurring checkpoint types, drafts the extension content conversationally, and writes the extension file for the subagent-orchestrator plugin, with a re-sync mode that audits it for drift. Long plugin and skill names prevent accidental invocation | Development | ❌ |
| [superpowers-additions](./plugins/superpowers-additions/) | Additions to the superpowers plugin — currently ships reviewing-plans, a critical multi-lens audit of an implementation plan against its spec, project posture, and current code | Development | ❌ |
| [web-fetching-with-pullmd](./plugins/web-fetching-with-pullmd/) | Fetch web pages, documents, and YouTube transcripts as clean Markdown via PullMD. Claude Code redirects WebFetch through an escape-hatch hook; Codex receives host-neutral skill and session guidance to prefer the separately registered PullMD MCP tool over native web research. Built-in host rules always allow GitHub, the npm registry, PyPI's package JSON API, and loopback, and deny by default the hosts PullMD cannot serve. | Productivity | ✅ (PullMD MCP required) |

## Structure

```
itb-ai-tools/
├── .agents/
│   └── plugins/
│       └── marketplace.json        # Codex marketplace registry
├── .claude-plugin/
│   └── marketplace.json            # Claude Code marketplace registry
├── .github/
│   └── scripts/
│       └── setup-bats.sh           # BATS test framework setup
├── AGENTS.md                        # Shared Codex and Claude Code guidance
├── AGENTS.override.md               # Codex project-specific extension
├── CLAUDE.md                        # Claude Code wrapper for AGENTS.md
├── plugins/
│   └── <plugin-name>/               # Each plugin follows this pattern:
│       ├── .claude-plugin/
│       │   └── plugin.json          # Claude Code manifest, when supported
│       ├── .codex-plugin/
│       │   └── plugin.json          # Codex manifest, when supported
│       ├── skills/                  # Optional: Skills
│       ├── agents/                  # Optional: Agents
│       ├── hooks/                   # Optional: Hooks
│       └── README.md                # Plugin documentation
├── plugin-tests/                    # BATS tests for hook scripts
├── build-skill-for-web.sh           # Creates Claude Web-compatible ZIPs
├── LICENSE
└── README.md
```

## Path Resolution

### Marketplace Paths (`marketplace.json`)

Both marketplace formats resolve local plugin paths relative to the marketplace root, which is this repository's root—not the directory containing `marketplace.json`.

| Host | Registry | Local plugin source |
|---|---|---|
| Claude Code | `.claude-plugin/marketplace.json` | `"source": "./plugins/my-plugin"` |
| Codex | `.agents/plugins/marketplace.json` | `"source": { "source": "local", "path": "./plugins/my-plugin" }` |

Keep local paths `./`-prefixed and inside the marketplace root.

### Plugin Paths (`plugin.json`)

Keep component paths in `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` relative to the plugin root. Codex manifest paths must start with `./`; conventional component directories may be discovered automatically.

## Building Skills for Claude Web

Skills in this marketplace use the `allowed-tools` frontmatter field to pre-approve tools in Claude Code — it auto-approves the listed tools for the invoking turn so Claude is not prompted, and it does **not** restrict which tools are available (`disallowed-tools` is the field that removes tools). This field is **only supported in Claude Code** and must be removed for Claude Web compatibility.

### Opt-in with `.claude-web` Marker

Not all skills are suitable for Claude Web. To enable a skill for web builds, add an empty `.claude-web` file to the skill directory:

```bash
touch ./plugins/<plugin>/skills/<skill>/.claude-web
```

The GitHub workflow automatically builds ZIP archives only for skills with this marker file.

### Manual Build

The `build-skill-for-web.sh` script creates Claude Web-compatible ZIP archives by stripping Claude Code-specific fields:

```bash
./build-skill-for-web.sh ./plugins/<plugin>/skills/<skill>
# Output: <skill-name>.zip
```

### Why is this necessary?

According to [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills):

> `allowed-tools` is only supported for Skills in Claude Code.

Skills uploaded to Claude Web will ignore this field. The build script ensures clean ZIPs without unsupported fields.

### Downloads

| Skill              | Download                                                                                        |
|--------------------|-------------------------------------------------------------------------------------------------|
| prompt-engineering | [Download](https://github.com/it-bens/ai-tools/releases/download/latest/prompt-engineering.zip) |
| content-editing    | [Download](https://github.com/it-bens/ai-tools/releases/download/latest/content-editing.zip)    |

Or browse all downloads on the [Releases page](https://github.com/it-bens/ai-tools/releases/latest).

## Contributing

This is a personal marketplace, but suggestions and feedback are welcome via GitHub issues.

## License

MIT
