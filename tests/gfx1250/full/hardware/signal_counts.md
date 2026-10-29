# Safe signal-count hardware replay

`signal_counts_run.py` uses the four safe entries listed in
[`references.json`](../../portable-graph/signal-counts/references.json).
It assembles and links the exact unchanged `native-signal-counts.s`; the fixture
LLVM source is retained as provenance. Only the phase-count-change kernel
(block 64, two F32 outputs) and zero/NULL/maximum markers (block 1, one F32 output
each) are launched. Every value must equal 7 exactly.

Eight repetitions require 32 launches and 40 outputs, zero input bytes, 262144
unchanged 4-KiB allocation-guard bytes and 128 untouched tail bytes per device.
All output words start as NaNs. Each allocation has one extra NaN word whose
bytes must remain unchanged. These are repetitions of source-defined constants,
not different external input patterns. Ambiguous equality, reserved-bit,
invalid-count and deadlock entries are never launched.

```sh
python3 tests/gfx1250/full/hardware/signal_counts_run.py \
  --host "$GFX1250_HOST" --device "$GFX1250_DEVICE" --rocm /opt/rocm \
  --result /tmp/signal-counts.json
```

The shared runner checks source revision/hashes, real wave32 target and selected
physical-device identity, object/code-object hashes, numerical accounting and
full guards. Keep generated receipts outside the repository. A matching second
reserved device requires a separate invocation and receipt. Hardware numerical
agreement does not replace the symbolic protocol and ordering controls.
