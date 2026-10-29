# volta_cli

The `volta` binary (`src/main.rs`). It parses command-line flags into an
`AnalysisConfig`, drives `volta_pipeline`, and prints results with exit codes.
It holds no verification logic of its own.

| command | does | exit |
|---------|------|------|
| `volta parse <file>` | syntax check | 0 / 1 |
| `volta analyze <file> -k K ...` | analysis + target-selected graph checks: prints the symbolic outputs, a per-instruction-kind profile (`--no-profile`), each check's verdict, any deadlock and the first failure; `GRAPH VERIFICATION: VERIFIED \| REJECTED \| UNKNOWN` | 0 / 1 / 2 |
| `volta compare <ref> <opt> --kernel1 .. --kernel2 .. --check-array A` | both kernels through both branches, then `decide`: `VERDICT: ACCEPT \| REJECT \| UNKNOWN` | 0 / 1 / 2 |
| `volta verify <file> <spec> -k K --dim N=..` | one kernel against a `.spec` (file or inline string), through both branches and `decide` | 0 / 1 / 2 |
| `volta viz <store> -o page.html` | the `volta_viz` page over a run store | |

## Flow of a command

```text
source + backend/target + launch flags ──► KernelModule + AnalysisConfig
                                                  │
                                    verify_source_kernel
                                      │           │
                        graph report ─┘           └─ symbolic outputs
                             │                            │
                analyze: graph verdict         compare/verify: equivalence
                                                        + graph evidence
                                                              │
                                                           decide
```

- **Launch flags** (shared by `analyze`/`compare`/`verify` via the flattened
  `LaunchArgs`): `-b/--block`, `-g/--grid`,
  `--array name:base:elem_width:len:in|out|inout|index`,
  `--param int:N|float:X|sym:name|ptr:array` (in declaration order), globals,
  dynamic shared size. `--config FILE` replaces them all with a JSON launch
  file (`volta_ptx_analysis`'s `launch_file` format), whose `"kernel"` is the
  default `--kernel` of `analyze`/`verify`. `compare` adds `--block2/--grid2`
  for the optimized kernel.
- **Equivalence flags**: `--sample N`, `--verify-numeric`,
  `--recycle-terms N`, `--iterations N`.
- **Artifacts**: `analyze --emit-exprs FILE` (`.vexpr`) and `--dump-graph FILE`
  (`volta-graph 2` with native AMD events, otherwise version 1). These graph dumps are
  diagnostic text, not replay inputs. `compare --dump-vcs FILE` executes and
  checks both kernels before saving their expressions. `compare --exprs a.vexpr b.vexpr` and `--from-dump FILE` skip execution and run equivalence
  only; success prints `EQUIVALENT` without a graph-verification verdict.
- **Logs**: every run writes a `volta_common::run_log` file (`--log-dir`,
  `--no-log-file`). Build with `--features logging` and pass
  `--log-level info` to narrate the stages.

```sh
cargo run --release -p volta_cli -- analyze relu.ptx -k relu -b 128 \
  --array x:0x10000:4:128:in --array out:0x20000:4:128:out \
  --param ptr:x --param ptr:out

cargo run --release -p volta_cli -- analyze relu.ptx --config relu.json
```

See the top-level `README.md` for the full flag reference.

## Native gfx1250

Use `--backend amdgpu --target gfx1250` with `parse`, `analyze`, `verify` and
`compare`. The same launch JSON, output footprints, numeric confirmation,
expression/VC replay, profiles, logs and graph viewer apply. Source targets
must match explicit selection; omitted AMD targets remain gfx950. Native graph
failures exit 1, inconclusive checks exit 2, and success exits 0. Expression-only
replay reports equivalence without claiming any graph checks. See the
[gfx1250 compiler corpus](../../tests/gfx1250/README.md) for the wave32/ABI subset
and source-pinned gfx1250 hardware validation receipts.
