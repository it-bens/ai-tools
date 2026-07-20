# PHP Code Stack

## Doc consultation: CLI reflection

The PHP CLI answers signature questions from the installed runtime. Pick the narrowest query:

| Need | Command |
|---|---|
| One function's signature and parameters | `php --rf <function>` |
| A class with its methods and properties | `php --rc <ClassName>` |
| An extension's classes and functions | `php --re <extension>` |
| An extension's configuration | `php --ri <extension>` |

For Composer dependencies, read the installed package source under `vendor/<vendor>/<package>/` — the version the lockfile pins is the contract, not the latest documentation. Escalate to the official manual or the package's documentation when the behavior in question is semantic (return-value edge cases, error modes) rather than a signature.

Consultation is not required for: everyday language constructs (`foreach`, `isset`, `count`, string interpolation); a call that already runs with a passing test exercising it; mechanically repeating an idiom established in the same file.

## Footgun catalog

Scan every written line against these; apply them even when nearby code does not.

- **Loose `==` comparisons.** `==` type-juggles (`"1" == 1`, `"abc" == 0` on old majors, `null == false`). Use `===` / `!==` everywhere; a loose comparison is acceptable only with a why-comment naming the coercion it deliberately exploits.
- **Unhandled `false`/`null` returns from the standard library.** Many stdlib functions signal failure through their return value (`strpos`, `file_get_contents`, `preg_match`, `json_decode`). Check the failure value explicitly with `===` before using the result — `strpos` returning `0` is a match at position zero, not a failure.
- **Missing `declare(strict_types=1);`.** Every new file starts with it. Without strict types, scalar type declarations coerce silently and a `"5"` satisfies an `int` parameter.
- **String-built SQL.** Bind parameters via prepared statements; never concatenate or interpolate values into a statement.
- **Array-vs-null ambiguity.** A function returning `array|null` (or `array|false`) forces every caller to branch; returning an empty array for "none" and reserving exceptions for failures keeps call sites linear. When consuming such a function, handle the non-array case explicitly — `foreach (null)` raises, and `count(false)` fatals.

## Doc-comment convention: PHPDoc DocBlock

A DocBlock is a `/** ... */` comment immediately preceding the structural element it documents. With full native parameter and return types, tags that restate the types are noise; the DocBlock carries only what the signature cannot say — array value shapes, throw behavior, side effects. Minimal-correct example:

```php
/**
 * Load the manifest for the directory, applying the project's override chain.
 *
 * @throws ManifestNotFoundException when the directory has no manifest file.
 */
public function resolveManifest(string $directory): Manifest
```

Use `@param`/`@return` tags only where they add information beyond the native types — for example `@param list<string> $paths` to narrow a native `array`.
