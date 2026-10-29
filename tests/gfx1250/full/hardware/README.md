# Original32 hardware input coverage

These host drivers load the unchanged original-shape compiler assembly. Their
ordinary CPU reference formulas, launch mappings, complete output projections,
native supersets, NaN sentinels, full input checks, byte guards and untouched
output-gap checks are retained. Sparse inputs do not shorten any GPU or CPU loop.

The required default pattern counts include the following explicit bases:

| Runner | Required patterns | Added basis coverage | Launches | Native outputs |
| --- | ---: | --- | ---: | ---: |
| `original_run.py` | 10 | Pattern9: final element, both RoPE partners, RMS/softmax4095, matvec final row/K4095, reduction tail and initial output dependence | 180 | 264660 |
| `original_convolution_run.py` | 5 | Pattern4: input channel63, filter tap2,2, output channel127 and final original spatial coordinate at K575 | 10 | 122880 |
| `original_matrix_run.py` | 6 | Pattern4: A K4095 plane; pattern5: B K0/31/32/4095 planes. BitDelta includes packed group127/bit31 and group0/bit31 to group1/bit0 boundaries | 36 | 1818624 |
| `original_advanced_run.py` | 6 | Patterns4/5: attention D63/D0 and keys0/63/64/last, signed-I8 limits and both key scales; Sinkhorn first/last bases; state t255/t0; separate scan current/prior terms | 36 | 596928 |

Each device run therefore checks 262 launches and 2803092 native outputs,
including 2453652 original-projection outputs. Flash uses its real grid16 and
checks all1024 native rows. Matrix K4096, convolution K576, attention sequences,
Mamba times and all physical pitches remain unchanged. Matrix tags use exactly
representable dyadic F16/E4M3 values. Packed weights remain externally supplied
U32 bytes, and Sage keeps its signed-I8 inputs and separate per64-key scales.

Run each runner with `--local --device "$GFX1250_DEVICE" --result /tmp/...json`
on a matching reserved GPU, or use its existing SSH staging options. The runner
and driver both reject counts below these minima. Reports from older drivers
retain their historical scope; they do not satisfy this new basis gate. No
device-run receipt is committed by this change.

CPU-only verification, without a GPU launch:

```sh
python3 -m unittest discover -s tests/gfx1250/full/hardware -p '*test*.py' -v
```

The four drivers can also be compiled using the host `clang++` command in
`original_run.py`, then run with `--cpu-only`. Their host-only buffers check
first/last basis encoding for all five storage types, unchanged guards and
bounds rejection. The matrix driver separately enumerates every packed bit to
check the exact group boundaries. These controls do not claim a numerical GPU
run or replace the separate symbolic full-output software proofs.
