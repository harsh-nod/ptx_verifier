# Upstream synchronization

The fork tracks `francois141/ptx_verifier`'s `master` branch. The
[Upstream sync workflow](../.github/workflows/upstream-sync.yml) checks at
00:17, 06:17, 12:17 and 18:17 UTC, and supports manual dispatch. GitHub may delay
scheduled runs. Its run summary records the exact fork and upstream revisions.

When upstream is already an ancestor of `origin/main`, no merge or build is
needed. Otherwise, `scripts/sync_upstream.py` merges upstream into an isolated
detached worktree. Both existing fork commits and original upstream commits stay
in its ancestry, preserving published source identities and previous merge
resolutions. Replaying historical merges can recreate conflicts and alter their
recorded resolutions even when a new upstream change touches unrelated files.
The caller's checkout and `main` remain intact.
Conflicts stop the run with their paths and diagnostics; the script neither
chooses a side nor skips a conflicting commit.

A completed merge must pass workspace formatting, release Rust tests, strict
release Clippy, the frozen-study host controls and the tensor comparison controls
under ordinary and optimized Python. Validation also refuses a
changed source tree or commit. A changed remote base defers publication. With
`--publish`, a passing candidate opens a draft PR in this fork for review. It
never writes upstream, approves a PR, merges it or force-pushes `main`.
Publication rechecks the source and remote base, then pushes the exact tested
commit. A checked follow-up may advance the same draft branch by fast-forward.
Land reviewed PRs with a merge commit so original upstream ancestry stays intact.
If an earlier branch push succeeded but PR creation failed, retry requires the
same complete source tree and both fork/upstream ancestry, then reruns checks on that
exact published head before creating the PR.

Run the same preparation locally with a fresh output directory:

```sh
python3 scripts/test_sync_upstream.py -v
python3 scripts/sync_upstream.py --output /tmp/new-upstream-sync
```

Add `--publish` to open the fork draft after the checks pass. `report.json`,
per-check logs and the isolated worktree stay in the output directory, including
on a conflict. Keep that directory until review is complete. Local runs need Git,
Rust with rustfmt/Clippy, Python 3 and, for publication, authenticated GitHub CLI.

The hosted workflow uses its repository-scoped `GITHUB_TOKEN`; repository
settings must allow Actions to create PRs. Scheduled workflows on forks may need
explicit enabling, and GitHub can
disable schedules after prolonged repository inactivity. Check the workflow's
actual enabled state and run results when resuming maintenance.

Inspect the workflow and its run history before starting another local sync:

```sh
gh workflow view upstream-sync.yml --repo harsh-nod/ptx_verifier
gh run list --workflow upstream-sync.yml --repo harsh-nod/ptx_verifier
```

Avoid a manual dispatch while an equivalent local integration is running. After
the reviewed upstream merge lands, a dispatch can exercise the hosted workflow's
up-to-date path without repeating the integration and checks.
