# AMD backend comparison

`compare.py` compares two verifier builds using the same frozen AMD development
configurations from the [safety corpus](../design-study/README.md). It keeps all
67 configurations: 43 safe and 24 with seeded hazards, across gfx942, gfx950 and
gfx1250. These are configurations rather than 67 different algorithms or new
application bugs. The historical assembly, launch shapes, output coordinates and
mathematical specifications remain unchanged. Heldouts are not executed or used
as prospective validation or tuning evidence.

The complete measurement rules are in [protocol.json](protocol.json). A hazard
qualifies only after a complete graph rejects an intended property. Each safe
configuration needs complete output export and a specification proof with
`--sample 0`. Missing checks, duplicate verdicts, unsupported execution, UNKNOWN,
aborted traces and incorrect output coverage cannot qualify.

## Run a comparison

Use Python 3.10 or later, Linux `/usr/bin/time`, Git and two release verifier
binaries. Stop unrelated builds and tests before collecting timings. All output
directories must be fresh and outside the repository. Keep the frozen checkout,
binaries, build records and logs in place until the final audit finishes.

First freeze the source inputs, helpers, protocol and materialized assembly:

```sh
python3 tests/amdgpu/backend-comparison/compare.py prepare --output /tmp/amd-plan
```

Record the printed plan SHA-256. Each binary needs a JSON build declaration with
these fields:

```json
{
  "trust": "caller_attested",
  "source_clean": true,
  "revision": "<full Git commit>",
  "source_tree": "<Git tree hash>",
  "binary_sha256": "<binary SHA-256>",
  "comparison_role": "baseline",
  "profile": "release",
  "default_features": true,
  "features": [],
  "rustc": "<rustc --version>",
  "cargo": "<cargo --version>"
}
```

The baseline tree must equal revision
`d88be6827351de697d7f7ae0ded77ac57ef908e1`; a candidate must descend from that
revision. Compiler versions, profile and feature declarations must match between
arms. Record the actual build command and relevant build environment as extra
fields. An optional `original_build_receipt` must include its SHA-256 in
`original_build_receipt_sha256`. These are caller attestations; hashes bind the
supplied files and do not prove a reproducible build or independently attest a
clock measurement.

Qualify each arm using its own binary, declaration, exact revision and role:

```sh
python3 tests/amdgpu/backend-comparison/compare.py qualify \
  --plan /tmp/amd-plan/plan.json --plan-sha256 PLAN_SHA256 \
  --binary /path/to/baseline/volta --build-record /path/to/baseline/build.json \
  --revision BASELINE_COMMIT --role baseline --output /tmp/amd-baseline
```

Repeat with `--role candidate` and a separate output directory. Qualification
retains every outcome, including failures. Then collect adjacent randomized
pairs, with a separate first-observation round and 31 repeated fresh-process
rounds:

```sh
python3 tests/amdgpu/backend-comparison/compare.py collect \
  --plan /tmp/amd-plan/plan.json --plan-sha256 PLAN_SHA256 \
  --baseline-qualification /tmp/amd-baseline/report.json \
  --candidate-qualification /tmp/amd-candidate/report.json \
  --output /tmp/amd-timing
```

Only baseline qualification selects the timing population. Candidate failures
remain visible and cannot create a speedup by removing cases. A per-case ratio
requires qualification in both arms and all 31 successful, measured repeats in
each arm. Safe timing omits expression export; its complete output and proof
controls are retained separately. Hazard latency is the parent-observed arrival
of an intended diagnostic, validated against the complete final graph. Process
wall time, CPU time, peak RSS, misses and timeouts are retained too. There is no
claim of cold caches, CPU isolation or an improvement before measurement.

## Audit retained results

Both execution commands audit their results automatically. Before publication,
repeat the audit independently:

```sh
python3 tests/amdgpu/backend-comparison/compare.py audit \
  --plan /tmp/amd-plan/plan.json --plan-sha256 PLAN_SHA256 \
  --qualification /tmp/amd-baseline/report.json --role baseline
python3 tests/amdgpu/backend-comparison/compare.py audit-collection \
  --plan /tmp/amd-plan/plan.json --plan-sha256 PLAN_SHA256 \
  --report /tmp/amd-timing/report.json
```

The collection audit checks both qualification reports, full commands, launch
contracts, source and binary hashes, retained transcripts/resources/outputs,
exact pair order and round counts. It recomputes eligibility, medians, p95 and
ratios. Keep raw commands, machine identities and artifacts outside the
repository; publish sanitized numerical results only after audit.

The CPU controls exercise refusal and tamper handling without running a GPU:

```sh
python3 -m unittest discover -s tests/amdgpu/backend-comparison -p 'test_*.py'
python3 -O -m unittest discover -s tests/amdgpu/backend-comparison -p 'test_*.py'
```
