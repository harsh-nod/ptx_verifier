# AMD kernel qualification replay

This study compares native AMD semantic coverage against fork revision
`8a4b2bc2` (#144). It reuses the retained process observer and artifact auditor
from the [trace-cost study](../trace-cost-study), with a separate frozen
selection, protocol and results. Historical studies remain unchanged.

The denominator is 26 configurations: 13 safe kernels and 13 seeded scalar
readiness hazards across gfx942, gfx950 and gfx1250. Existing algorithms and
previously examined sources are reused. Four runtime-parameterized copy/add
parents use complete 259-thread launches at disjoint addresses above 8 GiB;
fixed original programs retain their full registered dimensions and outputs.
The gfx950 reduction's registered workgroup adds the first 256 of its 4,096
declared inputs to its initial output; it does not cover a whole-grid reduction.
The [manifest](cases.json) binds source, assembly, specifications, launch
contracts and each mutation's producer/wait/use anchors. This is a development
replay, with no unseen-algorithm or newly discovered application-bug claim.

Safe qualification requires complete graph checks, every configured output
coordinate and a `--sample 0` specification proof. A seeded hazard counts only
with a completed trace and its intended typed `ReadBeforeReady` witness. The
witness must bind the exact producer/use lines, instructions, event IDs and
shared scalar register word; unrelated readiness findings do not count.
Unsupported, incomplete and failed executions stay in the denominator.

The [protocol](protocol.json) specifies a separate first observation and 31
randomized adjacent pairs for baseline-qualified cases. Newly qualified cases
receive a separate first observation and 31 candidate-only observations; they
have no baseline latency ratio. Safe timing measures full analysis, while
qualification separately runs the full specification proof. Hazard timing uses
the parent observer's first readiness-failure banner time, conditional on the
subsequent intended witness. It does not time the rendering of that witness.
All first/repeated failures are kept.

The diagnostic comparison removes only execution/solver clock values and
artifact destinations. Instruction counts, output counts, checks, witnesses
and verdicts remain exact. The coverage/resource gate requires all candidate
cases to qualify, retains every baseline result, and applies the declared
latency/RSS limits. A coverage gain does not establish a speedup. Bootstrap
intervals are pointwise with no multiple-comparison correction; shared-host
measurements retain their environmental limits.

## Run and audit

Use clean release builds with matching default features and toolchains. Build
declarations bind source revisions/trees, cleanliness and binary hashes; they
are caller attestations. Keep declarations, plans and raw artifacts outside
the checkout. Run from the repository root:

```sh
python3 tests/amdgpu/kernel-qualification-study/run.py prepare --output /tmp/qualification-plan
python3 tests/amdgpu/kernel-qualification-study/run.py qualify \
  --plan /tmp/qualification-plan/plan.json --plan-sha256 "$PLAN_SHA256" \
  --role baseline --binary /tmp/baseline/volta --build /tmp/baseline/build.json \
  --output /tmp/qualification-baseline
```

Repeat qualification with `--role candidate` and its own binary, declaration
and fresh output directory. Then use `collect --baseline REPORT --candidate
REPORT --output DIRECTORY`, passing the same plan and its hash. Stop builds,
tests and other worker activity before collection. `audit --report REPORT`
reconstructs classifications, source identities, schedules, resource values
and statistics from the retained artifacts.

`publish --report REPORT --independent-audit RECEIPT --output DIRECTORY`
requires a separate numerical audit bound to the raw report. It emits only
machine-neutral result fields and compressed samples. Independently check
the published projection and README numbers before committing them.

```sh
python3 -m unittest discover -s tests/amdgpu/kernel-qualification-study -p 'test_*.py'
```
