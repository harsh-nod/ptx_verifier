# AMD safety measurement protocol

This study measures graph-based safety diagnostics on explicitly configured
compiler kernels and known harmful mutations. The corpus combines independent
small computations, native LDS/matrix/tensor controls and feasible original
F16 workloads without reducing their shapes, storage widths or output sets.
An untimed preflight separately checks full mathematical specs on safe cases;
its statuses are retained in the report. Timed graph acceptance alone is not a
mathematical-equivalence result.

`cases.json` fixes source hashes, launch configurations, complete output indices,
safe/hazard expectations, mutation locations and required typed properties before
measurement. Existing mathematical specifications and independently written
native regression assertions establish expectations. A scalar destination read
without its completion wait is a register-readiness hazard; a tensor load writes
LDS, so its consumer-before-completion hazard is a memory conflict. Assembly
acceptance alone establishes neither property. Mutants are never run on GPUs.

## Measurements

```sh
python3 tests/amdgpu/design-study/test_benchmark.py -v
python3 tests/amdgpu/design-study/benchmark.py \
  --binary /path/to/frozen/volta --revision SOURCE_COMMIT \
  --output /tmp/amd-safety-baseline --split development \
  --repeats 31 --timeout 60 --seed 20261030
```

Every sample starts a new verifier, graph and solver state. After specification
preflight, the first measured invocation of each case is reported separately.
Later samples may reuse operating-system
file caches but share no verifier process state. These are first-process and
repeated-process measurements, not machine-cold and in-process-warm claims.
Cases run sequentially in a seed-fixed shuffled order on every round. Raw
stdout, stderr, generated mutants, expression artifacts and process records stay
outside the repository. Record competing CPU activity when interpreting timing;
exploratory runs during unrelated builds do not establish performance gains.

Time to detection is elapsed time until the parent observes the first streamed
`FAIL` for the independently required typed property. It includes process
startup, scheduling and output delivery; it does not measure an instrumented
internal first-discovery event. Process completion time is separate. Detection
also requires a passing trace contract and a supported rejected execution.
Unsupported instructions, unknown/inconclusive results, timeouts,
crashes and unrelated diagnostics do not satisfy a hazard expectation. A timeout
is censored, not replaced by an invented latency or counted as a detection.
Safe acceptance requires graph verification and every exact output coordinate.
The report also retains emitted execution time and instruction counts; their
printed precision limits fine-grained phase attribution.

Per-case summaries separate the first process from repeated-process median and
nearest-rank p95. Report repetition counts, verdict variability, detection counts,
safe false positives and hazard false acceptances. A short exploratory repetition
set has insufficient p95 resolution; use the registered larger repeat count for
a controlled comparison. Do not pool targets or families to hide regressions.

## Comparison controls

Build both the baseline and candidate from the same parent containing unrelated
coverage and correctness fixes. Pin both executable hashes, manifests, budgets,
sample order and measurement driver. Alternate/interleave baseline and candidate
runs under comparable CPU load. Attribute only the proposed mechanism's diff to
the comparison; unrelated semantic changes cannot become algorithmic gains.

Separate common-supported safety detection from expanded instruction coverage.
Report unsupported/unknown/timeout/crash counts separately for every variant.
Preserve all baseline detections and safe controls; a faster result that loses
detections or creates false positives is not an improvement. Re-run complete
mathematical controls, since changing safety scheduling must not alter outputs.
Report negative or tied results and uncertainty, without assuming superiority.

Wrong-counter, tensor source-lifetime and tensor-bounds mutations form the held-out
hazards. Matched safe exchange/tensor configurations use fresh disjoint global
array bases. These are held-out mutation/configuration checks, not unseen-family
coverage. Keep their results out of mechanism selection. Freeze the intervention and
all development choices before evaluating held-out mutation classes or new
configurations. Any later revision uses development data only and requires a new
held-out evaluation. Original fixed baseline objects and full-workload contracts
remain unchanged.

## Method boundaries

The [original Volta paper](https://arxiv.org/html/2511.12638v1) proves results for
its formal structured-CTA model and real-valued expression domain. Those results
do not automatically establish AMD instruction or graph-checker soundness.
[AI as a Compiler, Appendix B](https://arxiv.org/html/2609.36800v1) explicitly
leaves soundness/completeness of its asynchronous and modern-architecture
extensions unproved. This study measures implementation behavior within explicit
target profiles; it does not supply a new theorem or complete ISA coverage claim.

The current implementation first generates candidate symbolic outputs and an
event graph, then independently checks the graph's target contracts, completion,
barrier/publication and conflict obligations. Retaining those independent checks,
exact footprints and conservative unsupported boundaries is a requirement for
any proposed acceleration. Measurements must precede a mechanism choice.
