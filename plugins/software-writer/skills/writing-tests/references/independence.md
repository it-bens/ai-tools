# Test Independence

## Shared mutable state

Tests do not share mutable state across test functions, cases, or fixtures. Four leak vectors:

1. **Package/module-level mutable state** in a test file, written by one test and read by another. Each test owns its state; a fixture or factory produces it fresh.
2. **Closure or fixture capture across cases**, where an outer scope mutates a variable later cases read.
3. **Unrestored globals**: environment variables, working directory, default clients, module attributes, mocked functions, mocked system time.
4. **Wall clock or randomness feeding an assertion.**

Do NOT flag:

- Read-only values loaded once (a compiled regex, a parsed golden file, a shipped default configuration) that no test mutates.
- Values produced fresh per test by a helper or fixture.
- Lazily initialized immutable data behind a once-guard.

## Scoped restore

When a seam can reach the dependency (an injected clock, an injected environment reader), use the seam and leave the global untouched. When a global must be mutated, restore it in the framework's teardown or cleanup hook, registered right after the mutation — never by hand at the end of the test body.

## Non-deterministic inputs

Non-determinism (wall clock, unseeded randomness, generated ids) never feeds an assertion.

## Hermetic by default

A test depends on nothing outside its own body and its declared fixtures: no network, no shared external services, no shared databases, no reads from the developer's machine state. A test that needs an external resource either injects a fake at a production seam or belongs to an explicitly marked integration tier the project defines. Shared external resources that must be touched (a container daemon, a device) are acquired and released within the test's own scope.
