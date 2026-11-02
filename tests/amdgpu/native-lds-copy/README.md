# Original gfx950 global-to-LDS copy

One unchanged HipKittens F32 copy specialization now completes modeled safety
checking and proves every original output. This is **one original coverage
improvement and zero new bugs**. The source already contains its completion
waits and barrier. No kernel, instruction, allocation, launch or output was
reduced or repaired.

| CPU verifier result | Before | After |
| --- | --- | --- |
| Source revision | `70df9b1e9282cd1697b44d3fc8d5214af0cd81df` | `8eae0e69755612acaee48dbe26c46b80de81b7b1` |
| Executed instruction records | 25 | 31 |
| Terminal | UNKNOWN at PC24: opaque shared aperture used as ordinary bits | Completed |
| Graph properties | Four PASS results on an aborted prefix; overall UNKNOWN | Four PASS results; overall VERIFIED |
| Output and specification | No outputs; equivalence unavailable | All 64 `out[i] = x[i]` roots and all 64 specification elements proved; ACCEPT |

The before/after data are the exact retained files in
[results/baseline](results/baseline/report.json) and
[results/candidate](results/candidate/report.json). The copied
[independent result audit](results/independent-audit.json) records 1,137 checks
and zero errors, including separate pre-existing regression replays. Those
regressions are not additional original coverage or bug findings. Captured
reports and transcripts retain historical `/tmp` artifact paths; replay does
not depend on those paths. All original raw files and failed attempts remain
unchanged outside this package.

## Source, full launch and ABI

The [whole emitted module](fixtures/original.s) comes from
[HipKittens `8cde3dd146bd1c4be78023b582c1f4375c48489f`](https://github.com/HazyResearch/HipKittens/tree/8cde3dd146bd1c4be78023b582c1f4375c48489f),
[the original unit source](https://github.com/HazyResearch/HipKittens/blob/8cde3dd146bd1c4be78023b582c1f4375c48489f/tests/unit/cdna4/warp/memory/vec/global_to_shared.cu).
The source is also [copied locally](fixtures/global_to_shared.cu), with its
[MIT notice](fixtures/LICENSE.HipKittens). This is `shared_vec_load_store<float>`
with `S=4`, register-tile columns 16 and `NW=1`: the original size is 64 elements.
The host reference is identity.

The [launch](launch.json) keeps grid `(1,1,1)`, block `(64,1,1)`, selected group
`(0,0,0)`, 80,000 bytes of dynamic LDS, and the full 256-byte input and 256-byte
output allocations. Both original arguments are 16-byte by-value global-layout
objects, aligned to 8 bytes with their pointer at offset 0; argument offsets
are 0 and 16 in a 32-byte kernarg segment. The unused padding is explicitly
zero and is not loaded by this module. The [compile-time layout check](provenance/layout.cpp)
checks `sizeof`, `alignof`, pointer offset, the 64-thread warp constant and
`MAX_SHARED_MEMORY=160000` used by the host's half-capacity LDS launch.

[Source and compile provenance](provenance/source.json) binds the public source
commit, six relevant source hashes, original compile/layout record hashes,
compiler identity and an LLVM-MC accepted object hash. Command templates replace
checkout/tool include paths with explicit placeholders; they are not byte-exact
copies of the original command records. Compiling again may produce different
assembly on a different toolchain. Replay uses the pinned, complete module.

## Replay

From this directory, use a fresh output directory with an appropriate compiled
CLI. The package includes no binaries.

```sh
python3 replay.py --binary /path/to/volta --output /tmp/lds-copy-after
python3 replay.py --binary /path/to/old-volta --output /tmp/lds-copy-before --baseline
python3 replay.py --check-recorded
python3 -m unittest -v test_replay.py
python3 -O -m unittest -v test_replay.py
```

`--baseline` requires this exact historical UNKNOWN boundary, rather than any
error or unsupported result. Each replay runs complete `verify --sample 0
--verify-numeric` with `N=64`, then `analyze` with all outputs, graph and
expression export. Each process has a fixed 60-second budget. The helper refuses
changed inputs, duplicate/missing coordinates, partial or duplicate PCs,
contradictory typed hazards or verdicts, incomplete equivalence, and changed
DMA/FLAT effects, waits or barrier records. It checks all 64 identity expression
roots, the DMA's VM contribution, both VM and LGKM contributions for the shared
FLAT read, the original waits, and complete lane exits. These are finite
artifact-contract checks, not a second implementation of the graph checker.
Only host controls and checks over existing records were used to prepare this
package; this helper did not generate the historical captures.

[manifest.json](manifest.json) records original source/build/binary and capture
identities; [checksums.json](checksums.json) covers all other package files.
Build and process association is caller-attested. Hashes identify bytes; they
do not prove which source produced an executable or that a recorded process
ran it. Fresh replay records identify the user-supplied binary without assigning
it a guessed source revision.

The result remains within the native 64-bit FLAT profile, with PTR32 and mode
writes unsupported, XNACK replay disabled, one CU per workgroup, mathematical
arithmetic, and issue-time modeled asynchronous data. It establishes neither
hardware behavior nor a hardware mode attestation. It makes no speed, RSS,
new-bug, whole-library coverage or whole-grid claim beyond this original
single-workgroup launch.
