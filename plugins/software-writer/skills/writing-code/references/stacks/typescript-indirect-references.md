# TypeScript: References a name search misses

A plain-name search misses or misattributes these references. Check them before concluding that a symbol has no production caller; references from test files do not count as callers.

- `export * from "./mod"` re-exports every named export (not the default) without naming it, so consumers import through the re-exporting module's path. `export { x as y }` makes consumers use `y`.
- A default export is imported under whatever local name the importer picks; search import specifiers for the module path, not the symbol name.
- Dynamic `import()` takes any expression as its specifier, so the module path can be built at runtime.
- `package.json` names entry files by path: `main` and `bin` directly, `exports` and `imports` (`#`-prefixed keys) through conditional mappings, `scripts` inside shell commands.
- Framework conventions call modules by file location and export name with no import — Next.js App Router `app/**/page.tsx` default exports and `generateStaticParams`.
- DI by string token (NestJS `provide: 'CONNECTION'` with `@Inject('CONNECTION')`) matches the provider by the token, not the class name.
- `import type` and `export type` are erased from emitted JavaScript; a value referenced only that way has no runtime use.
