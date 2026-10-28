These controls use complete native workloads. `cases.json` pins each unchanged
compiler source and defines one exact mutation: replace the first `s_barrier`
after that kernel's entry with `s_nop 0`. The checked-in integration test applies
this mutation to the actual source, retains every arithmetic/memory instruction,
and requires a typed Shared LDS conflict. Both mutants also assemble for gfx950;
their source/object hashes are in `assembler-provenance.json`.

The matvec preserves all 32 output rows and the complete K4096 dot products. Its
native scalar wave/LDS implementation differs from the PTX matrix/bulk pipeline.
The scan preserves all 32 time rows, 128 features, state K32 and scan K128, plus
every companion zero at the original output pitch1024. Both native source and
independent mathematical reference retain previous-state-to-half and
weighted-CB-to-half conversion order; the existing real abstraction ignores
rounding. Exact native scan assembly also runs against a separate CPU reference
that applies those half conversions, checks all pitched gaps/guards, and tests
state-only, scan-only and mixed inputs.

The original PTX workload findings are `ProxyOrderViolation` at Shared byte0,
missing `ProxyAsync`: ReadWrite for matvec and WriteRead for scan. These are
source-specific proxy rules. Native publication-barrier negatives exercise the
corresponding full computation's CDNA4 LDS visibility/order requirement. They
do not claim that AMD has a PTX async-proxy fence or that a generic matrix
microtest reproduces either original workload.
