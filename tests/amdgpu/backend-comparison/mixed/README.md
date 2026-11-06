# Mixed-LGKM functional controls

These 26 prospective handwritten configurations test mixed scalar-memory and
LDS completion on gfx942 and gfx950. They are separate from the 67 wide-kernel
comparison. Each target has four safe partial-wait geometries (63, 64, 65 and 128
work items), one safe full-drain control, and eight seeded readiness hazards.

| Observation | Baseline | Candidate |
| --- | ---: | ---: |
| Safe configurations accepted | 2/10 | 10/10 |
| Safe false positives | 8/10 | 0/10 |
| Seeded readiness hazards correctly rejected | 16/16 | 16/16 |
| Complete graph executions | 26/26 | 26/26 |
| Complete identity specifications proved | 26/26 | 26/26 |
| Independently checked output coordinates | 1,792/1,792 | 1,792/1,792 |

[results.json](results.json) retains every case, geometry, mutation, property
verdict and hash. All 26 full graphs and expression exports are identical across
the two arms. The improvement removes eight false-positive configurations;
the seeded-hazard detection count stays unchanged. These controls provide no
latency, hardware-performance or newly discovered application-bug result.

The evaluator transports data eagerly. Graph readiness is checked separately
from the full `out[i] = x[i]` proof. A hazardous control can have correct symbolic
outputs while its graph is rejected. This word-copy experiment does not measure
floating-point rounding or sample numerical inputs. Each result covers the
configured workgroup `(0, 0, 0)` and all of its output coordinates.

## Reproduce

Build `volta_cli` in release mode from baseline commit
`d88be6827351de697d7f7ae0ded77ac57ef908e1` and candidate commit
`2bdedfdec2335e06b9ab3bff3a3a9eb3686ac488`, using separate build directories.
The recorded baseline binary was built at
`ecb09dceef3588cd41a3f48b834a54c9ee739afc`, whose source tree is identical to the
baseline comparison commit. Build receipts are caller attestations; their hashes
do not establish reproducible builds.

From a checkout containing the source commit:

```sh
python3 tests/amdgpu/backend-comparison/mixed/reproduce.py \
  --baseline baseline/volta --candidate candidate/volta \
  --source-root . \
  --source-revision 2bdedfdec2335e06b9ab3bff3a3a9eb3686ac488 \
  --output ../mixed-reproduction
```

The script reads both committed assembly fixtures through Git and checks their
recorded hashes. The output directory must be outside both source and helper
repositories. Before executing either binary, it freezes all 26 complete
assemblies, launch configurations, expected coordinates, identity specifications,
and binary hashes in the new output directory. Each arm runs ordinary complete
analysis and a full specification proof (`--sample 0`), with early options off.
It checks exactly four native graph properties, a completed trace, every output
coordinate, and each unsafe case's expected type and consuming source within the
same finding. Missing/UNKNOWN/aborted results stay in the denominator and fail
qualification. Outputs contain raw local logs and a public-field `results.json`;
process timing is not an endpoint. Binary hashes identify the supplied files;
record their build revisions separately.

Run the CPU checks with:

```sh
python3 -m unittest discover -s tests/amdgpu/backend-comparison/mixed -p 'test_*.py'
```

`export_recorded.py` creates the published explicit-field artifact from the
original external records, verifying source, receipt, report and raw-log hashes
and independently rechecking output, property and same-finding evidence.
