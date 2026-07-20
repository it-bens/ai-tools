# Python Code Stack

## Doc consultation: `pydoc`

Run through the project's environment runner so the project's pinned versions answer (`uv run python -m pydoc ...`, `python -m pydoc ...` in an activated venv). Pick the narrowest query:

| Need | Command | Typical size |
|---|---|---|
| One function, class, method, or constant | `python -m pydoc <pkg>.<Symbol>` or `<pkg>.<Class>.<method>` | small |
| Class with its methods | `python -m pydoc <pkg>.<Class>` | medium |
| Module overview | `python -m pydoc <pkg>` | medium |
| Keyword search across installed modules | `python -m pydoc -k <keyword>` | varies |
| Full HTML dump | `python -m pydoc -w <pkg>` | large — avoid for one-off lookups |

`inspect.signature` returns the parameter shape without rendering the docstring: `python -c "import inspect, pkg; print(inspect.signature(pkg.fn))"`.

Escalate past pydoc when: the docstring is empty or a stub (common for SDK wrappers) → read the installed package source; the signature accepts `**kwargs` with unlisted keys → grep the package source or check the changelog for the version the project pins; the method exists on multiple types with different semantics → confirm which object is in scope before calling.

Consultation is not required for: everyday builtins (`len`, `range`, `enumerate`, `zip`, `isinstance`); a call that already runs with a passing test exercising it; mechanically repeating an idiom established in the same file.

## Footgun catalog

Scan every written line against these; apply them even when nearby code does not.

- **Mutable default arguments.** `def f(items=[])` shares one list across every call. Default to `None` and construct inside, or use `field(default_factory=list)` on dataclasses.
- **Broad `except` that swallows the failure.** Name the specific exception; on that path either produce a structured result that records the failure or let it propagate. Returning `[]`, `None`, or `{}` from an `except` block makes a malformed input indistinguishable from a clean one. Bare `except:` and blanket `except Exception` followed by a default return are banned.
- **None-vs-falsy truthiness.** `if not config:` fires on both `None` and `{}`. Use `if config is None:` whenever None-vs-empty matters.
- **String-built SQL.** Bind parameters; never format or f-string values into a statement. String-built SQL is an injection risk and breaks on quoting edge cases even with trusted input.
- **Path string concatenation.** Use `pathlib.Path` operators (`/`, `.with_suffix`, `.relative_to`), never `+` or f-strings on path fragments, and not `os.path.join` on `Path` instances.
- **Late-binding closures in loops.** A closure created in a loop captures the variable, not its value at creation — every closure sees the final value. Bind at creation (`def make(x): return lambda: x`, or a default argument `lambda x=x: x`).

## Doc-comment convention: docstrings

PEP 257 docstrings on public symbols, with Google-style `Args:` / `Returns:` / `Raises:` sections when the contract needs them. Minimal-correct example:

```python
def resolve_manifest(directory: Path) -> Manifest:
    """Load the manifest for directory, applying the project's override chain.

    Raises:
        ManifestNotFoundError: directory contains no manifest file.
    """
```

The one-line summary is the contract; sections carry only what the typed signature cannot say (raise behavior, side effects, preconditions). A complete type signature already states parameter types and optionality — do not restate them. Private (`_`-prefixed) helpers get no docstring unless they carry a load-bearing why.
