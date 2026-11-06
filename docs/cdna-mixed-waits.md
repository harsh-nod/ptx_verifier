# Mixed CDNA wait counters

The native gfx942/gfx950 checker can prove an older LDS result ready after a
nonzero `lgkmcnt` wait even while scalar memory is pending. It counts only the
ordered LDS/permutation stream for that proof. Scalar loads, FLAT operations and
messages do not acquire an artificial global issue order.

Both public ISA references describe same-type ordering and the scalar-memory
exception: [CDNA3 §4.4 and §8.3](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf)
and [CDNA4 §4.4 and §8.3](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf).
Pinned [LLVM `SIInsertWaitcnts.cpp`](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SIInsertWaitcnts.cpp)
also identifies separate event-type timelines as a way to weaken mixed LDS/SMEM
waits safely. These references establish ordering rules, rather than hardware
performance measurements.

## Why an LDS prefix is known

A completed `lgkmcnt(n)` wait bounds the total remaining charge by `n`, so each
individual stream also has at most `n` remaining charge. An ordered LDS stream
can therefore retire its older prefix while retaining its newest `n` charges.
The checker uses the recorded instruction charge, not transfer bytes or lane
count. The independent scalar stream remains unresolved until LGKM0; a wide
scalar load does not count as two ordered LDS instructions.

For example, issue a scalar load, then LDS reads A and B, then `lgkmcnt(1)`.
A must be complete; B and the scalar destination can each still be pending.
Reading A is safe with respect to this completion obligation. Reading either
other result or reusing its destination retains a readiness failure. Reusing a
pending LDS store source also remains a failure. A different counter or a
barrier does not discharge those obligations. The maximal LGKM field, 15, is a
no-op even when the logical issue history exceeds that value.

FLAT retains both VM and LGKM obligations. Mixed ordinary VM/DMA waits and the
separate gfx1250 DS/KM/X/async/Tensor counters retain their existing rules.
The change neither infers scalar response order nor supplies an initialized
value, a missing memory effect, workgroup publication or output equivalence.

## Controls

The complete [gfx942](../tests/amdgpu/native-mixed-lgkm/gfx942.s) and
[gfx950](../tests/amdgpu/native-mixed-lgkm/gfx950.s) controls copy `x[i]` through
LDS. A pending two-word scalar load overlaps two LDS reads; `lgkmcnt(1)` allows
the older read to be stored. These are handwritten instruction controls.
Their [pipeline tests](../crates/volta_pipeline/tests/cdna_mixed_lgkm_tests.rs)
require every output at block sizes 63, 64, 65 and 128. Wrong/missing/maximal
waits, the newer read, scalar reads and destination reuse, and an inactive
second LDS read retain typed failures even though all copy outputs agree.
A separate LGKM0 control proves the same complete outputs.

The [direct graph controls](../crates/volta_graph_check/tests/amdgpu_tests.rs)
place scalar work before, between and after two, three or five LDS issues,
checking thresholds on both architectures. They also retain pending store
sources, independent FLAT counters and maximal-field behavior.
Unchanged compiler controls remain separate: the gfx942 two-wave F16 pipeline
requires all 512 outputs; the gfx950 `float_ops` proof requires all 1,344 writes.
No original fixture, launch, allocation, specification or frozen study result is
changed to obtain these checks.

```sh
cargo test -p volta_graph_check --test amdgpu_tests
cargo test -p volta_pipeline --test cdna_mixed_lgkm_tests
cargo test -p volta_pipeline --test gfx942_compiler_tests --test gfx950_float_sign_transport_tests
```
