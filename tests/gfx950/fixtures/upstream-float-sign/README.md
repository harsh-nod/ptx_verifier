# Original public float-sign fixture

These three files retain the exact public `float_ops` source, complete emitted
module and expected output from upstream commit
[`abd90436ac8a8e33dde8546fcc3d46f31f08f529`](https://github.com/francois141/ptx_verifier/commit/abd90436ac8a8e33dde8546fcc3d46f31f08f529).
They also match fork commit `178a63be6dcb9e0c38589e7a912b95659ff9ab22`
at `crates/volta_amd_analysis/tests/fixtures/float_ops.{cl,s,out}`.

The native pipeline regression keeps all 21 assignments, 44 executed entry
instructions and 1,344 output coordinates. The complete module includes the
original uncalled helper. These are preserved compiler artifacts, without
recompilation, trimming or a new hardware result.

Upstream subsequently changed its experimental backend's live `float_ops`
fixtures. Those current files remain separate; the native regression uses
these pinned originals.

| File | SHA-256 |
| --- | --- |
| `float_ops.cl` | `d4f37620712703c6b3510b26d35e3558ef519f47cb572044832809520794bb8f` |
| `float_ops.s` | `db9d32e5480e499d8741a0ab370b8e2008f9a42190f177660e41258eeb012a62` |
| `float_ops.out` | `7f9b559e3dea9b5ab794b424d445279d4af60c227190ef717fb5400a7fea74e9` |
