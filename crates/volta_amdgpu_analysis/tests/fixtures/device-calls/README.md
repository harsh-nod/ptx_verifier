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


`qualified-add1.ll` is a separate positive source: its noinline leaf returns
`x + 1` for each of 64 F32 inputs. Both the leaf and kernel truthfully declare
`amdgpu-no-dispatch-ptr`, `amdgpu-no-queue-ptr`, `amdgpu-no-dispatch-id` and
`amdgpu-no-implicitarg-ptr`: neither uses these runtime values, directly or
transitively. The pinned [LLVM ABI hint contract](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/docs/AMDGPUUsage.rst#L1829-L1880)
warns that depending on a value excluded by a hint is undefined behavior.
The [call lowering](https://github.com/ROCm/llvm-project/blob/7b800a19466229b8479a78de19143dc33c3ab9b5/llvm/lib/Target/AMDGPU/SIISelLowering.cpp#L3814-L3843)
omits passing the excluded values. These hints do not provide arbitrary
hostcall or private-memory support.

The complete, unedited generated `qualified-add1.s` retains actual REL32
construction, SWAPPC, the leaf's wait/add/SETPC and the kernel's final store/END.
There are no scratch or lane-spill instructions. Compiler dynamic-stack and
private-enable descriptor flags remain intact with zero fixed private bytes.
The source was written before its first compilation; its prologue was not
removed. `qualified-add1-provenance.json` pins the source, assembly, generated
object, launch, specification, public references and exact compiler tools.
Reproduce with the commands above, replacing `leaf` by `qualified-add1`.

The launch has one wave64 workgroup, two disjoint 64-element F32 arrays and
output/input pointers at kernarg offsets 0/8. The test executes the whole module,
checks the independent graph, and compares every output coordinate with
`qualified-add1.spec`, including numerical oracle confirmation under the existing
mathematical-real model. No GPU behavior or physical rounding result is claimed.

```sh
volta verify qualified-add1.s qualified-add1.spec \
  --config qualified-add1.launch.json --dim N=64 \
  --backend amdgpu --target gfx950 --sample 0 --verify-numeric
```
