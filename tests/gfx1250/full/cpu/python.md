# Full original Python API replay

`prove_python.py` runs the existing
`test_registered_original_case_analyzes_every_index_and_matches_full_spec`
regression for all32 original configurations. Each actual Python test parses
native assembly, analyzes every configured output index, requires verified
race checks, then verifies the complete mathematical specification with
`sample=0` and numeric confirmation. This is the actual heavy
`VOLTA_GFX1250_ORIGINAL_FULL=1` gate, not an analysis-only substitute.

The runner requires the full32 registration contract and395,394 configured
outputs. It pins the Python interpreter, imported native extension, test source,
fixtures, specifications, launch configurations and original baseline sources.
The supplied source revision is a builder assertion; hashes identify the actual
bytes executed. Keep the extension's build receipt alongside replay evidence.
It records actual Python ABI and linked runtime libraries before running tests.
A portable CPython3.12 distribution can run a matching cp312 extension on a
host whose system Python is newer. A successful import alone is no proof.

```bash
python3 tests/gfx1250/full/cpu/test_prove_python.py -v
python3 tests/gfx1250/full/cpu/prove_python.py \
  --python /owned/python312/bin/python3.12 \
  --site-packages /owned/site-packages \
  --extension-sha256 EXACT_IMPORTED_EXTENSION_SHA256 \
  --source-root /owned/source-snapshot \
  --source-revision BUILDER_COMMIT \
  --output /unique/results
```

Only exactly32 successful, distinct, expected pytest/JUnit cases yield `pass`.
Failed, skipped, missing, duplicate or unexpected cases do not pass. An explicit
`--kernel NAME` selection is recorded as `partial` even if it succeeds. Failed
operational preflight replaces any stale success receipt before loading inputs.
Host accounting/refusal controls are not native execution evidence.

The process tree runs on CPUs with empty GPU visibility, a128GiB RSS cap and
256GiB address-space cap by default. The defaults permit8hours wall time for the
complete serial suite; coordinate its memory allocation with other jobs. Runtime
logging is a separate build/gate and is not implied by this default PyO3 replay.
No current PASS is implied by checking in this runner.

For independent case groups, repeat `--kernel NAME` for every member of one
disjoint group and use a unique output directory. Every group still invokes the
same existing heavy pytest case; it retains status `partial` even when all its
tests pass. Coordinate the aggregate process-tree RSS budget before parallel
launches. The bounded runner does not infer available memory from a count of
groups.

After all groups finish, aggregate on the host that retains their pinned source,
interpreter, extension, runtime and JUnit/log artifacts:

```bash
python3 tests/gfx1250/full/cpu/test_aggregate_python.py -v
python3 tests/gfx1250/full/cpu/aggregate_python.py \
  --registry /owned/source-snapshot/tests/gfx1250/full/cases.json \
  --receipt /unique/group-a/receipt.json \
  --receipt /unique/group-b/receipt.json \
  --output /unique/full32-aggregate.json
```

The aggregate passes only if the groups cover exactly32 distinct original
cases and395,394 configured outputs, with no failed, missing, overlapping,
skipped or incomplete test. It rechecks actual JUnit files and stdout/stderr,
the unchanged pytest command, all original source/config/spec/baseline pins,
and identical interpreter/ABI/extension/runtime hashes. It preserves individual
partial receipts and rejects mixed revisions. Its own host refusal controls
are synthetic accounting tests; they provide no native execution evidence.
