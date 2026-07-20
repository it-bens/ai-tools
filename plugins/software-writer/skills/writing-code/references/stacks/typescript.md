# TypeScript Code Stack

## Doc consultation: the `.d.ts` surface

The TypeScript analog of a docs lookup is the declaration surface the compiler actually consults. Pick the narrowest source:

| Need | Path |
|---|---|
| One function or method signature | Hover / Go to Definition in the editor; lands on the `.d.ts` |
| A package's exported surface | The package's bundled `.d.ts` under `node_modules/<pkg>/` (entry named by its `types` or `exports` field) |
| A package without bundled types | `node_modules/@types/<pkg>/` — hand-authored, can drift from runtime |
| Behavior the declared types cannot express (async timing, side effects, defaults) | Go To Source Definition, or the implementation under the package's dist directory |
| Semantics, gotchas, version changes | The package's README or official documentation |

`tsc --noEmit` is the final arbiter: when unsure whether a call shape compiles, write it and typecheck rather than guessing from memory.

Escalate past the `.d.ts` when: the declared signature is loose (`options?: Record<string, unknown>`, overloads with `any`); the behavior is temporal or effectful — what a function awaits, when a handle closes, whether a callback is synchronous — which types cannot express; the types come from `@types/` and the call is load-bearing; the semantics changed between majors — check the version pinned in `package.json`, then the changelog.

Never silence a mismatch with `as any` / `as unknown as T` to make a call compile — the type error is the documentation. A forced double-cast is permitted only when the dependency offers no typed path; add a one-line why-comment naming the missing typed path.

Consultation is not required for: language builtins (`Array.prototype` methods, `Object.keys`, `JSON.parse`/`stringify`, `Math.*`, `Promise.all`); a call that already runs with a passing test exercising it; mechanically repeating an idiom established in the same file.

## Footgun catalog

Scan every written line against these; apply them even when nearby code does not.

- **Floating promises.** A `Promise`-valued statement is handled only if it is awaited, returned, `.then()`-ed with a rejection handler, `.catch()`-ed, or explicitly `void`-ed. Anything else silently drops rejections.
- **Truthiness on `0`, `""`, and `NaN`.** `if (!count)` fires on a legitimate `0`; `value || fallback` replaces `0` and `""`. Compare explicitly (`value === undefined`) and use `??` so only `null`/`undefined` trigger the fallback.
- **Non-exhaustive discriminated-union switches.** Every `switch` on a discriminant carries a `default` that assigns the narrowed value to `never` (`const _exhaustive: never = value;`) so adding a union member fails compilation at every switch instead of falling through at runtime. Never replace the `never` default with a permissive fallback.
- **`enum` vs string-literal unions.** Model domain alternatives as string-literal unions (`"one-time" | "recurring"`). Enums emit runtime objects and compare unsafely against raw literals; unions are erased entirely and narrow exhaustively.
- **Unchecked index access.** Array indexing and record lookups yield possibly-`undefined` values; handle the `undefined` by narrowing, or restructure to a lookup the type system can prove (closed-union record keys). Enable and honor `noUncheckedIndexedAccess`.
- **External data is `unknown` until validated.** Anything crossing a boundary — parsed JSON, form input, records read back from storage — is validated through its schema before use; no `as` casts on parsed data. A configuration that fails validation fails loudly at startup, never falls back to defaults silently.

## Doc-comment convention: TSDoc

TSDoc blocks only on exported symbols whose contract the types cannot express — side effects, throw behavior, ordering constraints, what absence of an optional value means. Omit `@param`/`@returns` tags that add nothing beyond the name and type. Minimal-correct example:

```typescript
/**
 * A configuration that fails validation is a startup defect, never a user
 * error — this throws instead of returning a fallback.
 */
export function loadCatalogConfiguration(raw: unknown): CatalogConfiguration {
```

Prefer making the types say it: a discriminated union over a comment listing valid combinations, a `readonly` field over "do not mutate", a unit-suffixed identifier (`timeoutSeconds`) over a `@param` explaining the unit.
