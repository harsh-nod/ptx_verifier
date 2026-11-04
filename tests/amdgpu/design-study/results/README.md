# Early-readiness results

Certified early rejection reduced the time to the first scalar-readiness finding
on gfx1250 while preserving the baseline's supported detections. It does not add
bug coverage or improve every workload. Full execution and graph/specification
checks remain required for acceptance; the option defaults to false.

## Frozen comparison

The baseline is this fork's ordinary full-trace implementation at
`56ac7a4dae734e4719a7692e7dc9ca538b4cca17`; the candidate is
`498644439df19839d4f7fb2ab0a80b58b73b7da2` with early readiness enabled only for
gfx1250. Both include the same unrelated semantic, compiler-coverage and quality
fixes. These are not performance measurements of upstream Volta.

Both clean binaries use Rust 1.97.1, the release profile and default features.
Measurements ran sequentially on CPU-only x86_64 WSL2 with 32 allowed logical
CPUs. No GPU was used for these measurements. Pairs were adjacent with randomized
A/B order; each invocation started a fresh process after untimed complete-spec
preflight. OS file caches could remain warm. No CPU affinity or exclusive CPU
isolation is claimed. Load observations are included in metadata.

Latency ends when the parent observes the first printed justified diagnostic; it
includes startup, scheduling and output delivery, not just the internal checker.
Timing hazardous runs omitted optional expression serialization for both versions;
separate default-off controls compared complete expression bytes and diagnostics.
Safe runs retained identical exports and all configured output coordinates.

## Detection latency

The following medians use the single confirmatory development run: 255 matched
repeated process observations per configuration, excluding the separately reported
first invocation. Bootstrap intervals use 2,000 paired resamples of the ratio of
medians. The three primary cases were selected before measurement.

| Missing-wait configuration | Baseline median (ms) | Early median (ms) | Speedup | 95% interval, early / baseline |
| --- | ---: | ---: | ---: | ---: |
| Copy | 7.580 | 7.085 | 1.07× | [0.915, 0.955] |
| Original F16 ReLU, N=1024 | 16.153 | 12.835 | 1.26× | [0.781, 0.810] |
| Original F16 RMSNorm, N=4096 | 51.901 | 16.065 | 3.23× | [0.301, 0.318] |

The corresponding executed-instruction counts fell from 75 to 34 for copy,
116 to 49 for ReLU, and 2,464 to 257 for RMSNorm. This supports the intended
mechanism: skip the suffix after a certified unsafe read. It is not an attribution
of CPU or memory cost to individual internal phases.

Six additional complete compiler-kernel configurations provide exploratory family
coverage. Each mutation removes its initial scalar-load completion wait; source,
producer and unsafe-consumer pins remain in the manifest.

| Missing-wait configuration | Baseline median (ms) | Early median (ms) | Speedup | 95% interval, early / baseline |
| --- | ---: | ---: | ---: | ---: |
| Elementwise | 14.449 | 14.256 | 1.01× | [0.967, 1.004] |
| Reduction | 14.984 | 14.377 | 1.04× | [0.942, 0.973] |
| Normalization | 18.868 | 14.534 | 1.30× | [0.757, 0.783] |
| Transpose | 7.722 | 7.352 | 1.05× | [0.938, 0.973] |
| Gemm | 16.438 | 14.566 | 1.13× | [0.867, 0.904] |
| Attention | 17.423 | 14.769 | 1.18× | [0.835, 0.868] |

Five family intervals are below 1; elementwise is inconclusive. These exploratory
cases cannot replace the predeclared primary cases. Intervals are descriptive
per-case estimates, with no simultaneous-coverage or serial-dependence guarantee.

## Detection coverage and outcomes

The unit is a kernel configuration, not a distinct algorithm or every bug site.
The frozen suite has 77 configurations: 47 safe and 30 seeded hazards. It covers
PTX and gfx942/gfx950 controls as well as gfx1250 scalar, matrix, exchange and
tensor kernels. Early stopping applies only to gfx1250 scalar-load readiness;
other properties keep their ordinary full-trace checks.

| Dataset | Configurations (safe / hazard) | Repeats per configuration per version | Repeated hazard detections, each version | Safe per-case limits |
| --- | ---: | ---: | ---: | --- |
| Initial development | 45 / 26 | 31 | 806 / 806 | GEMM p95 failed |
| Confirmatory development | 45 / 26 | 255 | 6,630 / 6,630 | All passed |
| Heldout | 2 / 4 | 31 | 93 / 124 | All passed |
| Independent heldout rerun | 2 / 4 | 31 | 93 / 124 | All passed |

Across the distinct configurations, both versions detect 29 of 30 seeded hazards.
The tensor-LDS-bounds mutation remains `UNKNOWN` with “tensor footprint exceeds
LDS capacity” in both versions: a missed intended finding, never a detection or
unsafe acceptance. Thus common-supported coverage is 76 of 77. The heldout wrong
DS counter, wrong tensor-load counter and missing tensor-store completion cases
are detected on every repeat in both runs; their properties are outside the early
observer's scope. The two heldout safe configurations pass on every repeat.
Heldouts test reserved mutations/configurations, not unseen algorithm families.

All 47 safe configurations retain complete mathematical specification proofs in
baseline, candidate-on and candidate-off controls. No safe false positives,
hazard false acceptances, timeouts, crashes or resource-observation errors occur
in any dataset. All default-off controls preserve ordinary diagnostics,
instruction counts and available output-expression hashes, including the absence
of outputs for aborted runs. Native/PTX wrong-spec
controls still refute their complete output sets. A combined two-property hazard
retains both property failures with early readiness disabled; early mode promises
only its first certified readiness finding, not every bug site.

The development confirmation passes the complete adoption predicate. Both heldout
reports pass correctness/overhead checks but record `adoption_gates_pass=false`:
that full predicate also requires a predeclared primary latency case, and the
heldout split contains none. The bounds miss is explicitly retained in coverage.

## Safe-case overhead and uncertainty

Each common-supported safe configuration must satisfy these unchanged limits:
median wall time <= baseline × 1.05 + 1 ms; empirical p95 <= baseline × 1.10 +
1 ms; maximum RSS increase <= max(5% of baseline, 8 MiB). RSS maxima include the
first invocation; timing medians/p95 exclude it. All 45 development safe cases
in confirmation and both safe heldout cases in both runs meet these point limits.

The initial 31-repeat run failed one limit: safe GEMM p95 rose from 22.329 to
26.620 ms, exceeding its 25.562 ms allowance. Before opening heldouts, exactly
one confirmation was declared with unchanged binaries, all 71 development cases,
255 repeats and seed 20261031. No observations were removed, no cases retried
selectively and no runs pooled. At 255 samples, nearest-rank p95 is the 13th-largest
observation, compared with the second-largest at 31 samples. Confirmation's GEMM
p95 was 22.180 versus 23.234 ms, below its 25.398 ms allowance. The initial failed
run remains fully published.

Among the 45 confirmation safe configurations, the largest relative median
increase was 3.54%, largest relative p95 increase 6.42%, and largest absolute RSS
increase 256 KiB. Those percentages are not maxima over the heldout runs: in the
independent heldout exchange control, p95 rose 16.62%, from 9.930 to 11.581 ms,
still below the explicit 11.923 ms allowance because the gate includes 1 ms.

The [safe p95-margin intervals](safe-p95-intervals.json) retain descriptive paired
bootstrap estimates for every confirmation safe case. Forty-four intervals lie
below zero; one crosses zero (safe original ReLU); none lies wholly above zero.
GEMM's margin is −2.163 ms with interval [−4.028, −1.407] ms; ReLU's is −1.873 ms
with interval [−3.341, +1.007] ms. These are uncertainty estimates, not replacement
gates or a uniform statistical guarantee that safe overhead is always bounded.

## Data and reproduction

- [summary.json](summary.json) preserves the full unrounded per-case decisions,
  classifications, first/repeated statistics and ratio intervals for all four
  datasets, kept separate.
- [samples.csv.gz](samples.csv.gz) preserves every timed first/repeated observation
  and untimed full-spec, mathematical-mismatch and default-off control. Values
  retain round-trip binary64 precision: seconds for times, KiB for RSS, integers
  for instructions. JSON structures, booleans and null use JSON within CSV;
  unavailable control metrics have empty cells.
- [metadata.json](metadata.json) pins source/spec/assembly/launch/ground-truth files,
  materialized mutations, executables, build settings, driver, raw reports and
  published artifacts. Source-to-binary revisions are recorded build declarations,
  not a reproducible-build proof. The embedded manifest's historical
  `baseline_source_revision` identifies its initial corpus snapshot; the actual
  comparison revisions are in `builds` and each dataset's `source_comparison`.
- [safe-p95-intervals.json](safe-p95-intervals.json) records all 45 descriptive
  margin intervals and their report/postprocessor hashes.

Use the [measurement protocol](../README.md) and frozen candidate revision for
reproduction. `benchmark.py` records full reports; `publish.py` checks their
identities/completeness and exports numbers without rerunning measurements;
`safe_overhead.py` computes the descriptive p95 margins. The presentation README
and additional p95 artifact are added after export, with their final hashes in
metadata. Raw logs and local host/device identities remain outside Git.

Read the observations with standard Python:

```python
import csv
import gzip

with gzip.open("samples.csv.gz", "rt", encoding="utf-8", newline="") as stream:
    rows = list(csv.DictReader(stream))
```

Group timed observations by dataset/case/variant. `repeat=0` and `phase=first`
identify the separate first invocation; medians/p95 use `phase=repeated` only.
The median is the middle value (or mean of two middle values); nearest-rank p95
is `sorted(values)[ceil(.95 * len(values)) - 1]`. Detection statistics use only
observed detections, with misses reported beside their original denominator;
never replace an absent endpoint with zero or a timeout budget. `ordinal`
preserves original within-phase order. The frozen driver's 2,000-resample paired
ratio bootstrap uses seed 20261030, independently of the execution-order seed.

Exports use deterministic gzip (`mtime=0`, no filename header). Absolute local
paths become placeholders; reconstruct commands from pinned sources/launches.
Diagnostic hashes and classifications remain, while nonallowlisted free-form
text is omitted. Printed execution time is millisecond-quantized and GNU-time CPU
values centisecond-quantized. Whole-process RSS is not assigned to internal phases.
The exported observations and all four raw reports were independently compared;
heldouts were also independently rerun against the same frozen binaries.
