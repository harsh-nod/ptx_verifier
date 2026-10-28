# Native gfx1250 software validation

Work in progress for [issue 13](https://github.com/harsh-nod/ptx_verifier/issues/13).
These fixtures are genuinely cross-compiled for gfx1250 with the pinned ROCm
LLVM toolchain. Their assembly is not rewritten from another target.

**No gfx1250 hardware execution has been performed.** Hardware validation is
explicitly skipped for this software task because no target device is available.
Compiler/assembler acceptance and CPU semantic tests cannot replace hardware
evidence. gfx942/gfx950 devices are not gfx1250 hardware substitutes.

`cases.json` uses the existing native case schema for CLI/Python integration.
Each required case remains pending until its graph checks, complete footprint
and independent mathematical reference are validated. The fourteen configurations
cover copy/add, cross-wave LDS, wave32 reduction, multidimensional IDs, raw
F32/F16/BF16 WMMA, two-wave staged GEMM, two-stage tensor roundtrip, complete
small attention, packed 16-bit transpose, and signed/unsigned wide products.
Compilation and oracle self-checks are not counted as successful native semantic
tests. Separate broad portable workload ports are coordinated in a distinct
manifest; the mechanism cases do not silently stand in for original full shapes.

Cross-compilation needs no GPU:

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/fixtures
python3 tests/gfx1250/oracles.py --output tests/gfx1250/fixtures/oracle-self-checks.json
python3 tests/gfx1250/validate_mutations.py
```

The default toolchain is `/opt/rocm-7.2.0/lib/llvm/bin`, AMD LLVM 22, compiler
revision `7b800a19466229b8479a78de19143dc33c3ab9b5`. The old default LLVM 18
is not used. `fixtures/compiler-provenance.json` records actual commands,
tool/source/assembly/object/code-object hashes and the hardware exclusion.
The compilation script rejects an empty source directory. `emitted-instructions.json`
records actual instruction profiles, including VOPD components; it is an inventory,
not a stage-support claim. `mutations.json` pins fifteen assemble-valid controls
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

Tensor roundtrip uses an explicitly bounded F32 64-by-1 descriptor, stride64,
256-byte LDS storage, both copy directions, and two stages that reuse the buffer.
Padding, multicast, iteration and atomic-barrier descriptor features are outside
this fixture's profile. The attention case retains all 32 keys in normalization
and all 512 outputs; native exp/reciprocal use the disclosed real-number model,
which does not prove physical finite-precision error bounds.

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
`semantic-references.json` pins reachable public LLVM files at
`5fd50ec8e07abb94e203933017e8d6e40fb51824` and the independent public layout
reference. Local source snapshots are recorded only as secondary comparisons.
