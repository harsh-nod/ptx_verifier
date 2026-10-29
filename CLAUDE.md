# Development guidance

Read [README.md](README.md) for setup and examples, and
[docs/architecture.md](docs/architecture.md) for the data flow, crate boundaries
and extension workflow. Each crate README describes its own modules and public
entry points; Rustdoc is the reference for individual types and functions.

## Code conventions

- Use distinct types for values with different roles; avoid interchangeable
  integer indices or ambiguous boolean flags.
- Prefer explicit inputs and local state over hidden shared state.
- Keep parsing, lowering, value evaluation, event production, graph checking
  and equivalence checking at their existing boundaries.
- Validate target and operand contracts explicitly. Unsupported or incomplete
  execution stays distinct from a passing result.
- Comments explain non-obvious invariants and assumptions. Avoid narrating
  straightforward code or recording temporary implementation status.
- Keep comment blocks short, normally at most three lines. Put longer design
  explanations in the owning crate README or Rustdoc.
- Update the owning crate README and relevant guides when behavior or public
  interfaces change. Document how the code works and how to use it.

## Verification

Use focused tests while editing, then run the appropriate workspace checks:

```sh
cargo test --release --workspace
just test-python
cargo fmt --all -- --check
cargo clippy --workspace --all-targets
```

Preserve actual compiler fixtures, meaningful positive controls, exact output
indices and typed negative witnesses. Native source provenance and independent
numerical oracles live beside their fixtures. Keep generated graphs, logs and
hardware run artifacts outside tracked source.
