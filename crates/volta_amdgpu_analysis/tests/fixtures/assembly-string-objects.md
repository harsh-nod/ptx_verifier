# Initialized assembler string objects

The frontend accepts one quoted `.asciz` literal in an active, explicitly
declared module object. Printable ASCII is stored unchanged. The supported
escapes are `\\`, `\"`, `\n`, `\r` and `\t`; one terminating NUL is always
appended, including for an empty literal.

```asm
.type message,@object
.section .rodata,"a",@progbits
.p2align 4,0
message:
.asciz "line\n"
.size message,6
```

The example initializes exactly `6c 69 6e 65 0a 00`. The object retains the
section's read-only attribute, 16-byte alignment and exact declared size.
The existing module allocation model checks every byte and keeps writes to a
read-only object unavailable as successful outputs.

This is a bounded subset of LLVM's
[`parseEscapedString` and `parseDirectiveAscii`](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/MC/MCParser/AsmParser.cpp#L3000).
It refuses unknown escapes, hexadecimal/octal escapes, non-ASCII or literal
control characters, unterminated strings, multiple or adjacent literals and
trailing tokens. `.string` remains outside the profile. Plain `.ascii` retains
its existing printable-ASCII/no-escapes/no-terminator contract.

The encoded contents are limited to 16 MiB minus one byte, leaving room for
the required NUL. Decoded bytes and all other initializers together must fit
the existing 16 MiB object envelope. `.size` must equal the complete byte
count, including every NUL; section transitions, unsupported sections,
conditional alignment and executable inline data remain refused. An `.asciz`
outside a declared active object is explicitly refused instead of discarded.

Storage type is separate from writability. `.bss` and implicit `.bss.*` sections
use NOBITS storage: every initializer must produce zero bytes. The shared check
also applies to numeric, fill and plain-ASCII initializers. An empty `.asciz`
is legal there because its sole byte is the zero terminator. Explicit custom
PROGBITS/NOBITS types take precedence over a subsection's name; for example,
`.bss.custom` with `@progbits` can contain nonzero initialized data. Canonical
`.data`/`.rodata` cannot change to NOBITS, canonical `.bss` cannot change to
PROGBITS, and a previously used supported data section cannot change storage
type. Unknown storage types in supported data sections are refused. This does
not implement arbitrary ELF section flags or linker merging rules. Supported
`.rodata` and `.rodata.*` names keep a read-only contract: an explicit `w` flag
is refused, including on a later section declaration. Writable `.data` and
`.data.*` objects retain their existing support. The read-only name restriction
also conservatively refuses a new custom `.rodata.*` section whose writable
flags an assembler might otherwise permit.

String contents are data. They do not implement device assertions, hostcall
helpers, calls, return stacks, relocations or string merging/address identity.
Entry instructions retain their existing checks, including unsupported calls
and unreachable instructions. Source text and spans remain unchanged.

```sh
cargo test -p volta_amdgpu_analysis --test assembly_string_objects
cargo test -p volta_amdgpu_analysis --no-fail-fast
cargo clippy -p volta_amdgpu_analysis --all-targets -- -D warnings
```

Independent LLVM MC checks compare the ELF bytes for the accepted literal
profile on all three targets. Whole-module parser comparisons must retain
later refusals: making a compiler assertion-format object readable does not
establish a complete parse, execution, graph-safety or mathematical proof.
