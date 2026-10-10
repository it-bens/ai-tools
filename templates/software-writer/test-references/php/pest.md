# Pest: Referenced by name, not by call

A plain-name search for a caller finds none of these; deleting one of them requires removing the name reference too.

- `dataset('name', [...])` is referenced by `->with('name')`.
- `Pest.php` attaches base classes and traits by directory (`pest()->extend(TestCase::class)->in('Feature')`, `uses(...)->in(...)`).
