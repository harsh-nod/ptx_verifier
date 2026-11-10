# AMD qualification replay results

This frozen development replay compares baseline `8a4b2bc2` with semantic-coverage candidate `e2d10d6a`. It reuses existing compiler programs across gfx942, gfx950 and gfx1250; it establishes neither unseen-algorithm generalization nor newly discovered application bugs.

| Qualification | Baseline | Candidate |
| --- | ---: | ---: |
| Complete safe graph/specification proofs | 12/13 | 13/13 |
| Intended seeded readiness hazards detected | 12/13 | 13/13 |

The additional two qualifications are the unchanged gfx950 reduction workgroup and its seeded missing-scalar-wait variant. The original `block = 128` launch, all 4,096 declared half inputs, in/out float and complete registered specification remain unchanged: this selected tile adds the first 256 inputs to the initial output. It does not prove a 4,096-element whole-grid reduction.

All 1,600 observations are retained: 1,536 paired observations for 24 baseline-qualified cases, plus 64 candidate-only observations for the two newly qualified cases. Each includes a separate first observation and 31 repeated observations. All 50 first observations and 1,550 repeats have valid metrics and their expected result; no timed miss, false positive or timeout occurred. Unsupported baseline cases remain in the 26-case denominator.

The predefined coverage/resource gates pass with zero failures: all candidate cases qualify, baseline results and common output expressions are retained, and all safe latency/RSS limits hold. This is a coverage gain with a small measured cost, not a broad speedup. Of 12 common hazard medians, 2 improve and 10 slow; the median of their candidate/baseline ratios is 1.0094 (0.94% slower). The corresponding median ratio for 12 common safe analyses is 1.0174 (1.74% slower). No hazard has a pointwise 95% paired-bootstrap ratio interval wholly below1; intervals have no multiple-comparison correction.

Safe latency below measures complete analysis; qualification separately proves every sample 0 specification element. Hazard latency is the parent observer's first readiness-failure banner, conditional on the following typed witness matching the exact frozen producer/use locations and register. It does not time witness rendering. Newly qualified cases have no valid baseline latency ratio.

| Case | Expected | Baseline median ms | Candidate median ms | Candidate/baseline |
| --- | --- | ---: | ---: | ---: |
| `gfx942-copy-259` | safe | 11.08 | 11.60 | 1.0471 |
| `gfx942-copy-259` | hazard | 9.73 | 10.06 | 1.0339 |
| `gfx942-add-259` | safe | 12.07 | 12.34 | 1.0219 |
| `gfx942-add-259` | hazard | 10.43 | 10.63 | 1.0194 |
| `gfx950-copy-259` | safe | 10.83 | 11.61 | 1.0719 |
| `gfx950-copy-259` | hazard | 10.13 | 10.08 | 0.9947 |
| `gfx950-add-259` | safe | 12.02 | 11.89 | 0.9895 |
| `gfx950-add-259` | hazard | 10.74 | 10.77 | 1.0028 |
| `gfx950-original-silu_f16` | safe | 18.46 | 17.77 | 0.9626 |
| `gfx950-original-silu_f16` | hazard | 15.77 | 15.94 | 1.0114 |
| `gfx950-original-rope_f16` | safe | 17.35 | 16.76 | 0.9662 |
| `gfx950-original-rope_f16` | hazard | 15.50 | 15.90 | 1.0254 |
| `gfx950-original-matvec_f16` | safe | 500.60 | 494.36 | 0.9875 |
| `gfx950-original-matvec_f16` | hazard | 488.14 | 488.19 | 1.0001 |
| `gfx950-original-reduction_f16` | safe | — | 15.94 | — |
| `gfx950-original-reduction_f16` | hazard | — | 14.72 | — |
| `gfx1250-original-silu_f16` | safe | 17.39 | 18.64 | 1.0718 |
| `gfx1250-original-silu_f16` | hazard | 15.95 | 16.21 | 1.0166 |
| `gfx1250-original-rope_f16` | safe | 16.53 | 16.74 | 1.0128 |
| `gfx1250-original-rope_f16` | hazard | 14.43 | 14.88 | 1.0313 |
| `gfx1250-original-matvec_f16` | safe | 1102.82 | 1091.17 | 0.9894 |
| `gfx1250-original-matvec_f16` | hazard | 1068.80 | 1073.75 | 1.0046 |
| `gfx1250-original-reduction_f16` | safe | 15.64 | 16.07 | 1.0271 |
| `gfx1250-original-reduction_f16` | hazard | 14.68 | 14.79 | 1.0074 |
| `gfx942-pipelined-mfma-f16-high-address` | safe | 21.08 | 22.46 | 1.0657 |
| `gfx942-pipelined-mfma-f16-high-address` | hazard | 20.05 | 19.70 | 0.9826 |

The new reduction analysis median/p95 are 15.94/18.94 ms; its intended hazard median/p95 are 14.72/16.37 ms. These are unpaired candidate-only observations. Full per-case p95, RSS, pointwise intervals, qualifications, gates and source/build hashes are retained in [results.json](results.json); all machine-neutral samples are in [samples.json.gz](samples.json.gz).

Independent recomputation checked 47,307 conditions across 6,789 retained artifacts with zero errors, including source contracts, exact witnesses, randomized schedules, every first/repeated observation, medians, p95, 2,000-draw paired bootstrap intervals and gates. The public result binds the raw report and independent audit hashes.

Limits: one shared CPU host, without fixed-frequency or physical-host isolation attestations. Owned builds, tests and worker activity were paused during timing; unrelated host activity is not controlled. Results apply to the named release revisions/configurations, not arbitrary kernels or later source changes. Mathematical-real proofs do not certify exhaustive physical floating-point behavior or inter-workgroup safety.

See the [frozen protocol](../protocol.json), [complete contracts](../cases.json) and [reproduction/audit instructions](../README.md). Historical studies and the rejected storage experiment remain unchanged.
