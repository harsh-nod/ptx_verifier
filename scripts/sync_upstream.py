#!/usr/bin/env python3
"""Merge upstream in isolation, check the result and optionally open a fork draft PR."""

import argparse
import json
import os
from pathlib import Path
import subprocess

FORK = "harsh-nod/ptx_verifier"
UPSTREAM = "francois141/ptx_verifier"
CHECKS = (
    ("cargo", "fmt", "--all", "--", "--check"),
    ("cargo", "test", "--release", "--workspace"),
    (
        "cargo",
        "clippy",
        "--release",
        "--workspace",
        "--all-targets",
        "--",
        "-D",
        "warnings",
    ),
    (
        "python3",
        "-m",
        "unittest",
        "discover",
        "-s",
        "tests/amdgpu/design-study",
        "-p",
        "test_*.py",
    ),
    ("python3", "tests/gfx1250/test_measure_tensor_bounds.py"),
    ("python3", "-O", "tests/gfx1250/test_measure_tensor_bounds.py"),
)


def command(repo, *args, check=True):
    return subprocess.run(args, cwd=repo, text=True, capture_output=True, check=check)


def git(repo, *args, check=True):
    return command(repo, "git", *args, check=check)


def oid(repo, ref):
    return git(repo, "rev-parse", "--verify", ref + "^{commit}").stdout.strip()


def ancestor(repo, older, newer):
    result = git(repo, "merge-base", "--is-ancestor", older, newer, check=False)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr)
    return result.returncode == 0


def prepare(repo, worktree, base, upstream):
    """Never change the caller's checkout or resolve a conflict automatically."""
    base_sha, upstream_sha = oid(repo, base), oid(repo, upstream)
    result = {"base": base_sha, "upstream": upstream_sha, "strategy": "merge"}
    if ancestor(repo, upstream_sha, base_sha):
        return {**result, "status": "up_to_date"}
    if worktree.exists():
        raise ValueError("integration worktree must be a new path")
    git(repo, "worktree", "add", "--detach", str(worktree), base_sha)
    merged = git(
        worktree,
        "-c",
        "core.editor=true",
        "-c",
        "user.name=Upstream sync",
        "-c",
        "user.email=upstream-sync@users.noreply.github.com",
        "merge",
        "--no-ff",
        "--no-edit",
        upstream_sha,
        check=False,
    )
    if merged.returncode:
        conflicts = git(
            worktree, "diff", "--name-only", "--diff-filter=U"
        ).stdout.splitlines()
        return {
            **result,
            "status": "conflict" if conflicts else "merge_failed",
            "conflicts": conflicts,
            "diagnostic": (merged.stdout + merged.stderr)[-12000:],
        }
    if not all(ancestor(worktree, ref, "HEAD") for ref in (base_sha, upstream_sha)):
        raise RuntimeError(
            "completed merge does not preserve both fork and upstream ancestry"
        )
    return {
        **result,
        "status": "merged",
        "candidate": oid(worktree, "HEAD"),
        "branch": f"sync/upstream-{upstream_sha[:12]}-{base_sha[:12]}",
        "changed_files": git(
            worktree, "diff", "--name-only", base_sha, "HEAD"
        ).stdout.splitlines(),
    }


def reuse_published_head(repo, worktree, report):
    """Recover a push whose PR creation failed, before testing the exact head."""
    if report["status"] != "merged":
        raise ValueError("only a fresh merge can recover a published branch")
    remote_ref = f"refs/heads/{report['branch']}"
    if not git(repo, "ls-remote", "origin", remote_ref).stdout.strip():
        return report
    git(repo, "fetch", "origin", remote_ref)
    existing = oid(repo, "FETCH_HEAD")
    expected_tree = git(worktree, "rev-parse", report["candidate"] + "^{tree}").stdout
    actual_tree = git(repo, "rev-parse", existing + "^{tree}").stdout
    if actual_tree != expected_tree or not all(
        ancestor(repo, ref, existing) for ref in (report["base"], report["upstream"])
    ):
        raise ValueError(
            "existing sync branch differs from the prepared source/upstream"
        )
    if git(worktree, "status", "--porcelain", "--untracked-files=no").stdout.strip():
        raise ValueError("integration worktree changed before published-head recovery")
    git(worktree, "checkout", "--detach", existing)
    return {**report, "candidate": existing, "reused_published_head": True}


def validate(worktree, report, log_dir, checks=CHECKS):
    """A merge alone never marks its checks passed."""
    results = []
    for number, check in enumerate(checks):
        log_path = log_dir / f"check-{number}.log"
        with log_path.open("w") as log:
            run = subprocess.run(
                check, cwd=worktree, stdout=log, stderr=subprocess.STDOUT
            )
        results.append(
            {"argv": list(check), "returncode": run.returncode, "log": log_path.name}
        )
        if run.returncode:
            return {**report, "status": "checks_failed", "checks": results}
    if (
        oid(worktree, "HEAD") != report["candidate"]
        or git(worktree, "status", "--porcelain", "--untracked-files=no").stdout.strip()
    ):
        return {**report, "status": "checks_modified_source", "checks": results}
    return {**report, "status": "checked", "checks": results}


def publish(repo, worktree, report, output):
    """Only publish a checked candidate, and only to this fork's draft queue."""
    if report["status"] != "checked":
        raise ValueError("only checked integrations may be published")
    remote_base = git(repo, "ls-remote", "origin", "refs/heads/main").stdout.split()
    if not remote_base or remote_base[0] != report["base"]:
        return {**report, "status": "base_changed"}
    branch = report["branch"]
    existing = command(
        repo,
        "gh",
        "pr",
        "list",
        "--repo",
        FORK,
        "--head",
        branch,
        "--state",
        "all",
        "--json",
        "url,state",
    ).stdout
    if rows := json.loads(existing):
        return {**report, "status": "existing_pr", "pull_request": rows[0]}
    git(worktree, "push", "origin", f"HEAD:refs/heads/{branch}")
    body = output / "pull-request.md"
    body.write_text(
        f"Merge upstream `{report['upstream']}` into the fork's `{report['base']}`, "
        "preserving both histories. No conflicts were resolved automatically.\n\n"
        "Validation completed before publication:\n\n"
        + "\n".join("- `" + " ".join(row["argv"]) + "`" for row in report["checks"])
        + "\n\nReview the combined change and any backend contract differences before merging.\n"
    )
    created = command(
        repo,
        "gh",
        "pr",
        "create",
        "--repo",
        FORK,
        "--base",
        "main",
        "--head",
        branch,
        "--draft",
        "--title",
        f"Merge upstream {report['upstream'][:12]}",
        "--body-file",
        str(body),
    )
    return {**report, "status": "draft_pr", "pull_request": created.stdout.strip()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="New directory for the isolated merge and logs",
    )
    parser.add_argument(
        "--publish", action="store_true", help="Open a checked draft PR in the fork"
    )
    args = parser.parse_args()
    repo, output = args.repo.resolve(), args.output.resolve()
    if output.exists():
        parser.error("output directory already exists; keep earlier results intact")
    output.mkdir(parents=True)
    try:
        origin = (
            git(repo, "remote", "get-url", "origin").stdout.strip().removesuffix(".git")
        )
        if origin not in (f"https://github.com/{FORK}", f"git@github.com:{FORK}"):
            raise ValueError("origin must identify the configured fork")
        upstream = git(repo, "remote", "get-url", "upstream", check=False)
        if upstream.returncode:
            git(repo, "remote", "add", "upstream", f"https://github.com/{UPSTREAM}.git")
        elif upstream.stdout.strip().removesuffix(".git") not in (
            f"https://github.com/{UPSTREAM}",
            f"git@github.com:{UPSTREAM}",
        ):
            raise ValueError("upstream remote identifies a different repository")
        git(repo, "fetch", "origin", "main")
        git(repo, "fetch", "upstream", "master")
        worktree = output / "worktree"
        report = prepare(repo, worktree, "origin/main", "upstream/master")
        if report["status"] == "merged":
            if args.publish:
                report = reuse_published_head(repo, worktree, report)
            report = validate(worktree, report, output)
        if args.publish and report["status"] == "checked":
            report = publish(repo, worktree, report, output)
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        detail = (
            error.stderr if isinstance(error, subprocess.CalledProcessError) else ""
        )
        report = {"status": "error", "diagnostic": str(error), "detail": detail}
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    if summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(summary).open("a") as stream:
            stream.write(
                "## Upstream sync\n\n```json\n"
                + json.dumps(report, indent=2)
                + "\n```\n"
            )
    return (
        0
        if report["status"]
        in {"up_to_date", "checked", "draft_pr", "existing_pr", "base_changed"}
        else 1
    )


if __name__ == "__main__":
    raise SystemExit(main())
