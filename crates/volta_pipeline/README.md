# volta_pipeline

Composes kernel analysis, graph checking and mathematical equivalence checking.
The CLI and Python bindings use this crate to select a backend and combine its
results. Analysis produces artifacts; graph and equivalence checks consume
those artifacts independently.

```text
source + launch configuration
   └─ selected PTX or AMD analyzer
        ├─ event graph ──────────────► target-selected graph checks
        └─ symbolic outputs ────────► equivalence against a kernel or spec
                                         │
                         graph evidence + equivalence
                                         └─ decide: ACCEPT / REJECT / UNKNOWN
```

The analysis crates depend on neither checker. The equivalence and graph
branches never call each other. `tests/architecture_tests.rs` checks these
dependency boundaries.

## Public interfaces

| Interface | Responsibility |
| --- | --- |
| `Backend::select` | Resolve `ptx` or `amdgpu` and an optional native target. AMD defaults to gfx950; gfx942 and gfx1250 require explicit selection. |
| `KernelModule` | Hold the parsed PTX or AMD module. Native source and selected target must agree. |
| `verify_source_kernel` | Analyze a selected entry and run the applicable graph checks, returning common outputs, statistics, provenance and a `GraphReport`. |
| `verify_kernel` | PTX-specific analysis and graph-check entry point. |
| `check_equivalence` | Compare symbolic outputs. A symbolic difference needs independent numeric confirmation to count as a refutation. |
| `decide` | Combine equivalence with each kernel's graph evidence and modeling assumptions. |

`ACCEPT` requires a complete, unsampled equivalence proof and a `Verified`
graph conclusion for every kernel. A confirmed difference, failed graph check
or deadlock gives `REJECT`. Sampling, unresolved obligations and incomplete
execution give `UNKNOWN` unless another result establishes rejection.

`SourceKernelVerification` also exposes privately constructed certified-prefix
findings: opt-in scalar readiness and supported tensor LDS bounds. The pipeline
validates each property against the exact aborted prefix before constructing its
wrapper. These findings establish rejection only; the ordinary `GraphReport`
stays incomplete, and no output or equivalence proof is supplied. See
[early readiness](../../docs/early-readiness.md) and
[tensor bounds](../../docs/tensor-bounds.md).

Graph properties depend on the target. Consumers must use
`GraphReport::applicable_properties()` or `summaries()` rather than treating
the PTX property list as applicable to native AMD graphs. Expression and VC
replay have no event graph and can establish equivalence only.

## Integration tests

`tests/common/` supplies parsing, launch configuration, execution, graph checks
and output rendering for PTX suites. Successful runs require `Verified` and
compare every rendered output against the adjacent `.out` file. Race and
deadlock controls assert typed witnesses. `false_positive_tests.rs` contains
regressions for aligned-barrier loop visits, including valid uniform and
unaligned controls.

Native integration suites exercise the same public dispatch with genuine
assembly, exact output footprints, mathematical references, and CPU-only
missing-wait, publication, register-lifetime and barrier controls. The target
corpora describe the supported forms and reproduction commands:

- [gfx942](../../tests/gfx942/README.md)
- [gfx950](../../tests/gfx950/README.md)
- [gfx1250](../../tests/gfx1250/README.md)

```sh
cargo test -p volta_pipeline
```

Set `VOLTA_BLESS=1` only when intentionally updating PTX `.out` expectations.
Set `VOLTA_VIZ_DIR` to an absolute directory to record runs for
[`volta_viz`](../volta_viz/README.md). The `logging` feature adds stage logs.

The `record_viewer_runs` example records source/launch pairs. The
`measure_native_export` example analyzes a native source/launch pair, requires
a completed graph-verified run, and measures viewer export sizes. These
examples do not run code on a GPU or compare a mathematical specification.
