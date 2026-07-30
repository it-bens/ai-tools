# Dependency Update Triage

A read-only skill that assesses one dependency update before you adopt it. It answers three questions about the update, grounded in your own codebase, and hands you a clean write-up to post.

The skill assesses; it does not act. It never applies the update, edits files, fixes a broken build, replaces an abandoned dependency, or commits. Those are individual, easily-prompted tasks and are deliberately out of scope.

## Quick Start

### Claude Code

```bash
/plugin install dependency-update-triage@itb-ai-tools
```

### Codex

Add the repository marketplace, then install `dependency-update-triage` from the Codex marketplace. The investigation runs inline on Codex; the parallel model-routed fan-out is a Claude Code acceleration (see Model tiers).

The skill runs on universal defaults with no configuration. It detects the ecosystem, type system, and release-notes location from the host project at runtime.

## What it does

The skill triages a single update through one read-only path: gather the update and its release notes, detect the host stack, investigate, then report. The trigger conditions live in the skill's `description`; the prompts below are examples, not a separate trigger spec.

**Example prompts:**
- "Should we upgrade this package to the new version?"
- "Assess this Renovate PR before I merge it."
- "What does this dependency bump change for us?"
- "Is this version worth adopting?"

**The three-pronged assessment:**
1. **Requires changes.** What the update forces you to change across code, tests, docs, config, and pipeline, with every "this affects us" claim grounded in an actual call site in your codebase, not the changelog.
2. **Enables an improvement.** A change the update newly unlocks that leaves the code simpler, safer, more correct, or better tested, including improvements that only make existing code easier to test. Surfaced only with a concrete before-to-after.
3. **Latent-bug watch.** When the update fixes a bug, whether that bug could have reached your application, flagged as something to investigate because updating the dependency does not undo effects the bug already produced.

**Output:** one assessment, delivered to the clipboard for you to post. The skill never posts it for you.

## Handling large changesets

Big updates are kept tractable by structure, not by reading everything. The skill bounds the changelog into three finite inventories (changed surface, added surface, fixed-bug list), searches your codebase (call sites plus imports, config, and framework registration), ranks by criticality so unused changes fall out immediately, and dispositions every candidate, verifying the high-impact ones in depth and surfacing anything it could not verify as a limitation.

## Model tiers

The assessment routes work by cost: cheap models for the search-and-extract fan-out, a mid model for reading a changelog or verifying a call site, and a strong model for the driver that adjudicates findings and runs the three prongs. On Claude Code the driver dispatches subagents with per-worker model selection; recommend a strong session model (Opus) for the driver's adjudication. On Codex the tracks run inline, and the bounding-and-ranking structure keeps the work tractable without parallelism. No model is pinned in frontmatter, so the skill runs on the session model.

## Companions

All companions are soft. The skill checks for each and degrades with an explicit note when one is absent; it never proceeds as if a missing companion ran.

| Companion | Used for | Claude Code | Codex |
|---|---|---|---|
| Git-forge tooling | reading the update PR, diff, and release notes | a GitHub/GitLab CLI or MCP | the host's git tooling |
| Web reader | fetching changelogs and migration notes | `web-fetching-with-pullmd` or similar | PullMD MCP or similar |
| Clipboard | delivering the report | `clipboard-copy` or the host clipboard | the host clipboard |

## License

MIT
