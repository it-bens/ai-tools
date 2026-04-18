# ITB AI Tools

A collection of AI coding and productivity tools — skills, agents, hooks, and more — for Claude Code, Codex, and other AI coding assistants.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add it-bens/ai-tools
```

Then browse and install plugins:

```bash
/plugin
```

## Available Plugins

| Plugin                                                                  | Description                                                                                                             | Category     |
|-------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|--------------|
| [llm-author](./plugins/llm-author/)                                     | Author LLM-targeted content — prompts, skills, agents, and rules files — for Claude 4, GLM 4.7, and Gemini 3            | Productivity |
| [python-plan-optimizer](./plugins/python-plan-optimizer/)               | Analyze Python code in planning documents for design principles and improvement opportunities                           | Development  |
| [native-tools-enforcer](./plugins/native-tools-enforcer/)               | Enforces use of Claude Code native tools instead of bash equivalents via PreToolUse hook (smart piped grep filtering)   | Guardrails   |
| [explore-with-sonnet-enforcer](./plugins/explore-with-sonnet-enforcer/) | Enforces Sonnet model for Explore subagent to prevent lossy Haiku summaries                                             | Guardrails   |
| [explore-with-opus-enforcer](./plugins/explore-with-opus-enforcer/)     | Enforces Opus model for Explore subagent for maximum exploration accuracy                                               | Guardrails   |
| [plan-with-sonnet-enforcer](./plugins/plan-with-sonnet-enforcer/)       | Enforces Sonnet model for Plan subagent to ensure thorough architectural reasoning                                      | Guardrails   |
| [plan-with-opus-enforcer](./plugins/plan-with-opus-enforcer/)           | Enforces Opus model for Plan subagent for maximum reasoning depth                                                       | Guardrails   |
| [redundant-read-blocker](./plugins/redundant-read-blocker/)             | Prevent wasteful re-reads of unchanged files with smart range tracking and context decay                                | Guardrails   |
| [codex-integration](./plugins/codex-integration/)                       | Consult OpenAI Codex for fresh perspective — auto-escalation when stuck, on-demand second opinions, and web research    | Development  |
| [commit-message-generator](./plugins/commit-message-generator/)         | Generate and validate conventional commit messages with automatic type/scope detection                                  | Development  |
| [behavior-diagnostics](./plugins/behavior-diagnostics/)                 | Debug AI tooling behavior with root cause analysis and honest self-diagnosis across sessions                            | Development  |
| [reddit-research](./plugins/reddit-research/)                           | Disciplined Reddit research via reddit-buddy MCP — call budget, truncation awareness, query craft, proactive opt-in     | Development  |

## Structure

```
itb-ai-tools/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace registry
├── .github/
│   └── scripts/
│       └── setup-bats.sh       # BATS test framework setup
├── plugins/
│   └── <plugin-name>/          # Each plugin follows this pattern:
│       ├── .claude-plugin/
│       │   └── plugin.json     # Plugin manifest
│       ├── skills/             # Optional: Skills
│       ├── agents/             # Optional: Agents
│       ├── hooks/              # Optional: Hooks
│       └── README.md           # Plugin documentation
├── plugin-tests/               # BATS tests for hook scripts
├── build-skill-for-web.sh      # Creates Claude Web-compatible ZIPs
├── LICENSE
└── README.md
```

## Path Resolution

### Marketplace Paths (`marketplace.json`)

The `source` field in each plugin entry is resolved **relative to the marketplace.json file location** (not the `pluginRoot`):

```json
{
  "metadata": {
    "pluginRoot": "./plugins"  // Informational only, not used for resolution
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",  // Relative to marketplace.json
      "category": "development"
    }
  ]
}
```

**Key rule:** `source` must start with `./` and include the full path from `.claude-plugin/` to the plugin directory.

### Plugin Paths (`plugin.json`)

Each plugin's `plugin.json` uses paths relative to its own location. Component discovery (skills, agents, hooks) is automatic from the plugin root.

## Building Skills for Claude Web

Skills in this marketplace use the `allowed-tools` frontmatter field to restrict tool access in Claude Code. However, this field is **only supported in Claude Code** and must be removed for Claude Web compatibility.

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

| Skill              | Download                                                                                            |
|--------------------|-----------------------------------------------------------------------------------------------------|
| prompt-engineering | [Download](https://github.com/it-bens/ai-tools/releases/download/latest/prompt-engineering.zip) |
| content-editing    | [Download](https://github.com/it-bens/ai-tools/releases/download/latest/content-editing.zip)    |

Or browse all downloads on the [Releases page](https://github.com/it-bens/ai-tools/releases/latest).

## Contributing

This is a personal marketplace, but suggestions and feedback are welcome via GitHub issues.

## License

MIT
