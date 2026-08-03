# Three-Angle Pattern (Pass 2 Reference)

A rule can be represented three ways; the redundancy is load-bearing, not ballast.

## The Three Angles

A rule lands harder when it appears in three forms:

1. **Declarative rule** (Core Rules section): "X is banned because Y."
2. **Syntactic example** (Banned Patterns block): `WRONG: foo() / CORRECT: bar()`
3. **Thought interception** (Red Flags table): `"<rationalization>" → <correction>`

## Why Each Angle Matters

Each form is recalled via a different cognitive trigger:

| Angle | Recalled when the assistant is... |
|---|---|
| **Declarative** | thinking about the rule space |
| **Syntactic** | writing the specific token |
| **Thought interception** | rationalizing a bypass |

This is **intentional redundancy, not ballast.** The three forms together cost more tokens than any single one, but the cost is justified: each form catches failure modes the others miss.

## When To Use All Three

Apply the full three-angle treatment to rules where **bypass is a known failure mode**:
- Sycophancy and contrarianism (users can pressure the agreement or disagreement into the wrong direction)
- Defensive coding (fallbacks and try/catch feel productive)
- Silent fallbacks (graceful degradation feels customer-friendly)
- Test-writing shortcuts (loose assertions feel like coverage)

## When One Angle Is Enough

Rules with **no plausible rationalization** need only one or two angles. If the wrong path returns an error on its own (e.g. a host that returns 403 for automated fetches), the assistant cannot rationalize the wrong token — the environment enforces the rule. One declarative rule plus a decision gate and a small table is sufficient:

```markdown
# NPM Registry Access

**CRITICAL**: Use `registry.npmjs.org`, never `www.npmjs.com` — the latter returns 403 for automated fetches.

## Decision Test — run before any npm URL fetch

> **"Am I about to hit `www.npmjs.com`?"**

- no → proceed
- yes → rewrite to `registry.npmjs.org/<name>/latest`

## Endpoints

| URL | Returns |
|---|---|
| `registry.npmjs.org/<name>/latest` | Single version object (default) |
| `registry.npmjs.org/<name>` | Full packument |
```

No Red Flags, no WRONG/CORRECT block. Adding either would be ballast.

## Full Three-Angle Example

For a bypass-prone rule, the same rule appears declaratively, syntactically, and as thought interception. A condensed demonstration:

```markdown
# Fail Hard

**CRITICAL**: Hard failure is the default. Silent fallbacks corrupt downstream state — callers cannot distinguish a degraded result from a correct one.

## Decision Test — run before writing any catch block or default value

> **"If this path produces output, am I 100% sure that output is correct?"**

- yes → proceed
- no → throw

## Core Rules

- Missing required input → throw, never substitute a default.
- External dependency down → throw, never return stale/empty data.

## Banned Patterns

​```
WRONG:   try { real() } catch { fallback() }
CORRECT: let it throw

WRONG:   $requiredId ?? 'default-id'
CORRECT: $requiredId ?? throw new InvalidArgumentException(...)
​```

## Red Flags

| Thought | Reality |
|---|---|
| "Let's be defensive here" | Defensive code hides the bug you should see. |
| "We'll return empty if it fails" | Caller cannot distinguish empty from broken. |
```

All three angles covered:
- **Declarative** → `## Core Rules` bullets, recalled when reasoning about the rule space.
- **Syntactic** → `## Banned Patterns` WRONG/CORRECT block, recalled when writing the specific token.
- **Thought interception** → `## Red Flags` table rows, recalled when rationalizing a bypass.

## Pass 2 Check

For each major rule in the file being optimized:
1. Is there a declarative statement of the rule?
2. If the rule has a syntactic form, is there a WRONG/CORRECT pair?
3. Is there at least one Red Flags row that intercepts the rationalization a user would use to bypass it?

If the rule is bypass-prone and any of the three is missing, add it. If the rule is non-rationalizable, one or two is enough — don't manufacture the missing angles.
