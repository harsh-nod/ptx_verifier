# Specific matrix, LDS layout, and dtype contracts

Local validation run artifacts are not retained. Source fixtures and reproduction workflows remain available; removed observations do not establish current acceptance.

The 19 positive native gfx950 sources map 20 original success rows. A legal
wrong-format control brings the total to 20 assembly sources. `cases.json` records each actual PTX
source hash, Rust assertion, expected output, native configuration, and scope
changes. The coordinator owns parity dispositions.

```sh
cargo test -p volta_pipeline --test gfx950_matrix_parity_tests
```

| Original property | Native observable counterpart |
| --- | --- |
| `ldmatrix.trans`8×8 | All 64 half outputs satisfy `out[i]=x[(i%8)*8+i/8]`; explicit LDS half reads feed native low/high packing. |
| Aligned four-fragment load | Four 8×8 tiles expose all 256 half fragment items, retaining 16-byte row boundaries. |
| `stmatrix` lane byte placement | Native row/column address arithmetic covers all 128LDSbytes. Output 0 remains 1005 from byte 20;32 additional outputs expose every lane's distinct word. |
| WMMA row strides 32/48/64 bytes | Every gathered half is exported; weighted K16 MFMA exports all 256 F32 outputs. Both strided cases compare with the contiguous control. |
| WMMA store | All 256 F32 ones pass through row-major 64-byte LDS rows before output. |
| Raw accumulator bits | Zero A/B leaves the raw C fragment `[0x3f800000,0,0,0]` numerically `[1,0,0,0]` for all 128 original fragment outputs. |
| Immediate accumulator vector | Native scalar immediate C broadcasts 1 or 0; two actual MFMA broadcasts and native register moves build the original heterogeneous fragment. |
| TCGEN136 / raw 17 | Eight native waves preserve logical M128,N8,K16 and export all 1024 coordinates. The raw 17 case also transports the raw C seeds through LDS. |
| TCGEN mixed E4M3/E5M2 | Logical M128,N8,K32 retains the first two 16-K cores 128 bytes apart. Native unit-scaled K128 pads unusedK with zero, producing 408 at(0,0). Interchanging B's format produces 476 and fails equivalence. |
| Real-kernel TCGEN shape | Full M128,N256,K16 executes 128 native 16×16 tiles and exports all 32768 zero outputs. The final B b64 LDS read ends exactly at the compact operand region boundary. |
| FP8 byte and pair decoding | Concrete `0xb838` produces+1/-1, ReLU produces+1/0, and symbolic vector/byte selections retain independent x[0]/x[1]/x[2]/x[3] identities. |

The native matrix engine requires complete wave 64. The accumulator identity
cases execute that full wave and project the lower 32 lanes to preserve the
baseline 128-value fragment footprint. The larger TCGEN counterparts use 512 or
1024 threads and multiple 16×16 native tiles; native internal N16 padding is not
exported when the original shape has N8. All original logical rows, columns,
and nonzero K terms remain represented.

NVIDIA descriptor bitfields, tensor-memory allocation, warp fragments, swizzle
encodings, and optional output-lane-mask syntax do not become AMD instructions.
Their portable computations and bounded LDS accesses use explicit native
addresses and registers. The numeric 136/raw 17 source uses ordinary row-major
LDS. The mixed FP8 source explicitly retains the observed 128-byte separation
between its two 16-K cores. It does not claim that arbitrary TCGEN descriptor
addresses have the same native encoding. The full 128x 256 case retains the
original 49168-byte total LDS budget while its ordinary compact A/B operands
occupy 12288 bytes.

Native DS access alignment follows the actual transfer width: the strided
fragment gathers use 8-byte b64 accesses. The original WMMA tests require a
32-byte fragment base and 16-byte row alignment; those target-specific checks
are recorded separately. The exact half permutations and fragment outputs
prevent an unrelated dense multiplication from being counted as layout
coverage.

`mfma-operand-assembler.json` pins 317 positive and negative operand controls
across 11 native MFMA forms, including per-format F8 F6 F4 register widths. The
frontend test compares its decisions with each recorded assembler result:
A/B require VGPR or AGPR registers, register C shares the destination register
file, and immediate C has its encoded literal envelope. Zero operands are
materialized in native vector registers. Existing compiler and workload
assembly remains unchanged.

All arithmetic comparisons retain the repository's exact real-number model;
IEEE intermediate rounding is not added. Direct finite FP8-to-F32 decoding
preserves the baseline FP8-to-F16-to-F32 value because these finite FP8 values
are exactly representable in F16.

Every hand-written kernel entry uses `.p2align 8`, as required for AMDHSA hardware entry alignment. This packaging directive does not change the instruction sequence or mathematical reference. Source and assembler hashes include the alignment.
