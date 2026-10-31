"""Temporary Git histories exercise the actual rebase and refusal boundaries."""

import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "sync_upstream", Path(__file__).with_name("sync_upstream.py")
)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repository"
        self.repo.mkdir()
        self.git("init", "--initial-branch=main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        self.commit("common", "initial\n")
        self.git("branch", "upstream")

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args):
        return sync.git(self.repo, *args).stdout.strip()

    def commit(self, name, text):
        (self.repo / name).write_text(text)
        self.git("add", name)
        self.git("commit", "-m", name)

    def diverge(self, conflict=False):
        self.git("checkout", "upstream")
        self.commit("common" if conflict else "upstream-only", "upstream\n")
        self.git("checkout", "main")
        self.commit("common" if conflict else "fork-only", "fork\n")

    def remote(self):
        path = self.root / "remote.git"
        sync.git(self.root, "init", "--bare", str(path))
        self.git("remote", "add", "origin", str(path))
        self.git("push", "origin", "main")

    def test_up_to_date_creates_no_worktree(self):
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual(result["status"], "up_to_date")
        self.assertFalse(path.exists())

    def test_rebase_retains_both_trees_and_leaves_checkout_and_dirty_files_alone(self):
        self.diverge()
        before = self.git("rev-parse", "main")
        (self.repo / "common").write_text("uncommitted user work\n")
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual(result["status"], "rebased")
        self.assertTrue(sync.ancestor(path, result["upstream"], "HEAD"))
        self.assertEqual((path / "fork-only").read_text(), "fork\n")
        self.assertEqual((path / "upstream-only").read_text(), "upstream\n")
        self.assertEqual(self.git("rev-parse", "main"), before)
        self.assertEqual((self.repo / "common").read_text(), "uncommitted user work\n")

    def test_conflicts_stay_unresolved_and_cannot_publish(self):
        self.diverge(conflict=True)
        before = self.git("rev-parse", "main")
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual(result["status"], "conflict")
        self.assertEqual(result["conflicts"], ["common"])
        self.assertIn("<<<<<<<", (path / "common").read_text())
        self.assertEqual(self.git("rev-parse", "main"), before)
        with self.assertRaises(ValueError):
            sync.publish(self.repo, path, result, self.root)

    def test_existing_output_is_not_overwritten(self):
        self.diverge()
        path = self.root / "worktree"
        path.mkdir()
        (path / "precious").write_text("keep")
        with self.assertRaises(ValueError):
            sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual((path / "precious").read_text(), "keep")

    def test_failed_validation_stops_and_success_records_each_check(self):
        self.diverge()
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        failed = sync.validate(
            path,
            result,
            self.root,
            checks=(
                (sys.executable, "-c", "raise SystemExit(7)"),
                (sys.executable, "-c", "raise SystemExit(0)"),
            ),
        )
        self.assertEqual(failed["status"], "checks_failed")
        self.assertEqual(len(failed["checks"]), 1)
        with self.assertRaises(ValueError):
            sync.publish(self.repo, path, failed, self.root)
        passed = sync.validate(
            path,
            result,
            self.root,
            checks=((sys.executable, "-c", "raise SystemExit(0)"),),
        )
        self.assertEqual(passed["status"], "checked")
        self.assertEqual(passed["checks"][0]["returncode"], 0)

    def test_checks_cannot_succeed_by_changing_the_tested_source(self):
        self.diverge()
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        changed = sync.validate(
            path,
            result,
            self.root,
            checks=(
                (
                    sys.executable,
                    "-c",
                    "from pathlib import Path; Path('common').write_text('changed')",
                ),
            ),
        )
        self.assertEqual(changed["status"], "checks_modified_source")
        with self.assertRaises(ValueError):
            sync.publish(self.repo, path, changed, self.root)

    def test_failed_pr_creation_recovers_pushed_head_and_rechecks_that_exact_commit(
        self,
    ):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        passing = ((sys.executable, "-c", "raise SystemExit(0)"),)
        checked = sync.validate(path, report, self.root, checks=passing)
        original_command = sync.command
        create_calls = []

        def github(repo, *args, **kwargs):
            if args[:3] == ("gh", "pr", "list"):
                return subprocess.CompletedProcess(args, 0, stdout="[]", stderr="")
            if args[:3] == ("gh", "pr", "create"):
                create_calls.append(args)
                if len(create_calls) == 1:
                    raise subprocess.CalledProcessError(
                        1, args, stderr="transient API failure"
                    )
                return subprocess.CompletedProcess(
                    args,
                    0,
                    stdout="https://github.com/harsh-nod/ptx_verifier/pull/1\n",
                    stderr="",
                )
            return original_command(repo, *args, **kwargs)

        with patch.object(sync, "command", side_effect=github):
            with self.assertRaises(subprocess.CalledProcessError):
                sync.publish(self.repo, path, checked, self.root)
            pushed = self.git(
                "ls-remote", "origin", "refs/heads/" + report["branch"]
            ).split()[0]
            sync.git(
                path,
                "commit",
                "--amend",
                "-m",
                "new rebase identity with identical source",
            )
            prepared = {**report, "candidate": sync.oid(path, "HEAD")}
            self.assertNotEqual(prepared["candidate"], pushed)
            recovered = sync.reuse_published_head(self.repo, path, prepared)
            self.assertEqual(recovered["candidate"], pushed)
            self.assertTrue(recovered["reused_published_head"])
            exact_check = (
                (
                    sys.executable,
                    "-c",
                    "import subprocess; assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()=="
                    + repr(pushed),
                ),
            )
            rechecked = sync.validate(path, recovered, self.root, checks=exact_check)
            self.assertEqual(rechecked["status"], "checked")
            published = sync.publish(self.repo, path, rechecked, self.root)
            self.assertEqual(published["status"], "draft_pr")
            self.assertEqual(len(create_calls), 2)
            self.assertEqual(
                self.git(
                    "ls-remote", "origin", "refs/heads/" + report["branch"]
                ).split()[0],
                pushed,
            )

    def test_divergent_existing_sync_branch_cannot_be_reused_or_overwritten(self):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        sync.git(self.repo, "push", "origin", f"main:refs/heads/{report['branch']}")
        with self.assertRaisesRegex(ValueError, "differs"):
            sync.reuse_published_head(self.repo, path, report)
        self.assertEqual(
            self.git("ls-remote", "origin", "refs/heads/" + report["branch"]).split()[
                0
            ],
            report["base"],
        )


if __name__ == "__main__":
    unittest.main()
