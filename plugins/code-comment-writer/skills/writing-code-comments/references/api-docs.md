# API Documentation

Guidance for reviewing API documentation (PHPDoc, JSDoc, JavaDoc, docstrings, etc.): when it is a contract, how to condense it, and what to keep.

## Core Principle

API documentation describes the interface **contract** — what it offers, requires, and guarantees — not the **implementation** of how it works internally. Keep it brief and include only non-obvious information that adds value beyond the code signature.

## Visibility Determines Treatment

API documentation is for external consumers. Method visibility decides who those consumers are:

- **Public methods** — the external interface. Document the contract (capabilities, requirements, guarantees, exceptions).
- **Protected methods** — the inheritance contract. Subclasses are the consumers; document what to override and what is guaranteed.
- **Private methods** — internal implementation, **no external consumers**. Apply implementation comment rules: remove if obvious, improve if vague (explain WHY), condense if verbose. Do not write API-style PHPDoc for them.

**Detection strategy** for structured docs (`/** */` with `@param`/`@return`):

1. Check visibility first.
2. Private → implementation comment rules (WHY not WHAT, remove if obvious).
3. Public/protected → API documentation rules (condense if verbose, contract-focused).

### Private Method: Bad vs Good

```php
// Bad — API-style PHPDoc on a private method; restates obvious name/type
/**
 * Normalizes the path to match stored URL patterns.
 * @param string $path The URL path to normalize
 * @return string The normalized path with leading slash and no trailing slash
 */
private function normalizePath(string $path): string
{
    return '/' . trim($path, '/');
}

// Good — implementation comment explaining WHY, with the constraint kept
// Normalize path to match stored URL patterns (leading slash, no trailing slash)
private function normalizePath(string $path): string
{
    return '/' . trim($path, '/');
}
```

A purely self-documenting private helper (`getLayoutId()` that returns `$this->layoutResolver->resolve($route)`) needs no comment at all.

## Contract vs Implementation

| Document (contract) | Avoid (implementation) |
|---|---|
| Capabilities — what it does for the caller | Internal sequence — phases, stages, steps |
| Requirements — preconditions, input constraints | Algorithm details — how it is computed |
| Guarantees — postconditions, return values, state changes | Service calls — which internal components run |
| Exceptions — what fails and when | State transitions — internal workflow mechanics |
| Non-obvious behavior — caching, side effects, performance | Data flow — how data moves through layers |

### Example: Multi-Phase Pipeline

```php
// Verbose (implementation focus) — NEEDS CONDENSING
/**
 * Orchestrates the five-phase content pipeline to load and render content.
 *
 * Pipeline phases (sequential): 1. Route Matching 2. Entity Resolution
 * 3. Layout Resolution 4. Refinement 5. Hydration. After hydration, partial
 * rendering may extract a subtree if ?elementId present.
 *
 * @param string $path URL path to match
 * @param Request $request HTTP request
 * @throws ContentSystemException When route/layout not found
 * @return ContentPage Fully hydrated content page
 */
public function loadContent(string $path, Request $request, SalesChannelContext $context): ContentPage

// Condensed (contract focus) — BETTER
/**
 * Loads and renders content for the given URL path.
 *
 * @throws ContentSystemException When route or layout assignment not found
 * @performance Full pipeline: ~50ms; cached routes: ~20ms
 */
public function loadContent(string $path, Request $request, SalesChannelContext $context): ContentPage
```

The condensed version states WHAT (capability), documents the exception and performance characteristic (non-obvious, helps callers), and drops the internal phase list and redundant parameter restatements. The same applies to state machines, microservice orchestrations, event-driven systems, and algorithms: document observable behavior and complexity/constraints, not internal mechanics.

## Class Documentation

Make class docs one concise sentence plus important constraints. Do not list methods.

```php
// Good
/**
 * Manages file uploads with virus scanning and S3 storage.
 * Files are scanned with ClamAV before upload. Maximum file size: 100MB.
 * Uses multipart upload for files >5MB per AWS S3 guidelines.
 */
class FileUploadService

// Bad — vague, lists methods, no value
/**
 * Service for handling file operations.
 * Provides methods for uploading, downloading, and deleting files.
 */
class FileService
```

## Parameters and Return Values

Keep `@param` docs **only** when they add information the type cannot:

- **Constraints not in the type** — `Must be positive and not exceed $10,000 per business rule BR-2019`.
- **Units** — `Timeout in milliseconds (not seconds)`.
- **Format requirements** — `Phone number in E.164 format (e.g., "+14155552671")`.

Remove `@param` docs that restate the name or type:

```typescript
/**
 * @param userId The user ID    // REMOVE: obvious from name
 * @param email The email       // REMOVE: obvious from name
 */
function updateUser(userId: number, email: string)
```

Keep `@return` when the meaning is non-obvious, nullability has special significance, or it carries performance implications:

```php
/** @return User|null Returns null if user is soft-deleted (still in DB) */
function findUser(int $id): ?User
```

Remove `@return` that restates the return type (`@return User The created user`).

## Contracts: Preconditions, Postconditions, Invariants

Document these when they are not obvious from the signature or types.

**Preconditions** — requirements before calling (caller responsibilities): non-empty input, value ranges, held locks, authentication, validation. Example: `@precondition caller must hold database transaction lock`.

**Postconditions** — guarantees after execution: state changes, audit logging, locking, in-place modification, conservation rules. Example: `@postcondition total balance across both accounts remains unchanged`.

**Class invariants** — what holds for the lifetime of an instance: `balance >= 0`, immutable id after construction, all changes logged.

Remove contract documentation when the type system already enforces it (`@NonNull`), when it is obvious from the parameter name and type, or when there is no requirement beyond normal input validation.

## Summary

**Do document:** check visibility (private → implementation rules); one-sentence class docs; caching/performance/side effects; exceptions; constraints not in types; units; preconditions, postconditions, and invariants that matter.

**Don't document:** API-style PHPDoc on private methods; restated parameter names or return types; method lists in class docs; what the code obviously does; multi-paragraph summaries; constraints the type system already enforces.

API documentation is for developers **using** the code, not for explaining its implementation.
