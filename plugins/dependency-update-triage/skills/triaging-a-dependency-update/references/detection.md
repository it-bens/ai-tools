# Detection

Learn the host project from its own files. Never assume an ecosystem, forge, or updater bot.

## What to detect

| Target | Why the assessment needs it | Where to look |
|---|---|---|
| Ecosystem + package manager | To read the update and know where release notes live | The manifest and lockfile present in the repo |
| Dependency directness | To know whether the package's symbols appear in the host code (direct) or not (transitive) | The manifest (declares direct deps) versus the lockfile (resolves transitive ones) |
| Type system | To reason about whether the update surfaces type or contract errors | Manifest config, compiler/config files, file extensions |
| Release-notes location | To fetch the changelog for the exact version range | Registry metadata, the package repository, the update PR body |
| Gate commands | To name the gate a required change must pass (referenced, not run) | CI workflow files and the manifest's script section |
| Update source | To gather inputs (not to modify anything) | The update PR, or the user's request |

## Ecosystem and package manager

Identify the ecosystem from the manifest and lockfile in the repo, not from the package name. Identify the package manager from the lockfile. Examples of manifest/lockfile pairs across ecosystems, not a closed set:

- a JavaScript/TypeScript manifest with one of several lockfiles (npm, pnpm, yarn, bun)
- a Python project manifest or requirements file with its matching lock or pin file
- a Go module file and its checksum file
- a PHP manifest and its lock file
- a Rust manifest and its lock file

When more than one manifest or lockfile is present, scope each updated package to the manifest that declares it (or the lockfile that resolves it); packages of a grouped update are assessed in the same invocation, each against its owning manifest. If an owning manifest is genuinely ambiguous, ask rather than guess.

Determine whether the updated package is a **direct** dependency (declared in a manifest) or **transitive** (only present in the lockfile, pulled in by another dependency).

## Release-notes location

Resolve where the changelog for the exact old to new range lives, in this order:
1. The update PR body, when a PR exists (bots usually embed release notes).
2. The registry's metadata for the package (release notes, repository link, homepage).
3. The package's source repository (a `CHANGELOG`, releases page, or tagged notes).
4. When no changelog or release notes exist for the range, the diff between the two version tags: read it bounded to the public/exported surface, feed the same three inventories, and say in the report that the assessment is diff-derived.

Fetch through the available git-forge tooling for repository content and the available web reader for everything else, routing around known-blocked hosts. Never reconstruct a changelog from memory. If the range spans several releases, gather every intervening release's notes, not only the endpoints.

## Type system and gate commands

Read the project's CI workflow files and the manifest's script section to learn the exact typecheck, lint, test, and build commands. Detect them so the report can name the gate a required change must pass. Do not run them (read-only). Report the gate command and any existing CI result instead of executing it. Never invent a command the project does not define.

## Update source

Detect the source only to gather inputs. A forge PR gives the diff, the release notes, and the version range; a plain user request gives the package and target version directly. Do not assume a PR or a bot exists.
