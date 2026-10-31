# Scalar floating inline64 controls

These three complete handwritten controls exercise **one verifier semantic
defect** on gfx942, gfx950 and gfx1250. Each uses one active physical lane in
one selected workgroup, an eight-byte output allocation and both absolute u32
output coordinates. The instruction `s_mov_b64 ...,1.0` must produce
`0x3ff0000000000000`, so the required low/high words are `[0,1072693248]`.
The earlier verifier zero-extended the FP32 encoding instead and produced
`[1065353216,0]`.

| Target | Baseline graph checks | Baseline mismatched u32 outputs | Corrected graph checks | Corrected equivalent u32 outputs |
| --- | ---: | ---: | ---: | ---: |
| gfx942 | 4/4 pass | 2/2 | 4/4 pass | 2/2 |
| gfx950 | 4/4 pass | 2/2 | 4/4 pass | 2/2 |
| gfx1250 | 4/4 pass | 2/2 | 4/4 pass | 2/2 |

The complete traces execute 12 instructions on gfx942/gfx950 and 13 on gfx1250.
Every baseline graph passes, while full integer equivalence independently
refutes both output coordinates. Every corrected run passes full equivalence
and retains exactly the two expected typed output roots. This is a verifier
correctness repair, with no original-kernel coverage, additional bug-finding,
hardware, speed or memory-use claim. The three target controls are not three
independent defect patterns. Mathematical real-number arithmetic remains the
verifier's general numerical model; these controls inspect concrete encoded
words rather than floating-point arithmetic results.

[comparison.json](results/comparison.json) contains the per-target process
outcomes, full output values, artifact hashes and source/build identities.
The baseline source is `4b0e766a265390900f4450cab54398f1cb5cbf86` (binary
`66a32105a849a9eaa6ff0d19f33856f724807bfba5557b65c7737807f1078b1f`).
The corrected source and fixture revision is
`f1a252aae8cc105a2f0d6aa0e696cac6688ba059` (binary
`d99d05cd6eab8efc5d56dd6807a1697f3bb343374ea0bfa70a31910473be8302`).
The compact [baseline](results/baseline/build-record.json) and
[corrected](results/candidate/build-record.json) build records retain the raw
record hashes, default-feature release configuration and Rust workspace
fingerprints. Source/build association is caller-attested, not a cryptographic
proof of compilation.

The earlier two-target v3 [report](results/baseline/original-report.json),
[78-check independent audit](results/baseline/original-independent-audit.json)
and all its logs/graphs/expressions are retained byte-for-byte. A separate
[gfx942 baseline capture](results/baseline/gfx942-capture-report.json) adds two
processes without rewriting that earlier evidence. The corrected
[capture](results/candidate/report.json) runs all three targets. Historical
absolute temporary destinations in retained logs are producer records; replay
uses the checked-in fixtures and fresh relative artifact destinations.
Capture reports retain their original collection-script hashes. The comparison
records `published_replayer_sha256` separately for the current validator, which
also rejects contradictory typed memory-conflict and register-hazard diagnostics.

## Reproduce the functional checks

Assembly, launch files and `one.spec` are referenced from the
[checked-in fixtures](../../../crates/volta_amdgpu_analysis/tests/fixtures/scalar-inline64/README.md);
this package does not duplicate or modify them. Their producer records include
separate public LLVM-MC acceptance for all three targets. The public
[CDNA3 operand table](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf),
[CDNA4 operand table](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna4-instruction-set-architecture.pdf),
[CDNA5 §4.1](https://www.amd.com/content/dam/amd/en/documents/instinct-tech-docs/instruction-set-architectures/amd-instinct-cdna5-instruction-set-architecture.pdf)
and pinned [LLVM emitter](https://github.com/llvm/llvm-project/blob/5fd50ec8e07abb94e203933017e8d6e40fb51824/llvm/lib/Target/AMDGPU/MCTargetDesc/AMDGPUMCCodeEmitter.cpp#L233-L265)
provide the precision-specific constant rules.

From the repository root, using fresh output directories:

```sh
python3 tests/amdgpu/scalar-inline64/replay.py --repo . \
  --binary /path/to/earlier/volta --baseline --output /tmp/inline64-baseline
python3 tests/amdgpu/scalar-inline64/replay.py --repo . \
  --binary /path/to/corrected/volta --output /tmp/inline64-corrected
python3 -m unittest discover -s tests/amdgpu/scalar-inline64 -p test_replay.py
python3 -O -m unittest discover -s tests/amdgpu/scalar-inline64 -p test_replay.py
```

`--baseline` expects this specific old defect, not any rejection. The replay
requires all four graph properties to pass, a complete terminal trace, the
exact complete output footprint, numeric refutation of both baseline outputs
or full corrected equivalence, matching integer words in stdout and expression
roots, and successful process codes consistent with each mode. It rejects
unsupported/aborted/inconclusive evidence, contradictory results, duplicate or
missing coordinates and altered source inputs. Every source and executable
hash is checked before and after collection. A failed replay retains its raw
process records for diagnosis and does not claim a successful comparison.
