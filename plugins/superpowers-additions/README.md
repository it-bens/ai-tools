# Superpowers Additions

Additions to the [superpowers](https://github.com/anthropics/claude-plugins) plugin. Currently ships `reviewing-plans`, a sibling to the `writing-plans` / `executing-plans` skills that fits between them in the workflow.

## Quick Start

```bash
/plugin install superpowers-additions@itb-ai-tools
```

Optionally pair with the companion enforcer:

```bash
/plugin install reviewing-plans-with-opus-enforcer@itb-ai-tools
```

## Skills

### Reviewing Plans

**Triggers:** "review this plan", "audit this plan before I execute it", "find flaws in this plan", or invoked between `writing-plans` and `executing-plans`.

Critically reviews an implementation plan against:

- The plan's own spec (drift, missing scope, contradicted decisions)
- The plan's internal consistency (orphaned files vs tasks, architecture vs steps, commit-by-commit buildability)
- Project rules and invariants (rules files in context, AGENTS.md, architecture docs)
- Documentation drift (renamed symbols, moved invariants, stale READMEs)
- Scope and guardrail skepticism (deferred problems, planner-invented decisions, project posture)

Findings are classified into five labels (`silent-editorial`, `mechanical`, `awareness-single-option`, `multi-option`, `block-class`) so the routing between silent fix, mechanical correction, single-option awareness, multi-option decision, and verdict-blocker is auditable. The skill ends by editing the plan in place once the user has chosen options.

The skill assumes the user has not read the plan and treats every plan claim, scope boundary, DO, DON'T, and guardrail as a hypothesis to verify against current sources.

## Companion: Opus Enforcer

The plan-review workflow benefits significantly from Opus-level reasoning depth. The optional [`reviewing-plans-with-opus-enforcer`](../reviewing-plans-with-opus-enforcer/) plugin blocks `reviewing-plans` invocations when the active session is not on Opus, with a message guiding the user to switch via `/model opus`.

Install the enforcer if you want enforcement; skip it if you prefer to manage model selection yourself.

## License

MIT
