# Vitest: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `vi.mock(path)` names a module by string and is hoisted; without a factory it uses a same-named file in an adjacent `__mocks__` folder (the project-root `__mocks__` for dependencies).
- Config `setupFiles` references files by path.
