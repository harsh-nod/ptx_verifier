# Native tensor edge and metadata counterparts

`cases.json` reviews 18 existing source-reference fixtures: five tensor edge/layout
rows and 13 metadata/lifetime rows. It preserves their source hashes, original
assertions and goldens, with literal native test mappings and narrow target-specific
residuals. All dispositions await coordinator validation. No issue or parent ledger
completion status is changed here.

Four genuine HIP modules, ten entry points and their unchanged compiler assembly
are pinned in `compiler-provenance.json`. The compiler, assembler and linker
identities, commands, source/assembly/object/code-object hashes and successful
encoding stages are recorded. Encoding alone is not a semantic acceptance gate.
The harmful variants and all seven assembler-legal mutations are CPU-only. This
directory supplies no hardware acceptance receipt.

## Exact payload and launch

The original input remains an 8×8 F16 array with a 16-byte row pitch. The complete
logical 4×4 tile starts at coordinate (6,6). Native TDM copies its valid 2×2 crop,
using base `input+54` and row stride 8 elements, into an eight-byte LDS staging
area. Ordinary LDS stores explicitly fill the other 12 cells with zero. This
does not claim native TDM automatically provides the NVIDIA out-of-bounds fill
mode. All 16 native output cells must match independent coordinate formulas:

```text
in[54] in[55] 0 0
in[62] in[63] 0 0
     0      0 0 0
     0      0 0 0
```

The native launch uses 64 threads (two wave32s), versus the originals' 32 or 64.
The original two-output footprint is retained as an explicit projection:
original `out[0]` is native `out[0]`, and original `out[1]` is native `out[15]`.
Both projected values are compared directly with the actual original PTX runs;
the other 14 native cells are independently checked too. No input shape, dtype,
pitch or logical tile is reduced to satisfy the gate.

The native metadata programs use actual D0/D1 register descriptors. Their ordinary
shared-memory backing has 64 meaningful initialized bytes: D0 at bytes 0..15,
D1 at 32..63 and one zero vector at 64..79 reused for D2 and D3. It is a different
schema from the NVIDIA 128-byte memory-backed map. A **separate full 128-byte**
Shared-to-Global copy primitive preserves all 32 independent U32 words in both
its destination and second-wave readback arrays; the smaller native descriptor copy is not
substituted for that footprint.

The crosswave Global readback is also a required cache-visibility gate. The
genuine compiler emits explicit `scope:SCOPE_SYS` FLAT accesses, completed with
their actual counters before the CTA rendezvous. This requires the distinct
gfx125x cache-forwarding contract in the pinned LLVM memory-model reference. A
legacy CDNA workgroup-scope or single-CU assumption cannot substitute for it;
an `Unknown` ordered-copy result does not satisfy this positive test.

## Ordering and boundary obligations

- Actual crosswave construction and ordinary metadata copying require completion
  and CTA publication before a second wave loads the descriptor. Removing only
  publication must retain a complete harmful candidate with a typed Shared
  WriteRead conflict.
- Concurrent field writers and descriptor-copy source/destination replacements
  retain actual byte conflicts. The full 128-byte primitive requires the source
  Shared WR/RW witness and destination Global WW witness at their exact first
  words, alongside its complete positive control. Removing only the ordinary
  Global copy publication must retain a complete candidate with Global WriteRead
  at byte 0x20000 when the second wave reads the copied object.
- Descriptor operands cannot be consumed before their ordinary loads return.
  Replacing the needed DS-data wait with an unrelated KM wait must give typed
  ReadBeforeReady. Omitting a declared producer store must produce an actual
  uninitialized-byte error at LDS byte 0x40, without default values.
- A CTA barrier or unrelated load-counter wait cannot replace Tensor completion
  for the cropped LDS tile. The harmful control must retain a Tensor write/read
  conflict at the actual crop byte 128.
- Completing the Tensor operation does not publish a distinct earlier ordinary
  metadata store. Its positive publishes `meta + tile[0]` to a second wave;
  removing only the CTA publication must retain a conflict at Shared byte 16,
  outside the Tensor's 16-byte tile.
- Selecting the valid descriptor for `input+53` instead of `input+54` must change
  exactly cells 0, 1, 4 and 5. This separately checks descriptor identity; it is
  not presented as an AMD equivalent of a keyed NVIDIA proxy acquire.

AMD TDM captures its scalar descriptor values at issue; ordinary instruction
reads and their prerequisites still apply. Reusing the old metadata **memory
object** after those words are captured is different from overwriting an
asynchronous NVIDIA memory-backed map. The native buffer's asynchronous memory
effects, both Tensor directions and their completion/reuse obligations remain
real obligations. No extra X-counter charge, implicit GLOBAL lease or NVIDIA
proxy operation is invented.

Exact NVIDIA `tensormap.cp_fenceproxy.sync.aligned`, map-field layout,
generic/tensormap proxy release/acquire and CTA/cluster destination spellings are
target-specific residuals. They do not erase byte preservation, correct metadata
binding, initialization, publication or memory lifetime. Leader-only native
scalar TDM issue does not inherit an absent full-warp collective requirement.

## Reproduction

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/portable-tensor
python3 tests/gfx1250/portable-tensor/check_mutants.py \
  --output /tmp/gfx1250-tensor-mutants.json
python3 tests/gfx1250/portable-tensor/check_inventory.py
python3 -m unittest discover -s tests/gfx1250/portable-tensor -p 'test_*.py'
CARGO_HTTP_CAINFO=/home/harsh/.codex-openai/ca-combined.pem \
  cargo test --release -p volta_pipeline --test gfx1250_tensor_parity_tests
```

`mutations.tsv` is shared by the Rust semantic controls and the actual LLVM-MC
replay. The 128 or 512 independent scalar NOPs used in publication mutants preserve
initialization order in the concrete simulator; they add no completion or
happens-before edge. The checker records hashes for the exact mutated assembly,
then assembles it without loading or executing it on a GPU.

The native D0/D1 recipe and target references are pinned separately in
[semantic-references.json](../fixtures/semantic-references.json). The compiler output and
actual control forms determine the concrete encoding evidence here.
