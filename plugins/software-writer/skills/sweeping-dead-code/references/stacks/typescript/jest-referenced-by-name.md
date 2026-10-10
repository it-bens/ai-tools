# Jest: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `jest.mock('path')` names a module by string; a `__mocks__/` file adjacent to a module is used when that module is mocked, and `__mocks__/` adjacent to `node_modules` mocks node modules automatically.
- Config `setupFiles`, `setupFilesAfterEnv`, `globalSetup`, and `moduleNameMapper` reference files by path or pattern.
