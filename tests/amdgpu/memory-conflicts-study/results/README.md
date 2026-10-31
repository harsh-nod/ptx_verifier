# Instruction-local memory-conflict results — 2026-10-31

Certified prefix rejection detects **20/20 core seeded hazardous configurations**
versus **13/20** for the frozen full-trace baseline. It retains all **15/18**
baseline complete safe proofs. Three qualified original-shape inserted-store
primaries improve first-diagnostic medians by **22.2×, 101.7× and 227.9×**.
GEMM's baseline timeout has no ratio. Nine of ten portable late-store medians
are slower; five ratio intervals lie above 1, with **8.3%–13.4%** slowdowns.
The six reserved configurations retain three safe proofs and **2/3** hazard
detections in both versions; transpose remains inconclusive.

[Machine-readable observations](comparison-20261031.json) contain every functional
outcome, all **2,112** paired process samples, separate first observations,
full-precision summaries, numeric functional witnesses and source/build/driver
identities. The [independent audit receipt](independent-audit-20261031.json)
binds five raw reports and their separate audits: **90,465 checks, zero errors**.
Separate [publication](publication-audit-20261031.json) and
[documentation](documentation-audit-20261031.json) audits check the public
projection, recompute its statistics and verify every displayed table.
The public JSON SHA-256 is
`59edc7e412bf2872bd029d3ae86146d5924d5ad1e3a2d45bb4717f77ca6d0576`.

## What changed and what was measured

Full execution checks the completed trace, but a later
unsupported operation, execution failure or timeout can leave an earlier
conflict inconclusive. The opt-in observer proposes overlapping writes by
separate active physical lanes of the same issued ordinary global/direct-DS
instruction. Independent validation and final prefix replay must reproduce the
exact pair and lowest common byte using the existing target memory model.
A successful certificate authorizes rejection only. Safe kernels still require
complete execution, graph checks and mathematical output proofs.

The [implementation guide](../../../../docs/early-memory-conflicts.md) explains
eligibility and frontend/allocation trust premises. This experiment measures
first conclusive diagnostics, not all bug sites or all schedules. Counts are
seeded **configurations**, not distinct application defects. Each harmful seed
has a source-derived finite valuation with unequal bytes in the overlap; it need
not change the result for every input. Synthetic unsupported tails and existing
same-value HipKittens conflicts do not establish new application-bug coverage.

The manifest fixes 40 development cases: 18 safe originals, 20 core harmful
seeds and two synthetic tails. Six portable families run on gfx950 and gfx1250;
original-shape matvec K4096, GEMM K4096, attention T1024 and convolution K576
supply larger cases. ReLU N1024 and RMSNorm N4096 are additional late-store safe
controls. All retain complete compiler modules, selected workgroups, launch
contracts, storage types and output views. The original native GEMM launch has
1024 threads; the historical PTX launch differs. This is a native comparison.

The six reserved cases are mutation/configuration holdouts of known compiler
fixtures, not previously unseen algorithms. They were first executed by this
study after mechanism freeze and development review. No post-outcome tuning,
substitution or retry changed the frozen implementation or populations.

## All functional outcomes

| Population | Full-trace baseline | Candidate enabled |
| --- | ---: | ---: |
| Development safe graphs and complete footprints /18 | 17 | 17 |
| Development complete safe specification proofs /18 | 15 | 15 |
| Development core hazardous configurations /20 | 13 | 20 |
| Synthetic unsupported-tail configurations /2 | 0 | 2 |
| Reserved complete safe proofs /3 | 3 | 3 |
| Reserved hazardous configurations /3 | 2 | 2 |

The three development safe cases without a complete proof retain their fixed
60-second outcomes: convolution and attention time out in specification checking;
GEMM times out in graph analysis and specification checking. They provide no
safe-proof or overhead guarantee. The harmful reserved transpose attempts a
4-byte access at byte address 2. The existing model's alignment preflight stops
all three roles before the issue completes: exit 2, no outputs, `UNKNOWN` and no
certified conflict. This remains an explicit miss, not a detected memory conflict.

Candidate OFF retains baseline diagnostics, instruction counts and actual
expression/coordinate observations, except resource-censored timeout transcripts
are not required to be byte-identical. Enabled safe outputs retain complete
unique coordinates and identical expression bytes. Both wrong-equation controls
refute all 64 expected outputs in baseline, candidate OFF and candidate ON.
No false positive or unsafe acceptance was observed in the applicable completed
checks; unproved cases do not extend that evidence.

## First-diagnostic timing

Each baseline-qualified case has one separate first process and 31 repeated
fresh processes per arm. Order is randomized in adjacent pairs with seed
20261031; stages have a 60-second budget. There are 28 development comparisons
(15 safe, 13 hazardous) and five reserved comparisons (three safe, two hazardous).
Every baseline-fixed qualifier succeeds; no observation is removed or retried.
The first samples remain in the public JSON with `repeat: 0`; they are excluded
from timing median/p95. Rows below use repeated samples only, in milliseconds.

Latency is the parent's first observation of the ordinary memory-conflict
property FAIL line or certified marker, counted only after final strict rejection validation.
It is not internal checker time or GPU execution latency. Optional expression
export is absent in both timed hazardous arms. Full default diagnostics/export
invariance is checked separately. p95 is nearest-rank, the second largest of 31.
Intervals are descriptive paired-bootstrap 95% candidate/baseline median-ratio
intervals, using 2,000 resamples. They are not simultaneous confidence bounds,
stable tail estimates or guarantees for other workloads.

### Every qualified development hazard

A ratio below 1 means the candidate median is faster. `inserted` identifies the
three qualified predeclared primaries; other rows replace a store address.

| Configuration | Baseline median ms | Candidate median ms | Baseline p95 ms | Candidate p95 ms | Candidate/baseline | 95% ratio interval |
| --- | --- | --- | --- | --- | --- | --- |
| gfx950 elementwise | 15.148 | 15.526 | 17.049 | 17.625 | 1.0249 | [0.9669, 1.0738] |
| gfx950 reduction | 13.880 | 13.888 | 15.672 | 16.170 | 1.0006 | [0.9672, 1.0389] |
| gfx950 normalization | 19.175 | 21.747 | 24.139 | 25.592 | 1.1341 | [1.0905, 1.1971] |
| gfx950 gemm | 15.611 | 16.977 | 22.137 | 18.555 | 1.0875 | [1.0227, 1.1313] |
| gfx950 attention | 16.396 | 17.092 | 17.994 | 20.209 | 1.0425 | [0.9837, 1.1188] |
| gfx1250 elementwise | 16.749 | 14.762 | 19.478 | 16.391 | 0.8814 | [0.8474, 0.9317] |
| gfx1250 reduction | 14.260 | 14.891 | 15.786 | 18.621 | 1.0443 | [0.9766, 1.0697] |
| gfx1250 normalization | 20.922 | 23.313 | 24.358 | 27.438 | 1.1143 | [1.0495, 1.1908] |
| gfx1250 gemm | 16.761 | 18.694 | 19.465 | 22.087 | 1.1154 | [1.0675, 1.1671] |
| gfx1250 attention | 17.342 | 18.786 | 21.849 | 21.573 | 1.0833 | [1.0545, 1.1291] |
| gfx1250 original matvec K4096 inserted | 1090.957 | 49.179 | 1264.491 | 57.096 | 0.0451 | [0.0429, 0.0478] |
| gfx1250 original convolution K576 inserted | 8525.950 | 83.859 | 9338.032 | 95.936 | 0.0098 | [0.0094, 0.0103] |
| gfx1250 original attention T1024 inserted | 11094.927 | 48.684 | 12013.221 | 58.561 | 0.0044 | [0.0042, 0.0046] |

The fourth fixed primary, original GEMM's inserted conflict, times out at baseline
within 60 seconds. The candidate emits a certified diagnostic at 3.940 seconds
in functional qualification. This is one absolute observation, **not** a median
or a speedup ratio. The primary remains a failed baseline qualification.

Nine portable late-store medians regress. Five are clearly slower in this finite
sample: gfx950 normalization and GEMM, plus gfx1250 normalization, GEMM and
attention. Four intervals cross 1; gfx1250 elementwise is faster. The opt-in
therefore offers a useful early-conflict/coverage tradeoff, not universal speedup.

### Genuinely new core coverage

These seven configurations were baseline inconclusive, unsupported or timeout.
They establish five frozen manifest family identities (transpose plus four
original complex families), exceeding the predeclared four-family/two-complex
coverage floor. Portable and original GEMM/attention labels overlap conceptually;
family identities are not a count of wholly distinct algorithms. Both synthetic
tails are excluded. Times below are single functional observations.

| Configuration | Baseline outcome | Observed candidate diagnostic ms | Baseline ratio |
| --- | --- | --- | --- |
| gfx950 transpose | inconclusive | 8.160 | none |
| gfx1250 transpose | inconclusive | 8.037 | none |
| gfx1250 original matvec K4096 | inconclusive | 48.294 | none |
| gfx1250 original convolution K576 | unsupported | 79.856 | none |
| gfx1250 original attention T1024 | unsupported | 46.303 | none |
| gfx1250 original GEMM K4096 inserted | timeout | 3940.270 | none |
| gfx1250 original GEMM K4096 | unsupported | 4084.699 | none |

### Reserved hazards

| Configuration | Baseline median ms | Candidate median ms | Baseline p95 ms | Candidate p95 ms | Candidate/baseline | 95% ratio interval |
| --- | --- | --- | --- | --- | --- | --- |
| gfx1250 original SiLU N512 | 22.819 | 17.067 | 26.097 | 21.402 | 0.7479 | [0.7051, 0.7715] |
| gfx1250 original softmax N4096 | 152.726 | 24.246 | 203.068 | 27.284 | 0.1588 | [0.1507, 0.1709] |

The corresponding speedups are 1.34× for SiLU and 6.30× for softmax. The third
reserved hazard, transpose partial overlap, remains inconclusive in both modes
and has no ratio. Reserved coverage stays **2/3**, with no new coverage claim.

## Every safe overhead gate

Safe timings measure full graph analysis and complete expression export; full
mathematical proofs are separate qualification controls. Per-case median process
time must be ≤baseline×1.05+1 ms, p95 ≤baseline×1.10+1 ms, and peak RSS increase
≤the larger of 5% or 8 MiB. These are point-estimate gates. Maximum RSS includes
the first process and all 31 repeats; timing median/p95 exclude the first.
Every complete exported coordinate set and exact expression digest is validated
against a retained full reference. Only validated exact duplicates are deleted;
all logs/digests, retained references and unmatched artifacts remain outside Git.

### Development

All 15 cases pass each gate. The largest median increase is 2.29%, p95 increase 5.27%,
and RSS increase 512 KiB. Values are baseline → candidate.

| Configuration | Median ms | p95 ms | Peak RSS KiB | Median/p95/RSS gates |
| --- | --- | --- | --- | --- |
| gfx950 elementwise | 16.390 → 15.815 | 19.247 → 18.896 | 6400 → 6912 | PASS |
| gfx950 reduction | 16.077 → 15.985 | 19.305 → 19.647 | 6656 → 6912 | PASS |
| gfx950 normalization | 20.253 → 20.477 | 23.476 → 24.343 | 7168 → 7168 | PASS |
| gfx950 gemm | 17.474 → 17.065 | 21.935 → 21.700 | 6656 → 6912 | PASS |
| gfx950 attention | 19.009 → 18.852 | 22.532 → 22.003 | 7168 → 7168 | PASS |
| gfx950 transpose | 9.505 → 9.640 | 10.962 → 10.768 | 5888 → 5888 | PASS |
| gfx1250 elementwise | 17.124 → 17.516 | 20.641 → 19.421 | 6912 → 6912 | PASS |
| gfx1250 reduction | 17.331 → 16.787 | 19.031 → 19.666 | 6656 → 6912 | PASS |
| gfx1250 normalization | 21.859 → 21.619 | 25.471 → 26.813 | 7424 → 7424 | PASS |
| gfx1250 gemm | 19.570 → 18.733 | 24.759 → 23.266 | 7168 → 7168 | PASS |
| gfx1250 attention | 19.904 → 19.855 | 22.583 → 23.033 | 7168 → 7168 | PASS |
| gfx1250 transpose | 10.093 → 9.922 | 11.045 → 10.718 | 5888 → 5888 | PASS |
| gfx1250 original ReLU N1024 | 20.051 → 20.073 | 22.713 → 21.953 | 7936 → 7936 | PASS |
| gfx1250 original RMSNorm N4096 | 59.694 → 59.239 | 70.228 → 71.138 | 12800 → 12800 | PASS |
| gfx1250 original matvec K4096 | 1203.045 → 1175.883 | 1444.014 → 1429.719 | 119416 → 119380 | PASS |

### Reserved configurations

All three cases pass each gate. Median ratios are below 1; the largest p95 increase is
5.71%, with no increase in measured maximum RSS.

| Configuration | Median ms | p95 ms | Peak RSS KiB | Median/p95/RSS gates |
| --- | --- | --- | --- | --- |
| gfx950 transpose | 9.584 → 9.536 | 11.361 → 10.742 | 5888 → 5888 | PASS |
| gfx1250 original SiLU N512 | 19.391 → 18.916 | 21.961 → 23.215 | 7680 → 7680 | PASS |
| gfx1250 original softmax N4096 | 53.877 → 53.476 | 74.809 → 66.001 | 12032 → 12032 | PASS |

## Frozen identities, environment and reproduction

The baseline is this fork's full-trace release at
`0e634bc43536e5e4ac5cb13e8046d8e1edd57250`; the candidate mechanism is
`f0ee44285286aa1ea92f3e99aed6574ad89f3c82`. Baseline qualification preceded core
implementation; the candidate mechanism was frozen before candidate development
execution and this study's first reserved-case execution. Both use release/default-feature CLI
builds with rustc and Cargo 1.97.1. Source/binary association is caller-attested;
complete binary/workspace/input hashes are in the JSON. Later documentation and
publication tooling do not alter the measured Rust implementation.

Timing ran sequentially on CPU-only x86_64 Linux/WSL2, kernel
6.6.87.2-microsoft-standard-WSL2, Python 3.12.3, AMD RYZEN AI MAX+ PRO 395,
32 logical/allowed CPUs. No concurrent builds, profiling or other experimental
collection ran during paired measurements. There was no affinity setting, cache
flush or cold-cache claim; repeat processes use the normal OS cache. No faulty
kernel ran on a GPU, and no hardware performance claim follows from these data.

The [development protocol](../protocol.md) and [reserved protocol](../heldout-protocol.md)
give fresh-directory collection commands. The immutable [manifest](../cases.json)
binds sources, launch/specification contracts, finite harmful valuations and
populations. [Publication tooling](../publish_results.py) accepts only hash-bound
completed reports, recomputes consistency checks and renders an explicit field
whitelist. It executes no measurement process. The earlier
[readiness study](../../design-study/results/README.md) remains unchanged.

The independent audits parse raw logs/resources, check source/build/input
bindings, validate retained output bytes and unique coordinates, reproduce
randomized pair schedules, and recompute medians/p95, paired bootstrap intervals,
RSS and all gates without importing the measurement helpers. They cannot recreate
output-reception timestamps from plain logs, independently attest a build,
re-decode raw ISA or prove frontend/hardware soundness. The public JSON preserves
numeric typed witnesses for functional records; repeated observations retain
metrics and stdout digests. `printed_write_write_witnesses` counts exact rendered
matches, possibly CLI-capped, not all conflicts or application bugs.

Raw commands, logs and private runtime identifiers stay outside the repository.
The aggregate receipt binds every raw report and independent receipt by SHA-256;
the public data retains full numeric precision so its arithmetic can be checked
separately. Reported table numbers are rounded for readability.
