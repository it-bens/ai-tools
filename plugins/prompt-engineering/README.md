# Prompt Engineering Plugin

Expert prompt engineering for Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3 (including Deep Research) with production-ready templates.

## Overview

This plugin provides comprehensive guidance for creating, optimizing, and debugging high-performing prompts for Claude 4 models, GLM 4.7 (Z.ai), and Gemini 3. It transforms requirements into production-ready prompts through evidence-based techniques and systematic optimization. Also adapts existing Claude prompts for GLM 4.7 or Gemini 3 when requested, and supports specialized Gemini Deep Research prompts for autonomous multi-source research.

## Skills

### Prompt Engineering Lab

**Triggers:** "create a prompt", "write a prompt", "optimize a prompt", "debug a prompt", "improve my prompt", "help with prompting", "build a prompt chain", "make a system prompt", "design a prompt", "optimize this skill", "improve this agent", "adapt prompt for GLM", "convert to GLM 4.7", "adapt prompt for Gemini", "convert to Gemini", "deep research prompt", "Gemini deep research"

**Capabilities:**
- Create new prompts from scratch for specific use cases
- Optimize existing prompts for better performance
- Optimize LLM-targeted content (skills, agents, instructions, documentation)
- Debug problematic prompts and identify root causes
- Build prompt chains for complex, multi-step workflows
- Provide ready-to-copy prompts for Claude Web and Desktop
- Adapt Claude prompts for GLM 4.7 (Z.ai) with reasoning parity
- Adapt Claude prompts for Gemini 3 (Flash/Pro) with quality parity
- Create Gemini Deep Research prompts with scope, temporal, and source constraints

## Usage

Once installed, simply ask Claude Code for help with prompts:

```
"Help me create a prompt for code review"
"Optimize this prompt: [your prompt]"
"Optimize this SKILL.md"
"Improve this agent definition"
"Debug why my prompt isn't working"
"Build a prompt chain for research-to-report workflow"
"Adapt this Claude prompt for GLM 4.7"
"Create a prompt for GLM 4.7 that does [task]"
"Adapt this prompt for Gemini"
"Create a Gemini 3 prompt for [task]"
"Create a Gemini deep research prompt for [topic]"
```

## Claude Web Project

This plugin includes data for a Claude Web project in the `project/` directory. Use these files for a Claude Web project to provide the same prompt engineering capabilities without requiring Claude Code.

**Project files:**
- `system-prompt.md` - System prompt embedding all skill knowledge
- `title.txt` - Project title
- `description.txt` - Project description

The project wrapper allows users to simply describe what they need, and Claude handles the technical craft of creating effective prompts.

## Documentation Sources

The `docs/` directory contains the raw documentation files that were used to create the prompt-engineering skill. These files include comprehensive prompting guides and best practices from official Claude documentation:

- Core prompting techniques (clarity, XML structure, system prompts, examples, prefilling, chain-of-thought)
- Advanced strategies (prompt chaining, long context handling, output consistency, hallucination reduction)
- Claude 4 model-specific optimization and best practices
- GLM 4.7 adaptation techniques for achieving Claude parity
- Gemini 3 adaptation techniques for achieving Claude parity
- Gemini Deep Research prompting for autonomous multi-source research
- Claude Code integration patterns and workflows

These source materials are preserved for reference and can be used to update or extend the skill in the future.

## Contents

```
prompt-engineering/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── docs/                        # Source documentation (15 files)
├── skills/
│   └── prompt-engineering/
│       ├── SKILL.md             # Main skill definition
│       ├── references/          # Skill-specific references
│       └── examples/            # Ready-to-use templates
├── project/                     # Claude Web project
└── README.md
```

## License

MIT
