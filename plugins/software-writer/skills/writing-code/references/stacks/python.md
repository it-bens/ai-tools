# Python Code Stack

## Documentation sources

- `pydoc`, run through the project's environment runner so its pinned versions answer: `uv run python -m pydoc <pkg>.<Symbol>`, or `python -m pydoc <pkg>.<Symbol>` in an activated venv.
- Installed package source, located with `python -c "import <pkg>; print(<pkg>.__file__)"` through the same runner.

## Doc-comment convention

PEP 257 docstrings on public symbols: a one-line summary, then Google-style `Args:` / `Returns:` / `Raises:` sections only for what the typed signature cannot say.
