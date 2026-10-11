# PHPUnit: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `#[DataProvider('name')]`, `#[DataProviderExternal(Cls::class, 'name')]`, `#[Depends('name')]`, and `#[DependsExternal(...)]` name methods as strings; older versions use the `@dataProvider` and `@depends` docblock forms.
- `setUp`, `tearDown`, and methods marked `#[Before]`, `#[After]`, or `#[BeforeClass]` run with no caller.
- `#[CoversClass]` and `#[UsesClass]` name a production class without calling it; they are test-only references.
