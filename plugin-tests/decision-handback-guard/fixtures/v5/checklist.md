# Decision checklist

## The agent decides

- Test scope: unit tests only; the agent never adds integration tests on its own.
- Local re-runs of the test suite need no confirmation; CI is the gate.
- Push to origin once the tests pass.

## The user decides

- Releases and version bumps.
- Major dependency upgrades.
