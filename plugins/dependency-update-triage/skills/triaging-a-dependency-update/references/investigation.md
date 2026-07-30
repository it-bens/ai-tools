# Investigation and assessment

Search the currently visible checkout. If context specifies a different code state, follow it.

## The structured engine

Never read the whole diff. Bound the release into finite inventories, then search, rank, and disposition.

1. **Bound the release into three inventories** from the changelog:
   - **Changed surface**: every changed contract — removed, renamed, deprecated, or behavior-changed symbols, plus changed runtime or platform minimums, peer/companion dependency ranges, packaging or module format, configuration schemas and defaults, and operational requirements. Feeds prong (a).
   - **Added surface**: new APIs, new options, new test doubles / fakes / matchers / fixtures, new or loosened types. Feeds prong (b).
   - **Fixed-bug list**: entries described as bug fixes. Feeds prong (c).

   Each prong reads its own inventory first. The added surface is prong (b)'s primary inventory; an entry from the changed surface or the fixed-bug list also feeds prong (b) when it removes a limitation the code currently routes around. Anything else mined from the changed surface fails the unlocking test.
2. **Know the directness.** From detection, know whether the updated package is direct (declared in a manifest) or transitive (only in the lockfile).
3. **Search each candidate in the visible code.** Search call sites, and also imports, string keys, configuration references, and framework or dependency-injection registrations. A zero call-site count does not mean unused: reflection, DI, config-driven wiring, and generated code use a symbol with no textual call site. Search a non-symbol candidate (runtime minimum, packaging, default, config schema) in the manifest, configuration, and CI files rather than call sites.
   - For a **direct** dependency, search its symbols' usages.
   - For a **transitive** dependency, search the host code for its imports and symbols first: a hit means the package is used directly though undeclared — assess those usages as direct and report the undeclared use as a required change. When no direct use exists, run the detected package manager's dependency-query command (its `why`, `ls`, `tree`, or equivalent), confirmed to write nothing (no lockfile update, no install), to resolve which direct dependency pulls the package in, then assess reachability through that intermediary and ground the claim on the intermediary's affected call site. When the path cannot be established, or no write-free query exists against the current tree, report reachability as **unknown**, not "not used here."
4. **Rank by criticality, not raw count.** One call site on a hot or critical path outweighs many in rarely-run code. Take the highest-criticality, highest-reachability candidates first. Verify in depth only the top-ranked candidates — default five to ten, scaled to changeset size and criticality spread; every candidate below the line is dispositioned unverified and surfaced as a limitation.
5. **Disposition every candidate.** Each candidate ends verified (affected or not affected, with a code reference) or unverified. Surface every unverified candidate as a report limitation, and let it block an unconditional "no changes needed" conclusion.

## Model tiers

The driver adjudicates each worker finding against the evidence returned with it (code reference, changelog quote); a finding that arrives without evidence is dispositioned unverified. Workers run the cheap fan-out.

| Tier | Work | Where it runs |
|---|---|---|
| Fan-out (cheap) | inventory extraction, candidate search, link triage | dispatched worker |
| Reading (mid) | read one changelog or migration note in depth, verify one candidate's reachability | dispatched worker |
| Driver (strong) | decompose, adjudicate findings, run the three prongs, decide adopt vs wait | the session itself |

- Where the host dispatches subagents with per-worker model selection, send the fan-out tier to the cheapest capable model, the reading tier to a mid model, and keep the driver on the session model. Dispatch independent workers concurrently.
- Where the host has no per-worker model routing, run the tracks inline in the session.

## Prong (a): does it require changes?

From the changed surface. Decide what the update forces us to change across code, tests, docs, config, and pipeline. Ground every "this affects us" claim in a real code reference: the call site of a removed or changed symbol, the config key that no longer exists, the test that asserts the old behavior.

When you name a change the update requires, note whether a clean fix exists or only a workaround, and point at the strongest-correct form (the correct type, the real contract), not the quickest way to green.

## Prong (b): does it enable an improvement?

Primarily from the added surface, plus limitation-removing entries from the other inventories. An improvement is a concrete change the update newly makes possible that leaves our code simpler, safer, more correct, or better tested. The test is **unlocking**: the change was awkward, redundant, or impossible under the old version and becomes clean under the new one. It is not any change we could already have made, and not a speculative "would be nice."

Testability is its own axis. An update can leave the production code no simpler (the code is still affected, still there) yet make it easier to test: the new version is more mockable, exposes a seam it used to hide, or ships a test double, fake, matcher, or fixture helper. Count it as an improvement even when the production code does not get shorter. A single symbol can land in both prongs at once, affected by the update and newly testable because of it.

Illustrative shapes, not the whole set:
- removing a workaround that existed only to route around the old version's limitation
- replacing code we hand-maintained with a capability the update now provides
- dropping a dependency we adopted only to fill a gap the update now closes
- covering code the old version made hard to test, now that the new version is more mockable, exposes a seam, or ships a test double, fake, or matcher
- tightening a type or contract the new version now lets us express

An improvement that fits none of these still qualifies if it passes the unlocking test. Surface each one only with a concrete before→after; for a testability improvement, name what was untestable before and what the update lets you assert now.

## Prong (c): does a bug the update fixes implicate our application?

From the fixed-bug list, and only when it is non-empty. For each fixed bug, check whether it could have reached us through our use of the dependency, directly or transitively. Transitive reach has two senses, and both count: a dependency we do use may route through the fixed code, and the buggy package may be a transitive dependency we never named directly.

When the bug plausibly reached us, flag it in the report as an item **to investigate**, not as a verdict. The update does not undo effects the bug already produced. After the update, the application may still carry:
- persisted bad data the bug wrote,
- a workaround we added to compensate for the bug, now redundant or itself wrong,
- a parallel hand-rolled copy of the same buggy logic, still unfixed,
- or code that relied on the buggy behavior and now diverges from the corrected behavior.

Ground the "this could have reached us" claim in a real code reference, and cite the changelog entry describing the fix. In the flag, name the fixed bug, our affected path, and the reason the application-level effect might persist even after the update lands.
