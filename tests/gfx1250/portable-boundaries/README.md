# gfx1250 model, parser and equivalence controls

This directory tests model limits, parser/static validation and equivalence.
`cases.json` maps reference source hashes and Rust assertions to exact native
controls and target-specific differences. Deliberately rejected inputs are
separate from successful numerical programs.

Four genuine HIP modules compile to the checked-in, unchanged gfx1250 assembly.
`compiler-provenance.json` records the compiler, assembler and linker binary
identities, commands, source/assembly/object/code-object hashes and exit codes.
The 24 Rust tests exercise 41 native entry points, including deliberately failing
controls. Compilation and syntax evidence alone do not establish verification.
All controls here run on the CPU; traps and harmful programs are never launched
on a GPU.

## Exact obligations

- Eleven negative equivalence pairs retain every original output coordinate.
  Each native side is compared with the original PTX computation. The native pair
  must be `NotEquivalent` at all configured coordinates, including changed input
  indices, noncommutative operands, F16 ReLU, constants, FMA addends and integer
  sign XOR. Exporting and replaying both symbolic artifacts must retain the same
  verdict. Separate positive controls cover reassociation, the same FMA addend,
  exponent fusion and the all-ones U32 sentinel.
- The sign-XOR pair explicitly applies `& 0xffffffff` to **both** original and
  native values when comparing their declared U32 stored views. The only local
  normalization is mask idempotence `(x & M) & M = x & M`. The unchanged raw
  native XOR-versus-negation pair must still be `NotEquivalent`. This does not
  alter the existing symbolic mathematical-ring abstraction of integer
  add/subtract/multiply, constrain an input or modify production canonicalization.
- Model controls reject actual NaN consumption and NaN by-value parameters,
  symbolic execution control, undefined zero reciprocal and ambiguous symbolic
  fullword-to-byte truncation. Concrete controls retain 7/2 = 3, branch value 2
  and five exact low-byte stores. A constant predicate side effect preserves two
  conflicting global writes of 1; the single-writer control succeeds.
- Some native profiles support more than the original baseline. Power-of-two
  unsigned division is an exact masked logical shift, and signed byte widening
  carries a typed SignedI8 input atom through an actual volatile FLAT load to a
  U32 store. Its input domain is [-128,127], distinct from FP8. Both U32 stored
  views are explicitly projected when checking that identity. These positive
  counterparts do not pretend that the original unsupported outcome is itself a
  portable numerical requirement.
- Known malformed native instructions reject even behind an unconditional
  branch or an empty EXEC mask. Legal termination, wait and complete four-cell
  vector-copy controls prevent vacuous unknown-opcode tests. A legal native trap
  parses but returns explicit `Unsupported`/graph `Unknown`: no returning handler
  is assumed. LLVM encodes a 16-bit SOPP immediate, while the verifier supports
  trap IDs 0..255; 256 is assembler-legal but outside that verifier profile.

The exact PTX `copysign.f16` supported-precision list, `ldmatrix` modifier grammar,
`membar` spelling and `brkpt` no-op convention are narrow target-specific
residuals. They do not erase sign/magnitude computation, vector-load footprint,
wait completeness or static validation obligations. This directory's vector-load
grammar tests do not claim to prove matrix transpose layouts or PTX fence
semantics. Separate native F32 copysign controls retain the actual operand roles.

Floating expressions use the project's disclosed real-arithmetic abstraction;
the mathematical FMA/exponent controls do not claim physical rounding identity.
The six-byte F16 ReLU input includes the compiler's ordinary GLOBAL B32 load at
byte offset 2. Its narrow gfx1250 HSA byte-alignment profile follows the pinned
LLVM contract and separate byte-alignment tests; no SMEM, DS, FLAT or
older-target alignment rule is relaxed by this fixture.

## Reproduction

From the repository root:

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/portable-boundaries
python3 tests/gfx1250/portable-boundaries/check_syntax.py \
  --output /tmp/gfx1250-boundary-syntax.json
python3 tests/gfx1250/portable-boundaries/check_inventory.py
python3 -m unittest discover -s tests/gfx1250/portable-boundaries -p 'test_*.py'
cargo test --release -p volta_pipeline --test gfx1250_boundary_parity_tests
```

`syntax-mutations.tsv` is shared by the Rust parser tests and actual LLVM-MC
replay. `syntax-provenance.json` pins seven legal controls and 31 rejected forms;
the trap-256/65535 positive assembler probes remain explicitly outside the
verifier's supported trap profile. The host tests refuse empty/duplicate syntax
inventories, ambiguous instruction replacements, missing/duplicate reference rows
and changed artifact hashes. No bounded workload or sampled footprint satisfies
an original-shape full-workload gate.

Primary native ABI documentation:
[LLVM AMDGPUUsage.md](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md).
The actual emitted assembly and pinned assembler control the concrete encoding
evidence here; current upstream feature availability is not inferred from an
unrelated GPU target.
