# Native asynchronous memory obligations

The unchanged compiler module contains ten native TDM programs. TDM is used as
the documented AMD asynchronous copy counterpart; these programs do not assert
native execution support for the separate LDS-DMA instruction family or NVIDIA
transaction-byte accounting, scheduler cancellation or Tensor Memory allocation.

| Native program | Complete assertion |
| --- | --- |
| Four/sixteen-byte same-actor copies | One/four original input words reach every output word |
| Four/sixteen-byte cross-wave copies | A second wave observes all one/four copied words after completion and publication |
| Four-byte destination reuse, same actor/cross-wave | Overwriting the destination needs the actual copy to finish |
| Sixteen-byte Shared-source reuse | All four original words reach the Global destination before a second wave overwrites the Shared source |
| Two sixteen-byte regions | All 32 copied bytes complete before all 64 outputs observe the second region |
| No-output 128-byte destination reuse | All 128 asynchronous destination bytes complete before a second wave overwrites them; no Global output is invented |
| Four-byte Global-source reuse | The original input word reaches the copy output before a second wave replaces that input from a distinct initial word |

The basic copy and Global-source programs use ordinary load/store transport
without floating arithmetic on the copied words. The descriptor selects the
existing F32 storage profile. Complete symbolic output comparisons, exact
Tensor byte footprints and typed memory witnesses are separate assertions.

Fifteen CPU-only mutations remove Tensor completion, replace it with unrelated
load/DS completion, or remove publication. Each harmful candidate retains the
complete configured payload and the required memory conflict. The missing
publication control uses 128 independent scalar NOPs so the simulator's chosen
schedule initializes the tile before its read; those instructions supply no
completion or happens-before relation. No unsafe control is executed on hardware.

A completed Global read that happens before a later overwrite needs no cache
visibility from that future write. This narrowly avoids an inconclusive
read-before-write result while retaining the existing visibility checks for
all earlier writes, including writes hidden under an intervening read node.
Missing completion or publication still produces an actual Global ReadWrite
conflict. Native scope rules and all legacy AMD rules remain separate.

`references.json` pins supporting source-reference rows and keeps their
completion pending coordinator review. Shared-source transport is explicitly
separate from the original Global-source obligation. The no-output destination
test alone does not establish the opposite read-side storage lifetime or a
target-specific deallocation API.

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/portable-graph/async-memory
python3 tests/gfx1250/portable-graph/async-memory/check_mutations.py \
  --output /tmp/gfx1250-async-mutations.json
cargo test --release -p volta_pipeline --test gfx1250_async_memory_tests
cargo test --release -p volta_graph_check --test gfx1250_tests --test amdgpu_tests
```

The semantic sources are the public [LLVM DMA operations](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUDMAOperations.md),
[GFX125x memory model](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md#memory-model-gfx125x)
and the independently pinned [public descriptor recipe](../../fixtures/semantic-references.json).
The compiler provenance establishes encoding only; it contains no device-run
record or machine identity.
