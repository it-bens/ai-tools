@README.md

# Development Guide

## File Navigation

| When you need to... | Consult |
|---------------------|---------|
| Understand plugin purpose and usage | `README.md` |
| Modify skill behavior or triggers | `skills/prompt-engineering/SKILL.md` |
| Update core techniques or patterns | `skills/prompt-engineering/references/` |
| Update GLM 4.7 adaptation guide | `skills/prompt-engineering/references/glm-47-guide.md` |
| Add or modify example templates | `skills/prompt-engineering/examples/` |
| Research prompting best practices | `docs/` |
| Update Claude Web project | `project/system-prompt.md` |

## Directory Relationships

### `docs/` vs `skills/.../references/`

These serve different purposes:

- **`docs/`** - Raw source documentation from official Claude guides. Used as research material when creating or updating the skill. Not loaded by Claude Code at runtime.

- **`skills/.../references/`** - Curated, skill-specific reference material. Loaded by Claude Code when the skill activates and deeper context is needed.

When updating the skill, consult `docs/` for authoritative information, then distill relevant content into `references/` or `SKILL.md`.

### `skills/.../examples/` Purpose

Examples are ready-to-use templates that Claude can reference or adapt when helping users. They demonstrate concrete output formats, not teaching material.

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

1. Start a new Claude Code session
2. Use trigger phrases to activate the skill
3. Verify the skill loads and behaves as expected
4. Test edge cases mentioned in your changes
