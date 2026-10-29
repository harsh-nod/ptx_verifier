# volta_pipeline

The integration point. This is the only crate that composes the analysis stage
with its two branches and combines their results into a verdict.

```
analysis (selected PTX or AMD producer) ──► AnalysisResult { symbolic outputs, event graph, provenance }
   ├─ equivalence branch: symbolic outputs only  ──► EquivalenceVerdict    (equivalence.rs)
   └─ graph branch: event graph only, target-selected checks ──► GraphReport           (kernel.rs)
                                    aggregation (decide) ──► ACCEPT / REJECT / UNKNOWN   (aggregate.rs)
```

The analysis stage runs neither branch. The branches share only the stage's
artifacts and never call each other or the stage.
`tests/architecture_tests.rs` enforces this layering.

## API

- **`verify_source_kernel(&KernelModule, kernel, config) -> SourceKernelVerification`**
  (`backend.rs`): dispatches to PTX or native AMD analysis, normalizes the common
  outputs/graph/statistics, and runs the target-selected graph checks. Use
  `Backend::select` and `Backend::validate_amd_target` to keep selection consistent
  with native source. PTX uses ten applicable graph properties; supported AMD
  targets use four. Only `report.applicable_properties()` participate in acceptance.

- **`verify_kernel(module, kernel, config) -> KernelVerification`**
  (`kernel.rs`): the existing PTX-specific entry point runs the analysis and
  `volta_graph_check::check_graph` on its graph. Returns the analysis result with the graph report.
- **`check_equivalence(...) -> EquivalenceVerdict`** (`equivalence.rs`): runs
  `volta_equivalence` over the two sides' symbolic outputs. A claimed
  difference counts as a refutation only once the numeric oracle separates it
  (`confirm_differences`); otherwise it is `Unproven`.
- **`decide(&equivalence, &[KernelEvidence]) -> Decision`** (`aggregate.rs`):
  - **ACCEPT** requires a complete (unsampled) equivalence proof and every
    kernel's graph conclusion `Verified`;
  - **REJECT** on any refutation, failed graph check, or deadlock;
  - **UNKNOWN** otherwise (sampled check, unresolved obligations, aborted run,
    unproven difference).

  The `Decision` carries the verdict, its evidence, and the union of the
  modeling assumptions the analyses ran under.

## Tests

`gfx1250_named_barrier_tests` checks genuine compiler-allocated objects, complete
symbolic payloads, repeated initialization, subset drops and NULL joins. Its
assemble-valid CPU-only mutations distinguish count deadlocks, missing joins,
END without a named drop, and LDS completion from arrival/publication.
Its separate phases module checks two-object handshakes, independent counts,
the complete three-arrival arithmetic expression, and runtime-selected ID
deadlocks with a passing native control first.

Every PTX-driven test in the workspace lives here, end to end: each runs real
kernels from `tests/ptx/` through `verify_kernel` and asserts on the outcome.

- `aggregation_tests.rs`: real kernels through both branches and `decide`.
- `architecture_tests.rs`: the stage/branch dependency boundaries.
- `amd_frontend_compatibility_tests.rs`: the unchanged upstream gfx950 copy
  fixture through both syntax frontends, complete native output equivalence at
  wave boundaries, and typed missing-wait rejections. The upstream parser is a
  test-only dependency; production AMD dispatch remains native.
- the suites below, over `tests/common/`.

### How a test runs

`tests/common/` is shared by every PTX-driven suite:

- `parse` / `parse_named` returns a `Ptx`: module, source text, file name.
- `verify`, `analyze_only`, `check` and `run_kernel` run the pipeline with an
  `AnalysisConfig`.
- For kernels expected to complete, the graph conclusion must be `Verified`
  (not merely "not rejected"). The rendered symbolic outputs must then match
  the kernel's `.out` file byte for byte. `VOLTA_BLESS=1` rewrites the `.out`
  files.
- Race and deadlock tests assert on the failed check's **typed witness** (the
  byte, the two threads, the access modes, the async op), not on message text.
- With `VOLTA_VIZ_DIR` set, every run is recorded into that `volta_viz` store,
  keyed `<suite>/<test>[~<n>]` (`just viz`).

### Suites

| suite                              | what it checks |
|------------------------------------|----------------|
| `accepted_tests.rs`                | race-free kernels conclude `Verified` and match their `.out` |
| `mbarrier_epoch_tests.rs`          | Algorithm 1 over mbarrier phases |
| `mbarrier_ordering_tests.rs`       | Algorithm 2: unprotected `expect_tx` announcements |
| `memory_conflict_tests.rs`         | Algorithm 3: unordered conflicting accesses |
| `proxy_order_tests.rs`             | Algorithm 4: missing proxy / tensor-map fences |
| `tensor_order_tests.rs`            | Algorithm 5: unordered Tensor Memory accesses |
| `resource_lifetime_tests.rs`       | Algorithm 7: TMEM use after free, leaked allocation |
| `allocation_order_tests.rs`        | unordered `tcgen05.alloc` pairs |
| `allocation_permit_tests.rs`       | allocation after `relinquish_alloc_permit` |
| `mbarrier_release_order_tests.rs`  | waits observing phases out of order |
| `rejected_tests.rs`                | execution errors (`EvalError`, lowering errors) and deadlocks |
| `graph_tests.rs`                   | the recorded event graph itself, no checker |
| `negative_equivalence_tests.rs`    | kernel pairs differing in one detail must not be proved equivalent |
| `false_positive_tests.rs`          | kernels Volta wrongly verifies (`ptx/false_positive/`); each fails until fixed |
| `soundness_tests.rs`               | soundness regressions (`ptx/soundness/`) |

The unknown-directive regression requires a located `InvalidDirective` naming
the offending directive and verifies controls with that statement removed or
replaced by a known `.pragma`. The return regression rejects `ret 123;` and
`ret.uni 123;` specifically for expecting zero operands, while verifying their
operand-free forms.
The exit regressions verify plain `exit;` and require an unexpected-modifier
error for `exit.not_a_modifier;` and a zero-operand arity error for `exit 123;`.
The corresponding `brkpt` regressions check the same errors and verify plain `brkpt;`.
The `trap` regressions require those validation errors before execution and check
that plain `trap;` still produces `TrapReached` at runtime.
The `mbarrier` count regressions require an `init` count of 0 or `2^20` and an
`arrive` count of 0 to be rejected before any graph verdict, and the trailing
operand regression a lowering error for an `mbarrier.arrive` with four operands.

### Kernel layout (`tests/ptx/`)

`success/`, `failing/`, `execution_error/`, `negative_equivalence/`,
`false_positive/`, `soundness/`: each `.ptx` sits next to its expected `.out`
where one applies.

```sh
cargo test -p volta_pipeline                    # all suites
VOLTA_BLESS=1 cargo test -p volta_pipeline      # regenerate .out files
```

The `logging` feature narrates the stages (`[analysis]`, `[graph]`,
`[equivalence]`).

## Native target dispatch

`Backend::select("amdgpu", Some("gfx1250"))` selects wave32 analysis through the
same `KernelModule`, symbolic outputs, graph reports and aggregation used by
PTX/gfx942/gfx950. Source and selected target must agree. The AMD default stays
gfx950. Native fixtures under `tests/gfx1250` exercise complete graph acceptance,
independent matrix/arithmetic oracles, and typed safety rejections. Expression
and VC replay checks equivalence only: those formats carry no event graph and
cannot reestablish race freedom. The [hardware workflows](../../tests/gfx1250/hardware/README.md)
check exact positive assembly separately; local device-run records are not retained.

`gfx1250_original_matrix_tests` separately checks parsing/lowering of the exact
full K4096 six-kernel matrix corpus and its zero-scratch native descriptors.
That frontend gate does not claim execution, equivalence, or graph acceptance.

The CPU-only `measure_native_export` example accepts native source, launch JSON
and an output directory. It requires a completed, graph-verified run, prints
full event/output counts and export/page sizes, and records the viewer's display
selection. It does not compare a mathematical specification or execute on a GPU.
