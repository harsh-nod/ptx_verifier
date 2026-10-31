# Paired and one-off collection

The frozen `collect.py`, protocol, selection and initial baseline report stay
unchanged. `comparison.py prepare` runs no verifier: it checks that baseline,
attested candidate build and reviewed exact source patch, then records the fixed
27-case, five-pair schedule (270 processes), all28 candidate qualification command,
and13 safe cases with one export and one full specification per arm (52 processes).
Candidate qualification cannot change timing eligibility. Every first observation,
timeout, failed witness, refused process and storage failure remains a record.
No warmup, outlier removal, extra repetition or substituted case is permitted.

Preparation requires explicit baseline-plan/report and candidate binary/build/
revision/patch arguments. It emits `plan.json`, `candidate.patch`, and the exact
`candidate_qualification_command`. Review the new code and plan before running
that command. Review its all28-case report before running:

```sh
python3 comparison.py pairs --plan STUDY/plan.json \
  --reviewed-plan-sha256 PLAN_SHA \
  --candidate-qualification STUDY/candidate-qualification/report.json \
  --candidate-qualification-sha256 QUALIFICATION_SHA
python3 semantics.py --plan STUDY/plan.json \
  --reviewed-plan-sha256 PLAN_SHA \
  --candidate-qualification STUDY/candidate-qualification/report.json \
  --candidate-qualification-sha256 QUALIFICATION_SHA
```

Both output directories must be new. Timed pairs omit exports/specifications.
Their parent-observed endpoints and `/usr/bin/time` CPU/RSS use the frozen helpers.
All five observations, including the first, enter the descriptive point gates.
The comparison report records performance gates separately from semantic approval.

One-off expression capture uses a pre-opened FIFO reader and deterministic
level1 gzip, mtime0 and empty filename. It never creates an intermediate raw
expression file. Every gzip byte counts against a shared2GiB cap; every write
checks a2GiB free-space reserve. Reader/child failure, timeout or budget exhaustion
retains an explicitly incomplete artifact and supplies no semantic credit. The
FIFO alone is removed after the reader and child finish. Complete captures bind
stored gzip hashes and received uncompressed byte counts/hashes; incomplete
received-byte statistics do not claim that a complete raw expression was retained.

The hash-pinned structural scanner checks every independently expected output
coordinate and typed rooted operation, modulo node IDs/construction order. It
performs no algebraic rewriting and does not create a mathematical proof. All26
safe export captures must be complete and their13 rooted maps match. Eleven
previously proved full equations must still pass for both arms. The other
convolution/attention specification outcomes, including60-second misses, remain
explicitly unproved. The baseline-unqualified full-GEMM safe case gets no paired
ratio or unbounded export attempt; its candidate functional result is still kept.

The semantic report contains no performance claim from gzip, expression parsing,
full-specification unfolding or auditing. Full native graph/event/dirty-footprint
invariants are additionally checked by the independently reviewed eager/lazy
execution tests; matching real-kernel output DAGs alone does not attest raw ISA.

Every one-off safe process must also have zero typed graph findings and zero
unsafe acceptances. In particular, a new graph failure during an unproved
convolution/attention verification is a failed semantic control, not a permitted
specification miss. These gates are independent of the eleven required proofs.
An explicit mathematical refutation also fails the semantic gate, including for
the two previously unproved equations; only genuine unknown/timeouts remain
unproved observations. Expected paired launch/storage errors retain a failed
scheduled row and collection continues through the fixed denominator.
Positive canonical mismatch counts from raw stdout fail this gate even when
only some outputs mismatch and the frozen summary classifier says inconclusive.
The new candidate-report processing also checks canonical graph FAIL properties
in all28 raw qualification transcripts. A readiness/barrier/trace failure in the
baseline-unqualified safe GEMM remains an explicit failed functional control,
even when the frozen qualification status is inconclusive rather than a WW finding.

The independently reviewed comparator and its22 synthetic groups are copied
byte-identically as `compare_vexpr_structure_20261031.py` and its test file. Their
frozen source hashes remain unchanged. Run finite host controls with:

```sh
python3 -m unittest discover -s tests/amdgpu/native-lazy-input -p 'test_*.py'
python3 -O -m unittest discover -s tests/amdgpu/native-lazy-input -p 'test_*.py'
```
