# Output

One output shape: an assessment, presented to the user for them to post. The assessment never posts itself and never edits the repo.

## Report shape

Write the report for a human deciding what to do with the update. Include only the sections that have content, not empty headings.

- **What it is.** The package (each package, for a grouped update), the old to new version, and the update source.
- **Recommendation.** Adopt, or WAIT with the upstream reason and the wake-up condition that would flip it. Lead with this. For a grouped update, give each package its verdict plus one disposition for the group as a unit (any WAIT-worthy package WAITs the group; splitting the group is its wake-up condition).
- **Requires changes (prong a).** Each required change with its grounding code reference, labeled clean fix or workaround.
- **Enables improvements (prong b).** Each improvement with its concrete before→after. Omit the section when there is nothing concrete; do not pad it with "could be nice."
- **To investigate: possible latent bug (prong c).** Present only when an upstream bug fix plausibly reached the application. Name the fixed bug, our affected path, and why the effect might persist after the update. Frame it as something to investigate, not a verdict.
- **Not fully verified.** Any candidate dispositioned unverified, listed as a limitation. An unverified candidate blocks an unconditional "no changes needed" conclusion.
- **Sources.** Every changelog and web reference the assessment relied on, named inline where the claim is made and collected here.

## Delivery

Present the report inline so the user can post it themselves. Never post to the forge automatically; the user decides where it goes.

## Companion degradation

Every companion is optional. At each point where one would be used, check availability and, when it is missing, say plainly that the step is degraded and how. Never proceed as if a missing companion had run.

| Companion | Used for | When absent |
|---|---|---|
| Git-forge tooling | reading the update PR, its diff, and release notes | fall back to the user-provided details and the web reader; note the gap |
| Web reader | fetching changelogs and migration notes | ask the user for the changelog rather than guessing |
