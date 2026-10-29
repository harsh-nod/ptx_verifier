# Full-workload CPU proof drivers

These drivers invoke already-built CLI/Python artifacts on complete original
workload shapes. They do not compile assembly or launch a GPU. They snapshot
source/configuration/specification inputs, pin executable/runtime hashes and
check exact per-array output projections.

| Driver | Scope |
| --- | --- |
| `prove_cli.py`, `aggregate_cli.py` | All 32 original CLI graph/spec/numeric cases, optionally split into disjoint groups |
| `prove_matrix.py` | The six full K4096 matrix cases |
| [prove_advanced.py](advanced.md) | Convolution, attention, Sinkhorn and Mamba |
| [prove_python.py, aggregate_python.py](python.md) | Full original cases through the built Python extension |

## Run the CLI

Build a release binary first. The binary and fixture revision arguments must
be full 40-character commit IDs; they are supplied source labels, not inferred
from executable bytes. Keep build information associating the binary hash with
its revision.

```sh
python3 tests/gfx1250/full/cpu/prove_cli.py \
  --binary /path/to/volta --binary-revision BINARY_COMMIT \
  --registry tests/gfx1250/full/cases.json --fixture-revision FIXTURE_COMMIT \
  --kernel relu_f16 --output /tmp/gfx1250-cli-relu
```

Omit `--kernel` for all cases or repeat it for a subset. Every invocation copies
the complete registered input corpus and executable into a fresh snapshot.
Execution is sequential with target gfx1250, exact configured dimensions,
`--sample 0`, `--verify-numeric` and default opcode profiling. For a separately
built logging binary, use `--mode logging` and optionally `--log-level debug`.

Default per-case limits are 384 GiB RSS, 512 GiB address space, 28,200 CPU seconds
and 28,800 wall seconds. Override the resource flags for the host's capacity;
the driver never reduces shapes or storage widths. A timeout, failed graph/math
obligation, Unsupported, Unknown or resource failure cannot pass.

## Aggregate disjoint case groups

A successful subset records `partial`. Aggregate only groups built with the
same binary/source/build profile/runtime and executed under a compatible host
identity:

```sh
python3 tests/gfx1250/full/cpu/aggregate_cli.py \
  --registry tests/gfx1250/full/cases.json \
  --receipt /tmp/gfx1250-cli-group1/receipt.json \
  --receipt /tmp/gfx1250-cli-group2/receipt.json \
  --output /tmp/gfx1250-cli-full32.json
```

The aggregator requires all 32 cases and 395,394 original coordinates. It
rechecks logs, commands, snapshots, resources, all four graph properties,
unsampled VC counts, equivalence, final verdict and process exit. Missing or
duplicate cases, altered per-array index sets, mixed revisions, stale success
files and a nonzero process that prints ACCEPT are rejected.

Run/result files are initialized as incomplete before operational preflight.
Output alias checks prevent overwriting pinned source or proof inputs. Keep
result directories outside the repository and retain their snapshots when
aggregating; a receipt alone cannot replace the referenced artifacts.

## Matrix-only runs

```sh
python3 tests/gfx1250/full/cpu/prove_matrix.py \
  --binary /path/to/volta \
  --fixture-root tests/gfx1250/full --revision BUILD_COMMIT \
  --output /tmp/gfx1250-full-matrix
```

The runner snapshots the CLI, HIP/assembly/configuration/specification files
and resolved runtime libraries. Use `--kernel gemm_f16_full` to select one case,
or omit it for all six. Row projection validation rejects reduced K, missing
rows and remapped pitches. Defaults are 384 GiB RSS, 512 GiB address space,
6,900 CPU seconds and 7,200 wall seconds per case. Linux process-tree monitoring
and GNU time record resources; limits terminate the owned process group.

The drivers cover graph/spec/numeric proofs. CLI parse/export/compare/replay,
browser rendering and numerical GPU checks have separate tests. Host controls
exercise accounting and refusal paths with synthetic inputs:

```sh
python3 -m unittest discover -s tests/gfx1250/full/cpu -p 'test_*.py'
```
