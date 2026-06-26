# LLM Author Plugin

Author LLM-targeted content — prompts, skills, agents, and rules files — for Claude 4, GLM 4.7 (Z.ai), and Gemini 3 (including Deep Research).

## Overview

This plugin bundles the craft of authoring LLM-targeted content: designing high-performing prompts for Claude 4, GLM 4.7 (Z.ai), and Gemini 3; editing skills and agents without bloat; writing auto-loaded Claude Code rules files; and packaging session-to-session prompts (handoffs forward to a fresh session, feedback backward to the session that defined the work). It transforms requirements into production-ready artifacts through evidence-based techniques and systematic optimization. Also adapts existing Claude prompts for GLM 4.7 or Gemini 3 when requested, and supports specialized Gemini Deep Research prompts for autonomous multi-source research.

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

**Triggers:** "write a rule about X", "create a rules file", "optimize this rules file", "cut ballast from a rules file", edits or additions in `~/.claude/rules/` or a project's `.claude/rules/`

**Capabilities:**
- Create new Claude Code rules files from an interview or from mid-conversation context
- Optimize existing rules files via a two-pass content-then-structure loop
- Enforce the canonical family pattern (CRITICAL → Decision Test → body → Red Flags)
- Report honest token-reduction trajectory without manufacturing cuts

### Writing Subagent Descriptions

**Triggers:** "write a subagent description", "draft a description for this agent", "improve this agent's description", edits to the `description` field on a file under `.claude/agents/`, `~/.claude/agents/`, or a plugin's `agents/` directory

**Argument:** `<invocation-style>` — `broad` | `narrow` | `specialist`

**Capabilities:**
- Locate the target agent's identity, capability, and system-prompt body from conversation context or the working tree
- Draft a `description` field matched to the chosen invocation style:
  - `broad` — proactive auto-delegation with a wide routing net (`Proactively …`)
  - `narrow` — auto-fires when conditions match, with enumerated negative space (`MUST BE USED when … Do NOT use for …`)
  - `specialist` — capability and tight scope only, no auto-trigger phrases; `@-mention` invocation
- Audit drafts for router-vs-expert separation (no behavioural instructions, no workflow steps, no output-contract leaks) while preserving routing-critical tokens such as `PROACTIVELY` and `MUST BE USED`
- Treat descriptions as LLM-routing artifacts, never as human prose — human-targeted prose validators (anti-slop) are explicitly not applied

### Writing Handoff Prompts

**Invocation:** Invoked by Claude only when the user explicitly asks to write a handoff prompt for a fresh / new / separate session — never proactively. Hidden from the `/` menu (`user-invocable: false`), so it is not a typed slash command.

**Model:** `sonnet`. **Tools** (`allowed-tools`): `Skill(llm-author:prompt-engineering)` to craft the prompt, `AskUserQuestion` to offer delivery, and `Write` to save to a file. It gathers no new context — it works from what the session already holds.

**What it does:**
- Deduces the contextual requirements from context rather than hardcoding them: the kind of work (implement a spec, apply review/report fixes, turn review findings into a change proposal, continue an analysis, hand off the next phase), the branch, the commit and verification policy, and the in/out scope
- Crafts a self-contained handoff prompt with the `llm-author:prompt-engineering` skill (nested), so every needed fact is stated inline or reachable by an explicit file reference
- Includes (research-informed) a one-line mission, an explicit first action, a "settled vs. open" list, a "trust the code, not this prompt" directive, an escalation / stop-and-ask boundary, and evidence-based done criteria
- Uses only values that are concrete (no placeholders) and real (not invented) — for anything unknown, it writes how the receiver obtains the value
- Presents the prompt, then asks whether to save it to a file or copy it to the clipboard (no default)

### Writing Session Feedback

**Invocation:** Invoked by Claude only when the user explicitly asks to write feedback / a report / a note for another session — never proactively. Hidden from the `/` menu.

**Model:** `sonnet`. **Tools** (`allowed-tools`): `Skill(llm-author:prompt-engineering)` to craft the note, `AskUserQuestion` to offer delivery, and `Write` to save to a file. It gathers no new context.

**What it does:**
- Crafts a calibration note addressed to the upstream session (spec author, reviewer, or planner) with the `llm-author:prompt-engineering` skill (nested), anchored to the concrete change (branch, commit(s), verification state)
- Leads with a one-line verdict, then divergences from the upstream's framing and why, where reading the code changed the reasoning, and what was under-specified — a calibration, not a status summary
- Counters self-evaluation leniency (research-informed): a session over-praises its own work, so it defaults to scrutiny, tags each item with confidence/uncertainty, and shows before/after verification deltas
- Presents the note, then asks whether to save it to a file or copy it to the clipboard (no default)

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
"Write a broad description for this agent"
"Draft a narrow subagent description"
"Improve the description on .claude/agents/code-reviewer.md"
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
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── RESEARCH.md                  # Research + design knowledge behind the handoff & feedback skills
├── docs/                        # Source documentation (15 files)
├── skills/
│   ├── content-editing/
│   │   └── SKILL.md             # Content editing skill
│   ├── rule-file-writing/
│   │   ├── SKILL.md             # Rule-file writing and optimization skill
│   │   ├── assets/templates/    # Canonical rules-file skeleton
│   │   └── references/          # On-demand depth for optimization passes
│   ├── writing-subagent-descriptions/
│   │   └── SKILL.md             # Subagent description writing skill
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

## License

MIT
