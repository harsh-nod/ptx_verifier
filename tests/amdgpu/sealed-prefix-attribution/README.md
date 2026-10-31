# Prefix replay attribution

This experiment tested whether repeated final certificate validation was costly
enough to justify a suspension API. **None of the five predeclared target cases
met the cost gate**, so the proposal stopped before production implementation.
All 26 configurations ran five times, with no retries or substitutions.

The [results](results/README.md) publish all 130 observations and all phase
distributions, plus the independent raw-data audit. The five target cases spent
5.06%–9.67% of parent-observed wall time in final validation, below the required
15%. These are instrumented phase measurements; they establish no speedup or
phase CPU attribution. Eleven safe controls retain their earlier full equations;
two remain unproved.

The [measured source and protocol](https://github.com/harsh-nod/ptx_verifier/tree/4be3a57f7493271d635f9e9399dd1998c1c4ce49/tests/amdgpu/sealed-prefix-attribution)
are retained on a separate experiment branch. Production main has no profiling
hooks or new execution API from this experiment. The earlier memory-conflict
study and its results remain unchanged.

Regenerate the public projection from the exact retained artifacts:

```sh
python3 tests/amdgpu/sealed-prefix-attribution/publish.py \
  --plan /path/to/plan.json --report /path/to/report.json \
  --patch /path/to/instrumentation.patch --selection /path/to/selection.json \
  --protocol /path/to/protocol.md \
  --audit tests/amdgpu/sealed-prefix-attribution/results/independent-audit.json \
  --output-dir tests/amdgpu/sealed-prefix-attribution/results --check
```
