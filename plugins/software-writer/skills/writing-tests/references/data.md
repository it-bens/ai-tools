# Test Data and Fixtures

## Inputs must be locatable from the test

A reader of only this test can tell what the inputs are and where they came from. Inputs hidden in shared setup the reader cannot see from the test are a Mystery Guest.

### Acceptable sources

- Fresh temporary filesystem state the test creates itself (the framework's per-test temp-directory mechanism).
- A committed fixture file in the test tree's fixture location, for inputs of roughly 10 lines or more and for parser/scanner/importer subjects that deserve a representative on-disk shape.
- An inline literal, for single-line inputs, narrow units, and malformed-shape cases — inline is clearer than a dedicated fixture per malformation.
- A project fixture helper registered via `tests.fixture_sources`.

### Flag

- Absolute paths (`/home/user/data.json`, `/tmp/some-fixture`) — flaky across machines.
- Source-tree access at test time (opening production source files as test input).
- Cross-module or cross-package fixture borrowing — each test tree owns its fixtures.
- Dynamic globs over an unbounded directory.
- Reads from the developer's home directory.
- Network calls in unit or integration tests.

```python
# WRONG: absolute path
data = Path("/home/me/samples/manifest.json").read_bytes()

# WRONG: borrowing another module's fixtures
data = Path("../../other_module/tests/fixtures/manifest.json").read_bytes()

# CORRECT: state the test creates under its own temp directory
def test_loader_reads_manifest(tmp_path):
    (tmp_path / "manifest.json").write_text('{"parcels": []}')
    manifest = load_manifest(tmp_path / "manifest.json")
    assert manifest.parcels == []
```

## Real fixture files for parsers and complex inputs

Tests exercising parsing or complex I/O read committed fixture files rather than build content inline.

Applies when: the test writes a multi-line blob to disk and reads it back; the test builds a file via string concatenation longer than ~10 lines; the test exercises a parser, importer, exporter, or scanner against representative input.

Does not apply when: the blob is a single line; the test specifically exercises a malformed input shape; the content is never written to a file or stream.

```python
# WRONG: 40 lines of string concatenation rebuild a shape that belongs on disk
def test_scan_session_log(tmp_path):
    content = '{"event":"start","id":"run-1"}\n' + '{"event":"step",...}\n'  # ...38 more lines
    (tmp_path / "run.ndjson").write_text(content)
    events = scan_log(tmp_path / "run.ndjson")
    assert len(events) == 40

# CORRECT: the fixture lives in the test tree where it can be inspected and reused
def test_scan_session_log():
    events = scan_log(Path(__file__).parent / "fixtures" / "run.ndjson")
    assert len(events) == 40
```

## Descriptive identifiers

String literals used as identifiers in assertions are descriptive. Opaque blobs make failure messages unreadable.

Flag: 32 consecutive hex characters as a test-constructed identifier; repeated-character placeholders (`"0000000000000001"`); placeholder UUIDs invented for the test body; meaningless names (`"foo/bar"`, `"x"`).

Do NOT flag: UUIDs read from committed fixtures (they mirror real on-disk shapes); identifiers produced by the code under test (capture them in a variable named for what they are); tests that specifically exercise identifier-format validation.

```python
# WRONG: unreadable in a failure message
ledger.register(parcel("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))

# CORRECT: descriptive
ledger.register(parcel("priority-overnight-box"))
```

## DAMP over DRY

Test code optimizes for readability at the point of failure, not for zero duplication. A little repetition that keeps each test self-explanatory beats an abstraction that hides the variation under test.

### Helper extraction: the 5-line / 3-occurrence rule

Extract a helper on the third occurrence of the same 5+ consecutive lines of construction with identical types and arguments. Two occurrences are not yet a pattern — wait for the third.

Do NOT extract when:

- The helper would hide the single input that varies per test — the variation is the test.
- Fewer than 5 lines repeat.
- Only two occurrences exist; wait for the third.

Place helpers where the smallest set of tests that need them shares an ancestor, using the framework's helper idiom (the framework reference names it).

### Test Data Builder over Object Mother

When construction variation grows, prefer a Test Data Builder — a helper that produces a valid default object and accepts per-test overrides for exactly the fields under test — over an Object Mother, a catalog of named preconfigured objects. Builders keep the varied field visible at the call site; Object Mothers accumulate variants whose differences the reader must go look up.

```python
# Object Mother: the difference between these two is invisible at the call site
order = OrderMother.standard_order()
order = OrderMother.discounted_order()

# Test Data Builder: the varied field is the visible one
order = make_order()                       # valid defaults
order = make_order(discount_percent=15)    # the variation under test, visible
```

## Production-scale gating

Some projects gate adversarial-scale tests (huge fixtures exercising size caps or overflow guards) behind an opt-in tier so CI stays fast. `tests.scale_gating` names the project's pattern; without it, do not invent a gated tier.

When the pattern exists, pair every gated production-scale test with an always-on small-scale variant that exercises the same branches at trivial cost by overriding the caps through a production seam. Neither test replaces the other: the small variant confirms on every run that the rejection branch fires; the gated variant confirms the threshold holds at production scale. If the small variant cannot reach a branch the gated one reaches, document the gap in the gated test's leading comment.
