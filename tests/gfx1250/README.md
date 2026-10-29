# Native gfx1250 validation

Local validation run artifacts are not retained. Source fixtures and reproduction workflows remain available; removed observations do not establish current acceptance.

Software milestone for [issue 13](https://github.com/harsh-nod/ptx_verifier/issues/13).
These fixtures are genuinely cross-compiled for gfx1250 with the pinned ROCm
LLVM toolchain. Their assembly is not rewritten from another target.

See [hardware reproduction](hardware/README.md) for optional device checks.
Device-run records and machine-specific observations are not retained.
Compiler acceptance, graph/equivalence checks and numerical device execution
remain separate evidence classes; none establishes full ISA or whole-device coverage.
See [public semantic sources and artifact retention](PUBLIC_SOURCES.md).

`cases.json` uses the existing native case schema for CLI/Python integration.
The coordinator validated every required case through graph checks, complete
output footprints and independent mathematical references. The fourteen configurations
cover copy/add, cross-wave LDS, wave32 reduction, multidimensional IDs, raw
F32/F16/BF16 WMMA, two-wave staged GEMM, two-stage tensor roundtrip, complete
small attention, packed 16-bit transpose, and signed/unsigned wide products.
Compilation and oracle self-checks are not counted as successful native semantic
tests. Separate broad portable workload ports are coordinated in a distinct
manifest; the mechanism cases do not silently stand in for original full shapes.

Cross-compilation needs no GPU:

```sh
fixture_dir="$(mktemp -d /tmp/gfx1250-fixtures.XXXXXX)"
cp tests/gfx1250/fixtures/*.hip "$fixture_dir/"
python3 tests/gfx1250/compile_fixtures.py "$fixture_dir"
python3 tests/gfx1250/oracles.py --output "$fixture_dir/oracle-self-checks.json"
python3 tests/gfx1250/validate_mutations.py --directory "$fixture_dir"
```

The default toolchain is `/opt/rocm-7.2.0/lib/llvm/bin`, AMD LLVM 22, compiler
revision `7b800a19466229b8479a78de19143dc33c3ab9b5`. The old default LLVM 18
is not used. `fixtures/compiler-provenance.json` records actual commands,
tool/source/assembly/object/code-object hashes and the hardware exclusion.
The compilation script rejects an empty source directory. [`fixtures/emitted-instructions.json`](fixtures/emitted-instructions.json)
records actual instruction profiles, including VOPD components; it is an inventory,
not a stage-support claim. [`fixtures/mutations.json`](fixtures/mutations.json) pins fifteen assemble-valid controls
and their expected safety properties. Semantic rejection must be tested separately.

`oracles.py` uses ordinary dense CPU matrix loops after decoding only the lane ABI
at the boundary. Its public WMMA layout reference is FlyDSL `MmaAtom.cpp` at
`f37f7a2b98f295902240f9f96612222003578b40`: input K slices interleave eight
half-elements between lane groups; output groups each hold eight matrix rows.
The module does not import the emulator or call a GPU. Basis self-checks cover
all 256 outputs for 1,088 input coordinates; wide arithmetic is crosschecked with
Python arbitrary-precision integers. Exact u64 output constants use raw by-value
launch bytes and direct four-element integer comparison instead of `.spec`
literals outside that language's signed64 domain.

`wmma-validation-protocols.json` separately pins actual-interpreter controls:
2,176 A/B input-basis launches across all three types, plus three finite
by-value encoding controls. The BF16 input `0x3f80` must decode as 1, while
the F16 input uses `0x3c00`; all 256 results are checked for every launch.
These native gates pass the integrated execution and graph-checker contracts.
[`fixtures/wmma-oracle-vectors.json`](fixtures/wmma-oracle-vectors.json) contains nine independent asymmetric
finite CPU vectors and their complete outputs; those vectors alone do not
certify the interpreter. Use `--vectors-output` with `oracles.py` to regenerate them.
The native wide-product test parses once and checks all four exact outputs for
343 unsigned and 343 signed argument combinations.

Tensor roundtrip uses an explicitly bounded F32 64-by-1 descriptor, stride64,
256-byte LDS storage, both copy directions, and two stages that reuse the buffer.
Padding, multicast, iteration and atomic-barrier descriptor features are outside
this fixture's profile. The attention case retains all 32 keys in normalization
and all 512 outputs; native exp/reciprocal use the disclosed real-number model,
which does not prove physical finite-precision error bounds.
[`fixtures/descriptor-oracle.json`](fixtures/descriptor-oracle.json) enumerates every global/LDS element address for all
four tensor transfers, including both uses of the same bounded LDS allocation.

The compiler's tensor builtin takes D0/D1/D2/D3 plus cache policy. The newer
LLVM reference adds a reserved D4 argument. The source uses the actual
installed compiler's signature and retains its unchanged four-group machine
instruction; those signatures must not be conflated.

Target geometry, replay-sensitive behavior, descriptor bounds and individual
instruction semantics require separate primary-source contracts. In particular,
gfx1250 is wave32 with hardwired XNACK; it must not inherit the existing
wave64 replay-disabled assumptions. Workgroup-zero analysis does not certify
cluster or whole-grid behavior. The existing mathematical-real abstraction
does not establish IEEE rounding/NaN/denormal equivalence.
[`fixtures/semantic-references.json`](fixtures/semantic-references.json) pins reachable public LLVM files at
`5fd50ec8e07abb94e203933017e8d6e40fb51824` and the independent public layout
reference. Public references are the semantic sources; machine-local snapshots are not retained.

## Software acceptance and reproduction

The frozen acceptance corpus contains fourteen mechanism configurations plus
twenty bounded workload-family computations. The CLI and rebuilt Python tests
require complete configured output coverage; Rust additionally checks all 2,176
A/B WMMA basis launches and 686 exact signed/unsigned wide-arithmetic cases.
Fifteen assemble-valid safety mutants produce fourteen concrete typed graph
rejections and one exact LDS capacity abort. Empty selections, unsupported,
unknown, crashes and missing outputs cannot satisfy the mutation gate.

The portable ports cover elementwise activations, RoPE, reduction, softmax,
RMSNorm, matvec/GEMM, BitDelta, convolution, Mamba state/scan and four attention
families. They use decoded F32 inputs and explicit bounded dimensions, with all 590
outputs checked. BitDelta uses concrete index-generated packed words and complete
32-bit unpacking; Sage attention starts with decoded values. This is family
coverage, not original PTX shape/dtype/packing or whole-grid parity. Separate
WMMA tests cover finite raw F16/BF16 encodings and all 256 output coordinates.

```sh
cargo test --release --workspace --no-fail-fast
uv run --reinstall-package volta pytest crates/volta_py
python3 -m pytest external/tests -q
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/release/volta --color never
python3 ai_compiler_kernels/check_races.py --backend amdgpu --target gfx1250 \
  --binary target/release/volta --mutate -k copy --color never
```

The workspace retains the inherited PTX failure
`test_aligned_bar_sync_reached_on_different_iterations`. It is disclosed in the
historical baseline and is not a gfx1250 acceptance or regression claim.
Expression/VC replay checks equivalence only, because those formats contain no
native event graph. Target-preserving graph dumps and the viewer carry their
own trace evidence.

The [contract](CONTRACT.md) states register/ABI, replay and advanced-mode limits.
The [upstream audit](UPSTREAM_AUDIT.md) maps the latest transpose, BF16, wide
arithmetic and barrier-loop changes to native counterparts or explicit
architecture boundaries. [External recipes](../../external/gfx1250/README.md)
keep the existing HipKittens CDNA4 library profile explicit and provide genuine
LLVM-native gfx1250 extraction controls.

```sh
VOLTA_VIZ_DIR="$PWD/target/gfx1250-viewer" cargo test --release -p volta_pipeline \
  --test gfx1250_compiler_tests -- \
  --skip real_gfx1250_wmma_all_a_and_b_basis_coordinates_run_through_native_interpreter \
  --skip real_gfx1250_wide_product_and_mad_match_exact_unsigned_and_signed_128bit_oracles
cargo run --release -p volta_cli -- --no-log-file viz "$PWD/target/gfx1250-viewer" \
  -o target/gfx1250-viewer.html
```

Use an absolute `VOLTA_VIZ_DIR`: Cargo executes tests from the package folder,
while the CLI command above starts at the repository root. The skipped numeric
variations still run in the full native proof suite. See
[the browser harness](../../crates/volta_viz/tests/browser/README.md) for mixing
legacy records and running Chromium. The compiler-check receipt matches entire
regenerated assembly after normalizing only translation-unit CUID symbols; exact
committed assembly is separately assembled and linked. No generated assembly is
rewritten or relabeled as compiler evidence.

Run logs, measured host costs and hardware receipts are local artifacts. Reproduce
the software checks above and the [hardware workflows](hardware/README.md) for
the revision under review. Removed observations do not establish current acceptance.
