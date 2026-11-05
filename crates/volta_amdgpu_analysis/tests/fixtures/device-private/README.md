# Whole compiler stack-call fixtures

`stack-leaf.ll` and `stack-nested.ll` are new complete LLVM modules. Their
noinline leaf performs a volatile private DWORD store/load, then adds1 to one
F32 input. The nested outer actually calls that leaf and adds3. Each entry
retains all64 input and output coordinates. Their separate complete
specifications are `x+1` and `x+4` under the existing mathematical-real model.
No original HipKittens module or earlier call fixture was rewritten.

The assembly is unedited output of the local `AMD LLVM version 22.0.0git`
toolchain, whose binary hashes are recorded. Its build source revision has not
been verified: the version output and hashes alone do not establish it.
`7b800a19466229b8479a78de19143dc33c3ab9b5` is the pinned public
semantics/source reference, not an attested compiler build revision.
Source functions and entry truthfully
exclude the four unused dispatch/queue/dispatch-ID/implicitarg inputs with the
same public attributes as the earlier qualified call fixture. They do not
declare `memory(none)` on functions accessing the private stack. Work-item X
remains enabled. There is no removed prologue, callee stub or synthesized ABI
register value.

Reproduce the complete files, for `NAME=stack-leaf` and `NAME=stack-nested`:

```sh
llc -march=amdgcn -mcpu=gfx950 -O=2 -filetype=asm NAME.ll -o NAME.s
llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx950 -filetype=obj NAME.s -o NAME.o
llvm-readobj --notes --symbols NAME.o
volta verify NAME.s NAME.spec --backend amdgpu --target gfx950 \
  --config NAME.launch.json --dim N=64 --sample 0 --verify-numeric
```

`provenance.json` binds source, whole assembly, generated object, launch,
specification, tool hashes and retained baseline receipts. Both complete modules
were accepted by llc and MC. The frozen baseline refused called
`scratch_store_dword` before execution. Two initial verify CLI usage errors are
retained separately from the corrected semantic attempts; neither is a kernel
result. No timing, GPU result or original-kernel coverage claim is supplied.

The kernel explicitly initializes s32. The nested outer preserves an initially
unspecified s33 by exact transport; initializing it to numerical zero would
alter the program. Fixed private extents are8 and24 bytes with original compiler
dynamic-stack flags retained. The active leaf accesses use `sc0 sc1`, with VM0
between store/load and before consuming the load. The nested outer's folded
spill/reload under complemented EXEC is inactive for this full-wave launch;
the leaf's active volatile operations provide the actual scratch exercise.

The launch is grid1/block64/workgroup0 with two disjoint64-element F32 arrays,
out/input pointers at kernarg0/8 and kernarg size16. The native tests execute
the entire generated module, check the independent graph, require all64 output
roots and compare the complete specification with numerical confirmation. The
separate handwritten controls exercise opaque private return-word spills,
corruption, unknown-word observations, partial launches and wait failures.
