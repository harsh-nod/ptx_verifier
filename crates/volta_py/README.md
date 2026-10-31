# volta_py

PyO3 bindings for kernel parsing, analysis and verification, built with maturin
and imported as `volta`. The bindings use `volta_pipeline` for PTX and native
AMD dispatch. Kernel-to-kernel comparison and artifact replay are available
through the [CLI](../volta_cli/README.md). The [usage guide](../../docs/usage.md#python)
includes installation and a complete native example.

For a PTX `source` string defining a `copy` kernel with two pointer arguments:

```python
import volta

config = volta.Config(block=(4, 1, 1))
config.add_array(volta.ArrayDef("x", 0x10000, 4, 4, volta.ArrayKind.Input))
config.add_array(volta.ArrayDef("out", 0x20000, 4, 4, volta.ArrayKind.Output))
config.add_param(volta.Param.array_ptr("x"))
config.add_param(volta.Param.array_ptr("out"))

volta.parse(source)
result = volta.analyze(source, config, kernel="copy")
assert result.race_verified

verification = volta.verify(
    source, "dim N; array x[N]; array out[N]; out[i] = x[i];",
    config, kernel="copy", dims={"N": 4}, sample=0, verify_numeric=True,
)
assert verification.equivalent and verification.race_verified
```

`parse` checks source syntax for the selected backend. `analyze` executes one
configured workgroup and runs its graph checks. `verify` additionally unfolds
a mathematical specification and compares its outputs with the kernel's.

Invalid configuration arguments raise `ValueError`. Parse and execution
failures raise `VoltaError`; graph findings raise `DataRaceError` or
`DeadlockError`. Inconclusive graph checks emit a
`RuntimeWarning` and set `race_verified=False`. Inspect `AnalyzeResult.unresolved`
for the reasons. Mathematical equivalence and graph verification are separate
result fields: both are needed to establish the combined property. Use
`sample=0` for a complete equivalence check; a positive sample bounds the
checked output prefix. `equivalent=True` describes the checked elements; require
`elements_checked == elements_total` as well for a complete comparison. Full
output index sets are validated before sampling, so missing or extra writes
remain errors even when the sampled values match.

A certified gfx1250 tensor LDS overrun raises
[`TensorBoundsError`](../../docs/tensor-bounds.md), a `VoltaError` subclass,
before returning an analysis or verification result. Its diagnostic fields
identify the attempted interval and configured extent. No transfer or output
proof is implied by this rejected prefix.

`Param` provides `int`, `float`, `sym_float`, `array_ptr` and native `bytes`
constructors. Python does not currently expose PTX `StructField` or host
tensor-map constructors. Those aggregate forms are available through Rust
configuration or CLI launch JSON; see the
[parameter guide](../../docs/launch-parameters.md).

`AnalyzeResult.outputs` returns ordinary Python lists of
`(array_name, [(index, expression_string), ...])`. Expressions are formatted
when the property is read; the result retains a compact DAG internally.
Expanded expressions can be much larger than that DAG, so reading all output
strings for large workloads can require substantial memory. Verification uses
the DAG directly. Results also expose execution statistics and instruction
counts.

## Native AMD configuration

Pass `backend="amdgpu"` and an explicit `target` to both `parse` and `Config`:

```python
volta.parse(amd_source, backend="amdgpu", target="gfx1250")
config = volta.Config(block=(64, 1, 1), backend="amdgpu", target="gfx1250")
# Add arrays and parameters matching the selected kernel's ABI.
```

`Config(..., grid=(2,3,4), workgroup_id=(1,2,3))` selects one native group.
All three coordinates must lie inside the grid; the default is `(0,0,0)`.
Results expose `workgroup_id` and `assumptions`. Graph verification covers only
that group, with no claim about other groups or their conflicts. Output indices
remain absolute, and partial tiles still fail whole-array specification checks
even with sampling. PTX currently rejects nonzero selection.

Supported target profiles are gfx942 and gfx950 with wave64, and gfx1250 with
wave32. Omitting an AMD target selects gfx950; source and selection must match.
`Param.bytes(...)` supplies metadata-sized native by-value arguments, including
padding. `Config.add_shared_allocation(name, offset, size)` supplies optional
LDS object bounds in bytes; PTX rejects this native-only premise. See
[`volta_common`](../volta_common/README.md) for shared launch concepts and
[`volta_amdgpu_analysis`](../volta_amdgpu_analysis/README.md) for target limits.

`Config(..., early_memory_conflicts=True)` opts into the first certified
same-instruction memory conflict on gfx950/gfx1250. `analyze` and `verify` raise
`EarlyMemoryConflictError(DataRaceError)` with the exact pair, overlapping byte
and prefix metadata, without returning outputs. It defaults to false and never
enables early acceptance. See the [scope and trust contract](../../docs/early-memory-conflicts.md).

## Modules and tests

- `config.rs`: Python launch, array and parameter classes.
- `analyze.rs`: parsing, analysis, graph outcomes and lazy output formatting.
- `verify.rs`: specification instantiation and equivalence results.
- `error.rs`: Python exceptions and source diagnostics.

From the repository root:

```sh
just test-python
```

This rebuilds the extension and runs the Python tests. `just test` runs the
Rust and Python suites together. Tests cover PTX, native targets, ABI handling,
typed failures and the workload harness. Original-shape workload checks are in
`tests/test_gfx1250_original_workloads.py`; set
`VOLTA_GFX1250_ORIGINAL_FULL=1` for the heavy full-workload path described in
the [workload guide](../../tests/gfx1250/full-parity/README.md).
