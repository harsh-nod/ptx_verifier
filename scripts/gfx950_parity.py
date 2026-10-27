#!/usr/bin/env python3
"""Inventory and audit gfx950 parity against the pinned upstream revision.

Generation inventories work; it never infers successful verification from a
filename or an unsupported outcome. Only coordinator-reviewed evidence may move
an entry out of pending.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "tests/gfx950/parity.json"
BASELINE = "e8f819919e5d4628b68aa735deacaaa48d46cf23"


def baseline_paths(revision):
    paths = subprocess.check_output(
        ["git", "ls-tree", "-r", "--name-only", revision], cwd=ROOT, text=True
    ).splitlines()
    return {
        path: (
            "workload" if path.startswith("ai_compiler_kernels/") else
            "math-spec" if path.startswith("crates/volta_equivalence/tests/specs/") else
            "integration-fixture"
        )
        for path in paths
        if (path.startswith("ai_compiler_kernels/") and path.endswith(".ptx"))
        or (path.startswith("crates/volta_pipeline/tests/ptx/") and path.endswith(".ptx"))
        or (path.startswith("crates/volta_equivalence/tests/specs/") and path.endswith(".spec"))
    }


def generate(path):
    if path.exists():
        raise ValueError(f"refusing to overwrite existing evidence: {path}")
    entries = []
    for source, kind in sorted(baseline_paths(BASELINE).items()):
        entries.append({
            "baseline_path": source,
            "kind": kind,
            "status": "pending",
            "applicability": "needs-review",
            "amd_fixtures": [],
            "property_or_computation": "",
            "configuration": {},
            "expected_outcome": "",
            "assumptions": [],
            "required_instructions": [],
            "owner": "coordinator",
            "evidence": [],
            "reason": "",
        })
    result = {
        "schema_version": 1,
        "baseline_commit": BASELINE,
        "target": "gfx950",
        "policy": "Only coordinator-reviewed integrated validation closes parity entries.",
        "entries": entries,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result, indent=2) + "\n")


def audit(path, require_complete=False):
    manifest = json.loads(path.read_text())
    if manifest.get("schema_version") != 1 or manifest.get("target") != "gfx950":
        raise ValueError("unknown manifest schema or target")
    expected = baseline_paths(manifest["baseline_commit"])
    rows = manifest["entries"]
    actual = [row["baseline_path"] for row in rows]
    if len(actual) != len(set(actual)):
        raise ValueError("duplicate baseline paths")
    if set(actual) != set(expected):
        raise ValueError(f"inventory drift: missing={sorted(set(expected)-set(actual))}, "
                         f"extra={sorted(set(actual)-set(expected))}")
    for row in rows:
        status = row["status"]
        if status not in {"pending", "validated", "ptx-only", "baseline-limited"}:
            raise ValueError(f"invalid status {status}: {row['baseline_path']}")
        if row["kind"] != expected[row["baseline_path"]]:
            raise ValueError(f"wrong fixture kind: {row['baseline_path']}")
        if status == "validated":
            if not row["evidence"] or not row["expected_outcome"]:
                raise ValueError(f"validated row lacks evidence/outcome: {row['baseline_path']}")
            if row["kind"] != "math-spec" and not row["amd_fixtures"]:
                raise ValueError(f"validated row lacks AMD fixture: {row['baseline_path']}")
            for fixture in row["amd_fixtures"]:
                if not (ROOT / fixture).is_file():
                    raise ValueError(f"missing AMD fixture: {fixture}")
        elif status != "pending" and (not row["reason"] or not row["evidence"]):
            raise ValueError(f"exception lacks rationale/evidence: {row['baseline_path']}")
    counts = Counter(row["status"] for row in rows)
    print(json.dumps({"baseline": manifest["baseline_commit"], "target": "gfx950",
                      "kinds": dict(Counter(row["kind"] for row in rows)),
                      "status": dict(counts)}, sort_keys=True))
    if require_complete and counts["pending"]:
        raise ValueError(f"{counts['pending']} parity entries remain pending")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["generate", "check", "summary"])
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    try:
        if args.command == "generate":
            generate(args.manifest)
        audit(args.manifest, args.require_complete)
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
