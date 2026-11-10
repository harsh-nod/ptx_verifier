# Native AMD register-storage study

This study compares the native interpreter's register storage against revision
`b2f9aff43c1fd5b4b549000eb7df1956603c22fe`. The candidate changes storage only;
instruction semantics, trace completion, graph checks and findings must agree.
Its [source](https://github.com/harsh-nod/ptx_verifier/tree/experiments/amdgpu-lane-rows-20261110)
replaces per-lane ordered-map lookups with lazily allocated register rows and
explicit undefined lane cells. The [audited result](results/README.md) failed the
predeclared adoption gate, so this candidate remains experimental.

`cases.json` and `protocol.json` define 26 configurations selected before running
the candidate: 13 safe launches and 13 matching scalar-readiness mutations across
gfx942, gfx950 and gfx1250. They cover copy/add, activation, rotary embedding,
matrix-vector multiplication, reduction and a matrix pipeline. These reuse
existing compiler programs with new configurations or previously untimed complete
registered launches. They do not establish unseen-algorithm coverage or newly
discovered application bugs. Mutations run in the CPU verifier only.

Every safe launch needs a complete graph, every declared output coordinate and a
full sample-0 specification proof. Every hazard needs a completed trace and the
intended typed `ReadBeforeReady` finding. Unsupported instructions, incomplete
traces, unknown results, crashes and timeouts remain visible and cannot qualify.
Only baseline qualification selects the timing population. Candidate failures
stay in that population. All 26 qualification outcomes remain in the report.

Each selected case has a separate first observation and 31 randomized adjacent
baseline/candidate pairs. Hazard latency measures the parent's first observation
of the intended finding; safe latency measures process completion. Reports retain
all samples, nearest-rank p95, median, paired-bootstrap 95% ratio intervals and
per-process peak RSS. First observations are excluded from the repeated statistics.
No builds or test jobs should run during collection; host isolation must not be
claimed merely from a low guest load average.

Adoption requires preserved diagnostics, graph dumps and output expressions, no
lost detections or false positives, at least one hazard latency interval wholly
below 1, safe medians within 5% + 1 ms, safe p95 within 10% + 1 ms, and peak-RSS
growth within the larger of 5% or 8 MiB. Every case and regression is reported.

Use fresh external directories for `prepare`, `qualify` and `collect`; retain the
printed plan hash. Both builds need caller-attested clean release declarations
with revision, tree, binary hash, compiler versions and default features. Run
`python3 study.py --help` and each subcommand's `--help` for arguments. `audit`
reconstructs build identities, artifact hashes, classifications, diagnostics,
sample directories, randomized order, statistics and adoption gates. Raw logs,
commands and machine details stay outside the repository. Publish sanitized
results only after a separate reviewer recomputes them. The earlier frozen
studies are historical and remain unchanged.

For example, from this directory, using absolute paths for the binaries and
their build declarations:

```sh
python3 study.py prepare --output /tmp/register-plan
# Set plan_sha to the SHA256 printed by prepare.
python3 study.py qualify --plan /tmp/register-plan/plan.json --plan-sha256 "$plan_sha" \
  --role baseline --binary "$baseline_binary" --build "$baseline_build" --output /tmp/register-baseline
python3 study.py qualify --plan /tmp/register-plan/plan.json --plan-sha256 "$plan_sha" \
  --role candidate --binary "$candidate_binary" --build "$candidate_build" --output /tmp/register-candidate
python3 study.py collect --plan /tmp/register-plan/plan.json --plan-sha256 "$plan_sha" \
  --baseline /tmp/register-baseline/report.json --candidate /tmp/register-candidate/report.json --output /tmp/register-paired
python3 study.py audit --plan /tmp/register-plan/plan.json --plan-sha256 "$plan_sha" \
  --report /tmp/register-paired/report.json
```

`publish.py` requires this audit plus a separate review JSON containing
`status: "AUDITED"`, the exact `report_sha256`, and
`independent_statistics_recomputed: true`. It exports only selected numerical
fields, classifications and hashes; commands, paths, launch receipts and host
details are excluded, including from the first observations. An audit confirms
consistency with retained observations, not the truth of caller build attestations
or physical host isolation.

The frozen collector's recorded adoption field checks repeated observations.
Publication additionally refuses a failed first observation; excluding that round
from latency statistics must not hide a timeout or miss. This extra check does
not revise any recorded timing or statistic.

Run refusal controls with:

```sh
python3 -m unittest discover -s tests/amdgpu/trace-cost-study -p 'test_*.py' -v
```
