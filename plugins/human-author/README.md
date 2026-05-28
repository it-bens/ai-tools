# Human Author

Author content that reads like a human wrote it. Sibling plugin to [`llm-author`](../llm-author/), which authors content *for* LLMs. This plugin houses tools that scrub the LLM tells out of prose written *by* LLMs.

## Quick Start

```bash
/plugin install human-author@itb-ai-tools
```

Then dispatch the agent from any skill or directly from a conversation when you need anti-slop corrections applied to a piece of prose.

## Agents

### `ai-slop-writing-fixer`

A subagent that receives prose and returns the prose with anti-slop rule violations corrected, plus a structured report of every change it made.

**Inputs:**

- `content` (required): the prose to align.
- `voice_notes` (optional): characteristics to preserve so intentional voice doesn't get sanded into something that merely satisfies the rules.
- `debug` (optional, default false): when true, the output includes per-change `reasoning` and a `considered` list of candidates the agent weighed but did not change. Use to diagnose insufficient corrections.

**Output shape:**

```text
fixed_content: <the prose with violations corrected>
changes:
  - rule: <name of the rule applied>
    before: <verbatim snippet from the input>
    after: <the corrected snippet>
    location: <paragraph index or line range>
    reasoning: <debug only — why this snippet triggered the rule and why this fix>
considered:  # debug only
  - candidate: <snippet weighed but unchanged>
    rule: <rule considered>
    location: <paragraph index or line range>
    decision: <why left unchanged>
no_changes: <true if no changes were made>
```

In normal mode (`debug` false or absent), `reasoning` and the `considered` block are omitted.

**What it corrects:**

- Punctuation patterns (em/en dashes, colon overuse, semicolons)
- Banned vocabulary (verbs, adjectives, nouns, adverbs, intensifiers) with a narrow load-bearing exception
- Banned sentence patterns (contrastive reframe, hedging filler, pre-empted concession, balanced hedging, formulaic transitions, summary openings, resolution closers, "this" + abstract noun, rule of three)
- Banned description formats (AI-copilot category lists, emoji checklists, diff-link references)
- Sentence rhythm (metronomic 15-20 word uniformity)
- Parallelism in compound predicates
- Concreteness over abstraction (named specifics, counts only when load-bearing, labels expanded into explanations)
- Intent attribution (no guessing past authors' motivations)
- Formatting discipline (bold sparingly, lists for enumerations, prose for argument)
- Tone (direct, no exclamation marks, contractions where natural)

**What it does not do:**

- Restructure paragraphs or change meaning
- Enforce frequency budgets or quotas (counting belongs to the caller)
- Override voice characteristics surfaced via `voice_notes`
- "Improve" prose that already satisfies the rules

The agent runs a self-check before returning. A second pass on its output returns `no_changes: true`.

## When To Use

- After drafting a commit message, release note, blog post, or PR description that was generated or heavily assisted by an LLM.
- As a validation step in a larger writing workflow, before the prose hits a human-visible surface.
- When reviewing prose where you suspect anti-slop violations but want a structured report of what changed.

## Sibling Plugin

[`llm-author`](../llm-author/) is the inverse direction: authoring content *for* LLMs (prompts, skills, agents, rules files). Together the two plugins cover both sides of the human/LLM authoring boundary.

## License

MIT
