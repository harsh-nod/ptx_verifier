# Complete HipKittens source inventory

[inventory.json](inventory.json) covers every tracked C/C++/HIP source in public
[HipKittens revision 8cde3dd](https://github.com/HazyResearch/HipKittens/tree/8cde3dd146bd1c4be78023b582c1f4375c48489f).
It records all literal `__global__` definitions and declarations, including archive,
analysis, training, distributed and unit-test sources. Each definition is identified
by source path and line, with its complete declaration, template prefix and hash.
Every source and upstream build recipe is separately hashed.

```sh
git submodule update --init external/sources/HipKittens
python3 external/extraction/hipkittens_inventory.py --check
python3 -m unittest discover -s external/tests -p test_hipkittens_inventory.py -v
```

To inspect another clean checkout of that exact public revision, supply
`--source-root /path/to/HipKittens`. Regenerate the inventory explicitly after
reviewing a changed source pin; `--check` refuses drift. Generation rejects a
different revision or a dirty source tree. It does not execute kernels or need
ROCm, a GPU, PyTorch or Python binding packages.

## Definitions, instantiations and native targets

A lexical definition is not an executable specialization. For example,
`softmax_tk<_D>` has one source definition while the upstream Python binding
instantiates its configured `D`. Launch expressions are retained without guessing
values for arbitrary C++ template parameters. Compiler AMDHSA metadata determines
which concrete entrypoints a translation unit actually emits. A unit-test wrapper
can serve many type/shape combinations selected by the upstream test definitions;
its one declaration does not establish that all those combinations compile.

The inventory includes headers containing kernel wrappers and all standalone
`.cpp`, `.cu` and `.hip` translation units. A source fragment, an unused template,
a missing dependency, a compiler rejection, a parser rejection and a completed
execution are different outcomes. A file that emits no kernel must not count as
an analyzed kernel, and parsing a module does not establish a correct launch or
mathematical result.

Profiles follow the architecture directory, explicit build rules and the shared
upstream default where no architecture is named. Shared unit wrappers retain
multiple profile references; those references are not additional definitions.
The source bytes, compiler target and emitted wave-size metadata remain the
execution authority.

| Upstream source profile | Native target | Scope |
|---|---|---|
| CDNA3 | gfx942 | Original CDNA3 definitions and build settings |
| CDNA4 | gfx950 | Original CDNA4 definitions and wave64 primitives |
| CDNA5 | gfx1250 | Separate native CDNA5 definitions and their build settings |

The pinned tree contains a public gfx1250 GEMM ladder, including cluster variants.
Those are original CDNA5 kernels. Changing CDNA4 macros or wave64 launch settings
is not a valid way to obtain them. Compiler/toolchain and verifier refusals must
remain explicit for any unsupported cluster or instruction profile. Whole-source
compilation and actual launch/output contracts are required before making a
support claim.
