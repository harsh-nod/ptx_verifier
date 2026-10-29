# volta_py

Python bindings (PyO3, built with maturin) for the Volta engine, published as
the `volta` Python module. This is v0: `parse`, `analyze` and `verify`.
`compare` is not exposed yet; see `volta_cli` for the full command set.

```python
import volta

config = volta.Config(block=(4, 1, 1))  # mirrors volta_ptx_analysis::AnalysisConfig
config.add_array(volta.ArrayDef("in", 0x10000, 4, 4, volta.ArrayKind.Input))
config.add_array(volta.ArrayDef("out", 0x20000, 4, 4, volta.ArrayKind.Output))
config.add_param(volta.Param.array_ptr("in"))
config.add_param(volta.Param.array_ptr("out"))
volta.parse(ptx_source)                  # raises VoltaError on a syntax error
result = volta.analyze(ptx_source, config, kernel=None)  # DataRaceError / DeadlockError on findings
v = volta.verify(ptx_source, "dim N; array in[N]; array out[N]; out[i] = in[i];",
                 config, dims={"N": 4}, sample=0, verify_numeric=False)
assert v.equivalent and v.mismatches == []
```

`result.outputs` is a fresh ordinary Python list of array-name/element-list
tuples, with `(index, expression_string)` elements. Strings are formatted when
this property is read; `analyze` retains the compact expression DAG internally.
The text and existing 50 MiB per-expression display limit are unchanged. A
complete large attention result can still require substantial Python memory
when its expressions fit that limit. Graph checks and `verify` operate on the
complete DAG independently of display formatting.

## Modules

- `config.rs`: Python classes that wrap the Rust config types one to one
  (`Config`, `ArrayDef`, `ArrayKind`, `Param`), instead of the CLI's string
  mini-language (`"x:0x10000:4:128:in"`).
- `analyze.rs`: `parse` and `analyze`. They run the analysis and the graph
  checks, and return `AnalyzeResult` (outputs, `Stats`).
- `verify.rs`: `verify`. It instantiates a spec with caller-supplied `dims`,
  unfolds it into `SymbolicOutputs` standing in for a second kernel, and runs
  the equivalence check. It returns `VerifyResult` (`equivalent`, `mismatches`,
  `elements_checked`/`elements_total`, `stats`). `sample=` limits the checked
  elements.
- `error.rs`: maps Rust errors to Python exceptions: `VoltaError`, and its
  `DataRaceError` and `DeadlockError` for graph-check failures. Parse errors
  render their own "line N, col M" snippet, since in-memory source has no
  `FileCache`.

## Build and test

```sh
just test-python    # uv run --reinstall-package volta pytest crates/volta_py
```

Tests are in `tests/`, including PTX, native gfx942/gfx950/gfx1250, by-value
ABI and workload-harness cases. `just test` also runs Rust and stops at the
[documented inherited PTX regression](../../tests/gfx1250/README.md#software-acceptance-and-reproduction)
before its Python step; the command above rebuilds and runs Python independently.

## Native AMD targets

Pass `backend="amdgpu", target="gfx1250"` to `Config` and `parse` for the
selected wave32 profile; use `gfx942`/`gfx950` for those source targets.
Omitting the AMD target preserves gfx950. `analyze` runs native graph checks;
`verify` also checks the complete configured specification. Missing waits raise
`DataRaceError`; incomplete or resource-limited traces stay inconclusive.
By-value arguments use `Param.bytes(...)`, including descriptor padding checks.
See [gfx1250 scope and CPU validation](../../tests/gfx1250/README.md).
Optional exact-assembly numerical checks are described in
[the hardware guide](../../tests/gfx1250/hardware/README.md). Device-run records
are not retained. For native source, pass selection
explicitly to the independent syntax check as well:

```python
volta.parse(amd_source, backend="amdgpu", target="gfx1250")
config = volta.Config(block=(65, 1, 1), backend="amdgpu", target="gfx1250")
# Add the source kernel's arrays and arguments before analyze/verify.
```

`tests/test_gfx1250_original_workloads.py` checks all18 first-family original
shapes/storage dtypes through parse/analyze/verify, exact output coordinates and
unsampled numeric specifications. The separate heavy32-case workflow gate uses
`VOLTA_GFX1250_ORIGINAL_FULL=1` and refuses missing registrations. These tests
rebuild the current extension; they do not reuse an older binary as evidence.
See the [full-parity workflow recipes](../../tests/gfx1250/full-parity/README.md#public-workflow-gates).
