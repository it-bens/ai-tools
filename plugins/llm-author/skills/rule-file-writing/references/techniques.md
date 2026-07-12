# Specific Techniques (Pass 2 Reference)

Loaded before Pass 2 of the optimization loop. Each technique is a short named block Pass 2 can scan against when checking structural alignment with the family pattern.

## 1. Front-Load the Decision Gate

The Decision Test almost always belongs immediately after the CRITICAL opener, before the body of rules. Most unoptimized rules files bury it at the bottom as a closing self-check. Move it up.

**Why:** The assistant reads top-to-bottom. A gate at the bottom fires after all the rules have loaded; a gate at the top primes the check before the rules need to apply.

## 2. WRONG/CORRECT Code Blocks for Syntactic Patterns

```
WRONG:   $requiredId ?? 'default-id'
CORRECT: $requiredId ?? throw new InvalidArgumentException(...)
```

Code blocks beat prose because:
- Visual contrast makes them scannable.
- Exact tokens are present, so the assistant can pattern-match against its own next-token decisions.
- WRONG/CORRECT framing is unambiguous about which is the rule.

## 3. Tables for Classification

```
| Endpoint | Returns | Use when |
|---|---|---|
| `<URL>` | <shape> | <condition> |
```

Tables compress many directives into a single scannable block. Each row is a self-contained directive.

## 4. Single-Question Decision Tests

> **"If this code path executes and produces output, am I 100% sure that output is correct?"**

A Decision Test is **one** question with a binary answer mapping to one of two actions. Multi-question gates dilute the trigger.

## 5. Tight WHY Clauses Inline

Embed the WHY as a short clause on the rule itself rather than in a separate paragraph:

> "Empty collection / null / zero returns on error paths are BANNED: they look like valid empty results."

The `: they look like valid empty results` clause is the WHY. Costs ~6 tokens, lets the assistant judge edge cases.

## 6. Narrow Escape Hatches with Explicit Gates

When a rule has legitimate exceptions, name them with explicit gate conditions:

```
Degradation is ALLOWED only when ALL of the following hold:
1. Business criticality → ...
2. Secured alternative → ...
3. Documented → ...
4. Narrow blast radius → ...

Second gate: if the degraded path would produce invalid data, hard failure is STILL preferred.
```

Without explicit gates, an absolute rule will be ignored at the first plausible exception. With them, the rule remains absolute *outside* the gates and exceptions are rare and visible.

## 7. Cross-File Structural Alignment

When multiple rules files share a domain, use the same structural shape across all of them. A consistent `CRITICAL → Decision Test → rules → Red Flags` layout reinforces pattern-matching: when the assistant reads one rule file, the others become easier to parse and apply.

## Pass 2 Scan Checklist

Run through this when applying Pass 2:

1. Is the Decision Test immediately after CRITICAL, or is it buried?
2. Are WRONG/CORRECT pairs in code blocks, or described in prose?
3. Are multi-directive sections formatted as tables, or as long bullet lists?
4. Does each Decision Test ask one question with a binary answer?
5. Does each rule carry a WHY clause (inline, short)?
6. Do exceptions have explicit gate conditions, or are they hand-waved?
7. Does the file follow the family-pattern order: CRITICAL → Decision Test → body → Red Flags → (optional sections)?
