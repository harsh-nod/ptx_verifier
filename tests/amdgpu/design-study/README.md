# AMD safety measurement protocol

This study measures safety diagnostics for explicitly configured compiler kernels
and harmful source mutations. Its unit is a **kernel configuration**, and its
latency endpoint is the **first independently justified finding**. It does not
measure enumeration of every bug site. Full graph verification and complete
mathematical equivalence remain necessary for acceptance.

`cases.json` fixes sources, hashes, launches, complete output indices, expectations,
mutation locations and typed properties before measurement. The 77 configurations
contain 71 development configurations (45 safe and 26 hazardous) and six heldouts
(two safe and four hazardous). The additional six compiler-corpus hazards span
elementwise, reduction, normalization, transpose, GEMM and attention computations;
they retain the complete registered kernels, specifications and output sets.
They are exploratory family coverage. The three primary latency cases remain
the copy, original F16 ReLU and original F16 RMSNorm missing-KM-wait mutations.
The original F16 workloads retain their original shapes and storage widths.

Ground truth comes from mathematical specifications, pinned source/test assertions
and the target's completion rules, not from observed verifier verdicts. New
compiler-corpus hazards bind the scalar-load producer, removed completion wait
and consuming instruction separately. LLVM MC acceptance only establishes legal
assembly. Mutants are never executed on GPUs. The heldout invalid-access mutation
may produce a conservative refusal rather than a typed finding; that remains a
miss, with its actual outcome reported.

## Reproduction

Run the host refusal and bookkeeping controls first:

```sh
python3 tests/amdgpu/design-study/test_benchmark.py -v
```

A controlled comparison requires a baseline built from the declared common
parent and a candidate descended from that parent. Both must include the same
unrelated semantic, compiler-coverage and quality fixes. Freeze the implementation
and measurement choices before running heldouts. The driver checks ancestry,
records the source diff, executable hashes and harness hashes, and saves commands
and sample order. Revision arguments are build provenance supplied by the caller;
an executable hash alone does not prove which source built it.

```sh
python3 tests/amdgpu/design-study/benchmark.py \
  --baseline /path/to/frozen/baseline-volta --baseline-revision COMMON_PARENT \
  --candidate /path/to/frozen/candidate-volta --candidate-revision CANDIDATE_COMMIT \
  --common-parent COMMON_PARENT --split development \
  --output /tmp/amd-readiness-development \
  --repeats 31 --timeout 60 --seed 20261030
```

The candidate enables early readiness only for gfx1250. PTX, gfx942 and gfx950
run in their ordinary mode as unchanged-backend controls. For config-backed
launches, the driver writes a temporary JSON preserving every original field
except `early_readiness=true`; both original and derived hashes are retained.
It does not combine the conflicting `--config` and `--early-readiness` flags.

The driver also runs the candidate with early readiness disabled. This control
compares the baseline's ordinary diagnostics, rendered witnesses, instruction
count and exact exported expression hash. CLI diagnostics display a bounded
number of witnesses plus remaining counts; separate Rust controls check full
multi-finding retention. The two-property mutation requires both readiness and
memory-conflict failures in the baseline and candidate-off runs. Candidate-on
may stop after its first certified readiness witness.

Timed hazardous runs omit optional expression export in both variants; both keep
`--print-outputs 0`. This avoids charging full-output serialization only to the
baseline. Separate untimed baseline-off and candidate-off runs export expressions
for the invariance check. Timed safe runs retain identical exports to check their
complete coordinate sets. Graph acceptance of a hazardous configuration still
counts as false acceptance when expression export was intentionally omitted.

After the source and binary freeze, the six heldouts require a distinct fresh
output directory and `--frozen-mechanism` equal to the full candidate commit:

```sh
python3 tests/amdgpu/design-study/benchmark.py \
  --baseline /path/to/frozen/baseline-volta --baseline-revision COMMON_PARENT \
  --candidate /path/to/frozen/candidate-volta --candidate-revision CANDIDATE_COMMIT \
  --common-parent COMMON_PARENT --frozen-mechanism CANDIDATE_COMMIT \
  --split heldout --output /tmp/amd-readiness-heldout \
  --repeats 31 --timeout 60 --seed 20261030
```

Heldout hazards cover wrong-counter, tensor-source lifetime and tensor-bounds
mutations. Matched safe exchange/tensor configurations use fresh disjoint global
array bases. These are heldout mutation/configuration checks, not unseen-family
coverage. Their results must not select or tune the mechanism. A later mechanism
revision requires new heldout evaluation.

Single-binary exploration uses `--binary PATH --revision COMMIT` instead of the
paired arguments. It cannot run heldouts or establish comparative gains. `--case`
can select registered development IDs for a smoke check. Raw stdout, stderr,
mutants, launch JSON, expression artifacts and process records remain outside
the repository; the output directory must not already exist.

## Outcome and mathematical controls

Ordinary native detection requires a passing trace contract, supported overall
rejection, the expected typed property failure and exit status 1. PTX controls
likewise require ordinary supported rejection. Generic observer-stopped prefixes,
unsupported instructions, UNKNOWN, timeouts, crashes, stderr-only failures and
unrelated diagnostics never count as detections.

Certified prefix detection is a separate route. It requires exactly one
`EARLY_READINESS: CERTIFIED_REJECTION` marker, the readiness property failure,
a typed scalar `AmdRegisterHazard` with `ReadBeforeReady`, overall `VERDICT: REJECT`
and exit status 1. The pinned CLI emits this route only after the pipeline's
independent certificate validator succeeds. It does not assert a completed trace,
complete outputs or mathematical equivalence. Marker-only logs are refused.

Safe graph acceptance requires every configured absolute output coordinate, exact
per-array coverage and passing graph checks. Untimed preflight additionally proves
the complete mathematical specification before timing. Every baseline proof must
remain proved in candidate-on and candidate-off; every common-supported safe case
needs all three proofs. Unknown, unsupported or timed-out preflights cannot be
silently substituted for equivalence. Separate native and PTX mathematical
mismatch controls change only the specification and require all configured
outputs to be refuted while graph checks pass.

Reports retain all configuration outcomes and repeated-sample denominators,
including unsupported, unknown, timeout, crash, missed hazards, safe false
positives and hazard false acceptances. Typed invalid-access refusals have a
separate count. Common-supported safety execution requires a verified safe case
or a supported/certified expected hazard; conclusive diagnostic counts are shown
separately. A refusal does not become supported execution coverage.

## Timing, resources and comparison gates

Each sample starts a fresh verifier, graph and solver state. Specification
preflight is untimed. The first measured process per case is reported separately
from 31 subsequent samples. Later processes may reuse operating-system file
caches but share no verifier process state. These measurements do not claim
machine-cold caches or in-process warmth.

Cases run sequentially in a seed-fixed shuffled order each round. Baseline and
candidate run next to each other in randomized A/B or B/A order for each case.
Record competing CPU activity; exploration during unrelated builds does not
establish a gain. Time to detection ends when the parent observes the first
streamed expected-property failure or validated prefix marker. It includes
startup, scheduling and output delivery, and is not an internal discovery clock.
The report records CPU model, available CPU count, runtime versions and load
averages before preflight and each round. These observations help interpret load;
they do not identify every competing process or establish CPU isolation.

Process wall time is separate from detection latency. Timed-out process durations
remain observed censored durations, never invented completion or detection times.
Summaries report repeated-process medians and nearest-rank p95, with the first
sample excluded. Detection latency covers detected configurations only, with
misses and timeouts retained beside it. Printed execution time has millisecond
precision. GNU `time` supplies each analyze process's maximum RSS and CPU time;
peak RSS is not attributed to internal phases. Missing resource observations
invalidate resource comparisons. No constant-memory bound is assumed.

Per-case uncertainty uses a deterministic 2,000-resample paired bootstrap of the
candidate/baseline ratio of medians and a 95% percentile interval. It is a
descriptive estimate, not a soundness theorem or a population guarantee. Report
ties, regressions, unsupported outcomes and all predeclared primary cases, not
only favorable intervals. Additional family cases cannot replace the primary
latency selection after results are known.

Adoption requires preserved baseline detections, no new safe false positives or
hazard false acceptances, supported coverage, candidate-off invariance and full
mathematical controls. Each common-supported safe case must satisfy all three
resource/overhead bounds: median at most baseline × 1.05 + 1 ms; p95 at most
baseline × 1.10 + 1 ms; maximum RSS increase at most the larger of 5% and 8 MiB.
At least one predeclared primary case must retain all repeated detections and
have its detection-latency ratio interval wholly below 1. These are engineering
gates; an unsuccessful result remains reportable.

## Method boundaries

The [original Volta paper](https://arxiv.org/html/2511.12638v1) proves results for
its formal structured-CTA model and real-valued expression domain. Those results
do not automatically establish AMD instruction or graph-checker soundness.
[AI as a Compiler, Appendix B](https://arxiv.org/html/2609.36800v1) leaves
soundness/completeness of its asynchronous and modern-architecture extensions
unproved. This study measures implementation behavior within explicit target
profiles; it supplies neither a new theorem nor complete ISA coverage.

The ordinary implementation generates symbolic outputs and an event graph, then
independently checks target contracts, completion, publication and conflicts.
The optional mechanism independently certifies a bounded scalar-readiness
rejection from an instruction-complete prefix. It never accepts a prefix or
discharges unrelated unresolved obligations.
