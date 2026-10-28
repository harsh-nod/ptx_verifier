<p align="center">
  <img src="volta-logo.png" alt="Volta Blackwell logo" width="400">
</p>

Volta Blackwell checks NVIDIA PTX and native AMD gfx942/gfx950 assembly for data races and deadlocks, and checks a kernel for equivalence to a reference kernel or a math spec (floats are modeled as reals). This is an experimental fork of [Volta](https://github.com/willtunnels/volta).

> [!CAUTION]
> **This project is not intended to be a sound verifier, and we do not claim that it is a formal verifier. It is a best-effort verifier for catching bugs in generated kernels; a successful check does not guarantee correctness.**
>
> **We are aware of similar efforts, that claims to be a formal verifier but suffers from soundness issues in its handling of the Blackwell ISA. We recommend treating the output with care and using independent testing and validation as it seems there are no trusted blackwell verifiers yet. The latest up to date formal verifier is [Volta](https://github.com/willtunnels/volta).**

Kernels must have statically known sizes, and their addresses and branches must resolve from thread indices and concrete parameters, not from input values. The analyzers execute workgroup zero. An AMD result covers that workgroup under its recorded assumptions; it does not prove the whole grid.

## Build

```bash
cargo build --release   # the binary is target/release/volta
just test               # Rust and Python tests
```

`cargo run --release -p volta_cli -- <command> ...` builds and runs in one step.

## Native AMD gfx942 and gfx950

Select `--backend amdgpu --target gfx942` (MI300/CDNA3) or `--target gfx950`
(MI350/CDNA4) to analyze native LLVM AMDHSA `.s`
files. PTX remains the default. CPU analysis requires no ROCm installation;
hardware validation requires the corresponding GPU. Explicit target selection
must match the assembly; omitted AMD targets retain gfx950 as the default.
For example, the checked-in compiler copy kernel crosses a wave boundary:

```bash
gfx950_source=crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s
volta analyze "$gfx950_source" --backend amdgpu --target gfx950 -k copy -b 65 \
  --array x:0x10000:4:65:in --array out:0x20000:4:65:out \
  --param ptr:x --param ptr:out --param int:65 \
  --emit-exprs copy.vexpr --dump-graph copy.graph
volta verify "$gfx950_source" \
  'dim N; array x[N]; array out[N]; out[i] = x[i];' \
  --backend amdgpu --target gfx950 -k copy -b 65 --dim N=65 \
  --array x:0x10000:4:65:in --array out:0x20000:4:65:out \
  --param ptr:x --param ptr:out --param int:65
```

The same backend selection supports `parse`, two-kernel `compare`, expression
and VC exchange, numeric confirmation, profiling, logs, and the existing graph
viewer. Python selects it with
`volta.Config(block=(65, 1, 1), backend="amdgpu", target="gfx950")`.
Use `target="gfx942"` for gfx942 source. For a genuine MI300X compiler fixture:

```bash
volta verify tests/gfx942/fixtures/native-copy-add.s tests/gfx942/specs/copy.spec \
  --backend amdgpu --target gfx942 -k copy -b 65 --dim N=65 \
  --array x:0x10000:4:65:in --array out:0x30000:4:65:out \
  --param ptr:x --param ptr:out --param int:65
```

gfx942 support includes native copy/add, LDS exchange/reduction, packed local
IDs, selected F32/F16/BF16 MFMA forms, and a two-wave LDS/F16 matrix pipeline.
It uses its own LDS capacity and MFMA hazard timings. CDNA4-only instructions
and gfx942 FP8/BF8 number formats remain unsupported. See the
[gfx942 scope, compiler fixtures and MI300X validation](tests/gfx942/README.md).
The existing gfx950 parity inventory does not assert complete gfx942 parity.

Launch arguments follow the selected kernel's descriptor and argument metadata.
`--global NAME=value` overrides a writable defined module object;
`--dyn-shared N` supplies dynamic LDS capacity.

Native assembly usually omits source-level LDS object boundaries. Optional
`--shared-allocation NAME:OFFSET:SIZE` entries, or Python
`cfg.add_shared_allocation(name, offset, size)`, supply those boundaries as an
explicit caller premise. Without them, LDS bounds refer to the complete static
plus dynamic segment. The analyzer records supplied layouts in graph provenance.

See the [AMD support table](crates/volta_amdgpu_analysis/README.md) for supported
instruction forms, ABI/toolchain envelope and arithmetic assumptions, and the
[parity inventory and evidence](tests/gfx950/README.md) for remaining work.
`python3 scripts/gfx950_parity.py summary --require-complete` is the strict
completion gate; it fails while any baseline row is pending. Unsupported,
sampled, aborted and resource-limited analyses remain inconclusive.

### HipKittens kernels

`just extract-hipkittens` compiles pinned upstream HipKittens CDNA4 sources to
gfx950 assembly; `just hipkittens` checks them through the same external-kernel
harness used for ThunderKittens. The workflow reports unsupported application
instructions explicitly and includes a validated local vector-copy control.
See [the HipKittens workflow](external/hipkittens/README.md) for setup, current
results, exact ABI payloads, hardware checks and strict exit-status handling.

## CLI

### Check a kernel for races and deadlocks

```bash
volta analyze relu.ptx -k relu -b 128 \
  --array x:0x10000:4:128:in --array out:0x20000:4:128:out \
  --param ptr:x --param ptr:out
```

Prints the symbolic outputs (`--print-outputs N`, default 8 per array), the verdict of each graph check, and `GRAPH VERIFICATION: VERIFIED | REJECTED | UNKNOWN` (exit 0/1/2). `--emit-exprs FILE` writes the outputs as `.vexpr` text, `--dump-graph FILE` the event graph.

### Check a kernel against a spec

```
# relu.spec
dim N;
array x[N];
array out[N];
out[i] = max(x[i], 0);
```

```bash
volta verify relu.ptx relu.spec -k relu -b 128 --dim N=128 \
  --array x:0x10000:4:128:in --array out:0x20000:4:128:out \
  --param ptr:x --param ptr:out
```

The spec can also be passed inline as a string. Each spec output must be declared `out` or `inout`, and each `dim` needs a `--dim NAME=VALUE`.

### Compare two kernels

```bash
volta compare ref.ptx opt.ptx --kernel1 ref --kernel2 opt -b 128 \
  --array x:0x10000:4:128:in --array out:0x20000:4:128:out \
  --param ptr:x --param ptr:out --check-array out
```

`--check-array NAME` (required, repeatable) names the outputs to compare. Arrays, params and globals are shared by both kernels; `--block2`/`--grid2` override the optimized kernel's dims.

`verify` and `compare` print `VERDICT: ACCEPT | REJECT | UNKNOWN` (exit 0/1/2) and take:

- `--sample N`: check at most N elements per array (a sampled check is never ACCEPT)
- `--verify-numeric`: confirm each verdict with an f64 oracle at random inputs
- `--recycle-terms N`: bound memory by recycling intern tables past N terms
- `--iterations N`: re-run the solve N times (timing and determinism check)

`compare` can skip symbolic execution: `--exprs a.vexpr b.vexpr` (from `analyze --emit-exprs`), or `--dump-vcs pair.vcdump` once and then `--from-dump pair.vcdump`.

### Launch flags

`analyze`, `verify` and `compare` share these flags. They must match the kernel's parameters.

- `-b, --block X[,Y[,Z]]` / `-g, --grid X[,Y[,Z]]`: launch dims (default `1`)
- `--array name:base:elem_width:len:kind`: a global array of `len` elements of `elem_width` bytes at address `base`; `kind` is `in`, `out`, `inout` or `index` (concrete `a[i] = i`). Repeatable.
- `--param int:N | float:X | sym:name | ptr:array`: the kernel's parameters, in declaration order. Repeatable.
- `--global NAME=value`: value of a module-scope `.global` variable. Repeatable.
- `--dyn-shared N`: dynamic shared memory, in bytes
- `--no-profile`: skip the per-instruction-kind profile

### Launch files

`--config FILE` replaces every launch flag above with one JSON file. The ReLU launch of the first example reads:

```json
{
  "description": "relu over 128 fp32 elements",
  "kernel": "relu",
  "block": 128,
  "arrays": [
    {"name": "x",   "kind": "in",  "dtype": "f32", "shape": [128]},
    {"name": "out", "kind": "out", "dtype": "f32", "shape": [128]}
  ],
  "params": [
    {"ptr": "x"},
    {"ptr": "out"}
  ]
}
```

```bash
volta analyze relu.ptx --config relu.json
```

- `block` (required) and `grid`: a number or one to three numbers
- `arrays`: `kind` is `in`, `out`, `inout` or `index`; the element size is a `dtype` (`f32`, `bf16`, `u8`, `e4m3`, ...) or an `elem_width` in bytes, the length a `shape` or a `len`. Arrays without a `base` (a number or `"0x..."`) are laid out in order from `0x10000`, each on a 64 KiB boundary.
- `params`: exactly one of `{"int": N}`, `{"float": X}`, `{"sym": name}` or `{"ptr": array}` each, in declaration order. An optional `"name"` labels it for the reader and is not checked against the PTX.
- `globals` (`{"NAME": value}`), `dynamic_shared_bytes`, `max_instructions`, and a free-text `description`
- `kernel`: the default for `--kernel` (`analyze`, `verify`); `compare` names its two kernels with `--kernel1`/`--kernel2` instead

Unknown keys are errors, so a typo never falls back to a default. `--config` cannot be combined with the launch flags.

### Syntax checks and logging

`volta parse file.ptx` checks PTX syntax.

Every run writes a log under `volta-logs/` (`--log-dir DIR`, `--no-log-file`). Build with `--features logging` and pass `--log-level info` for a trace of the run.

## Python

Add the bindings to your project's `pyproject.toml`, then run `uv sync`:

```toml
[project]
dependencies = ["volta"]

[tool.uv.sources]
volta = { path = "<path/to/volta>/crates/volta_py", editable = true }
```

```python
import volta

src = open("relu.ptx").read()

config = volta.Config(block=(128, 1, 1), grid=(1, 1, 1), dynamic_shared_bytes=0)
config.add_array(volta.ArrayDef("x", base=0x10000, elem_width=4, len=128, kind=volta.ArrayKind.Input))
config.add_array(volta.ArrayDef("out", base=0x20000, elem_width=4, len=128, kind=volta.ArrayKind.Output))
config.add_param(volta.Param.array_ptr("x"))  # also Param.int, Param.float, Param.sym_float
config.add_param(volta.Param.array_ptr("out"))
# config.set_global("NAME", 42)

volta.parse(src)  # raises VoltaError on a syntax error

result = volta.analyze(src, config, kernel="relu")
result.outputs        # [("out", [(0, "max(x[0], 0)"), ...])]
result.race_verified  # True when every graph check passed
result.stats, result.op_counts

spec = "dim N; array x[N]; array out[N]; out[i] = max(x[i], 0);"
check = volta.verify(src, spec, config, kernel="relu", dims={"N": 128}, sample=0, verify_numeric=False)
check.equivalent, check.mismatches, check.elements_checked
```

`ArrayKind` is `Input`, `Output`, `InputOutput` or `IndexInput`. A race raises `volta.DataRaceError`, a deadlock `volta.DeadlockError`, and any other failure `volta.VoltaError` (the base class of both). An inconclusive graph check emits a `RuntimeWarning` and sets `race_verified` to `False`. `compare` is CLI-only for now.

## Event-graph visualization

`just viz` records the event graph of every test kernel and builds a single HTML
page at `target/volta-viz/volta-graphs.html`. Open it in a browser to inspect the
events, graph checks, and PTX source.

```bash
just viz
```

To build a viewer from an existing run store:

```bash
volta viz <run-store> -o page.html
```

<p align="center">
  <img src="volta-viz.png" alt="The Volta Blackwell event-graph viewer showing warp 1's reads racing a bulk async copy">
  <br>
  <sub>Warp 1's reads race a <code>cp.async.bulk</code> copy that a <code>bar.sync</code> does not order.</sub>
</p>

## Citation

```bibtex
@misc{costa2026aicompilercompilingtriton,
      title={AI as a Compiler: Compiling Triton kernels without the Triton compiler},
      author={François Costa and Charly Castes and Thomas Bourgeat and Azalia Mirhoseini},
      year={2026},
      eprint={2609.36800},
      archivePrefix={arXiv},
      primaryClass={cs.AI},
      url={https://arxiv.org/abs/2609.36800},
}
```

```bibtex
@article{volta,
  author    = {Driscoll, Benjamin and Dubey, Kshitij and Wei, Anjiang and Kayal, Neeraj and Sharma, Rahul and Aiken, Alex},
  title     = {Equivalence Checking of {ML} {GPU} Kernels},
  journal   = {Proc. ACM Program. Lang.},
  volume    = {10},
  number    = {OOPSLA2},
  articleno = {338},
  numpages  = {28},
  year      = {2026},
  doi       = {10.1145/3839470}
}
```

## License

MIT — see [LICENSE](LICENSE).
