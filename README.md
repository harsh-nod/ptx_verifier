<h1 align="center">GPU Kernel Verifier</h1>

<p align="center">
  <img src="gpu-kernel-verifier.png" alt="GPU Kernel Verifier: NVIDIA PTX and AMD assembly" width="560">
</p>

GPU Kernel Verifier analyzes GPU assembly for data races and deadlocks, and
compares a kernel's outputs with another kernel or a mathematical specification.
It supports NVIDIA PTX and selected native AMD instructions for gfx942, gfx950
and gfx1250. This experimental fork of [Volta](https://github.com/willtunnels/volta)
keeps the `volta` command and Python module names.

The engine symbolically executes a concrete launch configuration. It produces
output expressions and an event graph, then checks mathematical equivalence and
target-specific synchronization independently. Floating arithmetic uses a
mathematical-real model. Addresses, control flow and synchronization parameters
must resolve from concrete configuration and thread indices.

> This is a best-effort bug-finding tool, not a sound formal verifier. Results
> depend on supported instructions and the reported modeling assumptions. A
> successful result does not guarantee hardware correctness. Analysis covers
> one selected native workgroup (zero by default), not the whole grid or
> physical floating-point rounding. PTX currently analyzes only block zero.

## Build and run

Use a Rust toolchain that supports edition 2024 and a C build toolchain for the
rational-arithmetic dependency. CPU analysis does not require a GPU or ROCm.

```sh
cargo build --release -p volta_cli
target/release/volta --help
```

This example checks the checked-in native copy kernel and all 65 output elements:

```sh
target/release/volta verify \
  tests/gfx1250/fixtures/native-copy-add.s tests/gfx1250/specs/copy.spec \
  --backend amdgpu --target gfx1250 --kernel copy --block 65 --dim N=65 \
  --array x:0x10000:4:65:in --array out:0x30000:4:65:out \
  --param ptr:x --param ptr:out --param int:65
```

Replace `verify SOURCE SPEC` with `analyze SOURCE` and omit `--dim N=65` to
check synchronization without requesting mathematical equivalence. Use
`parse SOURCE` to check syntax. PTX is the default backend; native AMD source
requires `--backend amdgpu`, with an explicit matching `--target` recommended.

| Operation | What it checks |
| --- | --- |
| `parse` | Source syntax and target-specific frontend validation |
| `analyze` | One candidate execution and its graph properties |
| `verify` | Graph properties and complete outputs against a specification |
| `compare` | Graph properties and output equivalence between two kernels |
| `viz` | Interactive inspection of recorded event graphs |

`analyze` reports `VERIFIED`, `REJECTED` or `UNKNOWN`. `verify` and kernel-to-kernel
`compare` report `ACCEPT`, `REJECT` or `UNKNOWN`. Exit codes are 0, 1 and 2,
respectively. Sampling that omits outputs, incomplete execution and unsupported
semantics cannot produce full acceptance. Expression or VC replay checks
equivalence only; those artifacts do not contain a safety graph.

The [usage guide](docs/usage.md) explains launch files, specifications, kernel
comparison, artifacts, logging and Python setup.

## Supported targets and scope

| Backend / target | Execution model | Reference |
| --- | --- | --- |
| `ptx` | NVIDIA warp32; selected PTX instructions and synchronization objects | [PTX analyzer](crates/volta_ptx_analysis/README.md) |
| `amdgpu` / `gfx942` | Wave64; selected CDNA3 scalar/vector, memory and MFMA forms | [gfx942 fixtures and scope](tests/gfx942/README.md) |
| `amdgpu` / `gfx950` | Wave64; selected CDNA4 instructions and MFMA forms | [gfx950 fixtures and scope](tests/gfx950/README.md) |
| `amdgpu` / `gfx1250` | Wave32; selected WMMA, waits, named/split barriers and tensor transfers | [gfx1250 model](tests/gfx1250/CONTRACT.md) |

Omitting an AMD target selects gfx950. The source's declared target must match;
changing a target string does not port a kernel. Each target has its own register,
completion, publication and matrix rules. The [AMD analyzer guide](crates/volta_amdgpu_analysis/README.md)
describes the supported instruction and ABI profiles.

Launch configuration defines array extents, argument values, geometry and shared
memory. These are analysis premises and must match the actual kernel. The grid
may affect the computation even though only one selected native workgroup is
analyzed. Set `workgroup_id` in launch JSON or `--workgroup-id X,Y,Z`; it defaults
to zero and must lie inside the grid. Optional
native LDS allocation ranges preserve subobject bounds when assembly no longer
contains source-level object boundaries.

## How the code is organized

The [architecture guide](docs/architecture.md) follows a kernel through parsing,
lowering, execution, graph checking and equivalence checking. The main boundaries
are:

| Location | Responsibility |
| --- | --- |
| `crates/volta_ptx_analysis`, `crates/volta_amdgpu_analysis` | Parse and execute the selected backend; produce expressions, events and provenance |
| `crates/volta_expr`, `crates/volta_spec` | Shared symbolic expressions and the mathematical specification language |
| `crates/volta_graph`, `crates/volta_graph_check` | Typed event graph and target-selected safety checks |
| `crates/volta_equivalence` | Compare complete output index sets and their expressions |
| `crates/volta_pipeline` | Combine the independent safety and equivalence results |
| `crates/volta_cli`, `crates/volta_py`, `crates/volta_viz` | Command-line, Python and browser interfaces |
| `tests/`, `ai_compiler_kernels/`, `external/` | Compiler fixtures, workload configurations, independent oracles and extraction tools |

Each crate has a README explaining its public entry points and internal modules.
Start with `volta_pipeline/src/backend.rs` for backend dispatch and
`volta_pipeline/src/aggregate.rs` for verdict rules.

The [AMD technical report](docs/paper/amd-volta.pdf) compares gfx942, gfx950 and
gfx1250, explains which parts of Volta's approach are reused, and describes the
native execution and safety models required by each target. It includes
validation and limits. Its [LaTeX source](docs/paper/amd-volta.tex) builds with
`make -C docs/paper` using PDFLaTeX.

## Development and testing

`just` provides common commands; Python development uses `uv` and maturin.

```sh
cargo test --release --workspace
just test-python                 # rebuild the Python extension and run its tests
cargo fmt --all -- --check
cargo clippy --workspace --all-targets -- -D warnings
```

`just test` runs both Rust and Python tests. Focused examples and fixture-specific
commands are documented beside the relevant tests. Large workload proofs need
separate capacity planning; see the [full workload runners](tests/gfx1250/full/cpu/README.md).
To extend an instruction, follow the [development guide](docs/architecture.md#extending-an-instruction).

Generate library documentation with:

```sh
cargo doc --workspace --no-deps --exclude volta_cli
```

The CLI and Python crate share the `volta` output name. Build CLI internals into
a separate Rustdoc directory with
`cargo doc -p volta_cli --no-deps --target-dir target/cli-rustdoc`.

## Inspect an execution

```sh
just viz
```

This records pipeline test runs and builds `target/volta-viz/volta-graphs.html`.
The [viewer guide](crates/volta_viz/README.md) also explains focused recording and
exporting an existing store with `volta viz RUN_STORE -o page.html`. The viewer
shows target geometry, source instructions, events and typed findings. Its
bounded display never limits the graph used by the checks.

<p align="center">
  <img src="volta-viz.png" alt="Event-graph viewer showing reads racing an asynchronous copy">
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
