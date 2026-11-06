# Full-trace AMD comparison — 2026-11-06

All 67 frozen development configurations qualify in both versions: 43 complete
safe proofs and 24 intended seeded hazard rejections. All 43 safe output exports
are identical, preserving all 9,535 configured output elements. Both arms retain
744/744 repeated intended hazard detections and 1,333/1,333 repeated safe graph
acceptances, plus the separate first-observation round. There are no misses,
false positives, unsafe acceptances, timeouts or missing resource measurements.

The update does **not demonstrate faster bug finding**. Candidate medians are
slower in 58/67 configurations and faster in nine; p95 is worse in 40 and better
in 27. Eleven median ratios exceed 1.05. Ratios describe candidate divided by
baseline, so values above one indicate slower observations.

| Population | Configurations | Slower medians | Faster medians | Median of per-case ratios |
| --- | ---: | ---: | ---: | ---: |
| Safe completion | 43 | 39 | 4 | 1.030985 |
| Hazard diagnostic | 24 | 19 | 5 | 1.016674 |
| All configurations | 67 | 58 | 9 | 1.026554 |

The separate [26-case mixed-LGKM study](../../mixed/README.md) establishes the
bounded precision gain: eight safe false-positive configurations become
accepted, with all 16 seeded readiness hazards still rejected. Its mathematical
output checks remain separate from readiness safety.

## Scope and measurement context

This is a comparison within the fork, using identical ordinary full-trace
commands. All original assembly, launch shapes, allocations, selected-workgroup
outputs and mathematical specifications are preserved. These are development
configurations with seeded hazards, rather than 67 distinct algorithms or newly
found application bugs. Heldouts were not executed or used for prospective
validation or tuning. Arithmetic follows the verifier's mathematical-real model;
results cover configured workgroups rather than inter-workgroup safety or
bit-exact floating point.

One first-observation round is separate from 31 repeated fresh-process rounds.
The fixed seeded schedule uses adjacent randomized baseline/candidate pairs.
Hazard timing ends at parent-observed arrival of an intended diagnostic, checked
against a complete graph; safe timing ends at process completion without optional
expression export. Complete output exports and full specification proofs use
separate untimed controls. Per-case p95 is the nearest-rank statistic. Every
observation remains, with no outlier deletion or adaptive retry.

These are descriptive CPU measurements on a shared host. Builds and tests from
this run stopped before collection; other host work continued. A low-priority
read-only Git history scan overlapped part of collection, with its interference
unquantified. [measurement-context.json](measurement-context.json) records that
overlap. CPU isolation, cold caches and statistical significance are not
established. The published vendor/count/load context and every round's numeric
loads are retained in results.json.

## Data and provenance

- [results.json](results.json): every qualification, outcome, median, p95, ratio,
  full-output comparison, build identity, frozen input hash and load observation.
- [samples.csv.gz](samples.csv.gz) and [samples.json.gz](samples.json.gz): all
  4,288 observations, comprising 134 first observations and 4,154 repeats.
  CSV/JSON preserve numeric round-trip precision; first observations have round 0.
- [manifest.json](manifest.json): hashes for the three generated payloads and
  bindings to the frozen plan, raw report/samples, schedule and qualifications.
- [protocol and commands](../../README.md): preparation, qualification,
  collection, audit and sanitized export. Raw local logs and identities remain
  outside the repository.

**Baseline**: revision `ecb09dceef3588cd41a3f48b834a54c9ee739afc`, tree `06b1008cc8c059be837215442186972736bade6e`, binary SHA-256 `b4a904bd16a30d38743daeb679b15f45cc2fe6f233e310d97967585e05582153`.

**Candidate**: revision `2bdedfdec2335e06b9ab3bff3a3a9eb3686ac488`, tree `156d845acaac5cc87f11a316697f4917768b8ecd`, binary SHA-256 `49482db410adac21d617ec33c53dbb602afa4618415eab623ed8df6a88a4538d`.

The baseline was built at `ecb09dce`, whose complete tree equals the comparison
baseline `d88be68`. A fresh release build with empty optimization overrides and
no user/ancestor Cargo configuration reproduced its frozen binary exactly. Both
arms use Rust/Cargo 1.97.1, the release profile and default features. Build and
clock declarations are caller attestations: file hashes bind retained content
and do not independently prove reproducible builds or measurements. The frozen
harness audit and an independent recomputation agree on all 67 statistics and
all 4,288 observations. Sanitized data exclude local paths, commands, machine
identifiers and raw diagnostics.

A fresh release build of merged native commit `2f22997a` also matches the
measured candidate binary byte for byte; its later test-only borrow cleanup
changes no measured executable bytes.

## Every configuration

All rows have 31 successful repeated observations per arm, qualify in both arms,
and retain the full configured contract. Times are milliseconds; the endpoint
is completion for safe rows and intended-diagnostic arrival for hazard rows.
Full-precision values and separate first observations are in the data files.

| Configuration | Target | Kind | Baseline median | Candidate median | Baseline p95 | Candidate p95 | Ratio |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| `gfx942-elementwise` | gfx942 | safe | 19.414 | 20.098 | 21.902 | 21.244 | 1.035230 |
| `gfx942-reduction` | gfx942 | safe | 19.670 | 19.565 | 20.773 | 22.408 | 0.994667 |
| `gfx942-normalization` | gfx942 | safe | 23.658 | 24.768 | 26.062 | 28.051 | 1.046915 |
| `gfx942-gemm` | gfx942 | safe | 21.813 | 21.824 | 23.580 | 23.647 | 1.000505 |
| `gfx942-attention` | gfx942 | safe | 22.410 | 22.907 | 26.728 | 27.294 | 1.022174 |
| `gfx942-transpose` | gfx942 | safe | 10.407 | 10.744 | 12.049 | 13.979 | 1.032375 |
| `gfx950-elementwise` | gfx950 | safe | 18.936 | 19.174 | 21.430 | 20.634 | 1.012593 |
| `gfx950-reduction` | gfx950 | safe | 18.838 | 19.286 | 21.781 | 21.612 | 1.023750 |
| `gfx950-normalization` | gfx950 | safe | 23.435 | 23.581 | 24.819 | 26.414 | 1.006220 |
| `gfx950-gemm` | gfx950 | safe | 21.230 | 21.515 | 23.280 | 24.053 | 1.013413 |
| `gfx950-attention` | gfx950 | safe | 22.457 | 22.642 | 27.805 | 24.798 | 1.008218 |
| `gfx950-transpose` | gfx950 | safe | 10.136 | 10.407 | 12.122 | 12.038 | 1.026729 |
| `gfx1250-elementwise` | gfx1250 | safe | 19.966 | 20.204 | 21.829 | 21.751 | 1.011898 |
| `gfx1250-reduction` | gfx1250 | safe | 20.164 | 20.699 | 22.763 | 22.973 | 1.026554 |
| `gfx1250-normalization` | gfx1250 | safe | 25.394 | 26.186 | 28.060 | 28.454 | 1.031214 |
| `gfx1250-gemm` | gfx1250 | safe | 22.302 | 22.572 | 27.859 | 25.233 | 1.012113 |
| `gfx1250-attention` | gfx1250 | safe | 23.656 | 24.346 | 25.271 | 25.899 | 1.029191 |
| `gfx1250-transpose` | gfx1250 | safe | 10.502 | 11.137 | 11.365 | 14.614 | 1.060408 |
| `gfx942-native-copy` | gfx942 | safe | 10.267 | 10.525 | 12.999 | 13.656 | 1.025066 |
| `gfx942-native-add` | gfx942 | safe | 10.486 | 11.127 | 12.494 | 12.381 | 1.061120 |
| `gfx942-native-exchange` | gfx942 | safe | 11.518 | 11.903 | 12.918 | 13.292 | 1.033454 |
| `gfx942-native-reduce` | gfx942 | safe | 11.206 | 11.982 | 12.614 | 16.434 | 1.069263 |
| `gfx942-native-ids_3d` | gfx942 | safe | 9.907 | 10.027 | 11.999 | 11.903 | 1.012105 |
| `gfx942-native-mfma_f32` | gfx942 | safe | 10.648 | 11.291 | 12.221 | 12.214 | 1.060421 |
| `gfx942-native-mfma_f16` | gfx942 | safe | 11.398 | 11.881 | 12.557 | 14.744 | 1.042354 |
| `gfx942-native-pipelined_mfma_f16` | gfx942 | safe | 25.156 | 25.463 | 27.540 | 28.003 | 1.012186 |
| `gfx1250-native-copy` | gfx1250 | safe | 10.324 | 10.752 | 13.023 | 14.593 | 1.041421 |
| `gfx1250-native-add` | gfx1250 | safe | 10.407 | 11.101 | 12.453 | 13.173 | 1.066652 |
| `gfx1250-native-exchange` | gfx1250 | safe | 10.921 | 11.701 | 12.275 | 12.767 | 1.071431 |
| `gfx1250-native-reduce` | gfx1250 | safe | 10.732 | 11.332 | 14.236 | 13.450 | 1.055977 |
| `gfx1250-native-ids_3d` | gfx1250 | safe | 9.718 | 10.101 | 11.081 | 11.442 | 1.039418 |
| `gfx1250-native-wmma_f32` | gfx1250 | safe | 11.105 | 11.591 | 12.290 | 12.842 | 1.043755 |
| `gfx1250-native-wmma_f16` | gfx1250 | safe | 12.822 | 12.974 | 14.322 | 13.819 | 1.011830 |
| `gfx1250-native-wmma_bf16` | gfx1250 | safe | 12.836 | 13.354 | 13.968 | 14.168 | 1.040406 |
| `gfx1250-native-gemm_pipeline_f16` | gfx1250 | safe | 47.092 | 46.981 | 54.717 | 52.290 | 0.997640 |
| `gfx1250-native-tensor_roundtrip` | gfx1250 | safe | 13.391 | 13.805 | 14.559 | 18.305 | 1.030985 |
| `gfx1250-native-attention_small` | gfx1250 | safe | 225.713 | 220.508 | 238.883 | 242.576 | 0.976939 |
| `gfx1250-native-transpose_8x8_b16` | gfx1250 | safe | 10.647 | 10.994 | 12.202 | 11.754 | 1.032589 |
| `gfx950-native-copy` | gfx950 | safe | 10.052 | 10.713 | 11.890 | 13.224 | 1.065755 |
| `gfx950-native-exchange` | gfx950 | safe | 11.483 | 11.877 | 12.957 | 12.980 | 1.034339 |
| `gfx950-native-reduce` | gfx950 | safe | 11.165 | 11.658 | 14.476 | 14.173 | 1.044196 |
| `gfx1250-original-relu_f16` | gfx1250 | safe | 22.522 | 22.187 | 28.078 | 25.827 | 0.985128 |
| `gfx1250-original-rmsnorm_f16` | gfx1250 | safe | 69.805 | 70.547 | 80.446 | 77.287 | 1.010624 |
| `gfx942-exchange-mutation-0` | gfx942 | hazard | 10.045 | 10.389 | 12.322 | 11.949 | 1.034340 |
| `gfx942-pipelined_mfma_f16-mutation-1` | gfx942 | hazard | 25.048 | 23.832 | 30.999 | 26.451 | 0.951474 |
| `gfx942-exchange-mutation-2` | gfx942 | hazard | 10.045 | 10.182 | 10.890 | 12.138 | 1.013625 |
| `gfx942-mfma_f32-mutation-3` | gfx942 | hazard | 9.150 | 9.585 | 10.654 | 10.492 | 1.047510 |
| `gfx1250-copy_missing_km_wait` | gfx1250 | hazard | 8.586 | 9.264 | 9.536 | 11.177 | 1.078988 |
| `gfx1250-copy_missing_load_wait` | gfx1250 | hazard | 8.666 | 9.204 | 9.937 | 10.220 | 1.062187 |
| `gfx1250-exchange_missing_publication` | gfx1250 | hazard | 9.381 | 9.723 | 10.555 | 11.238 | 1.036438 |
| `gfx1250-wmma_missing_operand_load_wait` | gfx1250 | hazard | 9.681 | 9.838 | 10.933 | 11.061 | 1.016186 |
| `gfx1250-gemm_missing_initial_publication` | gfx1250 | hazard | 45.520 | 45.161 | 50.217 | 49.553 | 0.992128 |
| `gfx1250-gemm_missing_next_tile_publication` | gfx1250 | hazard | 45.437 | 45.382 | 51.046 | 51.182 | 0.998791 |
| `gfx1250-gemm_missing_matrix_ds_wait` | gfx1250 | hazard | 44.416 | 43.561 | 48.280 | 50.209 | 0.980765 |
| `gfx1250-tensor_missing_load_completion` | gfx1250 | hazard | 10.986 | 11.482 | 12.221 | 13.234 | 1.045182 |
| `gfx1250-tensor_missing_crosswave_publication` | gfx1250 | hazard | 11.260 | 11.745 | 12.589 | 13.205 | 1.043077 |
| `gfx1250-tensor_missing_store_producers` | gfx1250 | hazard | 10.950 | 11.142 | 12.081 | 11.746 | 1.017526 |
| `gfx1250-transpose_missing_ds_completion` | gfx1250 | hazard | 9.190 | 9.290 | 11.232 | 10.922 | 1.010881 |
| `gfx1250-original-relu_f16-missing-km-wait` | gfx1250 | hazard | 19.082 | 20.452 | 22.486 | 22.087 | 1.071770 |
| `gfx1250-original-rmsnorm_f16-missing-km-wait` | gfx1250 | hazard | 66.470 | 66.899 | 75.938 | 73.933 | 1.006449 |
| `gfx1250-exchange-two-independent-hazards` | gfx1250 | hazard | 9.565 | 9.599 | 11.634 | 10.364 | 1.003603 |
| `gfx1250-elementwise-missing-initial-km-wait` | gfx1250 | hazard | 18.078 | 18.330 | 20.233 | 20.480 | 1.013897 |
| `gfx1250-reduction-missing-initial-km-wait` | gfx1250 | hazard | 18.530 | 18.816 | 21.201 | 21.592 | 1.015393 |
| `gfx1250-normalization-missing-initial-km-wait` | gfx1250 | hazard | 23.684 | 24.090 | 26.341 | 28.171 | 1.017162 |
| `gfx1250-transpose-missing-initial-km-wait` | gfx1250 | hazard | 9.039 | 9.385 | 10.574 | 10.877 | 1.038298 |
| `gfx1250-gemm-missing-initial-km-wait` | gfx1250 | hazard | 20.722 | 20.519 | 26.553 | 23.003 | 0.990193 |
| `gfx1250-attention-missing-initial-km-wait` | gfx1250 | hazard | 21.410 | 21.794 | 24.330 | 24.955 | 1.017938 |
