# Codex Integration

Consult OpenAI Codex (GPT-5.2) for fresh analytical perspective — auto-escalation when stuck, on-demand second opinions, and web research for unfamiliar errors.

## What It Does

When you're stuck debugging or want a second opinion, this plugin consults OpenAI's Codex through the official MCP server. Two modes:

**Auto-escalation:** When Claude gets stuck after three failed attempts with identical errors, the `codex-consulting` skill automatically triggers to get fresh perspective from a different AI model.

**On-demand:** Ask Claude to consult Codex anytime — "ask Codex about this", "get a second opinion from Codex", or "use Codex to research this error."

## Features

- **Auto-Escalation**: Detects "running in circles" after three failed attempts
- **On-Demand Consultation**: Ask for Codex's perspective anytime
- **Web Search**: Research unfamiliar errors, APIs, and dependencies via Codex
- **Session Support**: Multi-turn conversations with Codex for complex problems
- **Progressive Escalation**: Codex -> User (prevents infinite loops)
- **Fresh Perspective**: GPT-5.2-codex provides independent analysis
- **Pre-Flight Verification**: `/codex-check` validates setup before use

## Quick Start

### Prerequisites

**Codex CLI** (v0.75.0+):

```bash
npm i -g @openai/codex
codex login --api-key "your-openai-api-key"
```

You need an OpenAI account with Codex access (typically included with ChatGPT Plus/Pro/Team subscriptions).

### Installation

```bash
/plugin install codex-integration@it-bens/itb-ai-tools
```

**IMPORTANT**: Restart Claude Code after installation for the MCP server to initialize.

### Verification

```bash
/codex-check
```

## Usage

### Auto-Escalation

Works automatically. When Claude is stuck after three failed attempts with no progress:

1. Recognizes the "running in circles" pattern
2. Invokes the `codex-consulting` skill
3. Gathers complete context (goal, attempts, errors, code)
4. Consults Codex (GPT-5.2) for root cause analysis
5. Researches via web search if needed
6. Implements and verifies the solution

### On-Demand Consultation

Ask Claude directly:

```
Ask Codex what it thinks about this approach
Get a second opinion from Codex on this error
Use Codex to research this SDK issue
```

### What Triggers Auto-Escalation

**Triggers (running in circles):**
- Same error persists after three different fix approaches
- Tests fail identically across three iterations
- Build issues remain unresolved despite multiple solutions

**Does NOT trigger (making progress):**
- Fixing error A reveals error B (new information)
- Each attempt reduces test failures (improvement)
- Each fix provides new diagnostic information (learning)

## Output Format

```
## Consultation Result

**Status:** [Resolved | Partially Resolved | Requires User Input]

**Root Cause Identified:**
[Summary of what Codex determined]

**Solution Implemented:**
[Description of the fix, with file paths and changes]

**Verification:**
- Tests: [Pass/Fail with details]
- Original error: [Resolved/Persists]
- New issues: [None/List any]

**Remaining Concerns:**
[Any caveats or follow-up recommendations]
```

## About Codex

This plugin uses the **official codex-mcp-server** to connect to OpenAI's Codex (GPT-5.2-codex). The MCP server provides:

| Tool | Purpose |
|------|---------|
| `codex` | AI coding consultation with session support and model selection |
| `websearch` | Web search for errors, APIs, and documentation |
| `ping` | Connection verification |

Codex provides recommendations; Claude remains the decision-maker, validating and implementing solutions.

## Common Issues

### MCP Server Not Starting

**Symptom**: `/codex-check` fails at ping step

**Solutions**:
1. Verify Codex CLI: `codex --version` (need v0.75.0+)
2. **Restart Claude Code** (required after installation)
3. Check authentication: `codex login`

### "Command not found: codex"

```bash
npm install -g @openai/codex
```

### Authentication Errors

```bash
codex login --api-key "your-openai-api-key"
```

Your OpenAI account needs Codex access (ChatGPT Plus/Pro/Team).

## License

MIT
