# Instruction-local memory-conflict study

`cases.json` binds complete compiler modules, original launch contracts and
mathematical specifications to ordinary GLOBAL/direct-DS write/write seeds for
gfx950 and gfx1250. It registers 40 development configurations and six heldouts.
The six portable families are elementwise, reduction, normalization, GEMM,
attention and unsigned-16 transpose. The larger native originals retain K4096
matvec/GEMM, 1024-key attention, K576 convolution, 1024-output ReLU and
4096-output RMS normalization. These are selected-workgroup contracts; every
original output view, storage width, absolute coordinate and full specification
is retained.

Each harmful seed has a source-derived finite input valuation with different
bytes in the actual overlapping interval. Those valuations establish a possible
harmful conflict; they do not assert that every input makes the writes unequal.
The four latency primaries insert one ordinary DS store immediately after a
valid initializing store in the original matvec, GEMM, attention and convolution
kernels. They reuse an allocated, defined zero-address VGPR without changing the
original held address/data registers, EXEC, source math, waits or initialization.
Address-replacement seeds can leave later reads uninitialized and have a separate
category. Two synthetic runtime-unsupported tails are explicit backend stressors,
not additional original application bugs. Equal-value HipKittens conflicts do
not count as these different-value algorithm cases.

## Check the source contracts

```sh
python3 tests/amdgpu/memory-conflicts-study/study.py check
python3 tests/amdgpu/memory-conflicts-study/test_study.py -v
```

These commands validate all source/config/specification and mutation pins without
executing the verifier, assembler or GPU. Mutation anchors must belong to the
selected entry in the complete module. Four primary IDs and six heldout IDs are
fixed in the validator. The partial-overlap holdout compares the intersecting
bytes, not merely different whole words.

## Collect a baseline qualification

```sh
python3 tests/amdgpu/memory-conflicts-study/study.py baseline \
  --binary /tmp/frozen/baseline-volta --revision FULL_SOURCE_COMMIT \
  --build-record /tmp/frozen/baseline-build.json \
  --output /tmp/memory-conflicts-baseline
```

Use a fresh output directory outside the repository. The build record uses the
caller-attested release/default-feature schema checked by
[`measure_tensor_bounds.py`](../../gfx1250/measure_tensor_bounds.py): it binds the
binary hash, source revision, Rust workspace fingerprint, profile and tools.
This is an attestation, not an independent proof of how the binary was built.
The collector snapshots its helpers, rehashes all inputs and never builds or
substitutes the executable.

The collector makes one functional pass over **development only**. It MC-checks
each complete module, analyzes every configuration and checks every safe
specification element without sampling. Safe graph acceptance also needs the
exact exported output coordinates. Wrong-equation controls remain separate from
memory-safety findings. Every stage has the fixed 60-second wall budget; process
errors, timeouts, UNKNOWN and Unsupported remain explicit. The command performs
no heldout subprocesses, including assembler invocations.

The recorded timing protocol uses eligibility fixed **only by baseline
qualification**. A hazard needs a typed, complete property finding; a safe case
needs its complete graph, outputs and mathematical proof. A later candidate
failure fails a gate and is never filtered away. Unqualified configurations stay
in the functional table, including censored runtime and failed primary IDs.
Candidate-only certified findings have absolute observed time and coverage,
without a baseline speedup ratio. Safe cases without a baseline proof cannot
support a safe-proof or overhead guarantee.

Paired timing uses 31 fresh-process repeats, adjacent randomized arms and the
fixed seed/budgets in `cases.json`. First samples remain separate. Median safe
overhead is limited to baseline ×1.05 +1 ms; p95 to ×1.10 +1 ms; RSS increase to
the larger of 5% and 8 MiB. Timed hazards omit optional expression serialization;
full-mode diagnostics and output-expression invariance have separate untimed
controls. No timing result is valid amid concurrent builds. A static instruction
position or unexecuted source suffix is not measured saved work.

A prefix counts only with the exact authenticated marker, typed WriteWrite
witness, explicit rejection/exit1, and no outputs or equivalence. A generic
property FAIL followed by an aborted/UNKNOWN graph is not a detection. Full
graph and mathematical verification remain necessary for acceptance. The earlier
[`design-study`](../design-study/README.md) data and identities are unchanged.

`fixtures/ordinary-analyze.stdout` is a captured ordinary CLI rendering from the
already measured unchanged HipKittens align case. Its conservative same-value
conflicts calibrate the six-space diagnostic format only; they are not one of
this study's different-value seeds or new findings. Certificate diagnostics have
a separate strict grammar. The regression refuses a marker without its typed
witness and ordinary FAIL diagnostics whose overall graph remains UNKNOWN.
