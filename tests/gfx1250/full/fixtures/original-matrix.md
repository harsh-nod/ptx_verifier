These six native kernels retain the W27–W32 input storage and full K4096
computations. `matrix-compiler-provenance.json` pins the actual gfx1250 compiler,
assembly, object and linked code object. Compilation and assembly establish no
numerical or graph-verification result.

| Symbols | Arguments, in order | Block | Selected CTA0 output |
| --- | --- | --- | --- |
| `gemm_f16_full`, `gemm_f8_full` | A, B, output | 1024x1x1 | 256x256 F16 |
| `gemm_add_silu_f16_full`, `gemm_add_silu_f8_full` | A, B, addend, output | 1024x1x1 | 256x256 F16 |
| `bitdelta_full` | F16 A, packed-u32 B, F16 output | 256x1x1 | 64x128 F16 |
| `bitdelta_batched_full` | F16 A, packed-u32 B, F16 output | 256x1x1 | 128x256 F16 |

GEMM inputs are row-major 4096x4096 F16 or OCP E4M3. The addend uses that same
input format. Outputs retain a 4096-element row pitch. Finite E4M3 values convert
exactly to F16 before native F16 WMMA. Accumulation and addend addition use FP32;
the fused epilogue uses `exp2(-x*float(log2(e)))` and hardware reciprocal, followed
by the final F16 conversion. The numerical hardware oracle checks conversion
and approximation behavior separately from the symbolic real abstraction.

GEMM has 32 wave32s, each responsible for 16x128 outputs. Two full K4096 passes
compute 16x64 each, limiting live accumulators without private spills. Two LDS
buffers for each 256x32 A/B panel total 64 KiB. Each K32 stage consumes the
current panel before the next split-barrier publication and buffer reuse.
`ctaid.x/y` select 256-row/column tiles. A selected CTA0 launch uses grid1x1x1;
the source has no dependency on grid extent. Grid16x16 covers the full matrix.

BitDelta reads arbitrary external words: weight(k,column) is +1 when bit(k%32)
of `packed[(k/32)*4096+column]` is one, otherwise -1. It never substitutes
generated words or decoded floating inputs. Packed B has shape128x4096 u32.
The small/large tiles use 24/48 KiB double-buffered LDS and eight native waves.
The large tile uses two full K4096 passes to keep all registers in the supported
low bank while retaining every original output.
The original grouped `ctaid.x` mappings remain:

| Kernel | First row | First column |
| --- | --- | --- |
| `bitdelta_full` | `((pid>>8)*8+(pid&7))*64` | `((pid>>3)&31)*128` |
| `bitdelta_batched_full` | `((pid>>7)*8+(pid&7))*128` | `((pid&127)>>3)*256` |

The batched kernel uses `ctaid.y` and the original strides: A/output advance
4096x4096 elements per batch; packed B advances 128x4096 u32 words per batch.
The selected original CTA0 uses grid1x1x1 and batch0. All six native descriptors
declare zero private scratch. Row-view GEMM specs bind every output row
`out000`…`out255` at its original byte offset. The public spec grammar currently
cannot express arbitrary packed-word bit selection; that BitDelta obligation
requires an integer-aware expression oracle and remains pending.
