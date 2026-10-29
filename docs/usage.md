# Using GPU Kernel Verifier

Run these examples from the repository root. `volta` means the locally built
`target/release/volta` executable, or the same executable installed on your PATH.
Use `volta COMMAND --help` for the complete option list.

## Describe the launch

The analyzer needs the kernel's geometry, memory allocations and arguments.
Array sizes are logical bounds, not actual GPU allocations. Symbolic input
values remain unknown; addresses and control flow must be concrete.

Create `copy.json` for the native fixture used below:

```json
{
  "block": 65,
  "grid": [1, 1, 1],
  "arrays": [
    {"name": "x", "base": "0x10000", "dtype": "f32", "shape": [65], "kind": "in"},
    {"name": "out", "base": "0x30000", "dtype": "f32", "shape": [65], "kind": "out"}
  ],
  "params": [{"ptr": "x"}, {"ptr": "out"}, {"int": 65}]
}
```

`block` is required. Geometry accepts a number or one to three dimensions;
omitted dimensions are one. Array kinds are `in`, `out`, `inout` and `index`.
`index` supplies concrete element values equal to their indices. Use `inout`
when the computation depends on the initial output, such as atomic accumulation.
An array can use `elem_width`/`len` instead of `dtype`/`shape`. Omitted bases
are placed consecutively at 64 KiB boundaries, starting at `0x10000`.
`dtype` is a size shorthand, not a typed-array assertion; instructions and their
consumers determine how raw words are interpreted.

Arguments are positional: each entry has exactly one of `ptr`, `int`, `float`
or `sym`. Native AMD by-value arguments also accept `bytes`, whose length and
padding must match the kernel's ABI metadata exactly. An optional argument
`name` is descriptive and does not change its position.

Other launch fields are `description`, `dynamic_shared_bytes`, `globals`,
`max_instructions` and native `shared_allocations`. The latter declares disjoint
LDS byte ranges, for example `[{"name":"tile","offset":0,"size":256}]`.
These ranges are caller-supplied subobject premises; PTX rejects them. Unknown
JSON fields, invalid geometry and overlapping allocation ranges are errors.
An optional `kernel` sets the default entry for `analyze` and `verify`. Omit that
field for `compare`, which selects entries with `--kernel1` and `--kernel2`.

`--config FILE` replaces launch flags and cannot be combined with `--block`,
`--grid`, `--array`, `--param`, `--global`, `--dyn-shared` or
`--shared-allocation`. Backend and target selection remain separate options.
See [launch_file.rs](../crates/volta_ptx_analysis/src/launch_file.rs) for the
shared JSON schema and validation rules.

## Parse and analyze

```sh
volta parse tests/gfx1250/fixtures/native-copy-add.s \
  --backend amdgpu --target gfx1250
volta analyze tests/gfx1250/fixtures/native-copy-add.s --config copy.json \
  --backend amdgpu --target gfx1250 --kernel copy --print-outputs 2
```

Parsing checks the supported source grammar. Analysis symbolically executes the
selected entry and applies the target's graph checks. The output includes array
element counts, instruction profiles, individual graph results and a final
`GRAPH VERIFICATION` status. It does not compare the computation with a reference.
`--print-outputs 0` suppresses expression rendering while retaining complete
execution and graph checks; `--no-profile` suppresses the instruction profile.

For PTX, omit `--backend` and `--target`, and provide its own source and matching
launch. Native AMD defaults to gfx950 if its target is omitted; selecting the
target explicitly makes a source mismatch an error.

## Verify a mathematical specification

```sh
volta verify tests/gfx1250/fixtures/native-copy-add.s \
  tests/gfx1250/specs/copy.spec --config copy.json --dim N=65 \
  --backend amdgpu --target gfx1250 --kernel copy --sample 0
```

The specification can be a file or inline text:

```text
dim N;
array x[N];
array out[N];
out[i] = x[i];
```

Bind every declared dimension with `--dim NAME=VALUE`. Every computed output
array must have the correct launch kind and complete index set. Equal element
counts alone do not establish equal footprints. The
[specification guide](../crates/volta_spec/README.md) describes reductions,
layouts and the expression language.

`--sample 0` checks all elements and is the default. A sample that omits elements
cannot produce full acceptance. `--verify-numeric` adds random f64 oracle
confirmation; it does not turn mathematical-real equivalence into a physical floating-point
proof. `--iterations N` repeats the solver with fresh sessions, and
`--recycle-terms N` controls term-table recycling (`0` disables recycling).

## Compare kernels and replay expressions

This identity comparison uses the same native copy source on both sides:

```sh
volta compare tests/gfx1250/fixtures/native-copy-add.s \
  tests/gfx1250/fixtures/native-copy-add.s --config copy.json \
  --kernel1 copy --kernel2 copy --check-array out \
  --backend amdgpu --target gfx1250 --dump-vcs copy.vcdump
volta compare --from-dump copy.vcdump --check-array out
```

Replace the second source/entry with the kernel under comparison. Repeat
`--check-array` for every output you want compared. Arrays, arguments and globals
are shared; `--block2` and `--grid2` can describe a different second launch.
These overrides must preserve the intended logical computation.

```sh
volta analyze tests/gfx1250/fixtures/native-copy-add.s --config copy.json \
  --backend amdgpu --target gfx1250 --kernel copy \
  --emit-exprs copy.vexpr --dump-graph copy.graph
volta compare --exprs copy.vexpr copy.vexpr --check-array out
```

`.vexpr` files contain symbolic outputs; `.vcdump` files contain the expressions
and output contracts for a comparison. Replay skips kernel execution and reports
equivalence only. A `.graph` dump is diagnostic text, not an executable replay
format. Use a recorded run store with `volta viz STORE -o page.html` to browse
events, target geometry, source links and typed findings.

## Read results and logs

| Operation | Success / failure / inconclusive | Exit codes |
| --- | --- | --- |
| `analyze` | `VERIFIED` / `REJECTED` / `UNKNOWN` | 0 / 1 / 2 |
| `verify`, source `compare` | `ACCEPT` / `REJECT` / `UNKNOWN` | 0 / 1 / 2 |
| Expression/VC replay | Equivalence result without a graph verdict | 0 / 1 / 2 |

A completed trace with passing graph checks is distinct from a proof of output
equivalence. Unsupported instructions, uninitialized values, budgets and missing
synchronization evidence must be understood from their diagnostics; they are
not successful results. Reports list the modeling assumptions used by the result.

The CLI writes per-invocation logs to `volta-logs/`. Use `--log-dir DIR` to move
them or `--no-log-file` to disable them. Stage logging is available with:

```sh
cargo build --release -p volta_cli --features logging
target/release/volta --log-level info --help
```

## Python

Install the local bindings into a virtual environment:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install ./crates/volta_py
```

Run from the repository root after activating that environment:

```python
from pathlib import Path
import volta

source = Path("tests/gfx1250/fixtures/native-copy-add.s").read_text()
spec = Path("tests/gfx1250/specs/copy.spec").read_text()
config = volta.Config(block=(65, 1, 1), backend="amdgpu", target="gfx1250")
config.add_array(volta.ArrayDef("x", 0x10000, 4, 65, volta.ArrayKind.Input))
config.add_array(volta.ArrayDef("out", 0x30000, 4, 65, volta.ArrayKind.Output))
config.add_param(volta.Param.array_ptr("x"))
config.add_param(volta.Param.array_ptr("out"))
config.add_param(volta.Param.int(65))

volta.parse(source, backend="amdgpu", target="gfx1250")
result = volta.analyze(source, config, kernel="copy")
assert result.race_verified and not result.unresolved
check = volta.verify(source, spec, config, kernel="copy", dims={"N": 65}, sample=0)
assert check.race_verified and check.equivalent
assert check.elements_checked == check.elements_total == 65
```

Python exposes `parse`, `analyze` and `verify`; kernel comparison and artifact
replay use the CLI. Configuration has typed argument constructors, globals and
native shared-allocation premises. `DataRaceError` and `DeadlockError` derive
from `VoltaError`. Inconclusive graph checks emit a warning and leave
`race_verified` false. Output strings are formatted on access and can be much
larger than their underlying expression DAG. See the
[bindings guide](../crates/volta_py/README.md) for result fields and tests.
