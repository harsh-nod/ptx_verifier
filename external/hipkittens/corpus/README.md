# Complete HipKittens source inventory

[inventory.json](inventory.json) covers every tracked C/C++/HIP source in public
[HipKittens revision 8cde3dd](https://github.com/HazyResearch/HipKittens/tree/8cde3dd146bd1c4be78023b582c1f4375c48489f).
It records all literal `__global__` definitions and declarations, including archive,
analysis, training, distributed and unit-test sources. Each definition is identified
by source path and line, with its complete declaration, template prefix and hash.
Every source, Makefile, CMake project and shell build/benchmark input is separately
hashed.

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

The inventory includes headers containing kernel wrappers and every `.cpp`,
`.cu` and `.hip` source probe. `source_role` distinguishes included source
fragments, other translation-unit sources, kernel headers and ordinary headers.
Relative quoted include edges record the actual parent and source line. These
lexical edges retain conditional includes; they do not evaluate the preprocessor
or guess compiler include-path resolution. A source fragment, an unused template,
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

The main pin includes CDNA3 sources. The separate public `cdna3` branch is a
different source revision and is outside this inventory; it requires its own pin
and campaign rather than substitution into a main-pin report.

## Compile, assemble and analyze a campaign

The campaign driver attempts every suffix-selected source probe under its
original architecture profile, including included fragments as explicitly labeled
probes. A fragment's failure when compiled alone does not establish a broken
application build. The driver obtains defines, optimization and math
flags from the pinned upstream Makefile's dry run, then invokes ROCm clang directly
with device-only assembly output. Host linking, output filenames, diagnostic-only
flags and temporary-file settings are removed; kernel sources are not rewritten.
Printed shell pipelines and log-directory commands are never executed. Unit
sources use the upstream `TEST_ALL` selector and `TEST_INTENSITY=2` sweep.
Absolute `SRC` paths retain archive sources outside a parent Makefile directory;
`TARGET` and `KERNEL` set host artifact names. Sources with another build system
remain `recipe_unavailable` until an exact recipe/dependency profile is configured.
For example, the distributed CMake project requires external Iris and MPI; the
driver does not automatically fetch a mutable Iris branch.

```sh
uv run external/extraction/hipkittens_corpus.py \
  --binary /absolute/path/to/volta --binary-revision SOURCE_COMMIT \
  --output /tmp/hipkittens-baseline --jobs 2 --timeout 180
```

The output must be a new directory outside the repository and upstream checkout.
`--source-root` selects another clean checkout of the pinned revision. Use
`--source relative/path.cpp` repeatedly to select translation units, or `--target`
to filter original profiles. The filter never retargets source. `--compiler`,
`--assembler`, `--rocm` and `--pybind11-include` select installed tooling; normal
`uv run` supplies the small Python binding/YAML dependencies. No GPU, PyTorch or
AITER installation is required unless an original source itself includes those
external dependencies; such missing dependencies are retained as compiler
failures, not silently removed from source.

Each source/profile probe retains its role, include parents, upstream recipe, actual compiler
arguments, source/assembly/object hashes, emitted AMDHSA kernel metadata and
separate recipe/compile/assemble/parse/analyze process records. Signals, timeouts,
missing tools, normal compiler rejections and unsupported parser forms have
separate statuses. The target and emitted wave size must match the original
profile. A successful compiler invocation with no entrypoints is reported as
`compiled_no_entrypoints`, not kernel support.

Analysis uses an existing exact launch contract where available: the original
softmax, rotary and BF16 GEMM configurations from the legacy CDNA4 extractor.
Other emitted entrypoints remain `launch_contract_required`; the driver does not
invent tensor dimensions, by-value payloads or reduced executions. Successful
analysis requires the expected per-array footprint and passing graph properties.
It is a graph-safety result, not a mathematical-equivalence or whole-grid claim.
All source and validation helpers plus their hashes are copied into the raw run
for reproducibility; changing them during a campaign invalidates the final report.
Machine paths and raw diagnostic logs remain outside Git.

Schema version 1 used `standalone_translation_unit` for filename-suffix selection;
that name did not establish a source's build role. Version 2 calls the same
selection `translation_unit_probe` and records roles independently. A version 1
report and its original inventory/source snapshots remain immutable when joined
to newer role annotations or compared with a separately run recipe correction.
Retain every attempted probe, including the original recipe failures and timeouts.

## Original register-vector specialization proofs

`hipkittens_vectors.py` reuses the complete compiler/MC-accepted CDNA4
`tests/unit/cdna4/warp/memory/vec/global_to_register.cu` module from a campaign.
The original intensity-2 sweep instantiates seven register-tile shapes, four size
multipliers, three dtypes and three vector layouts: 252 concrete entrypoints.
The extractor refuses missing, duplicate, unfamiliar or ABI-inconsistent
specializations. This finite decoder is tied to the pinned source and emitted
C++ symbols; it is not a general C++ template demangler.

The default `--profile copy` retains this 252-case selection and its original
identity and wrong-equation contracts. `--profile vec-add1` selects only the
`vec_add1` family in the complete original
`tests/unit/cdna4/warp/register/vec/maps.cu` module: the same seven register-tile
shapes, four size multipliers and three layouts, with the source's f32 dtype,
for exactly 84 original entrypoints. Other map operations and unfamiliar symbols
are refused. Neither profile rewrites assembly or reduces the host launch.

```sh
uv run external/extraction/hipkittens_vectors.py \
  --campaign /tmp/hipkittens-baseline \
  --binary /absolute/path/to/volta --binary-revision SOURCE_COMMIT \
  --output /tmp/hipkittens-vectors --timeout 60
python3 -m unittest discover -s external/tests -p test_hipkittens_vectors.py -v

uv run external/extraction/hipkittens_vectors.py --profile vec-add1 \
  --campaign /tmp/hipkittens-baseline \
  --binary /absolute/path/to/volta --binary-revision SOURCE_COMMIT \
  --output /tmp/hipkittens-vec-add1 --timeout 60
```

Each launch preserves the original host formula `SIZE=S*RT_SHAPE::cols`, dtype,
layout, grid of one workgroup, one 64-thread wave and 80,000-byte dynamic LDS
request. Both `GL` values retain their 16-byte native by-value ABI. A syntax-only
static-assert translation unit checks every instantiated GL's size, alignment and
pointer offset with the same compiler and flags as the original module. It adds
no executable code or changes to the original assembly.

The source host reference copies the whole input vector. Every case therefore
checks `out[i] = x[i]` over its complete original length, without sampling.
Verification requires an overall `ACCEPT`, all native graph properties passing,
and an exact full VC element count. An intentionally different equation must be
rejected with a mathematical mismatch on an otherwise passing graph for every
dtype with a verified original case. A dtype without one has an explicit
unavailable control. Unsupported forms, incomplete proofs, graph failures, process errors and
timeouts stay separate; 252 parsed entrypoints do not imply 252 proofs.

For `vec-add1`, the independent reference is the source's whole-vector host loop
`out[i] = x[i] + 1`, checked over every absolute output index `0..N-1` with
`N=S*RT_SHAPE::cols`. The wrong equation is `out[i] = x[i] + 2`. If no original
case passes the graph checks, this control may run on a complete mathematical
proof with a graph rejection. Its `math_refuted` and `graph_verified` fields stay
separate; a write/write rejection is retained and has no combined-control
`passed` field. When a case passes graph verification, the wrong-equation control
requires a mathematical mismatch on that passing graph. These specifications
use the verifier's mathematical-real model, not a hardware bit-exact float claim.

Raw outputs include the selected profile, source/module/binary/specification
hashes, original launch JSON, complete case identities, helper snapshots and
process records. Existing receipts bind their historical helper revisions and
are not rewritten when another profile is added.

Run the extractor once per frozen binary into distinct directories before any
comparison. These coverage runs make no latency claim; concurrent compilation
and verifier runs are unsuitable for measuring latency changes.

## Recorded baseline scope

[baseline.json](baseline.json) binds the public source pin, compiler/assembler,
verifier binary and source helpers to the complete baseline and separately
recorded recipe correction. Each measured driver revision is retained in Git;
use that revision to reproduce its recorded helper hashes after later code
changes. The initial 173 source/profile probes included 12
included-source fragments. All attempts remain in the denominator. Corrected
recipes added six MC-accepted modules; the explicit current overlay contains
68 modules with entrypoints and 3,484 emitted entrypoint occurrences. Three
modules parse in the baseline. These are compilation/parser counts.

The vector proof run records all 252 original specializations: 40 pass complete
graph and mathematical verification, 168 have typed write/write conflicts despite
identity-equivalent final outputs, and 44 reach unsupported buffer loads. The
208 complete identity proofs therefore establish a different property from the
40 combined accepts. Redundant same-value stores are not, by themselves,
evidence of a numerical application bug. bf16 and f16 wrong-equation controls
pass; the f32 control is unavailable because no f32 case passes the graph checks.

The receipt preserves the hash and counts of an earlier vector reporting error
that labeled the 168 graph rejections as `contract_error`; it never counted them
as verified. Corrected results are a separate run. Raw logs, absolute machine
paths and generated assembly remain outside Git. This is baseline coverage,
without a candidate comparison, hardware run or speed claim.

To check preserved stdout/stderr and process records with the current classifier,
without executing the verifier or changing the original run:

```sh
python3 external/extraction/hipkittens_reclassify.py /tmp/hipkittens-vectors \
  --output /tmp/hipkittens-vector-reclassification.json
```

The output must be a fresh file outside the repository. The receipt binds the
original report/driver, current classifier/shared checks, and every transcript's
hash. Changed outcomes, incomplete mathematical proofs and unavailable dtype
controls remain explicit. The recorded baseline's post-review reclassification
retains all 252 cases with zero outcome or proof-count differences.
