# Architecture and development guide

The engine has three independent responsibilities: construct a candidate
execution, check its safety graph, and compare its mathematical outputs.
`volta_pipeline` composes them for the CLI and Python interfaces.

```mermaid
flowchart LR
  S[Assembly + launch configuration] --> A[Backend parser, lowering and execution]
  A --> E[Symbolic outputs]
  A --> G[Event graph + provenance]
  R[Mathematical specification] --> E2[Reference outputs]
  E --> Q[Equivalence checker]
  E2 --> Q
  G --> C[Target-selected graph checks]
  Q --> D[Decision aggregation]
  C --> D
```

The graph checker never calls the interpreter or equivalence checker. The
equivalence checker consumes expressions, not events. This separation keeps an
arithmetic identity from hiding a synchronization defect, and a safe execution
from standing in for correct output values. Kernel comparison runs the assembly
path for both kernels and checks both graphs. Dependency boundaries are enforced
by [architecture_tests.rs](../crates/volta_pipeline/tests/architecture_tests.rs).

## Follow one kernel

1. `volta_cli/src/main.rs` or the PyO3 bindings select a backend and build an
   `AnalysisConfig`. `volta_common::config` validates shared geometry, arrays,
   arguments and allocation premises. The JSON launch reader lives in
   `volta_ptx_analysis/src/launch_file.rs` and serves both backends.
2. The CLI/Python interface parses the source into a `KernelModule`, then
   `volta_pipeline/src/backend.rs` dispatches analysis. PTX and native AMD have
   separate frontends, lowering and interpreters. Their outputs share
   `volta_expr` and `volta_graph` contracts.
3. The interpreter computes an expression DAG and records memory, register,
   synchronization and lifetime events for one execution. Provenance carries
   target, geometry, source spans and modeling assumptions. The terminal state
   distinguishes completion, a stuck execution and an abort.
4. `volta_graph_check::check_graph` selects the applicable checks from target
   provenance. Native AMD uses completeness, readiness, barrier-generation and
   memory-conflict checks. PTX has separate barrier, memory, proxy, tensor and
   resource checks. Each returns evidence, typed witnesses or unresolved reasons.
5. `volta_spec` turns a mathematical specification into the same output
   expression representation. `volta_equivalence` compares exact per-array index
   sets and expressions, with optional numerical oracle confirmation.
6. `volta_pipeline::decide` combines the independent results. `ACCEPT` needs
   complete equivalence and a completed trace with every applicable graph check
   passing. A refutation, index mismatch, failed check or deadlock yields
   `REJECT`; a missing proof yields `UNKNOWN`.

## Shared contracts

| Crate | Data and responsibility |
| --- | --- |
| `volta_common` | Source spans, diagnostics, launch primitives and run logs |
| `volta_expr` | Interned expression DAG, symbolic output indices and text exchange |
| `volta_spec` | Specification parser, dimension binding and formula unfolding |
| `volta_graph` | Typed events, edges, memory/register footprints and provenance |
| `volta_graph_check` | Independent graph properties and their certificates/witnesses |
| `volta_equivalence` | Algebraic equivalence, numerical refutations and VC serialization |

The `volta_amd_analysis` crate contains an experimental parser/lowering path.
The native `amdgpu` CLI backend uses `volta_amdgpu_analysis`; these crate names
do not select interchangeable implementations.

Native target differences belong in target profiles and explicit opcode/event
contracts. gfx942/gfx950 use wave64 MFMA rules; gfx1250 uses wave32 WMMA and
different counters and barrier objects. See the
[CDNA graph contract](gfx942-graph-contract.md) and
[gfx1250 model](../tests/gfx1250/CONTRACT.md). Never infer support by changing a
target string or accepting an opcode name without its operand profile.

## Extending an instruction

Follow the existing modules for the relevant backend:

1. Define its legal source grammar and typed operands. Validate every instruction
   in the selected entry, including unreachable and empty-EXEC code.
2. Lower it into the backend's typed instruction representation. Keep target,
   widths, modifiers and address spaces explicit.
3. Implement value semantics in the interpreter. Preserve byte definedness,
   source/destination widths and the existing arithmetic model.
4. Record its complete graph effects: register reads/writes, memory footprints,
   issue/completion attribution and any source lifetime.
5. Extend the independent graph checks when the new event changes readiness,
   publication, synchronization progress or resource lifetime.
6. Add an actual source fixture and a supported positive control, then malformed
   syntax and meaningful semantic negatives. Assert a typed witness for harmful
   executions; an aborted or unknown run is a separate result.

Use pinned public references and genuine compiler/assembler output for native
forms. Keep source, assembly, compiler commands and hashes together. Generate
run artifacts outside the source tree. The static profile inventories describe
what parses and lowers; they are not substitutes for execution or numerical tests.

## Tests and maintenance

PTX end-to-end fixtures live under `crates/volta_pipeline/tests/ptx`, with
integration suites in the parent directory. Native fixtures and launch/spec
contracts live under `tests/gfx942`, `tests/gfx950` and `tests/gfx1250`, with
additional frontend fixtures beside `volta_amdgpu_analysis`. Backend unit tests
exercise grammar, lowering and interpreter internals. Pipeline tests compose
execution with typed graph findings and mathematical output checks.

Keep Rust tests near the layer whose contract they exercise. Equivalence-only
tests use expressions/specifications; graph-only tests construct typed graphs;
end-to-end tests verify actual assembly. Include full array/index coverage and
supported controls when testing errors. Do not turn unsupported or incomplete
execution into an expected successful result.

Use `cargo test --release --workspace`, `just test-python`,
`cargo fmt --all -- --check` and `cargo clippy --workspace --all-targets` for
general changes. Fixture-specific tools have their own README commands. Large
workload proofs and hardware numerical checks run separately with explicit
budgets. The [usage guide](usage.md) explains how to inspect logs and exported
graphs when diagnosing a failure.

Update the owning crate README when its behavior or public interface changes.
Document lasting contracts, assumptions and failure modes rather than completed
tasks or transient run summaries. Keep detailed function/type documentation in
Rustdoc and link to it or the source instead of maintaining duplicate listings.
