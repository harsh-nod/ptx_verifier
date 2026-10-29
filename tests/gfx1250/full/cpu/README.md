`prove_matrix.py` runs the six original full K4096 matrix proofs using an
already-built CLI. It never compiles assembly or executes a GPU kernel. A
fresh snapshot pins the binary, assembly, HIP source, full launch configs and
specs by SHA256. `ldd` compatibility and exact resolved runtime hashes are
recorded before execution. The supplied revision labels the builder's binary;
the runner does not infer a source revision from executable bytes.

Run on a CPU host with sufficient RAM, using a reviewed release binary:

```sh
python3 tests/gfx1250/full/cpu/prove_matrix.py \
  --binary /path/to/reviewed/volta \
  --fixture-root tests/gfx1250/full --revision BUILD_COMMIT \
  --output /tmp/gfx1250-full-matrix-default
```

Copy the same runner, frozen fixtures/configs/specs and binary to the remote
CPU host before an SSH invocation. No Rust toolchain is needed there. Start
with `--kernel gemm_f16_full` to measure one complete 65,536-output proof;
the resulting receipt is `partial`, never a six-case pass. Omit `--kernel`
for all six. Repeat with the separately built logging binary and
`--mode logging`; the default logging level is info, with debug available.

Every invocation writes `incomplete` before preflight. A full pass needs exit0,
all four AMD graph checks, `EQUIVALENT`, the exact unsampled VC count and final
`ACCEPT` for every required kernel. The CLI checks each output's complete index
set internally. The runner also validates the original row projections and
rejects reduced K, missing rows or remapped output pitch. SHA checks after each
case detect changes to the frozen inputs or executable.

Execution is sequential, with defaults of 384 GiB RSS, 512 GiB address space,
6,900 CPU seconds and 7,200 wall seconds per case. Linux `/proc` monitors the
process tree's RSS; `/usr/bin/time` records the child peak separately. A timeout,
resource limit, signal, unsupported instruction, failed obligation or stale hash
keeps the receipt incomplete. GPU visibility is empty and viewer exports are
disabled for these memory-intensive proofs. Distinct viewer cases are recorded
separately. The host controls run with:

```sh
python3 -m unittest discover -s tests/gfx1250/full/cpu -p 'test_*.py'
```
