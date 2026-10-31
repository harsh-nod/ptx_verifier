# Paired measurement protocol

The frozen baseline collector is `study.py` at commit
`42849fdce9932c398858721493e5f99a191e0386`. Its manifest SHA-256 is
`f61df7312961ad8540b34de6f41647df9b165e2ae068dc9a2a25672d90f83886`.
Neither file nor the original qualification artifacts change in this phase.
The [baseline receipt](results/baseline-20261031.json) binds the original report,
100 process records and transcript inventory. A source/binary association uses
an explicitly caller-attested build record; hashes check identity and drift,
not the truth of an asserted build. A printed certificate marker is a signal
from the validated-certificate code path, without cryptographic authentication.

## Fixed populations

Every development functional table retains all 40 configurations: 18 safe
originals, 20 core harmful seeds and two synthetic unsupported-tail stressors.
The six heldouts remain reserved. The commands below never assemble, execute or
sample a heldout. The two tails have a separate denominator and do not establish
algorithm-family coverage. Configurations are not distinct application bug sites.

The original baseline has 17 safe graph/output passes, 15 complete safe proofs,
and 13 typed core rejections. Its inclusive hazard result is 13/22; the core
result is 13/20 and the tails are 0/2. Baseline qualification alone fixes the
**28 statistical cases: 15 safe and 13 hazards**. Candidate failures fail the
corresponding obligation; they do not remove it from this population.

Three of four original-shape inserted-store primaries qualify: matvec,
convolution and attention. GEMM's 60-second baseline timeout remains a failed
primary without a ratio or replacement, even if the candidate finds its conflict.
Every unqualified configuration retains its fixed-budget functional outcome and
observed/censored runtime. An UNKNOWN, Unsupported or timeout has no baseline
finding time. Newly certified coverage receives an absolute observed diagnostic
time, never an invented speedup relative to an undefined baseline endpoint.

## Functional preflight

`benchmark.py prepare` checks the immutable baseline report and transcript
inventory, source ancestry from `0e634bc43536e5e4ac5cb13e8046d8e1edd57250`,
release/default-feature build records and input hashes. The candidate mechanism
must already be frozen and reviewed. All original source, assembly, specification,
launch dimensions, selected group, dtypes and output views remain fixed.

Run candidate OFF and ON on all 40 development configurations. Each stage retains
its 60-second budget. Every safe original also receives a full, unsampled
specification check in both modes. The two independent wrong-equation controls
must still refute all 64 expected elements in both modes. For config-backed
launches, ON derives an outside-repository JSON differing only by
`early_memory_conflicts: true`; the incompatible CLI launch flag is not added.

Default-OFF controls compare actual diagnostics, executed instruction counts,
expression bytes and exported coordinate counts with baseline OFF. Baseline safe
exports are reused from the immutable qualification. Baseline hazard exports
have separate untimed controls, including unqualified cases where feasible.
Hazard exports may be incomplete because of their faulty address; exact equality
with that same fault is an invariance check, not a complete correct-output proof.
For safe controls, every configured absolute output coordinate must occur exactly
once. A timeout transcript is resource-censored and is not required to equal
another timeout's partial log. A non-timeout OFF mismatch remains a failed control.

An ordinary detection requires the complete native property set, typed WriteWrite
witness, overall graph rejection and exit 1. A certified prefix requires the exact
`EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION` marker, certified memory property
FAIL, typed WriteWrite witness with distinct events, REJECT/exit 1, and no output
or equivalence success. FAIL plus overall UNKNOWN, an unsupported suffix, a marker
without its witness, a process error or an invalid option is not a detection.
The marker's first observation counts only after this final validation.

## Paired timing

Only after functional review, final source/binary freeze and an idle CPU, run
`benchmark.py compare`. Use the unchanged manifest seed **20261031**, **31 repeated
fresh processes per arm** plus a separate first process, and **60 seconds per
stage**. Case order is shuffled per round; baseline/candidate are adjacent with
randomized arm order. No parallel builds, measurements, profiles or GPU runs.
There is no adaptive retry, sample exclusion, selective repetition, changed budget,
changed expectation or post-outcome primary substitution. Both arms use identical
launch options apart from the opt-in. First samples are reported separately from
OS-warm repeats; no cold-cache claim, cache flush or affinity modification.

Timed hazards omit optional expression export and use `--print-outputs 0` in both
arms. Default-mode expression/diagnostic invariance uses separate untimed exports.
Timed safe runs retain identical export work in both arms. Wall time ends before
post-run output validation or deletion. Parent streaming records first ordinary
property FAIL or certified marker reception, and counts it only after the final
strict outcome check. This is parent-observed diagnostic latency, not an internal
checker timestamp. GNU time records per-process peak RSS, user and system CPU.
The entire wrapper/verifier process group is killed on timeout. Missing resource
or instruction observations fail the measurement rather than become zero cost.

### Exact-duplicate export retention

This policy is fixed before any paired run to bound disk use without weakening
output checks. Retain one **full** preflight expression reference for each safe
case and role. Every timed safe export must have the full unique coordinate set
and **exact byte SHA-256, size and coordinate digest** of its retained role's
reference. Record the observation and reference identity beside every sample.
Only after all checks succeed may that temporary exact duplicate be removed.
Never remove unmatched, malformed, incomplete or otherwise nonqualifying exports.
Retain every raw process log, command, return code, resource record and digest,
including first samples and failures. Rehash retained references and all bound
inputs throughout and after collection. The original baseline artifacts are
always retained untouched.

## Summaries and gates

Use repeated-sample medians and nearest-rank p95, without pooling first samples.
Descriptive paired bootstrap median-ratio intervals use 2,000 resamples and the
fixed seed. Report every successful comparison and failed baseline-fixed
qualifier together. A late-store tie or slowdown stays in the table.

For every qualified safe case, candidate median process time must be at most
baseline ×1.05 +1 ms, p95 at most baseline ×1.10 +1 ms, and peak RSS at most baseline
plus the larger of 5% or 8 MiB. Candidate proof/output retention and OFF invariance
are independent requirements. An unproved baseline safe case cannot establish a
safe-proof, overhead or false-positive guarantee for that configuration.

Adoption also needs zero false positive/unsafe acceptance observations, all
baseline-qualified outcomes retained, the mathematical negative controls, and
**genuinely additional certified coverage** over baseline UNKNOWN/Unsupported/
timeout in at least four frozen manifest family identities, including two
original-shape complex families. Report all certified families separately;
accelerating an already detected case does not count as new coverage. Synthetic
tails never enter either algorithm-family count. Statistical latency claims use
only successful baseline-qualified comparisons; new coverage has no baseline
ratio. Primary latency changes and the failed GEMM primary remain explicit.

Runtime summaries can include Python/tool versions, CPU architecture/model,
logical/allowed CPU counts, scheduling policy and load observations. Raw host,
device, socket identities and absolute artifact paths remain outside published
data. Neither RSS observations nor instruction-local certificates imply a
constant-memory observer or full verification of an aborted prefix.

## Collection commands

All paths below are fresh outside-repository artifact locations. Use complete
reviewed revisions and strict build records; do not rebuild implicitly.

```sh
python3 tests/amdgpu/memory-conflicts-study/benchmark.py check
python3 tests/amdgpu/memory-conflicts-study/test_benchmark.py -v
python3 -O tests/amdgpu/memory-conflicts-study/test_benchmark.py -v

python3 tests/amdgpu/memory-conflicts-study/benchmark.py prepare \
  --baseline-report /tmp/memory-baseline/report.json \
  --baseline-binary /tmp/frozen/baseline-volta \
  --baseline-build-record /tmp/frozen/baseline-build.json \
  --candidate-binary /tmp/frozen/candidate-volta \
  --candidate-build-record /tmp/frozen/candidate-build.json \
  --candidate-revision FULL_CANDIDATE_REVISION \
  --output /tmp/memory-paired-preflight

python3 tests/amdgpu/memory-conflicts-study/benchmark.py compare \
  --baseline-report /tmp/memory-baseline/report.json \
  --baseline-binary /tmp/frozen/baseline-volta \
  --baseline-build-record /tmp/frozen/baseline-build.json \
  --candidate-binary /tmp/frozen/candidate-volta \
  --candidate-build-record /tmp/frozen/candidate-build.json \
  --candidate-revision FULL_CANDIDATE_REVISION \
  --preflight /tmp/memory-paired-preflight/report.json \
  --preflight-sha256 REVIEWED_PREFLIGHT_SHA256 \
  --output /tmp/memory-paired-development
```

A separate authorization and frozen-mechanism record is required before any
heldout collection; this driver intentionally provides no heldout command.
