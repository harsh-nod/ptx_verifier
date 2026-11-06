# AMD hardware validation

`suite.py` runs the complete existing positive host-driver catalog for gfx942,
gfx950 and gfx1250. It assembles the exact committed `.s` files and compiles
only the host drivers. It preserves their full launch shapes, input patterns,
output checks and guards. No racy, deadlocking or out-of-bounds mutations are
selected for GPU execution.

Use a clean committed version of the AMD test sources. Set up an SSH alias for
each reserved GPU and put the physical device ordinal and ROCm installation in
an external JSON file:

```json
{
  "targets": [
    {"target": "gfx942", "host": "gfx942-host", "device": 0, "rocm": "/opt/rocm"},
    {"target": "gfx950", "host": "gfx950-host", "device": 0, "rocm": "/opt/rocm"},
    {"target": "gfx1250", "host": "gfx1250-host", "device": 0, "rocm": "/opt/rocm"}
  ]
}
```

Run from any checkout, using Python 3.12 or newer on the controlling host:

```sh
python3 tests/amdgpu/hardware/suite.py --config /tmp/amd-hardware.json \
  --work-dir /tmp/amd-hardware-run --volta target/release/volta
```

`--volta` additionally compares the generated address/launch probes with that
local verifier. Omit it to run the numerical hardware checks alone; the receipt
then makes no verifier claim. The supplied verifier's path and binary hash are
recorded and checked before/after verification and between targets; this does
not attest its build or source revision. A single target can use `--target gfx950 --host
gfx950-host --device 0 --rocm /opt/rocm` instead of `--config`. Use `--local`
instead of `--host` when running on the GPU host. Local execution also stages
the sources outside the checkout.

The catalog contains 2 gfx942 groups, 12 gfx950 groups and 17 gfx1250 groups.
It includes all existing positive host drivers, the gfx1250 matrix and mechanism
feature drivers, and the common address/launch probes below. Adding a host driver
without registering it in `profiles.py` makes the gate fail. Existing gfx1250
sub-runners retain their independent reference and output-accounting checks.
The four original-workload runners retain all 262 launches and 2,803,092 native
outputs; supplemental feature checks are separate groups.

Targets run sequentially. A failure stops that target; the other requested
targets still run and retain distinct outcomes. `result.json` is replaced with
an incomplete record before source validation or transport, then becomes `PASS`
only when every requested target completes every required group. Changed
committed input, architecture overrides, inherited device selectors, mismatched
HIP libraries, missing/stale receipts and incomplete suite inventories fail.
Every subprocess has a bounded timeout; no device resets are attempted.

Receipts bind the invocation to a source revision/tree, exact staged-file hashes,
physical device identity, tool/runtime hashes, host binaries and assembled
objects/code objects. Each remote staging directory is unique and retained.
Small command logs and nested receipts are downloaded; built artifacts remain
at the recorded remote location. Keep work directories and receipts outside
the repository. Numerical hardware checks do not certify graph safety, arbitrary
ISA coverage or exhaustive IEEE behavior.

CPU-only controls for the catalog, source binding, receipt validation and failure
handling require no ROCm installation or GPU:

```sh
python3 -m unittest discover -s tests/amdgpu/hardware -p 'test*.py' -v
```

## Integer address and launch probes

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
