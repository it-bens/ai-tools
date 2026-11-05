# TypeScript Code Stack

## Documentation sources

- Bundled declarations: the package's `.d.ts` under `node_modules/<pkg>/`, entry named by its `types` or `exports` field; `node_modules/@types/<pkg>/` for a package without bundled types.
- The package's README: `node_modules/<pkg>/README.md`.
- The package's implementation under `node_modules/<pkg>/` (its compiled output), for behavior the types cannot express.
- The package's official documentation site.

## Doc-comment convention

TSDoc blocks only on exported symbols whose contract the types cannot express, without `@param` or `@returns` tags that add nothing beyond the name and type.
