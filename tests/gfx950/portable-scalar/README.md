# Portable scalar contracts on gfx950

These native AMDHSA sources exercise the computations and memory properties of
42 upstream success fixtures. `cases.json` identifies each original source,
its source hash, Rust assertion, expected output, native launch configuration,
and test. Two additional mappings use the unchanged compiler fixtures for
module globals and grid outputs. They cover 44 baseline rows; the mapping file
does not change the coordinator's parity statuses. Native handwritten kernels
use a consistent `x`/`out` pointer ABI; baseline input name `in` is renamed
`x`, and an unused input slot is retained for baseline output-only cases.

Run the complete native pipeline checks with:

```sh
cargo test -p volta_pipeline --test gfx950_portable_scalar_tests
```

Each check parses and lowers actual gfx950 assembly, executes the complete
configured workgroup, checks the AMD graph, checks every written output index,
and compares against an independently constructed expression. The shared
`gfx950_common` helper preserves viewer recordings when `VOLTA_VIZ_DIR` is set.
The packed F32 variants additionally compare with their scalar native reference
and reject the square-only mutant. Sources are assembled with the pinned ROCm
LLVM22 `llvm-mc`; `assembler-provenance.json` records commands, source/object
hashes, and the compiler binary hash. Object files are not checked in.

The arithmetic follows the repository's existing exact real-number model:
FMA and separate multiply/add can be equivalent, and reciprocal fractions are
exact model values. Native approximate reciprocal/exp hardware accuracy is not
proved by these symbolic tests. The exponential cases use the exact recognized
LOG2_E_F32 multiply followed by `v_exp_f32`. The zero-input tanh case retains
its `(exp(0)-1)/(exp(0)+1)` reference expression. Positive infinity is compared
as an exact signed constant before finite expressions enter polynomial
canonicalization, which deliberately rejects non-finite coefficients.

AMD registers and memory stores carry raw bits. An integer add of zero before
a typeless store explicitly selects the upstream unsigned integer consumer
where necessary. The 16-bit shifts and funnel shifts compose native shifts
and masks with bounds selection to preserve the upstream clamp behavior;
they do not assume AMD's wrapped shift count equals PTX's clamp behavior.
Packed F32 sources retain native register pairs, 64-bit word moves, and actual
word shifts/OR composition where the baseline tests those transports.

The election sources use32 active lanes in an AMD wave64; the second source
removes lane0 before choosing the lowest active lane and leaves output0
unwritten. The tail reduction uses16 active lanes and checks the full16-input
sum. These cases cover active-lane computations; terminated-wave barriers are
covered by separate scheduler tests.

The LDS cases preserve the original fixed/dynamic sizes and offsets. A
separate genuine compiler test checks a12-byte static allocation, padding to
a32-byte aligned extern window, an8-byte dynamic allocation, and the opaque
native shared aperture. The byte-pair case transports two symbolic FP8 bytes
through one16-bit LDS load/store before decoding each element. The exact-fit
case accesses offsets32..47 of a48-byte region, then the adjacent region at48.
The upper-address case preserves the exact baseline input base
`0x7ffffffffffffff0` and a+16 load crossing the signed64-bit boundary without
unsigned wrap.

The module-global compiler case includes a configured array ending exactly at
the synthetic module allocation window, actual bound object overrides, BSS,
and readonly initialized data. The grid case checks all9 ordinary native
outputs for grid2x3x4, groupID0/0/0, and block4x3x2. Its baseline also has exact
NVIDIA cluster fields; those fields are separately scoped, and this mapping
does not claim an equal15-field output contract. The CVTA baseline has no
output; its native counterpart strengthens ordinary pointer transport with a
bounded input/output copy. Rank-zero MAPA covers only an address in the same
workgroup's LDS allocation and the resulting offsets0/4/8/12.

The mixed-by-value compiler test is an additional ABI contract beyond these
44 rows. It preserves positional F32/F64/I32/I16/U8 parameters, symbolic F32
identity, signed narrowing, and the unknown padding byte after the U8 value.
Only explicitly selected defined bytes may be consumed; padding is not
zero-filled or exposed as an invented argument.

Every hand-written kernel entry uses `.p2align 8`, as required for AMDHSA hardware entry alignment. This packaging directive does not change the instruction sequence or mathematical reference. Source and assembler hashes include the alignment.
