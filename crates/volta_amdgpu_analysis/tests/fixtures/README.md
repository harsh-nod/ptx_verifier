`upstream-copy.s` is copied without edits from
`crates/volta_amd_analysis/tests/fixtures/copy.s` at upstream commit
`103c082bf88d2e538bb89f7c4f2e795c408d2339`.

SHA-256: `56057faed5557f357565f04d38c58dad6efbd108c79162f1ccb5daed4cdddeff`.

The compiler module includes the descriptor-backed `copy` entry and an unrelated
`__clang_ocl_kern_imp_copy` function returning through `s_setpc_b64`. The latter
instruction remains unsupported in analyzed kernel bodies. The unchanged module
tests entry selection without weakening instruction validation.
