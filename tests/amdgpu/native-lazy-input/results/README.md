# Native demand-input materialization results

The fixed five-pair CPU-only WSL2 study passed its predeclared functional, performance and semantic gates.
The three predeclared wide primaries had 3 benefit-gate wins. All 27 cases appear below, including every regression. These are descriptive results from five processes per arm, including the first.

The candidate median was slower in 14 of 27 cases. Hazard endpoints are parent-observed first validated-certificate rejection; safe endpoints are parent-observed process completion. RSS is the maximum of all five processes. JSON/CSV preserve unrounded values; only this table rounds for reading.

| Case | Baseline ms | Candidate ms | Change | Baseline/candidate | Max RSS KiB baseline/candidate | Within allowances |
|---|---:|---:|---:|---:|---:|---|
| `memory-wide-gfx1250-matvec_f16-inserted-collision` | 52.440 | 24.905 | -52.51% | 2.11× | 20224/7936 | yes |
| `memory-gfx1250-attention-safe` | 18.106 | 19.598 | +8.24% | 0.92× | 7936/7936 | yes |
| `memory-gfx950-attention-safe` | 16.785 | 17.506 | +4.30% | 0.96× | 7680/7424 | yes |
| `memory-gfx1250-reduction-safe` | 16.728 | 15.000 | -10.33% | 1.12× | 7168/7168 | yes |
| `memory-gfx1250-gemm-address-alias` | 19.641 | 19.208 | -2.21% | 1.02× | 7424/7424 | yes |
| `memory-wide-gfx1250-convolution_f16_original-inserted-collision` | 89.173 | 33.284 | -62.67% | 2.68× | 34304/8704 | yes |
| `memory-gfx1250-gemm-safe` | 16.440 | 17.617 | +7.16% | 0.93× | 7424/7424 | yes |
| `memory-gfx950-reduction-safe` | 15.296 | 15.527 | +1.51% | 0.99× | 7168/7168 | yes |
| `memory-gfx950-gemm-address-alias` | 15.973 | 17.408 | +8.99% | 0.92× | 7424/7424 | yes |
| `memory-gfx950-attention-address-alias` | 18.555 | 17.172 | -7.45% | 1.08× | 7424/7424 | yes |
| `memory-gfx950-elementwise-address-alias` | 14.930 | 17.789 | +19.15% | 0.84× | 7168/7168 | yes |
| `memory-gfx950-elementwise-safe` | 14.321 | 15.037 | +5.00% | 0.95× | 7168/7168 | yes |
| `memory-wide-gfx1250-flash_attention_original-full-query-safe` | 11977.684 | 11861.575 | -0.97% | 1.01× | 1.12807e+06/1.12736e+06 | yes |
| `memory-gfx1250-normalization-safe` | 21.296 | 21.804 | +2.38% | 0.98× | 7680/7680 | yes |
| `memory-gfx1250-elementwise-address-alias` | 14.525 | 14.427 | -0.67% | 1.01× | 7168/7168 | yes |
| `memory-gfx1250-elementwise-safe` | 16.597 | 15.849 | -4.51% | 1.05× | 7168/7168 | yes |
| `memory-gfx950-normalization-safe` | 17.521 | 19.765 | +12.81% | 0.89× | 7680/7680 | yes |
| `memory-wide-gfx1250-gemm_f16-full-input-inserted-collision` | 9551.380 | 193.530 | -97.97% | 49.35× | 3.15288e+06/21252 | yes |
| `memory-gfx1250-reduction-address-alias` | 15.693 | 15.025 | -4.26% | 1.04× | 7168/7168 | yes |
| `memory-gfx950-reduction-address-alias` | 14.367 | 14.294 | -0.51% | 1.01× | 7168/7168 | yes |
| `memory-gfx950-gemm-safe` | 16.907 | 17.087 | +1.06% | 0.99× | 7168/7168 | yes |
| `memory-gfx950-normalization-address-alias` | 21.140 | 22.326 | +5.61% | 0.95× | 7680/7680 | yes |
| `memory-wide-gfx1250-flash_attention_original-full-query-inserted-collision` | 59.460 | 26.968 | -54.64% | 2.20× | 26624/8448 | yes |
| `memory-wide-gfx1250-matvec_f16-safe` | 1078.802 | 1154.194 | +6.99% | 0.93× | 118352/121936 | yes |
| `memory-wide-gfx1250-convolution_f16_original-safe` | 8819.592 | 8393.858 | -4.83% | 1.05× | 479484/476476 | yes |
| `memory-gfx1250-normalization-address-alias` | 24.166 | 25.068 | +3.73% | 0.96× | 7680/7680 | yes |
| `memory-gfx1250-attention-address-alias` | 17.909 | 19.904 | +11.13% | 0.90× | 7424/7680 | yes |

Safe matvec was slower by +6.99% (+75.39 ms). This remains visible even when inside the predeclared 10% + 2 ms allowance.

gfx950 elementwise hazard was slower by +19.15% (+2.86 ms). This remains visible even when inside the predeclared 10% + 2 ms allowance.

The publication retains all 56 qualification outcomes, 270 paired observations (14 hazardous and 13 safe configurations) and 52 separate semantic/specification controls. Both full-input GEMM safe qualifications timed out and supplied no paired ratio, export or proof.
All 26 full export records remain. 13 of 13 exact-coordinate rooted DAG maps matched modulo node numbering, covering 25,080 selected outputs per arm. Retention of all 11 previous complete equation proofs: true. The four retained specification attempts for the same two previously unproved equations (convolution and attention), in the two arms, remain listed individually. Structural equality is not a mathematical proof. Export/specification timings supply no performance claim.

The full-A/B GEMM inserted-collision case is nonprimary. It retains its new full allocation contract and source-grounded certificate; the improvement does not constitute new algorithmic bug-detection coverage. The old attention-prefix and GEMM-prefix studies remain unchanged. See [protocol](../protocol.md) and [collection](../collection.md) for selection, thresholds and process controls.

`metadata.json` contains declared allocations, selected workgroup/output coordinates, source/module/spec/config/build/binary/tool hashes, per-observation transcript hashes and redacted-diagnostic identity hashes. `observations.csv` contains the same 378 individual records; `case-summaries.csv` contains all 27 descriptive medians/maxima/gates. Commands and private local roots are omitted. Bound inputs use `repo/`, `builds/` and `launches/` aliases; other inputs retain an opaque alias and content hash. Raw reports and full gzip payloads remain retained locally.

[Independent audit bindings](audit.json) retain the raw receipt hashes, check/error counts and script identities without private paths or free-form context.

Recalculate the published numbers without private raw files:

```sh
python3 tests/amdgpu/native-lazy-input/publication.py --check-public tests/amdgpu/native-lazy-input/results/metadata.json
```

For each case/arm, take the median of all five `endpoint_seconds` values and the maximum `usage.max_rss_kib`. The benefit gate requires at least two of three primary medians to improve by at least 20% and 5 ms. Every eligible case must satisfy candidate median ≤ baseline × 1.10 + 2 ms and candidate maximum RSS ≤ baseline + max(5%, 8192 KiB). All observations, including the first, enter these formulas. `--check-public` verifies the public sibling hashes, recomputes these formulas and checks all 27 rows; it runs no verifier.

Reproduce the projection from the named immutable raw inputs (replace `RAW` with local archived paths):

```sh
python3 tests/amdgpu/native-lazy-input/publication.py \
  --baseline-plan RAW/baseline-plan/plan.json \
  --comparison-plan RAW/comparison/plan.json \
  --baseline-qualification RAW/baseline-qualification/report.json \
  --candidate-qualification RAW/comparison/candidate-qualification/report.json \
  --paired RAW/comparison/paired/report.json \
  --semantics RAW/comparison/semantics/report.json \
  --output PUBLICATION
```

The projection command accepts only the six archived report identities recorded in its source; it does not accept newly repeated measurements. Include one `--audit NAME=SHA256=RAW_RECEIPT` per entry in `audit.json` to reproduce those audit bindings. Repeating the study uses the separate protocol/collection commands and creates new raw results; recalculating public arithmetic needs only the public metadata/CSV. The raw source/build association remains caller-attested; no GPU execution, phase CPU attribution, confidence interval or universal speed claim is inferred.
