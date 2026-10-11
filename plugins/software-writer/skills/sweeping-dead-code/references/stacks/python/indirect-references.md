# Python: References a name search misses

A plain-name search misses or misattributes these references. Check them before concluding that a symbol has no production caller; references from test files do not count as callers.

- `getattr`, `setattr`, `hasattr`, and `importlib.import_module` take names as strings, which can be computed.
- Aliases (`import x as y`, `from m import a as b`) put the alias at every use site. Package `__init__.py` files re-export names, and `from m import *` binds every name in `m.__all__` (or every name not starting with `_`) without naming it.
- Special methods run by syntax or protocol, never by name: `__enter__`/`__exit__`, `__iter__`, `__getitem__`, `__eq__`, descriptor `__get__`/`__set__`, `__set_name__`, `__init_subclass__`.
- Decorator registration hands the function to a framework that calls it: Flask `@app.route`, Click `@cli.command()`, Celery `@app.task` (a Celery task is also addressable by its name string).
- Dotted-path strings in configuration reference code: `pyproject.toml` `[project.scripts]` and `[project.entry-points]` (`module:object`), Django `INSTALLED_APPS`, `MIDDLEWARE`, `ROOT_URLCONF`.
- `unittest.mock.patch("pkg.module.Name")` names a production symbol by string without calling it, at the module where the object is looked up, which may differ from where it is defined; a patch target is a test-only reference.
