`prove_cli.py` runs all32 original CLI graph/spec/numeric proofs using the same
strict registration contract as the Python gate. It checks all137 current
source/config/spec/ABI inputs, including original PTX sources/configs and the
original workload configuration code. Every invocation copies the entire input
corpus and executable into a fresh snapshot, even when selecting one case.
Each result retains separate baseline/native per-array index hashes and the
complete projection hash, so counts cannot substitute between arrays or sparse
coordinates. The unchanged CLI verifies the complete native index set internally.

```sh
python3 tests/gfx1250/full/cpu/prove_cli.py \
  --binary /path/to/reviewed/volta --binary-revision BINARY_COMMIT \
  --registry tests/gfx1250/full/cases.json --fixture-revision FIXTURE_COMMIT \
  --kernel relu_f16 --output /tmp/gfx1250-cli-relu
```

Both revisions must be full40-character commit IDs; the binary revision is the
builder's supplied attestation, not inferred from executable bytes. Omit
`--kernel` for all32 cases, or repeat it for a subset. Each selected case runs
sequentially with exact target1250/config/dimensions, `--sample 0`,
`--verify-numeric` and the CLI's default opcode profiling. Default per-case budgets are384GiB RSS,
512GiB address space,28,200 CPU seconds and28,800 wall seconds. Larger workloads
need an adequately provisioned host; the driver never reduces shapes or dtypes.

A successful subset is `partial`. `aggregate_cli.py` accepts disjoint subsets
only when all32/395,394 original coordinates are accounted for under one binary,
source, build profile, runtime and host identity:

```sh
python3 tests/gfx1250/full/cpu/aggregate_cli.py \
  --registry tests/gfx1250/full/cases.json \
  --receipt /tmp/gfx1250-cli-group1/receipt.json \
  --receipt /tmp/gfx1250-cli-group2/receipt.json \
  --output /tmp/gfx1250-cli-full32.json
```

The aggregator inspects actual logs, commands, snapshots and resource files,
requires all four graph checks, exact unsampled VC counts, equivalence and final
ACCEPT, and checks exit status independently of stdout. Missing/duplicate cases,
unknown/unsupported results, altered arrays/index sets, mixed revisions, timeouts,
stale success files and nonzero processes that print ACCEPT fail the gate.
Recorded GNU-time peak RSS must also fit each group's declared budget. Both
drivers invalidate prior success before operational preflight, while refusing
output aliases that would overwrite retained source or proof artifacts.

This gate covers original CLI graph/spec/numeric verification and profiling.
Separate existing tests cover parse/analyze/export/compare/replay and Python
workflows; this gate does not supply those results or hardware validation.
The host tests use clearly labeled synthetic schema controls and produce no
acceptance evidence. Existing matrix/advanced/Python drivers remain unchanged so
their retained historical pins and running jobs stay reproducible.

`prove_matrix.py` runs the six original full K4096 matrix proofs using an
already-built CLI. It never compiles assembly or executes a GPU kernel. A
fresh snapshot pins the binary, assembly, HIP source, full launch configs and
specs by SHA256. `ldd` compatibility and exact resolved runtime hashes are
recorded before execution. The supplied revision labels the builder's binary;
the runner does not infer a source revision from executable bytes.

Run on a CPU host with sufficient RAM, using a reviewed release binary:

```sh
python3 tests/gfx1250/full/cpu/prove_matrix.py \
  --binary /path/to/reviewed/volta \
  --fixture-root tests/gfx1250/full --revision BUILD_COMMIT \
  --output /tmp/gfx1250-full-matrix-default
```

Copy the same runner, frozen fixtures/configs/specs and binary to the remote
CPU host before an SSH invocation. No Rust toolchain is needed there. Start
with `--kernel gemm_f16_full` to measure one complete 65,536-output proof;
the resulting receipt is `partial`, never a six-case pass. Omit `--kernel`
for all six. Repeat with the separately built logging binary and
`--mode logging`; the default logging level is info, with debug available.

Every invocation writes `incomplete` before preflight. A full pass needs exit0,
all four AMD graph checks, `EQUIVALENT`, the exact unsampled VC count and final
`ACCEPT` for every required kernel. The CLI checks each output's complete index
set internally. The runner also validates the original row projections and
rejects reduced K, missing rows or remapped output pitch. SHA checks after each
case detect changes to the frozen inputs or executable.

Execution is sequential, with defaults of 384 GiB RSS, 512 GiB address space,
6,900 CPU seconds and 7,200 wall seconds per case. Linux `/proc` monitors the
process tree's RSS; `/usr/bin/time` records the child peak separately. A timeout,
resource limit, signal, unsupported instruction, failed obligation or stale hash
keeps the receipt incomplete. GPU visibility is empty and viewer exports are
disabled for these memory-intensive proofs. Distinct viewer cases are recorded
separately. The host controls run with:

```sh
python3 -m unittest discover -s tests/gfx1250/full/cpu -p 'test_*.py'
```
