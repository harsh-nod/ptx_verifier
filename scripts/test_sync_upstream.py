"""Temporary Git histories exercise isolated merges and refusal boundaries."""

import importlib.util
import json
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

    def test_merge_retains_both_histories_and_leaves_checkout_and_dirty_files_alone(
        self,
    ):
        self.diverge()
        before = self.git("rev-parse", "main")
        (self.repo / "common").write_text("uncommitted user work\n")
        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual(result["status"], "merged")
        self.assertTrue(sync.ancestor(path, before, "HEAD"))
        self.assertTrue(sync.ancestor(path, result["upstream"], "HEAD"))
        self.assertEqual((path / "fork-only").read_text(), "fork\n")
        self.assertEqual((path / "upstream-only").read_text(), "upstream\n")
        self.assertEqual(self.git("rev-parse", "main"), before)
        self.assertEqual((self.repo / "common").read_text(), "uncommitted user work\n")

    def test_previous_resolved_upstream_merge_and_published_history_are_preserved(self):
        self.git("config", "rerere.enabled", "false")
        self.diverge(conflict=True)
        fork = self.git("rev-parse", "HEAD")
        first_upstream = self.git("rev-parse", "upstream")
        merge = sync.git(self.repo, "merge", "--no-ff", "upstream", check=False)
        self.assertNotEqual(merge.returncode, 0)
        (self.repo / "common").write_text("reviewed combined resolution\n")
        self.git("add", "common")
        self.git("commit", "-m", "resolve the first upstream integration")
        self.commit("published-contract", "immutable source identity\n")
        before = self.git("rev-parse", "HEAD")
        self.git("checkout", "upstream")
        self.commit("new-frontend", "new upstream parser\n")
        upstream = self.git("rev-parse", "HEAD")
        self.git("checkout", "main")

        replay = self.root / "historical-replay"
        self.git("worktree", "add", "--detach", str(replay), before)
        failed = sync.git(
            replay,
            "-c",
            "core.editor=true",
            "rebase",
            "--rebase-merges",
            upstream,
            check=False,
        )
        self.assertNotEqual(failed.returncode, 0)
        self.assertEqual(
            sync.git(replay, "diff", "--name-only", "--diff-filter=U").stdout.strip(),
            "common",
        )

        path = self.root / "worktree"
        result = sync.prepare(self.repo, path, "main", "upstream")
        self.assertEqual(result["status"], "merged")
        for commit in (before, fork, first_upstream, upstream):
            self.assertTrue(sync.ancestor(path, commit, "HEAD"))
        self.assertEqual(
            (path / "common").read_text(), "reviewed combined resolution\n"
        )
        self.assertEqual(
            (path / "published-contract").read_text(), "immutable source identity\n"
        )
        self.assertEqual(result["changed_files"], ["new-frontend"])
        self.assertEqual(self.git("rev-parse", "main"), before)

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
                "new merge identity with identical source",
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

    def test_matching_published_tree_cannot_drop_the_existing_fork_history(self):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        tree = sync.git(path, "rev-parse", "HEAD^{tree}").stdout.strip()
        without_fork = self.git(
            "commit-tree",
            tree,
            "-p",
            report["upstream"],
            "-m",
            "same source, lost fork history",
        )
        self.git("push", "origin", f"{without_fork}:refs/heads/{report['branch']}")
        with self.assertRaisesRegex(ValueError, "differs"):
            sync.reuse_published_head(self.repo, path, report)

    def test_post_validation_dirty_files_and_commits_cannot_publish(self):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        checked = sync.validate(
            path, report, self.root, checks=((sys.executable, "-c", "pass"),)
        )
        original_command = sync.command
        github_calls = []

        def github(repo, *args, **kwargs):
            if args[0] == "gh":
                github_calls.append(args)
                return subprocess.CompletedProcess(args, 0, stdout="[]", stderr="")
            return original_command(repo, *args, **kwargs)

        (path / "common").write_text("changed after validation\n")
        with patch.object(sync, "command", side_effect=github):
            with self.assertRaisesRegex(ValueError, "changed before publication"):
                sync.publish(self.repo, path, checked, self.root)
            sync.git(path, "add", "common")
            sync.git(path, "commit", "-m", "untested commit")
            with self.assertRaisesRegex(ValueError, "changed before publication"):
                sync.publish(self.repo, path, checked, self.root)
        self.assertEqual(github_calls, [])
        self.assertEqual(
            self.git("ls-remote", "origin", "refs/heads/" + report["branch"]), ""
        )

    def test_remote_main_advance_during_pr_lookup_defers_publication(self):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        checked = sync.validate(
            path, report, self.root, checks=((sys.executable, "-c", "pass"),)
        )
        original_command = sync.command

        def github(repo, *args, **kwargs):
            if args[:3] == ("gh", "pr", "list"):
                self.commit("later-main", "published meanwhile\n")
                self.git("push", "origin", "main")
                return subprocess.CompletedProcess(args, 0, stdout="[]", stderr="")
            if args[0] == "gh":
                self.fail("a changed base must not create a PR")
            return original_command(repo, *args, **kwargs)

        with patch.object(sync, "command", side_effect=github):
            result = sync.publish(self.repo, path, checked, self.root)
        self.assertEqual(result["status"], "base_changed")
        self.assertEqual(
            self.git("ls-remote", "origin", "refs/heads/" + report["branch"]), ""
        )

    def test_existing_draft_update_pushes_checked_commit_despite_late_head_move(self):
        self.diverge()
        self.remote()
        path = self.root / "worktree"
        report = sync.prepare(self.repo, path, "main", "upstream")
        self.git(
            "push", "origin", f"{report['candidate']}:refs/heads/{report['branch']}"
        )
        (path / "reviewed-fix").write_text("tested followup\n")
        sync.git(path, "add", "reviewed-fix")
        sync.git(path, "commit", "-m", "reviewed followup")
        report = {**report, "candidate": sync.oid(path, "HEAD")}
        checked = sync.validate(
            path, report, self.root, checks=((sys.executable, "-c", "pass"),)
        )
        original_command = sync.command

        def racing(repo, *args, **kwargs):
            if args[:3] == ("gh", "pr", "list"):
                rows = [
                    {
                        "url": "https://github.com/harsh-nod/ptx_verifier/pull/1",
                        "state": "OPEN",
                    }
                ]
                return subprocess.CompletedProcess(
                    args, 0, stdout=json.dumps(rows), stderr=""
                )
            if args[0] == "gh":
                self.fail("an existing draft must not create another PR")
            if args[:2] == ("git", "push"):
                (path / "untested-fix").write_text("changed at push\n")
                sync.git(path, "add", "untested-fix")
                sync.git(path, "commit", "-m", "untested late commit")
            return original_command(repo, *args, **kwargs)

        with patch.object(sync, "command", side_effect=racing):
            result = sync.publish(self.repo, path, checked, self.root)
        self.assertEqual(result["status"], "existing_pr")
        self.assertNotEqual(sync.oid(path, "HEAD"), checked["candidate"])
        self.assertEqual(
            self.git("ls-remote", "origin", "refs/heads/" + report["branch"]).split()[
                0
            ],
            checked["candidate"],
        )


if __name__ == "__main__":
    unittest.main()
