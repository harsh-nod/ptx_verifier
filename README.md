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

Ordinary `analyze` reports `VERIFIED`, `REJECTED` or `UNKNOWN`. `verify` and kernel-to-kernel
`compare` report `ACCEPT`, `REJECT` or `UNKNOWN`. Exit codes are 0, 1 and 2,
respectively. Sampling that omits outputs, incomplete execution and unsupported
semantics cannot produce full acceptance. Expression or VC replay checks
equivalence only; those artifacts do not contain a safety graph.

Opt-in [early readiness rejection](docs/early-readiness.md) can stop native
gfx1250 execution at its first certified scalar-read hazard. All three source
commands then print `VERDICT: REJECT` and exit 1, with an incomplete prefix and
no output or equivalence result. With this option disabled, execution uses its
normal instruction, bounds and budget checks.

Opt-in [early memory-conflict rejection](docs/early-memory-conflicts.md) handles
overlapping ordinary writes by distinct active lanes of one gfx950/gfx1250
memory instruction. Independent prefix replay must reproduce the exact conflict
before stopping. It reports a rejection without complete outputs or equivalence;
default execution retains its full diagnostic path.

Supported gfx1250 tensor transfers also receive a separate
[LDS bounds check](docs/tensor-bounds.md). A certified out-of-bounds attempt
prints `VERDICT: REJECT` and exits 1 without issuing the transfer or producing
outputs; its ordinary incomplete graph remains `UNKNOWN`.

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

## Measured time to a safety finding

### Ordinary write conflicts

Opt-in certified memory-conflict rejection detects **20/20 core seeded hazardous
configurations**, compared with **13/20** for this fork's frozen full-trace
baseline. The 40-configuration development study preserves complete compiler
modules and frozen selected-workgroup launch/output contracts, with explicit
seeded store mutations for hazardous cases. Three predeclared inserted-store primaries
have these parent-observed first-diagnostic medians on CPU:

| Measured configuration | Full trace | Certified prefix | Speedup |
| --- | ---: | ---: | ---: |
| F16 matvec, 32 rows, K=4096 | 1.091 s | 49.18 ms | 22.2× |
| F16 convolution, K=576 | 8.526 s | 83.86 ms | 101.7× |
| F16 attention, 128 query rows, 1024 keys | 11.095 s | 48.68 ms | 227.9× |

The [historical attention launch](tests/gfx1250/full/launch/flash_attention_original.json)
allocates 128 query rows; its full 16-CTA grid would need 1024. The
[historical GEMM launch](tests/gfx1250/full/launch/gemm_f16_full.json) allocates
256 A rows out of 4096. Those two cases do not establish timings with complete
host input allocations. All measurements cover one selected workgroup. Their
modules, datasets and published results remain unchanged.

Each comparison uses 31 paired fresh-process repeats and a separate first run;
all three descriptive 95% bootstrap ratio intervals are below 1. The fourth
primary, GEMM, times out at baseline and has **no speedup ratio**. Nine of ten
portable late-store cases have slower medians; five are 8.3%–13.4% slower with
ratio intervals above 1. All 15 baseline complete safe proofs are retained, and all 15 meet their
analysis/export time and memory limits; full mathematical proofs are separate
untimed controls. Three other safe configurations remain unproved.
Six reserved mutation/configuration cases retain all three safe proofs and the
same two of three hazard detections, with the transpose case inconclusive.
These are seeded configurations and CPU verifier timings. See the
[full results, every comparison and audit receipts](tests/amdgpu/memory-conflicts-study/results/README.md)
and [protocol](tests/amdgpu/memory-conflicts-study/protocol.md).

A [26-configuration attribution experiment](tests/amdgpu/sealed-prefix-attribution/README.md)
found final validation below its 15% cost gate in all five predeclared target
cases. The planned execution API change was rejected; all 130 observations and
the negative result are published.

### Historical scalar-read readiness study

Opt-in certified readiness rejection detects an unsafe gfx1250 scalar read
before executing the remaining symbolic trace. Against this fork's full-trace
baseline, the three predeclared missing-wait cases measured:

| Configuration | Baseline median | Early median | Speedup |
| --- | ---: | ---: | ---: |
| Copy | 7.580 ms | 7.085 ms | 1.07× |
| Original F16 ReLU, N=1024 | 16.153 ms | 12.835 ms | 1.26× |
| Original F16 RMSNorm, N=4096 | 51.901 ms | 16.065 ms | 3.23× |

These are parent-observed first-diagnostic times from 255 paired fresh processes
per configuration on CPU-only x86_64 WSL2. All three paired 95% bootstrap
ratio intervals are below 1. Five of six additional compiler-kernel families
also improved; elementwise was inconclusive. This measures verifier latency,
not GPU execution speed or a comparison against upstream Volta.

Both versions detected the same 29 of 30 seeded hazardous configurations across
the 77-configuration suite; one tensor-bounds case remained `UNKNOWN`. All 47
safe configurations retained their complete specification proofs, with no false
positives or unsafe acceptances. Confirmation and both heldout runs met the
predeclared per-case safe-time and memory limits. The initial 31-repeat run
failed one GEMM p95 limit and is retained separately; one confirmatory safe-case
p95 uncertainty interval crosses its allowance. See the
[complete results, limitations and reproducible data](tests/amdgpu/design-study/results/README.md)
and [measurement protocol](tests/amdgpu/design-study/README.md).

A separate [functional comparison](docs/tensor-bounds.md#functional-comparison)
tests two seeded tensor LDS overruns in one compiler kernel. The newer checker
certifies both; the earlier version reports both as `UNKNOWN`. Both versions
retain the valid kernel's complete 128-element specification proof. This adds
coverage without revising the frozen study or asserting a new timing gain.

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

The [HipKittens corpus](external/hipkittens/corpus/README.md) explains source
enumeration, native compilation, launch extraction and complete mathematical
and graph checks. The latest [vector coverage comparison](external/hipkittens/corpus/README.md#dwordx2-and-packed-half-coverage-comparison)
retains all 336 original cases: 112 pass safety and full-output equivalence,
224 retain write/write rejections, and none remains unsupported. These are
selected-workgroup results for two families, without a latency claim.

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
The [upstream sync workflow](docs/upstream-sync.md) checks every six hours and
prepares tested rebases as draft PRs for review.

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
