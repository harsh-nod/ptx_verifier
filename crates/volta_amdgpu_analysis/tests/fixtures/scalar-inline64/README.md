# Scalar inline64 word controls

These three handwritten modules are separately accepted by public ROCm LLVM
`7b800a19466229b8479a78de19143dc33c3ab9b5` for gfx942, gfx950 and gfx1250.
Each complete module has one active lane, an eight-byte output allocation, an
eight-byte output-pointer argument and both absolute u32 output coordinates.
The bodies store the low and high words of `s_mov_b64 ...,1.0` without a numeric
floating-point conversion. Explicit argument metadata is part of each fixture.

The required words are `[0, 1072693248]` (`0x3ff0000000000000`). The earlier
verifier at `4b0e766a265390900f4450cab54398f1cb5cbf86` instead produces
`[1065353216, 0]` on the validated gfx950/gfx1250 controls: it zero-extends FP32
bits. Both complete traces pass their graph checks while refuting both output
coordinates against `one.spec`. This is a verifier semantic defect; these
synthetic controls make no original-kernel, hardware or speedup claim.

Public precision-specific inline rules are documented in the
[CDNA3 ISA §6.2](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[CDNA4 operand table](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
[CDNA5 ISA §4.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
and [LLVM's inline64 emitter](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/MCTargetDesc/AMDGPUMCCodeEmitter.cpp).
Selector 248 uses exactly `0x3fc45f306dc9c882`; nearby decimal values are not
encoding certificates. The instruction's operand position still matters:
`s_lshl_b64` and `s_lshr_b64` use a 64-bit data source and a 32-bit shift count.

From this directory, assemble and verify a complete target-specific control:

```sh
llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx1250 -filetype=obj gfx1250.s -o /tmp/inline64.o
volta verify gfx1250.s one.spec --config gfx1250.launch.json \
  --backend amdgpu --target gfx1250 --dim N=2 --sample 0 --verify-numeric
```

`provenance.json` and `gfx942-provenance.json` retain exact compiler/source/object
hashes and original producer commands. Producer paths and original filenames in
these raw records are retained; the packaged assembly bytes match their source
hashes. The first records cover the two metadata-complete controls, while the
latter records the separately assembled gfx942 control.

The regression also checks both binary operand positions, aliases, SCC/EXEC,
all supported inline bits, mixed-width shifts and pending scalar loads. Direct
AST negative-inline cases check the typed-value API without broadening the
source lexer's negative-modifier profile. Raw integer literals, 32-bit consumers,
mathematical FP64 evaluation and the selected AND64/CMP64 restrictions keep their
existing profiles.
