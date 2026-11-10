# Native AMD register-storage study

This study compares the native interpreter's register storage against revision
`b2f9aff43c1fd5b4b549000eb7df1956603c22fe`. The candidate changes storage only;
instruction semantics, trace completion, graph checks and findings must agree.

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

Run refusal controls with:

```sh
python3 -m unittest discover -s tests/amdgpu/trace-cost-study -p 'test_*.py' -v
```
