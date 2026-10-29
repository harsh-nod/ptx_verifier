#!/usr/bin/env python3
"""Inventory pinned upstream references and validate native fixture mappings."""

import argparse
from collections import Counter
import hashlib
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
            "workload"
            if path.startswith("ai_compiler_kernels/")
            else "math-spec"
            if path.startswith("crates/volta_equivalence/tests/specs/")
            else "integration-fixture"
        )
        for path in paths
        if (path.startswith("ai_compiler_kernels/") and path.endswith(".ptx"))
        or (
            path.startswith("crates/volta_pipeline/tests/ptx/")
            and path.endswith(".ptx")
        )
        or (
            path.startswith("crates/volta_equivalence/tests/specs/")
            and path.endswith(".spec")
        )
    }


def generate(path):
    if path.exists():
        raise ValueError(f"refusing to overwrite existing evidence: {path}")
    entries = []
    for source, kind in sorted(baseline_paths(BASELINE).items()):
        entries.append(
            {
                "baseline_path": source,
                "kind": kind,
                "mapping_kind": "unmapped",
                "applicability": "unspecified",
                "amd_fixtures": [],
                "property_or_computation": "",
                "configuration": {},
                "expected_outcome": "",
                "assumptions": [],
                "required_instructions": [],
                "reason": "",
            }
        )
    result = {
        "schema_version": 1,
        "baseline_commit": BASELINE,
        "target": "gfx950",
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
        raise ValueError(
            f"inventory drift: missing={sorted(set(expected) - set(actual))}, "
            f"extra={sorted(set(actual) - set(expected))}"
        )
    for row in rows:
        mapping_kind = row["mapping_kind"]
        if mapping_kind not in {
            "unmapped",
            "native_assertion",
            "shared_assertion",
            "target_boundary",
            "model_boundary",
        }:
            raise ValueError(
                f"unknown mapping kind {mapping_kind}: {row['baseline_path']}"
            )
        if row["kind"] != expected[row["baseline_path"]]:
            raise ValueError(f"wrong fixture kind: {row['baseline_path']}")
        if mapping_kind in {"native_assertion", "shared_assertion"}:
            outcome = row.get("expected_outcome")
            if not outcome or isinstance(outcome, str) and not outcome.strip():
                raise ValueError(f"missing expected outcome: {row['baseline_path']}")
        if mapping_kind == "native_assertion" and not row["amd_fixtures"]:
            raise ValueError(f"missing native fixture: {row['baseline_path']}")
        if mapping_kind in {"target_boundary", "model_boundary"} and not row["reason"]:
            raise ValueError(f"missing exact boundary: {row['baseline_path']}")
        for fixture in row["amd_fixtures"]:
            if not (ROOT / fixture).is_file():
                raise ValueError(f"missing native fixture: {fixture}")
        configuration = row.get("configuration", {})
        if "manifest_sha256" in configuration:
            fixture_manifest = configuration.get("manifest")
            if not isinstance(fixture_manifest, str) or not fixture_manifest:
                raise ValueError(
                    f"missing configuration manifest: {row['baseline_path']}"
                )
            fixture_manifest = ROOT / fixture_manifest
            if not fixture_manifest.is_file():
                raise ValueError(f"missing configuration manifest: {fixture_manifest}")
            if (
                hashlib.sha256(fixture_manifest.read_bytes()).hexdigest()
                != configuration["manifest_sha256"]
            ):
                raise ValueError(
                    f"configuration manifest hash changed: {row['baseline_path']}"
                )
    counts = Counter(row["mapping_kind"] for row in rows)
    print(
        json.dumps(
            {
                "baseline": manifest["baseline_commit"],
                "target": "gfx950",
                "kinds": dict(Counter(row["kind"] for row in rows)),
                "mappings": dict(counts),
            },
            sort_keys=True,
        )
    )
    if require_complete and counts["unmapped"]:
        raise ValueError(
            f"{counts['unmapped']} source references have no native mapping"
        )


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
