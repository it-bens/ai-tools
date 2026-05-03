# Scope and guardrail skepticism — full lens

Loaded from SKILL.md Step 4 when the scope-and-guardrail lens runs. The lens is posture-driven: read the project's documented posture in `CLAUDE.md`, `AGENTS.md`, or equivalent surfaces, and apply *its* rules rather than a generic stance.

A clean boundary in prose is still a finding when the deferred problem will bite the in-scope work.

## Audit checklist

- For each out-of-scope item: is the carve-out principled, or does it defer a problem the in-scope work creates? Call out convenient dodges. Phrasings like "keep the diff small", "minimize blast radius", and "stay focused" are flags when the project's posture explicitly rejects them; weaker flags otherwise.
- For each "preserve current behavior", "compatibility shim", or deprecation step: check whether the project documents a backwards-compatibility budget. If posture disclaims one (e.g. "no BC promise", "no consumers outside the maintainer"), preservation mechanisms and dual code paths are findings. Documentation labels for actual breaking changes are *not* flagged — `BREAKING CHANGE:` trailers, changelog entries, and README notes about removed APIs record that a break occurred, which is what the posture allows. The flag is for preservation mechanisms, not for labels of breaks that did happen.
- For each plugin hook, public registration API, or "make this pluggable" claim: check whether the project documents an extension-point budget. If posture disclaims one (e.g. "no external library consumers planned"), scaffolding added for non-existent extension authors is a finding. Internal abstractions and interfaces that organize today's code are fine; the test is whether the surface exists to keep a non-existent consumer working.
- For each DO or DON'T: is it tied to a named rule or spec line, or invented locally? Invented guardrails are weaker than rule-backed ones.
- For each pre-commit check: does it actually catch the failure modes the plan introduces? Green tests and a clean linter do not catch renamed symbols in a README, drifted commit counts, or scope creep.
- For "the user did X" assertions: do they match what the user actually specified, or does the plan assume?

## Citable-source test

Apply this test to every scope decision, deferred item, design tradeoff, and simplifying choice. A decision passes when the plan cites a source for the choice.

Acceptable sources:

- A spec line naming the user's choice.
- Project posture documented in `CLAUDE.md`, `AGENTS.md`, or equivalent project surfaces.
- A prior commit.
- An active named follow-up (a forward reference to a *plan that exists*; vapor references fail).

A decision without such a source is planner-invented and surfaces as a finding regardless of how settled the prose makes it look. Phrasings that signal planner-invented decisions live in `planner-invented-phrasings.md`.

## Posture-silent edge case

If the project's posture is silent on a budget the plan is appealing to, the lens still asks whether the carve-out is principled or convenient — but the bar is "documented posture" not the skill's opinion. Findings against undocumented posture surface as `awareness-single-option` or `multi-option` in Step 5 (user decides), not `block-class`.
