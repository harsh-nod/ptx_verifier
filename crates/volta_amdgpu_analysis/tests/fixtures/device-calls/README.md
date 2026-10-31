# Compiler call fixtures

These complete standalone LLVM modules use real `noinline` functions. Their
assembly is the unedited output of public ROCm LLVM revision
`7b800a19466229b8479a78de19143dc33c3ab9b5` (LLVM 22 development version):

```sh
llc -march=amdgcn -mcpu=gfx950 -O=2 -filetype=asm leaf.ll -o leaf.s
llc -march=amdgcn -mcpu=gfx950 -O=2 -filetype=asm nested.ll -o nested.s
llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx950 -filetype=obj leaf.s -o leaf.o
llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx950 -filetype=obj nested.s -o nested.o
```

Both complete assembly modules are accepted by that compiler's assembler. The
leaf body uses a native wait, vector addition and scalar return. Its kernel also
moves runtime queue-pointer registers; unavailable runtime inputs must remain a
refusal. The nested helper spills through scratch memory and remains unsupported.
Neither fixture justifies stubbing a function or dropping a prologue. The
handwritten controls in `device_calls.rs` separately exercise successful calls,
nesting, exact return identity, shared state and independent wait checking.

The finite code-address profile follows [CDNA4 ISA §12.3](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf)
and the pinned [LLVM SOP1 definitions](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/SOPInstructions.td#L312).
It preserves the [native calling convention](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/AMDGPUCallingConv.td#L19)
by executing physical registers and instructions, without synthesizing clobbers
or caller/callee saves.
