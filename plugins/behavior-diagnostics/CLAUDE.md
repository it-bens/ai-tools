@README.md

# Development Guide

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify analysis workflow or triggers | `skills/diagnosing/SKILL.md` |
| Modify introspection constraints or triggers | `skills/introspecting/SKILL.md` |

## Directory Structure

```
plugins/behavior-diagnostics/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── diagnosing/
│   │   └── SKILL.md             # Root cause analysis + question generation
│   └── introspecting/
│       └── SKILL.md             # Honest self-diagnosis constraints
└── README.md
```

## Design Philosophy

1. **Two-session workflow** — `diagnosing` runs in the dev session (Session A), `introspecting` runs in the misbehaving session (Session B). They never run together.
2. **No agent orchestration** — The skills are independent and have no runtime dependency.
3. **No references directory** — Both skills are workflow/behavioral, not knowledge-heavy. Instructions are self-contained in SKILL.md.
4. **Diagnosis vs testimony** — `diagnosing` performs the analytical work (root cause analysis, hypothesis formation). `introspecting` only provides honest testimony — it does not diagnose or propose fixes.

## When to Modify

| Task | File |
|------|------|
| Change gap analysis categories | `skills/diagnosing/SKILL.md` (Phase 4) |
| Change root cause categories | `skills/diagnosing/SKILL.md` (Phase 5) |
| Change question generation approach | `skills/diagnosing/SKILL.md` (Phase 6) |
| Change introspection constraints | `skills/introspecting/SKILL.md` (Hard Rules) |
| Change answer structure | `skills/introspecting/SKILL.md` (Phase 3) |
| Update plugin metadata | `.claude-plugin/plugin.json` |

## Critical Behavior Notes

### Diagnosing: No Treatment

The `diagnosing` skill must never propose fixes. Its output is introspection questions, not recommendations. If a skill instruction is poorly written, it should say so in the analysis — but the fix happens elsewhere.

### Introspecting: Honesty Over Helpfulness

The `introspecting` skill's hard rules (no excuses, no corrections, no people-pleasing, no deflection) exist because LLMs have strong tendencies toward all four. These constraints must remain explicit and forceful — subtle phrasing will be overridden by default model behavior.
