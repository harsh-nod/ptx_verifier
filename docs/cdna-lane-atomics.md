# CDNA4 lane selection and reduction

The gfx950 backend supports bare `v_readlane_b32` and `v_writelane_b32` with
plain SGPR/VGPR words and either a literal lane 0–63 or a plain SGPR selector.
The low six selector bits choose the lane. Both instructions ignore EXEC,
including empty EXEC, but cannot access unlaunched lanes or undefined words.
Modifiers, special-register selectors and other encodings remain outside this
bounded execution profile. CDNA4 allows one distinct SGPR source per VALU
instruction: a scalar-selected lane write must use the same SGPR for its data
and selector. Two distinct SGPR sources are refused.

Instruction records retain the selected VGPR lane and the selector SGPR as
separate dependencies. The checker requires four independent instruction states
after a VALU writes a selector SGPR, two for ordinary scalar data, and one from
a VGPR write to a lane read. Pending scalar loads still need LGKM completion.
The matching `v_mbcnt_lo_u32_b32`/`v_mbcnt_hi_u32_b32` EXEC-word inputs support
lane-rank computation with ordinary scalar-data dependencies on EXEC aliases.

The bare three-operand `global_atomic_add_f32` profile supports one active lane
per wave, a 64-bit SGPR base and an unsigned 32-bit VGPR byte offset. It has no
return register, requires an aligned in-bounds DWORD, and charges VM only.
The address, data and both base words remain live until VM0 or the implicit
end-of-program drain. Other policies, returned values, XNACK replay and
multi-lane issues remain unsupported. Unsequenced cross-wave atomic
serialization remains inconclusive. Atomic addition follows the existing
mathematical-real model; IEEE rounding and FP32 denormal flushing are outside
the numerical proof.

The [complete reduction test](../crates/volta_pipeline/tests/gfx950_reduction_qualification_tests.rs)
uses the unchanged registered `portable-f16.s` entry `reduction_f16`, block 128,
grid `[1,1,1]`, all 4,096 declared half inputs, and the original single in/out
float output. It proves the full existing selected-workgroup specification:
the initial output plus the first 256 input elements. This is one selected
tile; it does not establish a 4,096-element whole-grid reduction. Historical
benchmark manifests and results retain their original revision's outcomes.

The contracts follow AMD's public [CDNA4 ISA reference](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
§4.4–4.5, §10.3.1–10.4 and the V_READLANE, V_WRITELANE, V_MBCNT and
GLOBAL_ATOMIC_ADD_F32 instruction definitions. LLVM's
[lane instruction definitions](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.0/llvm/lib/Target/AMDGPU/VOP2Instructions.td)
separately identify lane transport as independent of EXEC.
