# Native register-storage measurements

Prospective configurations of existing compiler programs; seeded scalar-readiness hazards, not newly discovered application bugs or unseen algorithms.

Baseline `b2f9aff43c1fd5b4b549000eb7df1956603c22fe`; candidate `b2ad063c623f01ec5718668dc74449c855642a32`.

26 configurations; 24 baseline-qualified configurations timed with 1536 observations. First observations are retained separately from the 31 repeated pairs.

Hazard rows measure the parent's first observation of the intended finding; safe rows measure process completion. Ratio is candidate / baseline; smaller values are faster. Peak RSS is the maximum over repeated observations.

| Case | Baseline / candidate median (ms) | Baseline / candidate p95 (ms) | Ratio [pointwise 95% interval] | Baseline / candidate peak RSS (KiB) |
| --- | ---: | ---: | ---: | ---: |
| gfx942-copy-197 | 11.585 / 11.174 | 13.312 / 13.077 | 0.965 [0.926, 1.026] | 6656 / 6656 |
| gfx942-copy-197-missing-scalar-wait | 9.990 / 10.065 | 11.249 / 12.597 | 1.007 [0.976, 1.042] | 6656 / 6656 |
| gfx942-add-197 | 11.841 / 12.047 | 14.320 / 14.621 | 1.017 [0.957, 1.059] | 6656 / 6656 |
| gfx942-add-197-missing-scalar-wait | 10.069 / 10.025 | 11.204 / 11.472 | 0.996 [0.957, 1.054] | 6656 / 6656 |
| gfx950-copy-197 | 11.219 / 11.269 | 13.015 / 12.657 | 1.004 [0.963, 1.057] | 6656 / 6656 |
| gfx950-copy-197-missing-scalar-wait | 9.918 / 9.926 | 11.785 / 11.243 | 1.001 [0.947, 1.038] | 6656 / 6656 |
| gfx950-add-197 | 12.062 / 12.105 | 14.718 / 15.351 | 1.004 [0.969, 1.076] | 6656 / 6656 |
| gfx950-add-197-missing-scalar-wait | 10.514 / 10.626 | 13.477 / 11.984 | 1.011 [0.971, 1.050] | 6656 / 6656 |
| gfx950-original-silu_f16 | 18.672 / 18.109 | 24.876 / 23.436 | 0.970 [0.922, 1.031] | 7936 / 7936 |
| gfx950-original-silu_f16-missing-scalar-wait | 16.405 / 17.105 | 23.677 / 24.985 | 1.043 [0.946, 1.109] | 7936 / 7936 |
| gfx950-original-rope_f16 | 17.438 / 17.735 | 26.775 / 21.173 | 1.017 [0.943, 1.086] | 7168 / 7168 |
| gfx950-original-rope_f16-missing-scalar-wait | 16.286 / 15.829 | 27.198 / 34.241 | 0.972 [0.914, 1.029] | 7168 / 7168 |
| gfx950-original-matvec_f16 | 516.312 / 389.989 | 605.278 / 472.103 | 0.755 [0.703, 0.778] | 60304 / 59964 |
| gfx950-original-matvec_f16-missing-scalar-wait | 519.462 / 369.916 | 608.350 / 462.258 | 0.712 [0.689, 0.748] | 60308 / 59968 |
| gfx950-original-reduction_f16 | — / — | — / — | — — | — / — |
| gfx950-original-reduction_f16-missing-scalar-wait | — / — | — / — | — — | — / — |
| gfx1250-original-silu_f16 | 18.607 / 18.692 | 23.229 / 21.221 | 1.005 [0.950, 1.060] | 8192 / 8192 |
| gfx1250-original-silu_f16-missing-scalar-wait | 16.283 / 16.739 | 40.549 / 36.462 | 1.028 [0.983, 1.070] | 8192 / 8192 |
| gfx1250-original-rope_f16 | 17.210 / 16.339 | 28.529 / 21.731 | 0.949 [0.907, 1.003] | 7680 / 7680 |
| gfx1250-original-rope_f16-missing-scalar-wait | 15.208 / 15.811 | 18.646 / 20.574 | 1.040 [0.982, 1.098] | 7680 / 7680 |
| gfx1250-original-matvec_f16 | 1285.949 / 1066.450 | 2901.705 / 2100.830 | 0.829 [0.787, 0.871] | 122196 / 122228 |
| gfx1250-original-matvec_f16-missing-scalar-wait | 1220.101 / 991.501 | 1878.611 / 1271.463 | 0.813 [0.785, 0.844] | 123276 / 122628 |
| gfx1250-original-reduction_f16 | 17.982 / 16.379 | 19.729 / 19.561 | 0.911 [0.873, 0.981] | 7424 / 7424 |
| gfx1250-original-reduction_f16-missing-scalar-wait | 15.053 / 14.874 | 23.723 / 18.271 | 0.988 [0.941, 1.051] | 7424 / 7424 |
| gfx942-pipelined-mfma-f16-high-address | 22.502 / 21.390 | 28.552 / 44.776 | 0.951 [0.905, 1.047] | 8704 / 8704 |
| gfx942-pipelined-mfma-f16-high-address-missing-scalar-wait | 21.444 / 18.903 | 31.509 / 21.298 | 0.882 [0.839, 0.949] | 8704 / 8704 |

The full qualification outcomes, diagnostic/output invariants, misses, adoption gates and every numerical observation are retained in [results.json](results.json) and [samples.json.gz](samples.json.gz). The two unsupported reduction configurations are retained above with no ratio. Raw process artifacts and host details remain outside Git.

Predeclared adoption gates: FAIL; the storage candidate remains experimental. See every reason in results.json.

Limitations:

- Single shared virtualized CPU host; unrelated background work remained visible. Physical host isolation and fixed frequency were not attested.
- Randomized adjacent pairs reduce order effects; they do not remove all environmental confounding.
- Intervals are pointwise paired-bootstrap 95% intervals with no multiple-comparison correction.
- The unchanged gfx950 reduction and its mutation both stop at a register-selected lane operation; they remain in the denominator without a timing ratio.
- Performance applies to the named storage-only candidate revision, release toolchain and configured launches, not every kernel or later combined source tree.
- Safe proofs use the existing mathematical model; they do not establish exhaustive hardware floating-point equivalence.
- The independent audit identifies 9 proof-diagnostic flags caused only by retained Exec/VC timing numbers; the recorded gate failures remain unchanged.

Reproduce with the [protocol and commands](../README.md).
