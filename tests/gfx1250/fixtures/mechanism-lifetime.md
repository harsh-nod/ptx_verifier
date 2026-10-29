These source-only controls address the eleven explicit portable gaps in the
mechanism review and two additional matrix publication directions. The finite
13-row contract retains exact original assertions, source hashes, empty-output
positives, logical projections and target-specific residuals. Coordinator
acceptance remains pending; compilation provenance and source mappings are
separate from runtime proof or hardware validation.

`async_source128_reuse` borrows exactly 128 LDS source bytes for an actual TDM
store, waits for its completion and then reuses them from the second wave.
All 64 F32 outputs preserve their independent inputs. Removing the Tensor wait
or substituting Store/DS waits retains the complete candidate and reports a
typed Shared ReadWrite conflict. The independently integrated
`async_no_output128_reuse` counterpart checks the distinct 128-byte destination
write role, including its intentionally empty output contract.

Genuine allocated LLVM named objects retain expected counts 1 and 65,535 in
their actual 16-bit M0 field. Non-NULL count0 is rejected; NULL count0 remains a
valid no-op. The original hidden PTX transaction-credit positive at 2²⁰−1 and its
exact 2²⁰ refusal are independently rerun. Manual PTX byte credits retain their
precise target residual; neither a native 20-bit counter nor a different native
limit is fabricated.

The original zero-MMA lifetime and boundary programs are independently verified
before their native mapping is checked. Original logical shapes M32/N64,
M128/N64, M128/N256 and M128/N8 have explicit projections into the existing
M128/N256 native superset. Every additional native coordinate is checked in both
32,768-element output views. Original K16 zero operands are padded explicitly to
native K32. An assemble-valid early WMMA destination overwrite retains the full
candidate and reports `MatrixDestinationReuse`; no TMEM deallocation opcode is
invented for native registers or LDS.

The two new matrix-ordering entries keep their memory directions distinct.
`matrix_input_cross_wave` publishes 512 operand bytes from wave0 to wave1 before
WMMA reads and checks every weighted result. `matrix_completion_keeps_metadata_separate`
checks all 256 matrix outputs plus a separate arbitrary U32 metadata word.
Removing its publication barrier leaves matrix readiness successful while the
earlier unrelated metadata store has a typed Shared WriteRead conflict at byte0.
Prior initialized phases keep harmful candidates complete. Ordinary global
inputs retain const pointers; shared operands retain volatile pointers, so their
actual compiler memory domains remain explicit.

```sh
cargo test --release -p volta_pipeline --test gfx1250_mechanism_lifetime
python3 tests/gfx1250/full-parity/validate_native_mappings.py \
  --contract tests/gfx1250/fixtures/mechanism-lifetime-contract.json
```

The three genuine compiler modules and all six harmful assembly mutations have
actual compiler/MC/link provenance. Count0/refusal and harmful memory/register
mutations stay on CPU. `mechanism-positive-cases.json` lists only the six safe
new entries with their exact argument order and independent reference formulas.
