# pytest: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- Fixtures are injected by parameter name; `conftest.py` fixtures need no import; `autouse=True` fixtures are never requested.
- `@pytest.mark.usefixtures("name")` names a fixture as a string; `pytest_*` hook functions are found by name; `pytest_plugins` lists modules as strings.
