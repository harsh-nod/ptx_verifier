# HipKittens compiler and verifier frontier

[frontier.json](frontier.json) joins the complete [source inventory](inventory.json),
all original compiler attempts, a later recipe follow-up and a whole-module parser
replay. It uses unchanged public [HipKittens revision
8cde3dd](https://github.com/HazyResearch/HipKittens/tree/8cde3dd146bd1c4be78023b582c1f4375c48489f).
It does not execute kernels, invent launches or replace any historical report.

| Population | Count | Meaning |
|---|---:|---|
| Lexical kernel definitions | 140 | Source path + declaration line, including headers and archives |
| Definition/target references | 143 | Some common wrappers have two native profiles |
| Source/target probes | 173 | Suffix-selected `.cpp`, `.cu`, `.hip` probes; includes fragments |
| Preserved compiler attempts | 205 | Original 173 plus 32 recipe follow-up attempts |
| MC-accepted nonempty modules | 68 | Latest explicit attempt for each source/target |
| Metadata entry occurrences | 3,484 | Specializations across those modules, including repeated wrappers/helpers |
| Complete modules parsed | 7 | Parser success only, without a launch or output proof |

These populations have different denominators. In particular, 3,484 entry
occurrences are neither unique lexical kernels nor 3,484 verification results.
An included fragment that fails standalone compilation is not an application
build failure. A header definition has no artificial standalone probe. Every
lexical definition/target has a direct probe or explicit header relation and an
observed-entry disposition, including definitions with no emitted candidate.

The two original reports remain separately hash-bound. `selected_attempt` chooses
the latest explicit recipe attempt for that probe; the `attempts` array retains
both earlier failures and later attempts. Each attempt binds its available stage
records and stdout/stderr hashes. The selected attempts contain 69 compiler
rejections, six compiler timeouts, 25 compilations with no kernel entrypoints,
five recipe refusals/unavailable recipes and 68 accepted nonempty modules.

## Parser frontier

The replay used source `f0ee44285286aa1ea92f3e99aed6574ad89f3c82` and binary SHA-256
`57d555dbafee093f804b2c0744c477c4a5e567726aece81017f828647bdbc167`.
It parses each complete original assembly module, with its original target.
Results: seven parsed, 33 parser/profile rejections and 28 unsupported-instruction
refusals; no parser timeout or crash. All seven successes target gfx950. None of
the 11 gfx1250 or two gfx942 modules parsed in full.

| First blocker | Modules | Interpretation |
|---|---:|---|
| Compiler `max(integer, symbol)` resource constants | 16 | `.set` expression grammar, often in linked hostcall helpers |
| `v_rcp_iflag_f32_e32` | 15 | Unsupported instruction |
| Three-operand `buffer_load_dwordx4` | 8 | Outside the selected buffer operand profile |
| `global_load_async_to_lds_b128` | 6 | Unsupported instruction |
| BF16 WMMA followed by `matrix_a_reuse` | 4 | Four real operands plus an unsupported cache-reuse modifier |
| Three-operand `buffer_load_dword` | 4 | Outside the selected buffer operand profile |
| Other first blockers | 8 | Recorded individually with assembly line/hash and preceding function |

These are module counts, not independently failing kernels. The parser visits
whole modules, including compiler helpers. A first failure can obscure unrelated
entrypoints and later failures. In particular, accepting a reuse modifier without
modeling its cached-operand semantics would not establish correct execution.

The seven parser successes are the original vector copy, vector `vec_add1`,
vector reductions, rotary and three attention-preparation modules. Their metadata
contains 427 entry occurrences. Parsing these does not provide host dimensions,
by-value ABI, selected-workgroup output coordinates or numerical references.

## Definitions and launch evidence

Each entry records its metadata ordinal/hash, symbol and candidate lexical
source definition. The finite symbol decoder reads only an unqualified Itanium
source-name prefix; it does not infer template arguments, namespaces or host
launch dimensions. A relative quoted include chain provides 918 candidate
relations. The other 2,566 use a unique lexical name, principally common wrappers
resolved through compiler include paths. Both are labeled **candidates**:
conditional preprocessing and C++ instantiation identity are not proved by this
lexical join. Ambiguous or unrecognized names remain explicit rather than being
silently assigned. Repeated entry occurrences can refer to the same definition.

The ledger also imports the already published
[buffer comparison](buffer-comparison.json) by exact source, assembly, object,
symbol, launch and specification hashes. Those 336 original specialization
contracts were run with verifier revision
`0e634bc43536e5e4ac5cb13e8046d8e1edd57250`: 88 combined accepts, 224 graph
rejections and 24 unsupported results. Their revision remains separate from the
parser replay. Mathematical proofs on rejected graphs remain graph rejections;
parser success never upgrades a result. Other entrypoints explicitly retain
`launch_contract: required` and `verification: not_run`. These fields describe
this ledger's imported evidence, not an assertion that no other experiment or
launch contract exists elsewhere.

## Reproduction and maintenance

Keep raw campaign/replay directories outside the repository. The source checkout
must be clean at the inventory pin. The original compiler/assembler identities,
recipes and flags are bound by the original reports and stage hashes; the replay
does not recompile or repair sources.

```sh
python3 external/extraction/hipkittens_frontier.py \
  --source-root /path/to/pinned/HipKittens replay \
  --campaign /tmp/hipkittens-campaign \
  --binary /absolute/path/to/volta --binary-revision FULL_SOURCE_COMMIT \
  --binary-sha256 FULL_BINARY_SHA256 --output /tmp/hipkittens-parse-replay

python3 external/extraction/hipkittens_frontier.py \
  --source-root /path/to/pinned/HipKittens summarize \
  --campaign /tmp/hipkittens-campaign --replay /tmp/hipkittens-parse-replay

python3 external/extraction/hipkittens_frontier.py \
  --source-root /path/to/pinned/HipKittens summarize \
  --campaign /tmp/hipkittens-campaign --replay /tmp/hipkittens-parse-replay --check

python3 -m unittest discover -s external/tests -p test_hipkittens_frontier.py -v
```

`--campaign` contains `baseline-all/report.json` and
`recipe-followup/report.json`, including their original per-probe artifacts.
`replay` requires a fresh destination and checks the binary before and after.
`summarize` refuses missing/duplicate probes, missing accepted modules, changed
sources/artifacts/logs/metadata, wrong command or binary identities and incomplete
imported accepts. It publishes structured source-relative/numeric fields and
hashes rather than machine paths or free-form diagnostic logs. Binary-to-source
association and original compiler execution remain caller-attested; this report
is not independent ISA decoding, build attestation, hardware validation or a
whole-grid safety theorem.
