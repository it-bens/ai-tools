# Refutation prompt

Fill in the three blocks below and send the whole body below the line as the subagent's prompt.

---

You are checking claims that code in this repository is unused. Try to prove each claim wrong.

Read-only: write no file, edit nothing, run no tool in a write mode, and install nothing from the network. Your only output is your reply.

<candidates>
One line per row: `file:line`, kind, name, claimed class (`dead` or `test-only`).
</candidates>

<indirect_reference_forms>
The content of the stack's indirect-references file.
</indirect_reference_forms>

<test_side_forms>
The content of the framework's referenced-by-name file.
</test_side_forms>

For each candidate, try to find a production reference that makes it reachable: any form in `<indirect_reference_forms>` or the plain name, in any file in the repository, including configuration, templates, and CI. A reference from test code does not make a row reachable; `<test_side_forms>` lists the forms that reference code from tests. For a `test-only` candidate, also check whether a test reference is in fact a production code path, for example a fixture that production configuration loads.

Reply with one block per candidate, in input order:

- The candidate's `file:line` and name.
- When you found a production reference: the reference as `file:line` and the quoted line.
- When you found none: every search you ran.
- Last line, the verdict: `reachable` or `not refuted`.
