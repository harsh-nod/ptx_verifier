# Early scalar readiness rejection

The normal pipeline executes a candidate kernel, records its event graph, then
checks safety and mathematical outputs independently. This separation keeps an
arithmetic identity from hiding a synchronization defect and preserves all
reported bug sites. See the [architecture guide](architecture.md).

An optional early observer can stop execution after a checker-validated scalar
readiness finding. It changes when a rejection becomes available. It supplies
no acceptance evidence and does not establish the safety or output values of an
unexecuted suffix. Ordinary execution remains the default.

## Supported finding

The observer currently handles gfx1250 `ScalarLoad` destinations and
`ReadBeforeReady` hazards. Scalar loads charge `KM_CNT` and may complete out of
order. A same-wave `KM_CNT=0` wait establishes destination availability;
nonzero waits cannot identify a completed scalar load. Retiring `X_CNT`,
waiting on another counter, another wave's wait, or a barrier cannot substitute
for scalar data completion.

If a recorded instruction reads a scalar destination while that load remains
pending, a later wait cannot repair the earlier use. This makes the existing
readiness counterexample persistent under an execution suffix. The argument is
limited to this wave-local property within the implemented target model; it is
not a proof for arbitrary synchronization, memory publication or ISA behavior.

The public rules used by the existing checker are pinned to LLVM
[`AMDGPUHWEvents.cpp`](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/AMDGPUHWEvents.cpp)
and
[`SIInsertWaitcnts.cpp`](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/SIInsertWaitcnts.cpp),
including scalar completion order and separate data/translation counters.

## Discovery and validation

The APIs live in
[`amdgpu::early_readiness`](../crates/volta_graph_check/src/amdgpu/early_readiness.rs):

- `ScalarReadinessObserver` consumes newly appended records after each complete
  instruction batch: register signature, semantic event and all memory effects.
  It proposes the first scalar-read hazard. The observer is an optimization,
  not a rejection authority.
- `ScalarReadinessCertificate` is an untrusted candidate. It identifies the
  issue, unsafe use, wave and register, plus prefix lengths and graph provenance.
- `validate_scalar_readiness_prefix` independently replays the prefix. It
  checks graph structure, target, instruction/effect roles, counters and barrier
  prerequisites before requiring that exact scalar-read hazard.

The ordinary gfx1250 checker and observer share `ScalarReadinessState` and the
scalar completion predicate. Native execution does not implement a second set
of wait-counter semantics. Register reuse, translation-source lifetimes, other
memory counters and matrix readiness keep their existing full-checker paths.

A prefix may omit waves that have not yet been scheduled because the checked
readiness state is wave-local. This does not relax ordinary full-trace
completeness. The validator accepts a live construction prefix or the explicit
instruction-observer halt, and refuses generic unsupported/error/deadlocked
executions, incomplete batches and mismatched certificates. A generic observer
stop without a validated certificate remains inconclusive.

The integration layer must revalidate the halted graph before exposing a typed
certified rejection. The graph remains an aborted prefix: no `END`, completed
trace, symbolic output set or equivalence result is fabricated. Ordinary graph
serialization carries no trusted early-acceptance marker.

## Trust and diagnostic scope

The frontend and typed interpreter remain responsible for decoding source and
recording its effects. Graph provenance binds the target, launch, selected
workgroup, assumptions and instruction identities/spans. The checker validates
and replays that declared contract; it does not independently decode source
bytes or attest an arbitrarily fabricated whole graph.

Early mode reports the first certified finding and can omit later bug sites.
Use full mode for complete diagnostic enumeration. Every acceptance still needs
a completed execution, all applicable graph checks and complete mathematical
equivalence. PTX, gfx942/gfx950 and other gfx1250 properties retain their normal
checking paths. No general performance improvement follows from this interface;
latency and overhead require controlled measurement on the supported subset.

Independent graph controls are in
[`early_scalar_readiness.rs`](../crates/volta_graph_check/tests/early_scalar_readiness.rs):

```sh
cargo test -p volta_graph_check --test early_scalar_readiness
```
