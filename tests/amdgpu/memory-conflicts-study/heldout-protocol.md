# Reserved heldout collection

`heldout.py` is separate from the frozen development collector and paired driver.
It reuses their checked command construction, process-group timeout cleanup,
source/build identity checks, certificate classification, complete-output checks,
export retention and statistical routines. Implementing this command does not
authorize running it. Run the heldouts only after an explicit mechanism freeze,
reviewed development correctness preflight and authorization to collect them.

The six IDs in the original manifest remain unchanged: three matched safe
originals and three harmful configurations. The transpose pair retains its
relocated arrays. The harmful seeds are the two-byte intersection of ordinary
DS stores in transpose, a final B64 GLOBAL store alias in SiLU, and a final B128
GLOBAL store alias in softmax. Every original source instruction outside those
predeclared edits, dtype, shape, launch, selected group, allocation and output
view remains fixed. No GPU execution is involved.

The finite valuations are independent of observed verifier outcomes. In the
transpose seed, unsigned-16 inputs `x[i]=i` produce lane words `00000100` and
`02000300`; the actual intersecting bytes are `0100` versus `0200`. SiLU's first
four zero inputs and next four unit inputs distinguish zero halves from positive
SiLU(1) halves. Softmax's first eight zero inputs, next eight unit inputs and
remaining 240 zeros in row zero distinguish representable halves of
`1/(248+8e)` and `e/(248+8e)`. These are possible harmful valuations, not claims
that all inputs make the writes unequal. The static host controls recompute those
byte inequalities without executing heldout assembly or inspecting outcomes.

## Qualification

Both collection commands require `--frozen-mechanism` as an exact 40-character
candidate commit, matching its strict source/build record. They also require the
reviewed development preflight and its explicit SHA-256, with passing development
correctness and the same baseline/candidate identities. The default false
configuration remains the full execution path, with its usual instruction,
bounds and budget checks; completion is never assumed.

`qualify` visits all six IDs, MC-checking complete modules, then runs baseline OFF,
candidate OFF and candidate ON analyses. Every safe original receives full
absolute-coordinate export validation and an unsampled specification check in
all three roles. For default-OFF invariance, compare actual diagnostic witnesses,
instruction counts and exported expression bytes, including incomplete hazard
footprints as their own faulty results. An incomplete hazard export is not a
correct-output proof. Preserve all logs, failures and resource-censored outcomes.

Baseline OFF alone fixes heldout timing eligibility. A hazard requires a typed
ordinary complete rejection; a safe case requires a complete graph, unique full
output footprint and full specification proof. A candidate failure cannot remove
a baseline qualifier. UNKNOWN, Unsupported, timeout and errors remain separate
outcomes, never typed detections. A newly certified prefix follows exactly the
[paired protocol](protocol.md): validated-code-path marker, typed WriteWrite pair,
strict overall rejection and exit 1, without outputs or equivalence success.

## Paired collection and interpretation

`compare` requires the reviewed heldout qualification and its explicit SHA-256.
Only baseline-qualified cases receive the unchanged 31 fresh-process repeats plus
one separate first process, seed 20261031, adjacent randomized arm order and
60-second budget. All six functional rows remain in the final report. A new
candidate-only finding has an absolute observed diagnostic time and no baseline
ratio. New coverage requires a baseline inconclusive, Unsupported or timeout
outcome; an existing finding disqualified by missing telemetry is not a new
detection. No retries, changed expectations, post-outcome replacement, or pooled
first/repeated samples are permitted.

The safe export policy and median/p95/RSS limits are identical to development.
Validate every timed safe export against a retained full role reference before
removing only an exact duplicate. Keep every log, command and digest and all
unmatched artifacts. Latency median/p95 exclude first samples; maximum RSS uses
the first process and all 31 repeats. Collection requires idle CPUs without
concurrent builds, profiles or measurements; first-diagnostic time is observed
by the parent process, not an internal checker timestamp.

The heldout report evaluates retention, observed false outcomes and the applicable
safe overhead gates. The development requirement for four additional algorithm
families, and its four primaries, do not apply to this six-row subset. They are
not silently waived for the overall study: the original development result keeps
its own adoption gates. A baseline-unproved heldout safe case cannot establish a
safe-proof or overhead guarantee, and a missed harmful case stays in the full
three-case hazard denominator. Even an all-missed population must not be described
as successful bug coverage because a retention condition is vacuously true.

## Commands

The static checks execute no assembler or heldout verifier process:

```sh
python3 tests/amdgpu/memory-conflicts-study/heldout.py check
python3 tests/amdgpu/memory-conflicts-study/test_heldout.py -v
python3 -O tests/amdgpu/memory-conflicts-study/test_heldout.py -v
```

After authorization, supply the same identity arguments to both commands. Every
output directory must be fresh and outside the repository:

```sh
python3 tests/amdgpu/memory-conflicts-study/heldout.py qualify \
  --baseline-report /tmp/memory-baseline/report.json \
  --baseline-binary /tmp/frozen/baseline-volta \
  --baseline-build-record /tmp/frozen/baseline-build.json \
  --candidate-binary /tmp/frozen/candidate-volta \
  --candidate-build-record /tmp/frozen/candidate-build.json \
  --candidate-revision FULL_FROZEN_CANDIDATE_REVISION \
  --frozen-mechanism FULL_FROZEN_CANDIDATE_REVISION \
  --development-preflight /tmp/memory-paired-preflight/report.json \
  --development-preflight-sha256 REVIEWED_DEVELOPMENT_SHA256 \
  --output /tmp/memory-heldout-qualification

python3 tests/amdgpu/memory-conflicts-study/heldout.py compare \
  --baseline-report /tmp/memory-baseline/report.json \
  --baseline-binary /tmp/frozen/baseline-volta \
  --baseline-build-record /tmp/frozen/baseline-build.json \
  --candidate-binary /tmp/frozen/candidate-volta \
  --candidate-build-record /tmp/frozen/candidate-build.json \
  --candidate-revision FULL_FROZEN_CANDIDATE_REVISION \
  --frozen-mechanism FULL_FROZEN_CANDIDATE_REVISION \
  --development-preflight /tmp/memory-paired-preflight/report.json \
  --development-preflight-sha256 REVIEWED_DEVELOPMENT_SHA256 \
  --qualification /tmp/memory-heldout-qualification/report.json \
  --qualification-sha256 REVIEWED_HELDOUT_QUALIFICATION_SHA256 \
  --output /tmp/memory-heldout-paired
```

No command in the development driver is changed. The original baseline report,
40 development observations, six heldout IDs and frozen expectation manifest
remain immutable.
