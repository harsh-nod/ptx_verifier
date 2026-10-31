# Native input materialization: fixed comparison protocol

This study compares eager and demand materialization of native AMD symbolic
inputs. The common Rust parent is
`c256801df19928b3c24cbb62ebc40a4c8f9f4dc1`. The baseline release/default CLI has
SHA-256 `a774984789ee54e93797906fe5b51d37faf0c18f019aeece5323fdff1a932f76`.
No ISA, source instruction, mathematical specification, shape, allocation bound,
selected workgroup or proof obligation may change between arms. PTX is unchanged.
The candidate may change expression IDs and construction order, not expressions.

## Frozen population and allocation scope

There are 28 configurations:24 previously declared prefix-attribution cases,
two new full-query attention contracts and two new full-input GEMM contracts.
The earlier attention pair allocated only the selected query prefix and is
explicitly replaced before any new measurements. These are seen regression cases and new
derived full-input allocation contracts, not a heldout population or new HipKittens coverage.

| Target/family | Hazard/safe cases | Input elements per case | Input bytes | Selected outputs |
| --- | ---: | ---: | ---: | ---: |
| gfx950 elementwise | 1/1 | 64 | 256 | 64 |
| gfx950 reduction | 1/1 | 64 | 256 | 2 |
| gfx950 normalization | 1/1 | 128 | 512 | 64 |
| gfx950 GEMM | 1/1 | 192 | 768 | 32 |
| gfx950 attention | 1/1 | 72 | 288 | 10 |
| gfx1250 same five portable families | 5/5 | same as above | same as above | same as above |
| gfx1250 registered matvec | 1/1 | 135,168 | 270,336 | 32 |
| gfx1250 original convolution | 1/1 | 274,432 | 548,864 | 16,384 |
| gfx1250 full-query attention | 1/1 | 196,608 | 393,216 | 8,320 |
| gfx1250 new full-input GEMM | 1/1 | 33,554,432 | 67,108,864 | 65,536 |

Portable hazards preserve the existing address-replacement modules; wide hazards
preserve their existing inserted-collision modules. Each complete module and
original source/specification is hash-bound. The24 retained contracts preserve
their exact allocations, ABI, block/grid, selected workgroup `(0,0,0)`, dimensions
and output-coordinate sets. Matvec retains the registered 32-row A allocation
(`32*4096` elements) plus its 4096-element vector; the available provenance does
not establish a larger host matrix. Convolution retains C64/H56/W56/O128/R3/S3.
The new attention pair retains the unchanged complete source/mutant module,
Q128 selected output rows/T1024/D64, grid `(16,1,1)`, block128 and workgroup0.
Mode0 uses `sequence=gridDim.x*64=1024`, and even CTAs cover all1024 query rows.
Q/K/V therefore each declare65,536 F16 inputs, starting respectively at
`0x10000000`, `0x20000000`, `0x30000000`. Selected output views remain8192 F16 at
`0x40000000` and128 LSE F32 at `0x50000000`. Full-grid logical output extents are
65,536 F16 elements (131,072bytes) and1024 F32 elements (4096bytes); these extents
are metadata, not additional analyzed workgroups or claimed written coordinates.
All seven ABI arguments remain q,k,v,zero-bias,out,lse,zero-tmp. A new spec copy
changes only `array q[Q,D];` to `array q[T,D];`: every equation, dimension and output
domain stays byte-identical. Original spec/launch and derived copies have
separate hashes. The unchanged inserted Shared-byte0 collision keeps its archived
first witness/instruction/prefix contract. The old query-prefix pair is excluded
from this new study; older publications and raw artifacts remain unchanged.

The new GEMM pair uses the unchanged `gemm_f16_full` entry in
`tests/gfx1250/full/fixtures/original-matrix.s` and its existing inserted-collision
counterpart. Its HIP source has `row_base=blockIdx.x*256`,
`col_base=blockIdx.y*256`, full K4096 and 1024 threads; a 16 by 16 grid covers the
4096 by 4096 logical tile domain. The study analyzes only workgroup `(0,0,0)`.
This grid is a new derived launch contract, not a claim of a recovered host launch.
A and B each contain all `4096*4096` F16 elements. A starts at `0x10000000`, B at
`0x20000000`, and selected C row views start at `0x30000000 + row*8192`.
The 256 output views each contain 256 F16 elements, preserving full row pitch4096
and all 65,536 selected-tile coordinates. There is no full-grid safety claim.
Metadata declares exactly three global pointer arguments at offsets0/8/16,
size8 each, kernarg size24, static LDS65536 and maximum block1024. Parameters are
`ptr:a`, `ptr:b`, `ptr:out000`; dynamic LDS is0. Existing M/N/K4096/TILE256
specification equations are retained. The old GEMM A-prefix allocation remains
historical and is excluded from this new population. The existing injected DS
store must yield the Shared byte0 collision from wave0/physical threads0 and1:
source batch133, global instruction count4225 under the fixed32-wave schedule.
Both factor values are the existing A[0,0]/A[0,1] finite1/2 witness; original DS
initialization remains intact. Printed witness event IDs must be distinct and
inside the exact prefix frame; their values are not guessed. New coverage credit
requires an independent source/witness audit, not any same-space typed failure.

## Baseline-first qualification and final process counts

Before candidate coding, run exactly one uninstrumented baseline `analyze`
process per configuration: 28 processes, 60 seconds each, no expression export.
Retain every outcome and freeze the report. A hazard qualifies only with its
authenticated typed rejection, complete expected first witness and correct
exit status; a safe case qualifies only with successful complete analysis and
accepted full graph. No arbitrary FAIL/UNKNOWN or timed-out marker qualifies.
This baseline-only result fixes all performance denominators before candidate
outcomes. Unqualified cases stay in the report and do not receive ratios.

After candidate source/build and semantic tests are frozen, run one candidate
functional qualification for every one of the28 configurations, including
baseline-unqualified cases. Both arms therefore retain28 qualification records
(56 total); candidate success cannot change baseline-only ratio eligibility. A
new full-input GEMM finding may be reported with absolute observed time, but a
60-second baseline timeout supplies no speedup ratio. Candidate false findings,
lost findings, unsafe accepts and refusals remain in the full functional denominator.
Then run exactly five adjacent baseline/candidate pairs for each baseline-qualified
configuration.
Use seed20261031, a fixed shuffled case order per round, and alternating arm order
with each case's initial order drawn before collection. Each case has 2/3 or3/2
arm orders across five rounds. All ten processes per eligible case are retained;
the first is an observation, not discarded warmup. There are at most280 timed
processes. Baseline-unqualified configurations receive no final paired processes or
selective retry. Their candidate qualification observations remain descriptive
and cannot be inserted into the paired comparison.

Commands use the same native backend, target, full configuration and
`early_memory_conflicts=true` in both arms, with `--no-log-file`, `--no-profile`
and `--print-outputs 0`. Timed analyses omit `--emit-exprs` and specification
unfolding. The parent timestamps the first authenticated certificate marker;
`/usr/bin/time` records CPU time and maximum RSS. Hazard endpoint is
that first diagnostic; safe endpoint is parent-observed process completion.
The parent monotonic clock supplies both endpoints; GNU time does not supply the
latency metric. The marker
is credited only after the final status, typed witness and exit code validate.
Retain stdout/stderr, exit/signal/timeout state, order, first-diagnostic time,
parent-observed wall time, CPU time and RSS for every process. A timeout has no fabricated endpoint/ratio.

## Separate complete semantic and specification controls

Timing alone never establishes correctness. Once per arm, for every qualified
safe case, capture complete output expressions and check the exact coordinate
set against the frozen contract. Compare both arms with an independently tested
structural DAG comparator under expression/string-ID renaming: exact operations,
constants, input indices and ordered children; no algebraic equivalence shortcut.
Compare normalized event/role/counter/barrier/footprint and stored-expression
semantics in focused eager/lazy controls; raw ID-dependent dump hashes need not
match. Preserve all existing supported/refused behavior and output dirty ranges.

Run each declared complete specification once per arm for these qualified safe
cases with `verify --sample 0`, all frozen dimensions, 60 seconds and no export.
All old proved equations must remain proved. Convolution and full-query attention equations
were not previously proved under this short budget and remain explicitly
unproved unless complete verification actually succeeds. No sampled outputs,
matching graph verdict or matching expression pair substitutes for a full proof.
Unqualified new full-input GEMM gets no unbounded export attempt or proof credit;
its qualification timeout/refusal is retained. Every semantic/specification
timeout, mismatch, process/export failure or incomplete artifact is reported.

## Fixed descriptive point gates

All gates are frozen before qualification. The candidate passes only if:

* At least two of the three predefined inserted-collision families (registered
  matvec, original convolution, full-query attention) improve median first
  certified diagnostic by at least20 percent **and** at least5ms. All five
  observations must retain the exact expected finding; an unqualified primary
  does not count as a win and cannot be replaced.
* Every baseline-qualified safe or other hazardous case has median relevant
  endpoint no greater than `baseline_median*1.10 + 2ms`.
* For each qualified case, candidate maximum RSS across all five observations is
  no greater than `baseline_max + max(baseline_max*0.05, 8192KiB)`.
* There are zero lost supported findings, false findings, unsafe acceptances or
  changes to required output/graph semantics; previous complete proofs remain
  proved. Any failed required semantic control fails acceptance independently
  of performance.

Report all case medians, maxima, individual observations, misses and regressions.
There is no p95, confidence interval, bootstrap or universal speedup claim from
five observations. End-to-end timing/RSS does not attribute CPU or memory to
initialization, execution, graph checking or algebra. No instrumentation is used.

## Provenance, storage and stopping rules

Freeze source parent and exact candidate diff, clean build attestations,
executable hashes, source/module/spec/config/ABI/selection/protocol/collector
hashes, compiler/tool/runtime context and `/usr/bin/time` identity. Attestations
bind caller-built binaries to source; a hash is not a reproducible-build proof.
Retain the complete original module, not an extracted entry or rewritten fixture.
Keep older studies and their raw artifacts immutable.

Before each process, require at least2GiB free plus its reserved capture budget.
Timed stdout/stderr/time metadata is bounded by a declared total128MiB allowance;
overflow is an explicit failed retained process, never silently truncated.
Complete-output capture streams from its first byte into deterministic lossless
gzip, preserving uncompressed byte count/hash and compressed hash. Do not first
write and unlink a full raw file. Child timeout, gzip failure, reader failure,
storage limit or incomplete export invalidates that semantic control and retains
the partial compressed artifact. Only successful process and complete parsed
coordinate set can qualify. Reserve at most2GiB new compressed semantic artifacts
and256MiB other new study data while retaining the2GiB disk reserve; preflight
actual remaining space before capture. Stop rather than delete old data, resize
allocations, sample outputs or tune budgets after seeing a failure. New full GEMM
export is skipped when its baseline qualification is incomplete.

Qualification, paired collection and semantic controls require separately
reviewed code and explicit idle clearance. No concurrent builds, profiling,
verifier runs or measurements; no GPU execution. Failed gates reject this bounded
candidate. No retuning, changing case set, adaptive repetitions or silent retries.
