# Integer address and launch probes

These safe probes compare one exact assembly program with the verifier, an
independent integer reference, and an actual matching GPU. They cover gfx942,
gfx950, and gfx1250. All generated files and machine observations remain in an
external work directory.

SMEM cases vary the low bits of the base, SGPR displacement, and immediate
independently. CDNA3/4 cover 4-, 8-, and 16-byte loads. gfx1250 also covers U8,
U16, B96, and payload-width-scaled SGPR displacements. Input bytes are distinct
concrete integers from 0 to 127. The references use little-endian assembly and
mask each address component before adding it.

Launch cases enable X, Y/Z, all axes, or no axes, using compacted SGPRs on
gfx942/gfx950 and documented TTMP fields on gfx1250. Hardware checks every group
of each small grid; verifier runs check group zero and the last nonzero group,
retaining every absolute output index. The gfx1250 fields include GridYZvalid,
DebugMark, and local wave ID for a two-wave workgroup. Undefined TTMP fields are
not observed.

Every required output starts with its bitwise complement. The native driver
loads the exact assembled code object, checks every output, preserves the entire
input, and checks 4 KiB guards on both allocations. ELF entry/descriptor alignment
is checked before execution. The target and physical wave size must match, and
an architecture override is refused. There are no racy, deadlocking, or
out-of-bounds mutations in this hardware suite.

From the repository root, build the CLI and run:

```sh
python3 tests/amdgpu/hardware/test_probes.py -v
python3 tests/amdgpu/hardware/run.py --target gfx1250 \
  --host "$GPU_HOST" --device "$GPU_DEVICE" \
  --work-dir /tmp/amd-gfx1250-probes --volta target/release/volta
```

Use `--target gfx942` or `--target gfx950` with a matching host. `--rocm` selects
the local LLVM assembler/linker; `--remote-rocm` selects the remote HIP installation.
The remote directory is unique and retained for inspection. A repeated attempt
removes its prior success receipt before running, so failure cannot leave a stale
pass. `result.json` records exact source/tool/binary/code-object hashes, complete
counts, source revision, and whether the source tree was dirty. Review that flag
when reproducing a committed revision.

`probes.py --target TARGET --work-dir /tmp/amd-probes --volta BINARY` runs only the
verifier/reference comparison. Its graph result and exact integer output checks
are separate from physical execution. These bounded checks establish neither
general ISA coverage nor inter-workgroup race freedom, numerical floating-point
correctness, or behavior of undefined register bits.

The public ISA sources are AMD's
[CDNA3 manual](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[CDNA4 manual](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
(SMEM address formation), and
[CDNA5 manual](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
(sections 8.1.1 and 3.5.3.1). The implementation audit and additional refusal
regressions are described in [the semantic audit](../../../docs/amd-semantic-audit.md).
