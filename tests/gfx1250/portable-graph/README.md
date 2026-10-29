# Native portable graph controls

`native-barriers.hip` is compiled unchanged for gfx1250 by the pinned ROCm clang
22 toolchain. `compiler-provenance.json` records the source, assembly, object,
code-object and tool hashes plus the exact successful compiler/MC/link commands.
The assembly is an actual compiler output. None of these controls has been run
on a GPU; `exited_writer_no_arrival` is a CPU-only proof-limit control.

Reproduce compilation with:

```sh
python3 tests/gfx1250/compile_fixtures.py --llvm /opt/rocm-7.2.0/lib/llvm/bin tests/gfx1250/portable-graph
cargo test -p volta_pipeline --test gfx1250_portable_graph_tests
cargo test -p volta_graph_check --test gfx1250_tests
```

The native controls check complete symbolic payloads, not markers alone:

| Kernel | Native participants | Complete payload | Expected graph result |
| --- | --- | --- | --- |
| `phase_identity` | One live lane in one wave | `out[0] = in[0]` | Verified |
| `remaining_wave_progress` | Two waves; wave 1 exits without a payload | All 32 survivor outputs equal their inputs | Verified |
| `arrived_writer_then_exit` | Two waves; writer explicitly arrives and waits before exiting | All 32 reader outputs equal writer inputs | Verified |
| `exited_writer_no_arrival` | Two waves; writer completes LDS stores and exits without arrival | All 32 reader outputs equal writer inputs in the candidate schedule | Memory Unknown; other three AMD properties pass |
| `two_generation_two_consumers` | Producer wave and two consumer waves, four rendezvous phases | Exactly `in[0], in[1], in[0], in[1]` | Verified |

The exiting-writer result conservatively exposes an unpinned publication path.
LLVM's pinned public execution and memory models distinguish automatic drops
from arrive-release synchronization; they do not settle completed-LDS ordering
through END's implicit drop. See the precise rationale and primary links in the
[checker README](../../../crates/volta_graph_check/README.md#gfx1250-checks).
Independent event graphs additionally cover writes after an explicit arrival,
transitive later phases, read/read and disjoint accesses, and an unrelated actual
conflict that must remain a failure. These controls do not imply that arbitrary
barrier objects, participant counts, asynchronous copies or all portable baseline
rows are implemented.

`validate_flat_profile.py` separately records actual compiler pre-waitcnt MIR
for the unchanged portable ABI transfer source, plus two assemble-valid CPU-only
mutations. Run it after the portable ABI fixture dependency is available:

```sh
python3 tests/gfx1250/portable-graph/validate_flat_profile.py
```

The MIR preserves generic FLAT memory operands even when the runtime resolver
establishes a Shared aperture. `flat-profile-evidence.json` pins the exact input
hashes, compiler command, MIR hash and MC outcomes. It distinguishes generic
instruction translation ordering from resolved effect-space ordering. The
combined wait immediate `0x1` means Load0+Ds1; target FIFO retirement completes
only the older of two pending DS tokens. Replacing a FLAT destination by an
ordinary VALU write must retain the older GLOBAL source-lease hazard. These MC
receipts make no numerical, graph-safety or hardware claim by themselves.
