# Coordinator acceptance for issue #21

The coordinator reviewed all 32 original workload variants and all 520 finite
upstream reference rows at `aacbdb094c29133adcec85c5cc1695b60d775a3c`.
The explicit decisions are in [`coordinator-decisions.json`](coordinator-decisions.json).
They preserve every original shape, storage dtype, reduction/sequence extent,
launch mapping and per-array sparse output contract. The original configured
projection contains 395,394 outputs. Complete native supersets remain separate
from that projection.

This acceptance covers the selected unclustered workgroup and existing
mathematical-real model. It does not extend the ISA profile, certify other
workgroups, or establish physical IEEE rounding/exception behavior. The bounded
issue #13 fixtures retain their original scope. `gaps.json` and
`feature-review.json` retain historical planning and source identities; their
pending planning fields are not current coordinator decisions.

## Source-bound feature review

```sh
python3 tests/gfx1250/full-parity/coordinator_features.py \
  --decisions tests/gfx1250/full-parity/coordinator-decisions.json \
  --output /tmp/gfx1250-current-feature-review.json --require-all-reviewed
```

All 520 rows have one owner and an explicit reviewed decision: 278 native
assertion mappings, 8 typed native memory negatives, 65 precise mechanism
residuals, 14 target contract differences, 154 shared specification/aggregate
guards, and one intentional non-real input refusal. These are reference-file
dispositions, not an ISA percentage or 520 separate GPU programs. The helper
binds current implementation, assertions, goldens, recursive included fixtures
and adjudication overlays. Changing a bound source invalidates the decisions.

The complete current Rust run contains 2,060 passing tests across 142 test
targets, with zero failures or ignored tests. Every referenced native/shared
assertion is covered; the shared negative-pair helper functions are exercised
by their twelve mutation tests and the taxonomy meta-test. The independent
metadata controls cover stale sources, missing/overlapping ownership, complete
index sets and refusal to promote pending obligations.

NVIDIA grammar, TMEM allocation/permit/address encoding and cluster scheduler
residuals are reviewed at their exact mechanism boundary. Their arithmetic,
storage layout, byte lifetime and publication obligations have separate native
controls. Named signal-time updates support the public seven-bit count range,
zero/no-change, NULL and safe changes between phases of one initialization
lifetime. The exact mixed2/1 equality boundary stays inconclusive because the
pinned public rules disagree. Unordered conflicting setters/drop operations,
live-join reinitialization and unspecified END publication remain explicit proof
limits. None is described as a verified positive or a typed race finding.

## Original32 proofs and revision composition

Strict independent aggregation passed all 32 cases and 395,394 unsampled
outputs separately for the default CLI, logging CLI and Python extension.
Each aggregate validates immutable executable/runtime/input pins, exact
per-array index sets, all four graph properties, full VC counts, equivalence,
final verdict and process exit status. The frozen proof revisions remain:

| Gate | Builder/fixture revision |
| --- | --- |
| Default CLI and Python full-output proofs | `9ada7f3653e98b4293272e0b1d4383a5fd561cbb` |
| Logging CLI full-output proofs | `d00532dddf3c2167d821ac1601f79deb8a39d1de` |
| Final isolated CLI graph replay | `5724647134ce8214c93ea9a32847c946cba503c1` |
| Final rebuilt Python regression package | `d17e1edb886344bfbf63d3e4b8249a1ccbb63419` |

The final CLI independently replays all 32 complete original executions, all
four graph checks and each output array's full count. This is a graph replay,
not a relabeled new mathematical-equivalence run. All 137 workload inputs and
exact index contracts match the immutable full-output proofs. Expression,
specification and equivalence implementation sources are unchanged. The later
producer changes affect profiling labels and allocated named barriers; the
seven original compiler modules contain only unnamed signals. Later checker
changes cover completed-read ordering and named-object protocols; the final
full graph replay validates their integrated result. The coordinator reviewed
this composition explicitly rather than assigning an old binary a new revision.

The strict drivers and aggregators are in [`../full/cpu`](../full/cpu/README.md).
The runs used the following per-process memory budgets without shortening any
shape. Wall/CPU budgets were 28,800/28,200 seconds. CLI address space was 160 GiB;
Python used 160 GiB except SageAttention's 640 GiB.

| Original IDs | CLI RSS GiB | Python RSS GiB |
| --- | ---: | ---: |
| W01–W21, W25–W26 | 64 | 32 |
| W24 | 64 | 320 |
| W23 | 64 | 48 |
| W22 | 64 | 48 |
| W27–W28 | 64 | 48 |
| W29–W30 | 64 | 72 |
| W31–W32 | 64 | 64 |

The final graph replay used 64 GiB RSS, 160 GiB address space and 3,600/3,500
wall/CPU seconds per case, with four concurrent cases. A limit or incomplete
result fails a gate; these budgets are not architecture exclusions.

## Workflow and physical validation

The final rebuilt Python suite passes all 109 tests. The complete Rust run
covers CLI parse/analyze/verify/compare, launch/ABI paths, expression and VC
export/replay, repeated equivalence settings, complete output handling and
deliberate refutations. Expression/VC replay retains its equivalence-only scope.
The 37 CPU driver controls, 55 parity metadata controls and 18 external harness
controls pass. Formatting, whitespace, exact compiler regeneration, assembler
controls and the static 32-case/185-mnemonic/497-profile drift check pass.
Workspace Clippy succeeds with existing style warnings.

Real Chromium opens all 130 mixed PTX/gfx942/gfx950/gfx1250 records with zero
console/page errors, including new count positives, typed failures, deadlocks
and unsupported boundaries. Separate navigation covers the six original full
matrix traces, two typed memory failures, original atomic/F16/FP8 source links
and actual count2/count1 event metadata/source links. Display bounds remain
independent of complete safety and mathematical proof scopes.

The unchanged full PTX workload run reproduces 24 race-free, 2 racy and 6
unsupported outcomes. Its nonzero aggregate exit is expected and is recorded
separately from native acceptance. The inherited aligned-barrier visit-ordinal
defect was fixed without changing its original regression fixture.

The separate physical gate is coordinator-reviewed outside the repository.
Reproduction uses exact unchanged assembly and the guarded original,
convolution, matrix and advanced runners in [`../full/hardware`](../full/hardware),
plus the independent matrix, mechanism-lifetime and safe signal-count drivers.
These retain original dtype storage, complete projections/supersets, independent
CPU formulas, asymmetric/edge/basis inputs, output sentinels, unchanged inputs,
allocation guards and output gaps. Only safe positives are eligible for hardware
execution. Physical agreement supplements symbolic proofs.

## Public-information cleanup

The gfx942, gfx950 and gfx1250 evidence directories and inline device-run
receipts were removed from current source. Compiler provenance retains public
tool/source/assembly facts without machine hostnames. Current issue/PR text was
audited and recorded gfx1250 device identities were redacted. Generated run
artifacts and device identities stay outside the repository.

This cleanup covers current published contents. Prior commits/branches and
GitHub edit history can retain earlier versions; history was not rewritten.
