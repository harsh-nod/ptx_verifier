# Early memory-conflict rejection

Set `early_memory_conflicts` to find an eligible write/write conflict before
executing the rest of a native gfx950 or gfx1250 kernel. This can preserve a
finding that a later unsupported instruction or execution error would otherwise
leave inconclusive. Default execution retains its normal instruction, bounds and
budget checks, which can also stop an incomplete execution.
Every acceptance still requires complete execution and the ordinary safety and
mathematical-output checks.

Use `--early-memory-conflicts` with `analyze`, `verify` or source-based `compare`.
With `--config`, instead add `"early_memory_conflicts": true` to the launch JSON;
launch flags cannot override that file. Rust and Python configuration objects
expose the same option, defaulting to false. PTX, gfx942 and expression-only
replay refuse this option.

## Eligible conflicts

A certificate requires overlapping ordinary writes by two distinct active
physical lanes of the **same issued instruction**, wave and memory space. It
uses recorded byte intervals, including partial overlaps. Global-memory and
direct DS/LDS stores use their existing target-specific contracts. Global here
names the address space: already-supported concrete raw-buffer stores also
qualify through the same ordinary-write semantic classes and producer address
checks. This feature adds no buffer address or descriptor semantics.

Atomics, reductions, tensor transfers, mixed FLAT operations, unsupported or
opaque profiles, cross-instruction conflicts and cross-wave conflicts cannot
use this certificate. Same-value writes remain conflicts under the ordinary
memory policy; their detection alone does not demonstrate an application bug.

## Implementation

[`MemoryConflictObserver`](../crates/volta_graph_check/src/amdgpu/early_memory_conflicts.rs)
consumes only new records after each successful complete instruction batch. It
groups eligible effects by issuer, sorts their intervals and searches for an
overlap between distinct threads. Keeping the two farthest endpoints from
different threads avoids missing overlaps hidden by an intervening same-thread
interval. Discovery takes O(k log k) for k effects in an issue and proposes each
issue's first pair once, including when validation refuses it.

The public `MemoryConflictCertificate` is untrusted. It identifies the exact
provenance, prefix lengths, instruction, issue, wave, threads, effect events and
lowest overlapping byte. `validate_memory_conflict_prefix` first checks graph
structure, then effect and active-lane membership, recorded allocation premises,
and target-selected trace, readiness and barrier checks. Finally it requires
the **exact pair and byte** in the existing memory checker's retained findings.
A missing premise or truncated-away pair causes refusal and ordinary execution
continues; it cannot authorize a rejection.

The two ordinary effects are siblings of one issue. Under the existing memory
model its own completed-operation frontier does not order those siblings; a
future wait cannot repair this conflict. This bounded counterexample permits
stopping without predicting the remaining execution. It supplies no proof for
other conflict classes or a new hardware soundness theorem.

The pipeline validates the live candidate before stopping and replays the exact
halted prefix before constructing its private `CertifiedMemoryConflict` result.
A generic callback stop remains `UNKNOWN`. There is no fabricated end event,
complete output set or equivalence result. Scalar-readiness and memory-conflict
observers maintain separate state when both options are enabled.

## Results and trust

The CLI prints `EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION`, a typed
`WriteWrite` witness, instruction/issue IDs, both physical threads and prefix
counts, then `VERDICT: REJECT` with exit code 1. Python raises
`EarlyMemoryConflictError`, a `DataRaceError` subclass, with the same witness
metadata and no output expressions. Leave the option disabled when later
diagnostics are needed.

The frontend remains responsible for decoding instructions, validating concrete
addresses/descriptors and delivering a complete instruction batch. Graph replay
checks the declared effects and provenance; it does not independently decode
machine bytes or establish every omitted per-lane component count. Existing
legacy graphs without an encoded allocation extent do not acquire one from a
certificate. Native execution's existing allocation preflight remains a premise.

The separate [measurement protocol](../tests/amdgpu/memory-conflicts-study/protocol.md)
defines source-preserving mutations, baseline qualification, heldouts, paired
timings and overhead limits. A baseline UNKNOWN, Unsupported or timeout has no
conclusive finding endpoint, so newly detected cases establish coverage rather
than a speedup ratio.
The [audited results](../tests/amdgpu/memory-conflicts-study/results/README.md)
include coverage gains, early- and late-store timings, safe overhead and misses.

```sh
cargo test -p volta_graph_check --test early_memory_conflicts
cargo test -p volta_pipeline --test early_memory_conflicts_tests
cargo test -p volta_cli --test early_memory_conflicts_tests
```
