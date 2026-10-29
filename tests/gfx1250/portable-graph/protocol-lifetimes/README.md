# Native protocol lifetime controls

The four HIP kernels and five allocated named-object LLVM kernels are genuine
gfx1250 compiler inputs. Their retained assembly is unchanged compiler output.
The source checker reproduces both files byte for byte, assembles and links
them, and separately assembles the CPU-only unordered-initialization mutation.
An explicit public clang compilation-unit identifier makes the HIP output
independent of its output pathname.

```sh
python3 tests/gfx1250/portable-graph/protocol-lifetimes/check_sources.py --output /tmp/protocol-source-check.json
cargo test --release -p volta_pipeline --test gfx1250_protocol_lifetime_tests
```

All scalar inputs that select a harmful protocol are CPU-only test controls.
Compilation does not validate execution. No hardware run is claimed, and
coordinator dispositions remain pending in `references.json`.

| Source control | Complete safe behavior | Adverse behavior |
| --- | --- | --- |
| `ended_reader` | Complete ordinary 4-byte read precedes explicit workgroup publication and another wave's overwrite; no output stores | END plus a survivor's wave barrier supplies no cross-wave publication; typed Shared ReadWrite |
| `ended_writer` | Exactly `out[0]=42` after explicit publication before the writer ends | Completed store and END without that publication retain typed Shared WriteRead |
| `metadata_eight_bytes` | Both ordinary metadata bytes ranges cover exactly 8 bytes; complete output words `[42,0]` preserve raw 64-bit 42 | Unordered initialization and scratch store/load retain typed Shared WriteWrite |
| `undefined_shuffle_source` | Every one of 16 outputs equals the original input at index `i+8` | Lanes 16–31 never initialize fixed VGPR20; actual `ds_bpermute_b32` rejects the uninitialized source at wave0/lane16, with no symbolic outputs |
| `named_initialization_42` | A genuinely allocated object publishes exactly the index-1 marker42 | Missing initialization aborts; removing only the initialization rendezvous retains named-initialization ordering Unknown |
| `named_live_reinitialization_42` | The same exact index-1 marker42 with one initialization | Reinitializing an object while joins remain live is explicitly Unsupported and supplies no output certificate |
| `named_new_lifetime_count_change` | Released count-2 lifetime followed by an ordered count-1 lifetime; exactly `[7,7]` | The separate `named_count_mismatch_7` keeps expected3 with two arrivals; all64 workitems block in phase0 and no outputs are available |
| `named_wait_without_first_arrival` | A new native object has no completed prior phase | All64 workitems block at expected1/arrived0; an initially free ordinary buffer is instead covered by the separate lifecycle handshake control |

The native count is bound at initialization. PTX's per-arrival thread count and
count changes within one barrier's successive phases are distinct mechanisms;
the new-lifetime control does not claim to encode either. In particular, the
expected3/arrived2 deadlock is supporting evidence for counted progress, and
does not stand in for a mixed-count arrival instruction. The three baseline
count rows therefore retain explicit contract-difference dispositions.

Native whole-wave END and PTX individual-lane exit differ. These source controls
retain the completed memory direction and 42 marker, while the existing
automatic-drop corpus separately keeps implicit-drop publication Unknown.
The shuffle uses a genuinely uninitialized register source; it does not claim
that native END can retire an individual lane. Ordinary 8-byte metadata is
separate from the allocated native barrier resource, which is not represented
as an aliasing memory-backed PTX mbarrier.

The [public semantic source inventory](../../PUBLIC_SOURCES.md) and
[pinned references](../../fixtures/semantic-references.json) document the native
execution, memory and named-object profiles. These controls do not broaden
those profiles or turn incomplete/unsupported traces into accepted proofs.
