# LLM Author Plugin

Author LLM-targeted content — prompts, skills, agents, and rules files — for Claude 4, GLM 4.7 (Z.ai), and Gemini 3 (including Deep Research).

## Overview

This plugin bundles the craft of authoring LLM-targeted content: designing high-performing prompts for Claude 4, GLM 4.7 (Z.ai), and Gemini 3; editing skills and agents without bloat; writing auto-loaded rule files for AI coding assistants; and packaging session-to-session prompts (handoffs forward to a fresh session, feedback backward to the session that defined the work). It transforms requirements into production-ready artifacts through evidence-based techniques and systematic optimization. Also adapts existing Claude prompts for GLM 4.7 or Gemini 3 when requested, and supports specialized Gemini Deep Research prompts for autonomous multi-source research.

The shared skills support Claude Code and Codex. Claude Code uses `.claude-plugin/plugin.json`; Codex uses `.codex-plugin/plugin.json` and the repository marketplace at `.agents/plugins/marketplace.json`. Claude-specific frontmatter remains available to improve Claude Code behavior, while Codex ignores fields it does not support.

## Installation

### Claude Code

```bash
/plugin install llm-author@itb-ai-tools
```

### Codex

From a clone of this repository, add the repository marketplace once:

```bash
codex plugin marketplace add <repo-root>
```

Then install `llm-author` from the Codex plugin browser and start a new session.

## Skills

### Prompt Engineering

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

### Content Editing

**Triggers:** "is this too long", "content bloat", "should I add this", editing SKILL.md files, modifying agent markdown, expanding skill content

**Capabilities:**
- Evaluate proposed changes to LLM-targeted content
- Guide toward corrections over additions
- Enforce brevity and prevent content bloat

### Rule-File Writing

**Triggers:** "write a rule about X", "create a rules file", "optimize this rules file", "cut ballast from a rule file", edits or additions to auto-loaded rule files

**Capabilities:**
- Create new rule files from an interview or from mid-conversation context
- Optimize existing rules files via a two-pass content-then-structure loop
- Enforce the canonical family pattern (CRITICAL → Decision Test → body → Red Flags)
- Report honest token-reduction trajectory without manufacturing cuts

### Writing Handoff Prompts

**Invocation:** Invoked by the coding assistant only when the user explicitly asks to write a handoff prompt for a fresh / new / separate session — never proactively.

**Claude Code frontmatter:** `model: sonnet`, `user-invocable: false`, and `allowed-tools` improve model selection, menu visibility, and tool approval in Claude Code. Codex can ignore these fields; the skill body carries the portable workflow. The skill gathers no new context and works from what the session already holds.

**What it does:**
- Deduces the contextual requirements from context rather than hardcoding them: the kind of work (implement a spec, apply review/report fixes, turn review findings into a change proposal, continue an analysis, hand off the next phase), the branch, the commit and verification policy, and the in/out scope
- Crafts a self-contained handoff prompt with the `llm-author:prompt-engineering` skill (nested), so every needed fact is stated inline or reachable by an explicit file reference
- Includes (research-informed) a one-line mission, an explicit first action, a "settled vs. open" list, a "trust the code, not this prompt" directive, an escalation / stop-and-ask boundary, and evidence-based done criteria
- Uses only values that are concrete (no placeholders) and real (not invented) — for anything unknown, it writes how the receiver obtains the value
- Presents the prompt, then asks whether to save it to a file or copy it to the clipboard (no default)

### Writing Session Feedback

**Invocation:** Invoked by the coding assistant only when the user explicitly asks to write feedback / a report / a note for another session — never proactively.

**Claude Code frontmatter:** `model: sonnet`, `user-invocable: false`, and `allowed-tools` improve model selection, menu visibility, and tool approval in Claude Code. Codex can ignore these fields; the skill body carries the portable workflow. The skill gathers no new context.

**What it does:**
- Crafts a calibration note addressed to the upstream session (spec author, reviewer, or planner) with the `llm-author:prompt-engineering` skill (nested), anchored to the concrete change (branch, commit(s), verification state)
- Leads with a one-line verdict, then divergences from the upstream's framing and why, where reading the code changed the reasoning, and what was under-specified — a calibration, not a status summary
- Counters self-evaluation leniency (research-informed): a session over-praises its own work, so it defaults to scrutiny, tags each item with confidence/uncertainty, and shows before/after verification deltas
- Presents the note, then asks whether to save it to a file or copy it to the clipboard (no default)

## Usage

Once installed, ask your coding assistant for help with prompts:

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
llm-author/
├── AGENTS.md                    # Shared development guidance
├── CLAUDE.md                    # Claude Code wrapper: @AGENTS.md
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin manifest
├── .codex-plugin/
│   └── plugin.json              # Codex plugin manifest
├── docs/                        # Source documentation (15 files)
├── skills/
│   ├── content-editing/
│   │   └── SKILL.md             # Content editing skill
│   ├── rule-file-writing/
│   │   ├── SKILL.md             # Rule-file writing and optimization skill
│   │   ├── assets/templates/    # Canonical rules-file skeleton
│   │   └── references/          # On-demand depth for optimization passes
│   ├── writing-handoff-prompts/
│   │   └── SKILL.md             # Handoff-prompt writing skill (model-invocable)
│   ├── writing-session-feedback/
│   │   └── SKILL.md             # Session-feedback writing skill (model-invocable)
│   └── prompt-engineering/
│       ├── SKILL.md             # Main skill definition
│       ├── references/          # Skill-specific references
│       └── examples/            # Ready-to-use templates
├── project/                     # Claude Web project
└── README.md
```

Codex marketplace metadata lives at `.agents/plugins/marketplace.json` in the repository root.

## License

MIT
