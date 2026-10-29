# Native gfx1250 ABI and bounded-memory controls

These four HIP files compile to nineteen native wave32 entry points. Their
checked-in assembly is genuine compiler output. `compiler-provenance.json`
records the source, assembly, object and code-object hashes and exact commands.
Compiler and assembler success alone do not establish interpreter or graph
acceptance. End-to-end controls live in
`crates/volta_pipeline/tests/gfx1250_portable_abi_tests.rs`.

Regenerate from the repository root with:

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/portable-abi
python3 tests/gfx1250/portable-abi/assemble_mutations.py --check
python3 -m unittest discover -s tests/gfx1250/portable-abi -p 'test_*.py'
CARGO_HTTP_CAINFO=/home/harsh/.codex-openai/ca-combined.pem \
  cargo test --release -p volta_pipeline --test gfx1250_portable_abi_tests
```

`cases.json` preserves all thirty-one original reference paths and their source
hashes, explicit output obligations and target-specific residuals. The native
test mapping awaits end-to-end validation and coordinator review; its presence
does not close a parity gate. `mutations.tsv` defines six single-instruction
CPU-only controls. The assembler receipt pins their exact expanded assembly and
objects. A missing control or a stale source hash is a host validation failure.

`native-module-globals` has bounded writable scalars and a read-only initialized
constant table. Its native relocation is the contiguous
`s_get_pc_i64 s[p:p+1]` / `s_add_nc_u64 s[p:p+1], s[p:p+1], object@rel64+4`
profile. The linker computes `S+A-P`; lowering recognizes only this exact
construction for a defined object with a known size and alignment. Branches
into its second stage, mismatched registers/addends, unbounded externs, GOT
forms and unrelated PC arithmetic are outside the profile. Both source PCs
remain present. The no-carry instructions preserve SCC; their intermediate PC
words are opaque.

`native-arguments` retains positional pointer/F32/F64/signed16/unsigned8
arguments, including undefined padding, and all nine ordinary XYZ grid/group/
block fields. It makes no clustered-launch claim.

Native B32 memory instructions do not encode an integer or floating dtype.
Constant-output controls therefore contain explicit U32 or F32 add-zero
identity instructions after raw transport. U32 identities preserve every bit;
the F32 identities here consume only the positive finite constants7,9,42 and
preserve their bits and values. The verifier does not infer an output dtype
from the C++ pointer declaration or guess an interpretation of raw constants.

`native-dynamic-lds` retains real fixed-storage padding and a separate external
LDS window. `native-transfers` covers complete wide transfers, independent byte
and halfword values, partial-word writes, exact allocation ends, signed-boundary
global addresses and logical partitions. The scalar-base FLAT form has a
concrete vector DWORD offset plus a scalar address pair; the vector-pair form
has the ordinary 64-bit address. A shared-aperture high-word token stays opaque
and routes only the complete bounded transfer to LDS. No numeric shared base,
private aperture, scratch address or source-level object is inferred.

Native access alignment and wave32 ownership are explicit target differences.
These controls do not emulate PTX `cvta`, `mapa`, cluster registers, TMEM
quadrants or allocation handles. Their portable output and memory obligations
are assessed separately from those NVIDIA mechanisms.

Primary source pin: ROCm LLVM
[`5fd50ec8e07abb94e203933017e8d6e40fb51824`](https://github.com/ROCm/llvm-project/tree/5fd50ec8e07abb94e203933017e8d6e40fb51824).
See `llvm/lib/Target/AMDGPU/SOPInstructions.td` (`S_GETPC_B64`, `S_ADD_U64`,
their renamed real forms and SCC definitions), `lld/ELF/Arch/AMDGPU.cpp`
(`R_AMDGPU_REL64`), and
[`llvm/docs/AMDGPUUsage.md`](https://github.com/ROCm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/docs/AMDGPUUsage.md)
(ELF relocation table and
generic address-space apertures). The actual compiler binary and its distinct
build revision remain recorded in the compiler receipt.
