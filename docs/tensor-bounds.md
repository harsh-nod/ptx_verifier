# Tensor LDS bounds rejection

Native gfx1250 analysis can certify that a supported attempted tensor transfer
exceeds the workgroup's configured LDS extent. The transfer is not issued and
produces no memory effects or outputs. Its ordinary `GraphReport` remains
`UNKNOWN` because execution aborted. A separate independently validated prefix
result supplies the rejection.

For source `analyze`, `verify` and `compare`, the CLI prints
`TENSOR_BOUNDS: CERTIFIED_REJECTION`, a typed `TensorBoundsViolation`, and
`VERDICT: REJECT`, then exits 1. This route does not require `--early-readiness`.
It cannot produce acceptance or an equivalence result. Python raises
`TensorBoundsError`, a `VoltaError` subclass, with `event`, `wave`, `address`,
`bytes`, `configured_lds_bytes`, `access` and prefix-size attributes. It returns
no output object.

## Contract and scope

The shared descriptor decoder covers plain non-padded 2D transfers between
global memory and LDS, with 1-, 2- or 4-byte elements. It excludes multicast,
atomic barriers, iteration, gather, padding and OOB-fill modes. The semantic
basis is the pinned public [LLVM DMA contract](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUDMAOperations.md)
and [FlyDSL descriptor recipe](https://github.com/ROCm/FlyDSL/blob/f37f7a2b98f295902240f9f96612222003578b40/python/flydsl/expr/rocdl/tdm_ops.py).

For this profile, the contiguous LDS interval starts at D0's LDS byte address
and has `rows * columns * element_bytes` bytes. Arithmetic is checked. Its end
must not exceed the descriptor's static LDS allocation plus configured dynamic
LDS bytes. An interval ending exactly at that limit is valid. These allocation
values are frontend/caller premises, not inferred source object boundaries or
a claim that hardware raises a particular exception.

The producer records captured D0–D3 words and scalar tuple roles in an appended
`TensorAccessFault` event. This event is distinct from `MemoryIssue` and has no
memory-effect associations. `ConfiguredLdsBytes` preserves the execution's LDS
extent in provenance. Existing event variants retain their ordering and fields.

The checker independently verifies:

- The exact target, selected workgroup, source identities, fault record and
  prefix sizes match the untrusted certificate.
- The fault belongs to the active terminal tensor instruction with the recorded
  scalar source tuples; the descriptor is supported and predicate-enabled.
- Exactly one valid configured LDS extent exists, consistent with any supplied
  LDS object layout, and the decoded interval exceeds it.
- Prefix structure, instruction/effect contracts, register readiness and barrier
  reachability pass. Unscheduled other waves do not imply completed execution.
- The terminal is the matching typed error abort, with no later instruction or
  successful transfer effects.

The frontend remains trusted to capture concrete descriptor values and source
roles. Replay does not independently decode raw assembly or prove that arbitrary
fabricated provenance represents a real execution. Stale or malformed
certificates, pending descriptor loads, disabled EXEC/predicates, unsupported
descriptors and unrelated errors do not acquire this rejection authority.

`tensor_bounds_candidate` only identifies an untrusted candidate;
`validate_tensor_bounds_prefix` replays it. Only the pipeline constructs the
private `CertifiedTensorBounds` result after validation. Ordinary graph checking
and generic aborted traces do not promote a bounds error by matching text.

This route currently diagnoses configured LDS extent violations in that tensor
profile. Global allocation errors and source subobject errors still use their
existing conservative handling. It does not establish general memory safety.

## Functional comparison

The [recorded comparison](../tests/gfx1250/results/tensor-bounds-20261031.json)
uses the same compiler assembly, launch and complete specification in both
versions. Each harmful case changes only the first transfer's LDS start to 256;
the attempted interval is `[256,512)` against 256 configured bytes.

| Control | Earlier version (`e239cfc`) | Bounds checker |
| --- | --- | --- |
| Original kernel, all 128 specification elements | Accept | Accept |
| Seeded load overrun | Unknown | Certified rejection |
| Seeded store overrun | Unknown | Certified rejection |
| Unsupported descriptor | Unknown | Unknown |
| Pending descriptor load | Unknown | Unknown |
| Transfer under empty EXEC | Unknown | Unknown |

This is two seeded hazards in one kernel, with three refusal controls and one
complete positive control. It measures functional detection only. The frozen
77-configuration study retains its historical 29/30 result; these controls do
not establish a new full-suite detection rate, speedup or comparison against
upstream Volta.

A [separate hardened recheck](../tests/gfx1250/results/tensor-bounds-recheck-summary-20261031.json)
repeated all 12 process invocations twice and retained the same outcomes and
source/binary contracts. The original receipt is unchanged. The
[new receipt](../tests/gfx1250/results/tensor-bounds-20261031-recheck.json) includes
the validated build records and stdout/stderr hashes; the normalized
[baseline](../tests/gfx1250/results/tensor-bounds-baseline-build-20261031.json) and
[candidate](../tests/gfx1250/results/tensor-bounds-candidate-build-20261031.json)
build records are also available separately. Diagnostic hashes can vary between
runs because the CLI prints elapsed times; this comparison checks outcomes and
input identities, with no latency claim.

Reproduce with binaries built from the receipt's two source revisions:

```sh
python3 tests/gfx1250/measure_tensor_bounds.py \
  --baseline /tmp/baseline-volta --baseline-revision e239cfc \
  --baseline-build-record /tmp/baseline-build-normalized.json \
  --candidate /tmp/candidate-volta --candidate-revision CANDIDATE_REVISION \
  --candidate-build-record /tmp/candidate-build-normalized.json \
  --output /tmp/tensor-bounds-comparison.json
```

The script snapshots the source, specification and harness before execution,
uses one frozen specification in both versions, and checks their stability,
executables and build records before and after each invocation. It records
stdout/stderr hashes, requires exact overall outcomes and full specification
counts, and refuses to overwrite results. Its checks remain active under Python
optimization. All variants run in the CPU verifier.

Each normalized build record has `schema_version: 1`, `trust: "caller_attested"`,
the full `revision`, `source_clean: true`, `binary_sha256`, and a
`rust_workspace_fingerprint`. It also records `profile: "release"`, `features: []`,
`default_features: true`, the exact command
`["cargo", "build", "--release", "-p", "volta_cli"]`, and nonempty `rustc` and
`cargo` version strings. Empty features here means Cargo's default feature set.
Preserve the original build record when normalizing it; these fields describe
the actual build, rather than authorizing a revision label for another binary.

Print the fingerprint for a revision without running the comparison:

```sh
python3 tests/gfx1250/measure_tensor_bounds.py --fingerprint-revision e239cfc
```

`rust_workspace_fingerprint` is that command's complete JSON object. It hashes
the NUL-delimited `git ls-tree -rz --full-tree REV -- crates Cargo.toml Cargo.lock
rust-toolchain rust-toolchain.toml .cargo` output. This tracked Rust workspace
superset includes embedded viewer assets, tests and crate documentation; it is
not a claim to capture every external build dependency. The script independently
compares the declared revision, executable hash, workspace fingerprint and
fixture bytes. The build record remains a caller attestation, not an independent
proof that those source bytes produced the binary. The original recorded
comparison used the earlier helper; a hardened recheck has its own receipt and
does not rewrite that historical data or the frozen study.

## Reproduction

The compiler-generated [tensor roundtrip fixture](../tests/gfx1250/fixtures/native-tensor-roundtrip.hip)
copies two 64-float stages through a 256-byte LDS tile. Its original transfer
ends exactly at the allocation limit and retains all 128 output coordinates.
Create a CPU-only harmful assembly variant outside the repository:

```sh
python3 - <<'PY'
from pathlib import Path
source = Path("tests/gfx1250/fixtures/native-tensor-roundtrip.s").read_text()
instruction = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]"
assert instruction in source
Path("/tmp/tensor-bounds.s").write_text(source.replace(
    instruction, "s_mov_b32 s5, 256\n\t" + instruction, 1))
PY
target/release/volta analyze /tmp/tensor-bounds.s \
  --backend amdgpu --target gfx1250 --kernel tensor_roundtrip --block 64 \
  --array x:65536:4:128:in --array out:131072:4:128:out \
  --param ptr:x --param ptr:out
```

The attempted LDS write is `[256,512)` against a 256-byte extent. Do not execute
the harmful variant on a GPU. The analogous store mutation changes D0's LDS
word `s17` before the first `tensor_store_from_lds`; it diagnoses a read of the
same invalid interval.

Focused regression commands:

```sh
cargo test -p volta_graph_check --test tensor_bounds_prefix
cargo test -p volta_pipeline --test gfx1250_tensor_bounds_tests
cargo test -p volta_cli --test tensor_bounds_tests
```
