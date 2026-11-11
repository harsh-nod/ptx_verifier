# volta_common

Base utilities shared by Volta's crates. It depends on no other Volta crate.

- **Shared configuration** (`config.rs`): `AnalysisConfig`, `ArrayDef`,
  `ArrayKind`, `ParamValue` and `SharedAllocation` describe launch dimensions,
  inputs/outputs, parameters and optional native LDS subobjects. Common validation
  checks geometry, binding identities and allocation layout; target-specific ABI,
  by-value payload sizes and execution restrictions stay in the selected analyzer.
  Parameters include PTX structured fields and native AMD byte payloads; each
  analyzer rejects forms outside its ABI. Both analyzers re-export the main
  launch types for compatibility; aggregate fields and tensor-map definitions
  are available directly from `volta_common::config` and `volta_common::tensor_map`.
- **Selected native workgroup** (`AnalysisConfig.workgroup_id`) defaults to
  `(0,0,0)` and must be inside `grid_dim`. AMD analysis executes only this group;
  PTX rejects nonzero selection. Array indices and dispatch dimensions retain
  their original meaning.
- **Tensor-map fields** (`tensor_map.rs`): host descriptor values used by launch
  configuration and PTX lowering, independent of interpreter operands.
- **`span::Span`** (`span.rs`): a source location with named `start` and `end` byte offsets, built with `Span::new`.
- **`report::Locate<E>`** (`report.rs`): an error wrapper that adds an optional span and
  file path to an error kind `E`. Each crate defines an error kind enum and
  aliases `Locate<Kind>` as its error type. As an error travels up,
  `locate_span` and `locate_path` attach a span or path if none is set yet, so
  the innermost (most precise) location wins.
- **`FileCache`** (`file_cache.rs`): reads each file once and serves that copy
  afterwards, so error reports always quote the same version of the source the
  parser saw.
- **`report_error`** (`report.rs`): renders an error as a titled message with
  the source snippet at its span, colored with ANSI escapes and wrapped to the
  terminal.
- **`position`** (`report.rs`): where a byte offset falls, as a 1-based line
  and column (in characters) and that line's text. `report_error`'s
  `path:line:column` header and `volta_py`'s error messages both use it.
- **`logging`** (`logging.rs`): the `debug`, `info`, `trace` and `warn` macros
  the other crates log through. With the `logging` feature they are `log`'s
  own; without it, a stand-in compiles its arguments in a branch that never
  runs, so a value computed only for a log still counts as used. Each crate's
  own `logging` feature turns on this one.
- **`run_log::RunLog`** (`run_log.rs`): the per-invocation log file the
  `volta` binary writes (`<unix-seconds>-<pid>-<command>.log` under
  `--log-dir`, default `volta-logs/`). With the `logging` feature, `tee`
  mirrors an `env_logger` target into it.

The [parameter guide](../../docs/launch-parameters.md) describes positional
arguments, PTX field layouts and native byte payloads. Shared configuration
types do not imply that every backend or Python constructor accepts every form.

```sh
cargo test -p volta_common
```
