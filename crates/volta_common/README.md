# volta_common

Base utilities shared by the frontend, the analysis and the CLI. It depends on
no other Volta crate.

- **Shared configuration** (`config.rs`): `AnalysisConfig`, `ArrayDef`,
  `ArrayKind`, `ParamValue` and `SharedAllocation` describe launch dimensions,
  inputs/outputs, parameters and optional native LDS subobjects. Common validation
  checks geometry, binding identities and allocation layout; target-specific ABI,
  by-value payload sizes and execution restrictions stay in the selected analyzer.
  Parameters include PTX structured fields and native AMD byte payloads; each
  analyzer rejects forms outside its ABI. Both producers re-export the shared
  types for compatibility.
- **Tensor-map fields** (`tensor_map.rs`): host descriptor values used by launch
  configuration and PTX lowering, independent of interpreter operands.
- **`Span`** (`lib.rs`): a source location as a `(low, high)` byte-offset pair.
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
- **`run_log::RunLog`** (`run_log.rs`): the per-invocation log file the
  `volta` binary writes (`<unix-seconds>-<pid>-<command>.log` under
  `--log-dir`, default `volta-logs/`). With the `logging` feature, `tee`
  mirrors an `env_logger` target into it.

```sh
cargo test -p volta_common
```
