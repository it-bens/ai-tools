# Mocha: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `.mocharc.*` (or the `package.json` `mocha` key) selects test files by `spec` globs and loads modules by path through `require` entries.
