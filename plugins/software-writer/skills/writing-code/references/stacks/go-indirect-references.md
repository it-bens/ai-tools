# Go: References a name search misses

A plain-name search misses or misattributes these references. Check them before concluding that a symbol has no production caller; references from test files do not count as callers.

- Interfaces are satisfied implicitly: a method with no direct caller (`String`, `Error`, `ServeHTTP`) can be called through an interface value.
- `init()` runs automatically and cannot be referenced; `import _ "path"` exists only for that initialization.
- `text/template` and `html/template` call methods named in template text (`.Method`) and functions registered in a `FuncMap` by string key.
- `reflect` looks methods up by string (`MethodByName`), and encoders read struct tags by reflection.
- A method on an embedded field is promoted: `outer.M()` calls the method declared on the embedded type.
- Build constraints (`//go:build`) and `_GOOS`/`_GOARCH` filename suffixes exclude files from a build; a caller in an excluded file is invisible to that build and to analysis run on it. Search every file, not only the current build.
- `//go:linkname` references a symbol from another package under a different local name; cgo `//export Name` makes a Go function callable from C.
- Same-package `_test.go` files can call unexported identifiers; those calls are test-only references.
