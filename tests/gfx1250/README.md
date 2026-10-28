# Native gfx1250 software validation

Work in progress for [issue 13](https://github.com/harsh-nod/ptx_verifier/issues/13).
These fixtures are genuinely cross-compiled for gfx1250 with the pinned ROCm
LLVM toolchain. Their assembly is not rewritten from another target.

**No gfx1250 hardware execution has been performed.** Hardware validation is
explicitly skipped for this software task because no target device is available.
Compiler/assembler acceptance and CPU semantic tests cannot replace hardware
evidence. gfx942/gfx950 devices are not gfx1250 hardware substitutes.

`cases.json` uses the existing native case schema for CLI/Python integration.
Each required case remains pending until its graph checks, complete footprint
and independent mathematical reference are validated. Initial copy/add,
cross-wave LDS, wave32 reduction and multidimensional ID configurations are
listed. The WMMA and tensor sources initially establish only emitted syntax
and ABI; they are not counted as successful semantic tests.

Cross-compilation needs no GPU:

```sh
python3 tests/gfx1250/compile_fixtures.py tests/gfx1250/fixtures
```

The default toolchain is `/opt/rocm-7.2.0/lib/llvm/bin`, AMD LLVM 22, compiler
revision `7b800a19466229b8479a78de19143dc33c3ab9b5`. The old default LLVM 18
is not used. `fixtures/compiler-provenance.json` records actual commands,
tool/source/assembly/object/code-object hashes and the hardware exclusion.

The compiler's tensor builtin takes D0/D1/D2/D3 plus cache policy. The newer
LLVM reference adds a reserved D4 argument. The source uses the actual
installed compiler's signature and retains its unchanged four-group machine
instruction; those signatures must not be conflated.

Target geometry, replay-sensitive behavior, descriptor bounds and individual
instruction semantics require separate primary-source contracts. In particular,
gfx1250 is wave32 with hardwired XNACK; it must not inherit the existing
wave64 replay-disabled assumptions. Workgroup-zero analysis does not certify
cluster or whole-grid behavior. The existing mathematical-real abstraction
does not establish IEEE rounding/NaN/denormal equivalence.
