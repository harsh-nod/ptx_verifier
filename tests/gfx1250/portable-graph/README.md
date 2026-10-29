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

## Allocated shader named objects

`native-named-barriers.ll` uses the toolchain's allocated
`target("amdgcn.named.barrier", 0)` object type. The actual llc 22 toolchain uses
address space 3 for this type; the public reference has since assigned a
dedicated address space. This is compiler input, not an edited descriptor or a
pointer literal masquerading as an allocation. All six unchanged compiler
outputs declare `.amdhsa_named_barrier_count 1`, allocating four shader objects.
The selected controls use object 1 and independent ordinary LDS payload storage.

```sh
python3 tests/gfx1250/portable-graph/validate_named_profile.py
cargo test -p volta_pipeline --test gfx1250_named_barrier_tests
cargo test -p volta_graph_check --test gfx1250_tests
```

`named-profile-evidence.json` pins the actual input/output/tool hashes and exact
llc, MC and link commands. It also assembles five harmful mutations; they run
only in the CPU graph tests, never on a GPU. Their positive controls must first
produce GraphVerified and the complete symbolic payload.

| Native control | Participants and obligation | Complete output |
| --- | --- | --- |
| `named_identity` | Two waves; INIT count 2, JOIN, DS completion, SIGNAL, WAIT, LEAVE | `in[0]` |
| `named_encoded_wait_uses_last_join` | Encoded WAIT 2 resolves to joined object 1 | `in[0]` |
| `named_reinitialized_identity` | Two initialized lifetimes separated by all leaves and a workgroup rendezvous | `in[0], in[1]` |
| `named_subset_drop` | Three joined waves; one explicitly drops and two arrive/wait | `in[0]` |
| `named_null_unjoin` | Join NULL without dropping former object; NULL LEAVE preserves the NULL join across another WAIT | `in[0]` |
| `named_two_arrivals_one_wave` | One wave issues both arrivals of a count-2 phase | `in[0]` |

The mutations exercise a wrong expected count, a missing signal, END without a
named drop, WAIT without JOIN, and replacing DS completion by an unrelated Load
wait. Independent event graphs additionally test all IDs 1–16, malformed M0 and
allocation roles, stale incarnations, forged/duplicate releases, phase
interleaving, unordered initialization and drop-dependent memory Unknown.

The checker follows the pinned LLVM
[execution model](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUExecutionSynchronization.md).
Arrivals are wave-uniform operations, not distinct waves or PTX per-lane counts.
INIT reads its expected count from M0, and each reinitialization receives a fresh
trace incarnation. END does not implicitly drop a named object. This selected
slice does not cover signal-time count changes, `_isfirst`, clustered objects,
or reinitialization with outstanding joins, and does not complete every portable
barrier, lifetime or asynchronous-copy obligation. No hardware result is claimed.
NULL waits require an explicit NULL join; an unbound initial last-joined selector
is not inferred from the encoded operand and remains Unknown.

After recording these tests with `VOLTA_VIZ_DIR` into a mixed PTX/gfx942/gfx950/
gfx1250 store and building its HTML page, run the actual Chromium control with:

```sh
PLAYWRIGHT_MODULE=/path/to/playwright node tests/gfx1250/portable-graph/named_browser.cjs /path/to/index.html /path/to/evidence
```

It checks all six native kernels' actual event/source links, encoded versus
resolved selectors, reinitialization incarnations, subset drops, the counted
END-without-drop deadlock, the unbound NULL limit and a typed Shared witness.
The browser receipt states its rendering-only scope and binds the page/script
hashes; mathematical, graph and hardware evidence remain separate.

## Independent objects and producer handshakes

`native-named-phases.ll` and its unchanged compiler output add four separate
controls. The compiler assigns `full` object ID 2 and `empty` ID 1 in this module;
the tests check those actual allocations, count values and every observed phase.
The original six-kernel module is unchanged.

| Kernel | Launch/ABI | Complete payload and obligation |
| --- | --- | --- |
| `named_two_object_handshake` | block 64, `in*, out*`, both length 2 | `out = [in[0], in[1]]`; full count 2 plus empty count 2 order buffer reuse between generations |
| `named_independent_object_counts` | block 64, no arguments or outputs | Object 2 count 1 completes phases 0 and 1 around object 1 count 2 phase 0 |
| `named_three_arrivals_expression` | block 32, `in*, out*`, capacity 3 | Only out[0] is written: `(in[0] + in[1]) * in[2] - in[0]`; one wave with one payload lane completes three count-1 arrival phases |
| `named_selected_object_copy` | block 64, `in*, out*, u32 different`, arrays length 1 | Safe `different=0` copies `in[0]`; **different=1 is CPU-only** and deadlocks both waves on different IDs |

```sh
python3 tests/gfx1250/portable-graph/validate_named_profile.py --module native-named-phases
cargo test -p volta_pipeline --test gfx1250_named_barrier_tests
```

The separate `named-phases-profile-evidence.json` records compilation, MC/link
and three assemble-valid mutations: removing the consumer handshake must expose
a Shared conflict; changing one object's expected count must deadlock both waves;
changing the encoded WAIT selector preserves both payloads because the joined
object still determines the wait. The runtime ID-mismatch control uses the same
actual assembly with a different scalar input, not an edited descriptor. No
hardware outcome is claimed here. The native payload lane is inactive elsewhere;
this does not emulate PTX independent lane termination or PTX count rounding.

## Copy completion and publication

`copy-order/native-copy-order.hip` and its unchanged compiler output preserve
ordinary memory obligations through the actual SMEM, GLOBAL and FLAT-to-LDS
instructions selected by clang. These are native counterparts for portable
payload and ordering assertions; they do not claim NVIDIA transaction-byte
accounting, proxy fences, Tensor Memory, or native asynchronous DMA instructions.

| Kernel | Launch and arrays | Complete assertion |
| --- | --- | --- |
| `copy_scalar_same_wave` | block 1, `in[1], out[1]` | Four input bytes and four LDS bytes; `out[0] = in[0]` after returned-value readiness |
| `copy_scalar_cross_wave` | block 64, `in[1], out[1]` | Lane 0 produces four LDS bytes; lane 32 consumes after completion and workgroup publication; `out[0] = in[0]` |
| `copy_both_regions_before_publication` | block 64, `in[8], out[64]` | Two disjoint 16-byte LDS regions complete before publication; all 64 outputs equal `in[4]` |
| `copy_two_completed_regions` | block 1, `in[8], out[2]` | Two disjoint 16-byte copies observed in order; `out = [in[0], in[4]]` |
| `copy_result_dependency_ids` | block 32, `out[256]` | All 32 IDs return through 128 bytes of LDS; only output indices 0 through 31 are written |
| `copy_every_actual_reader_waits` | block 64, `in[4]`, no outputs | All 16 copied bytes complete before publication; exactly lanes 32 through 63 read the first LDS word |

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/portable-graph/copy-order
python3 tests/gfx1250/portable-graph/copy-order/validate_mutations.py
cargo test -p volta_pipeline --test gfx1250_portable_copy_tests
```

The eight CPU tests check full symbolic outputs, untouched output tails, exact
input/LDS byte footprints and reader attribution. Three separately MC-accepted
mutations replace the actual KM wait with a Load wait, replace a returned FLAT
load wait with Store completion, or remove crosswave publication after LDS
completion. Each has a passing unmodified payload control and a typed failing
graph property. Independent scalar NOPs in the last mutation keep its candidate
execution complete; they do not establish memory ordering. The mutations are
CPU-only. Compiler and mutation receipts record source/tool/object hashes; no
hardware result or completion of the entire portable feature group is claimed.
