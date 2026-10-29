# Native signal-time barrier counts

`native-signal-counts.ll` and its unchanged compiler assembly contain eight
allocated-object kernels. One typed `NamedBarrierSignalWithCount` records the
signal and its M0 bits22:16 update; the original signal event layout is
unchanged. Zero updates and NULL signals retain the original no-change/no-op
semantics. Nonzero reserved M0 bits remain unsupported.

```sh
python3 tests/gfx1250/portable-graph/signal-counts/check_sources.py --output /tmp/signal-count-source-check.json
cargo test --release -p volta_pipeline --test gfx1250_signal_count_tests
cargo test --release -p volta_graph_check --test gfx1250_tests --test amdgpu_tests
```

| Actual source control | Required result |
| --- | --- |
| `named_phase_count_update7` | Same object/incarnation, phase0 count2 followed by phase1 count1; exactly `[7,7]` |
| `named_signal_count_deadlock7` and `_reverse` | Explicit count3 signals occur in opposite wave orders; all64 workitems block at expected3/arrived2 in either source |
| `named_decrease_below_arrived7` | Count1 after two arrivals yields a typed barrier violation and no outputs |
| `named_equal_arrived_boundary7` | Exact native count2 then count1 after one arrival remains explicitly Unsupported/Unknown |
| `named_zero_update_marker7` | Zero leaves initialized count1 unchanged; exactly marker7 |
| `named_null_update_marker7` | NULL with nonzero encoded count remains a no-op; ordinary allocated count1 then completes marker7 |
| `named_max_signal_count7` | All127 actual arrivals at the 7-bit maximum complete marker7 |

The pinned public [execution model](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUExecutionSynchronization.md)
specifies update before increment. Its generic rule requires the new count to
exceed existing arrivals, while its native code-sequence text permits equality.
The implementation accepts the common defined range, reports a typed invalid
decrease below existing arrivals, and leaves equality inconclusive. It does
not infer a hardware result at that disputed boundary.

Different setters and drops need execution-order certificates. The checker
tracks changed-count signals across phases and also orders every explicit
setter against drops, including setters numerically unchanged in this chosen
schedule. Identical explicit updates can commute; a legacy zero/no-change
signal is distinct. Independent three-wave, drop and cross-phase controls
reject scheduler-only acceptance while preserving ordered controls.

PTX thread counts64/32 map separately to native wave-arrival counts2/1. The
mixed-count rows retain the exact2/1 boundary control and its explicit public
ambiguity. The stable count3 deadlock is supporting progress evidence; it is
not described as the same conflicting-count instruction. All dispositions
remain coordinator candidates. No GPU run or machine metadata is retained.
