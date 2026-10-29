# Complete convolution, attention and Mamba CPU proofs

`prove_advanced.py` runs W19–W26 with their original shapes, storage dtypes,
logical grids, null ABI arguments and complete output footprints: **65,824
configured outputs**. It validates the full32 registration contract before
starting. No alternate kernels, sampled outputs, shortened reduction axes or
GPU calls are used. Mathematical equivalence follows the disclosed Volta
symbolic arithmetic model; physical floating-point accuracy remains a separate
hardware gate.

The runner snapshots the supplied release binary and exact source/assembly/spec/
launch inputs, verifies their registered hashes and records runtime-library
hashes. Binary and fixture revisions are supplied separately by their builders;
a hash identifies the bytes actually executed. Keep a build receipt associating
the binary hash with its claimed revision. Runtime logging uses a separately
built `--mode logging` binary; default and logging receipts must not be conflated.

```bash
python3 tests/gfx1250/full/cpu/test_prove_advanced.py -v
python3 tests/gfx1250/full/cpu/prove_advanced.py \
  --binary /frozen/volta --binary-revision BUILD_COMMIT \
  --fixture-root tests/gfx1250/full --fixture-revision FIXTURE_COMMIT \
  --output /unique/results
```

Each case must exit0, pass all four native graph properties, check exactly its
full unsampled VC count and produce `EQUIVALENT (matches spec)` plus final
`VERDICT: ACCEPT`. Missing output, Unsupported, Unknown, crash, timeout,
resource-limit termination and failed graph/math gates never pass. Failures are
recorded and later cases still run sequentially. Explicit `--kernel NAME`
selection records `partial`, even when that selection succeeds; only all eight
successful cases yield `pass`.

The defaults cap each process at7200 wall seconds,6900 CPU seconds,384GiB RSS
and512GiB address space. They measure the process tree and terminate the entire
owned process group on a wall/RSS limit. Coordinate concurrent jobs on the host
before selecting caps; do not infer acceptance from a process that is still
running. `receipt.json` is initialized as incomplete before operational preflight,
so a failed invocation cannot retain an earlier success. Host controls validate
these refusal paths; their synthetic text and short Python children are not
native proof evidence.
