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
