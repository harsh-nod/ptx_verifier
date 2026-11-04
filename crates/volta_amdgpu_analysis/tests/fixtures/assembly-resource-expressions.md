# Absolute assembly resource constants

The frontend accepts a bounded, immutable subset of LLVM AMDGPU assembly
constants: integer bit patterns, symbol references, unary signs, parentheses,
checked addition/subtraction, signed variadic `max(...)` and bitwise variadic
`or(...)`. Both functions require at least one argument. Forward references are
resolved before entry instruction normalization; every definition must resolve,
including definitions not referenced by an entry.

The public LLVM definitions are pinned at
[5fd50ec8e07abb94e203933017e8d6e40fb51824](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/MCTargetDesc/AMDGPUMCExpr.cpp#L50):
`getNumExpectedArgs`, `op` and `evaluateAsRelocatableImpl` specify the argument
count, signed maximum and bitwise OR over absolute arguments. LLVM's
[function resource usage documentation](https://llvm.org/docs/AMDGPUUsage.html#function-resource-usage)
shows compiler-generated `.set` expressions for registers and stack sizes.

This is a strict subset of the assembler expression language. Unknown functions,
relocations, undefined names, cycles, arithmetic overflow and excess depth/size
are rejected. `.set` and `.equ` reassignment remain explicitly unsupported:
[LLVM allows reassignment](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/MC/MCParser/AsmParser.cpp#L2899),
which requires preserving the value visible at each use. Resolving every use to
the final value would be incorrect. `.equiv` is also nonredefinable. Known
constants remain available to the existing exact data-object initializer grammar;
forward object-data references and arbitrary expressions in other directives do
not gain support from this feature.

Resolving resource annotations does not implement calls, scratch memory, compiler
hostcall routines, new instructions, string objects or relocation-bearing data.
Those remain independently checked. Symbolic register indices and control
immediates still pass their existing allocation and encoding validation after
substitution. Native source spans remain unchanged.

```sh
cargo test -p volta_amdgpu_analysis --test assembly_constant_expressions
cargo clippy -p volta_amdgpu_analysis --all-targets -- -D warnings
```

For an independent assembler check, assemble the same finite expressions with
`llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx950 -filetype=obj`, then inspect
absolute symbol values with `llvm-readobj --symbols`. Use full original compiler
modules to measure parser progress; later refusals and unchanged launch/proof
coverage must remain explicit.
