# Development guidance

Read [README.md](README.md) for setup and examples, and
[docs/architecture.md](docs/architecture.md) for the data flow, crate boundaries
and extension workflow. The CLI also exposes upstream `solve` and `extract lean`
workflows through its command modules. Each crate README describes its own
modules and public entry points; Rustdoc is the reference for individual types and functions.

## Scope

This fork develops AMD support. Keep fork-specific implementation changes and
upstream submissions focused on AMD. Preserve upstream NVIDIA/PTX instruction
semantics and tests; shared interfaces and launch adapters may change as needed
to integrate AMD backends.

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
cargo clippy --workspace --all-targets --all-features
cargo clippy --workspace --exclude volta_ptx_analysis --all-targets --all-features --no-deps -- -D warnings
cargo clippy -p volta_ptx_analysis --lib --all-features --no-deps -- -D warnings
```

Workspace Clippy covers every target. Strict checks cover all targets outside
the PTX crate and its production library with all features. PTX test, example
and benchmark targets retain upstream's warning policy.

Preserve actual compiler fixtures, meaningful positive controls, exact output
indices and typed negative witnesses. Native source provenance and independent
numerical oracles live beside their fixtures. Keep generated graphs, logs and
hardware run artifacts outside tracked source.

## Frontend and proof boundaries

Explicit native AMD selection uses `volta_amdgpu_analysis` and its target-selected
graph/certificate contracts. Extension-inferred `.s` solve/extract uses upstream
`volta_amd_analysis`; that experimental gfx950 interpreter and Trainium NKI do
not record a race graph. The experimental AMD interpreter tracks ordinary LDS
completion and refuses barriers reached with pending LDS operations; this does
not establish race freedom. Keep its output-only mathematical results separate
from native graph verification. `extract lean` emits obligations that still
require proofs; rejected or incomplete native executions cannot export them
as a successful extraction.

`volta_cli/src/cli.rs` defines command arguments, and `src/commands/` contains
handlers. `volta_pipeline` composes frontend outputs, graph evidence and canonical
or Lean solvers. Producers do not depend on either checking branch. Preserve
source/target validation, exact output coordinates and the private independently
validated prefix routes when adapting these interfaces.
