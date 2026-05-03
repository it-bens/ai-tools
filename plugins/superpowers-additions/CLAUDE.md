@README.md

## Directory & File Structure

```
plugins/superpowers-additions/
├── README.md
├── CLAUDE.md
├── CHANGELOG.md
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── reviewing-plans/
        ├── SKILL.md
        └── references/
            ├── scope-and-guardrail-lens.md
            └── planner-invented-phrasings.md
```

## Component Overview

This plugin provides:
- **Skill** (`skills/reviewing-plans/`) — workflow for critical plan review against spec, rules, docs, and current code

**No commands, agents, hooks, or MCP servers** — skill-only plugin.

## Key Navigation Points

| Task | Primary File | Key Concepts |
|------|--------------|--------------|
| Modify the four lenses (lens shape, ordering) | `skills/reviewing-plans/SKILL.md` Step 4 | Spec consistency, internal consistency, rule violations, doc drift, scope skepticism |
| Modify scope-and-guardrail audit checklist or citable-source test | `skills/reviewing-plans/references/scope-and-guardrail-lens.md` | Posture-driven lens, audit checklist, citable-source test, posture-silent edge case |
| Modify finding classification | `skills/reviewing-plans/SKILL.md` Step 5 | Five labels, banned routing substitutions |
| Modify decision-menu rules | `skills/reviewing-plans/SKILL.md` Step 7 | Option count by label, recommended-option framing |
| Modify plan-edit pass | `skills/reviewing-plans/SKILL.md` Step 8 | Plan correction / documented decision / withdrawn finding |
| Update planner-invented phrasings list | `skills/reviewing-plans/references/planner-invented-phrasings.md` | Citable-source test |

## Companion Plugin

`reviewing-plans-with-opus-enforcer` is the opt-in enforcer that blocks `reviewing-plans` on non-Opus sessions. The two are intentionally separate plugins so that users who manage model selection themselves can install the skill without the hook.
