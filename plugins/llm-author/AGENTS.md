@README.md

# Development Guide

## Compatibility Contract

This plugin must remain compatible with Claude Code and Codex.

- Claude Code uses `.claude-plugin/plugin.json`.
- Codex uses `.codex-plugin/plugin.json` and the repository marketplace at `.agents/plugins/marketplace.json`.
- Skill bodies and loaded references use host-neutral actions and rule-file concepts.
- Preserve helpful Claude-specific frontmatter such as `model`, `user-invocable`, and `allowed-tools`; Codex may ignore unsupported fields.
- Keep `.claude-web` markers and `project/` as intentional Claude Web compatibility assets.

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Update Claude Code plugin metadata | `.claude-plugin/plugin.json` |
| Update Codex plugin metadata | `.codex-plugin/plugin.json` |
| Update Codex marketplace registration | `.agents/plugins/marketplace.json` at the repository root |
| Understand the research and design knowledge behind the handoff & feedback skills | `RESEARCH.md` |
| Modify skill behavior or triggers | `skills/prompt-engineering/SKILL.md` |
| Modify content editing behavior | `skills/content-editing/SKILL.md` |
| Modify rule-file writing behavior or triggers | `skills/rule-file-writing/SKILL.md` |
| Update Pass 1 essential vs ballast reference | `skills/rule-file-writing/references/essential-vs-ballast.md` |
| Update Pass 2 techniques or three-angle pattern | `skills/rule-file-writing/references/techniques.md`, `skills/rule-file-writing/references/three-angle-pattern.md` |
| Update the rules-file skeleton template | `skills/rule-file-writing/assets/templates/rules-file-skeleton.md` |
| Modify handoff-prompt writing behavior or triggers | `skills/writing-handoff-prompts/SKILL.md` |
| Modify session-feedback writing behavior or triggers | `skills/writing-session-feedback/SKILL.md` |
| Update core techniques or patterns | `skills/prompt-engineering/references/` |
| Update output format templates | `skills/prompt-engineering/references/output-formats.md` |
| Update GLM 4.7 adaptation guide | `skills/prompt-engineering/references/glm-47-guide.md` |
| Update Gemini 3 adaptation guide | `skills/prompt-engineering/references/gemini-3-guide.md` |
| Update Gemini Deep Research guide | `skills/prompt-engineering/references/gemini-3-deep-research-guide.md` |
| Add or modify example templates | `skills/prompt-engineering/examples/` |
| Research prompting best practices | `docs/` |
| Update Claude Web project | `project/system-prompt.md` |

## Directory Relationships

### `docs/` vs `skills/.../references/`

These serve different purposes:

- **`docs/`** - Raw source documentation from official Claude guides. Used as research material when creating or updating the skill. Not loaded automatically at runtime.

- **`skills/.../references/`** - Curated, skill-specific reference material. Loaded by the active coding assistant when the skill activates and deeper context is needed.

When updating the skill, consult `docs/` for authoritative information, then distill relevant content into `references/` or `SKILL.md`.

### `skills/.../examples/` Purpose

Examples are ready-to-use templates that the active coding assistant can reference or adapt when helping users. They demonstrate concrete output formats, not teaching material.

## Extending the Skill

### Adding New Techniques

1. Research the technique in `docs/` or official Claude documentation
2. Add core concepts to `SKILL.md` if essential to the workflow
3. Add detailed guidance to a new or existing file in `references/`
4. Update trigger phrases in `SKILL.md` frontmatter if needed

### Adding New Examples

1. Create a new `.md` file in `skills/prompt-engineering/examples/`
2. Follow the structure of existing examples
3. Reference the new example in `SKILL.md` under "Additional Resources"

## Claude Web Project Sync

The `project/` directory provides Claude Web compatibility. When making significant changes to the skill:

1. Update `project/system-prompt.md` to reflect major changes
2. The system prompt is a standalone version - it embeds core knowledge rather than referencing files
3. Keep the project description in `description.txt` aligned with current capabilities

## Testing Changes

After modifying the skill:

1. Validate both plugin manifests and all changed skills
2. Install or update the plugin in Claude Code and Codex
3. Start a new session in each coding assistant
4. Use trigger phrases to activate the skill
5. Verify the skill loads and behaves as expected
6. Test edge cases mentioned in your changes
