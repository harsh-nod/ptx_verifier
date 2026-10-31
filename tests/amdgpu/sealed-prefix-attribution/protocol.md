# Prefix-validation phase attribution

This instrumentation-only experiment attributes the existing opt-in ON mechanism
at `f0ee44285286aa1ea92f3e99aed6574ad89f3c82`. It does not implement suspension,
change certificate validation, add a public verifier option, or establish a new
performance result. The original executable and published study remain unchanged.
Collection requires completed code/protocol review and an explicitly idle host.

`selection.json` freezes 26 existing configurations: ten portable late hazards,
three qualified early inserted-store primaries, and their thirteen original safe
controls. It binds the original 46-case manifest and reviewed raw ON reports.
The three qualified primaries are matvec, convolution and attention. The five
cost-gate cases are the previously slower gfx950 normalization/GEMM and gfx1250
normalization/GEMM/attention cases. All exclusions are listed before collection;
there are no new heldouts or substitutions in this attribution stage.

## Measurements

The separate release instrumentation build enables a private pipeline recorder
only through `VOLTA_STAGE_A_PHASES`, which names a fresh outside-repository file.
No source instruction, graph record, certificate premise or verifier decision
uses that recorder. File-write failure leaves an invalid/missing measurement,
without altering functional stdout, stderr or exit status. The runner rejects
that measurement. There are no corresponding production API changes.

The five phase counters are exclusive wall-clock nanoseconds:

- `discovery`: the two existing checker observers' candidate discovery calls;
- `live_prefix_validation`: independent validation before the callback stops;
- `final_prefix_validation`: repeated independent validation after native return;
- `final_ordinary_graph`: the existing final ordinary `check_graph` call;
- `remaining_execution_output`: the rest of pipeline-managed analysis, including
  lowering/setup, execution, graph construction, output extraction/normalization
  and any unchanged auxiliary result handling.

Nested scopes subtract each child's inclusive time exactly once. The recorded
exclusive sum must equal the outer pipeline span; invalid nesting or arithmetic
cannot become zero-cost data. Instrumentation bookkeeping, startup, parsing,
configuration loading, CLI rendering/export and scheduling outside this span are
not falsely assigned to a checker phase. The runner separately retains parent
wall time and its unassigned remainder. No CPU, RSS-per-phase or asymptotic claim
is made. The observation/write overhead is part of the instrumented process;
these observations cannot replace published uninstrumented latency samples.

Run exactly five sequential fresh processes for every selected configuration,
with fixed seed 20261031 and 60 seconds per process. There is one instrumented ON
arm, not a paired speed comparison. No retries, adaptive repetitions, discarded
samples, builds, concurrent profiling or GPU execution occur during collection.
Keep every process result, failed measurement and timed-out stage. Outcomes,
normalized complete diagnostics, instruction/prefix counts and the exact first
typed witness must match the archived immutable ON authority. The safe controls
retain their complete actual expression exports, coordinates and bytes. A safe
control whose archived complete equation was unproved remains unproved; analyzing
it for attribution does not create a mathematical proof.

## Fixed gate

For each of the five declared gate cases, use all five repetitions. A case meets
the cost gate only if `median(final_prefix_validation_ns) >= 1,000,000` and
`median(final_prefix_validation_ns / parent_prediagnostic_wall_ns) >= 0.15`.
The parent endpoint is reception of the first certified marker, credited only
when the final strict certificate outcome and matching witness validate. This
is a per-sample phase share, not an arm ratio or a ratio of separately pooled
medians. At least three of the five cases must meet both conditions. Any missing,
invalid or behavior-changing observation fails that case instead of removing it.
Safe controls use full process completion as their endpoint, including expression
export; their endpoint is not described as a finding or pre-diagnostic latency.
Failure stops the suspension proposal. A pass requires a separate ownership and
terminal-transition design review before any production implementation.

## Preparation and collection

`prepare` performs only source/artifact validation and writes a frozen plan; it
never invokes the verifier. `collect` is a distinct explicit action, used only
after review and idle clearance. Both require strict caller-attested release
build records. The current-ON binary is identified by its immutable hash, not a
fresh rebuild. The instrumentation build's exact committed diff, Rust tree,
executable, compiler/tool identities, runner, selection and raw reference hashes
are retained. Paths and raw logs stay outside public metadata.
