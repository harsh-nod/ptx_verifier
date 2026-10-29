# Current per-reference coordinator review

The original `feature-review.json` retains its historical planning dispositions,
baseline source identities and coordinator-only completion fields. The seven
current candidate manifests hold the actual per-reference computation/property
mapping. `coordinator_features.py` prepares a separate, finite current review from
those inputs and never promotes a candidate by inference.

```sh
python3 tests/gfx1250/full-parity/coordinator_features.py \
  --output /tmp/current-feature-candidates.json
```

Each of the 520 output rows identifies its exact owner, current native/shared
control references and native source hashes. Historical reference hashes are
preserved separately when source changed. The proof identity binds the canonical
owner manifest and all those current sources. Missing actual test names, changed
native source pins, overlapping owners or malformed source mappings fail the
preparation. Preparing this artifact runs no GPU program or mathematical proof.

After independently validating the final integrated sources, the coordinator can
provide explicit decisions. Each decision must copy the exact current row's
`proof_identity_sha256`, state whether its portable obligation is satisfied, and
record a concrete review note and reproduction commands. For example:

```json
{
  "authority": "coordinator",
  "rows": [
    {
      "path": "<exact reference path from prepared output>",
      "proof_identity_sha256": "<exact current row identity>",
      "status": "reviewed",
      "portable_obligation_satisfied": true,
      "note": "<exact native assertion and narrowly reviewed target residual>",
      "validation_commands": ["<actual independently replayed command>"]
    }
  ]
}
```

```sh
python3 tests/gfx1250/full-parity/coordinator_features.py \
  --decisions /tmp/coordinator-decisions.json \
  --output /tmp/current-feature-review.json \
  --require-all-reviewed
```

Unlisted rows stay pending. A pending portable obligation cannot be overridden by
candidate ownership or a decision, and a source change invalidates its previous
proof identity. `--require-all-reviewed` fails until all 520 references have
explicit current decisions. The output remains separate from the original
planning, candidate and decision inputs; the helper refuses to overwrite them.
The explicit decisions record the coordinator's review, while the referenced
tests and native workload gates establish the actual results.
