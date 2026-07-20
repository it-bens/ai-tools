# Writing Style

## Sentence and paragraph constraints

- Sentences ≤25 words, averaging 12 to 17.
- Active voice predominant; passive only when the agent is genuinely uninteresting.
- Paragraphs ≤4 sentences.

The targets correspond to a Flesch-Kincaid band of roughly 10-14, which is the working range for developer documentation. Reject rewrites that push the text toward consumer-grade readability — simplifying below the band strips precision the audience needs.

## Headings predict their content

`§<heading name>` cross-refs are the navigation backbone across surfaces. They break the moment a heading goes vague, so heading clarity is load-bearing, not cosmetic.

| Heading | Verdict |
|---|---|
| `## Compiled-file handling` | Predicts content; safe to cite as `§Compiled-file handling` |
| `## Implementation notes` | Vague; the cross-ref rots when content drifts |
| `## Details` | Vague; rename to what the section actually covers |

When renaming a heading, search for `§<old name>` across every surface and update every cross-ref in the same edit.

## Jargon discipline

Project-specific jargon is defined once at the surface `docs.jargon_home` names and never re-defined. A surface that re-defines a term creates a second canonical definition that will drift from the first — point at the definition instead.

Stack and standard-library vocabulary stays undefined. The audience knows what a dataclass, a test runner, a container flag, and a template engine are; defining them adds noise and signals the wrong audience.

## Numbers earn their place

Include a numeric value only when the reader cannot derive it from surrounding text. Decision test: if replacing the number with "several" or deleting it loses no information, delete it.

**Keep** (the value carries information):

- Thresholds and limits (truncation lengths, memory caps, concurrency bounds)
- Version pins and floors
- Indexing conventions (1-indexed lines, 0-indexed columns)

**Strip** (the value restates or invents):

- Counts labeling an enumeration the text then gives ("the three output formats" followed by the three formats)
- Speculative future cardinalities ("adding a sixth checker") — write "a new checker"
- Approximate counts restated across surfaces — let the authoritative source (a registry, a list command) carry the number, cited once

## Diagrams earn their place

`docs.diagrams` sets the stance; the default is table-first: add a diagram only when a table cannot express the relationship. Cross-module flow and containment relationships qualify; a flag list or a contracts skeleton never does. Do not add a diagram to a module README to make it "friendlier", and do not strip an existing earning diagram during a single-owner pass — the diagram is the owning surface for the system's shape.

## Worked rejections

| Suggested rewrite | Rejection |
|---|---|
| "Restate the count in each module README so each is self-contained" | The count lives once at its authoritative source. Restatements drift on the next change. |
| "Add a diagram to the module README to illustrate the flag flow" | A flag table carries it. Diagrams belong where the relationship is cross-module. |
| "Giving the count upfront frames the list that follows" | The list already gives the count. The label is noise; delete it. |
| "Future-proof the rule for when a sixth format appears" | "Sixth" bakes in today's count and breaks on the next add. Write "a new format". |
| "Soften this contract claim to 'should' so it's safer" | Hedging hides drift. Verify against code and state it, or remove the claim. |
| "Simplify the wording so any reader can follow" | The audience is developers. Rewrites below the FK band strip precision without adding readers. |
