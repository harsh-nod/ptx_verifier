#!/usr/bin/env python3
"""Validate finite reference coverage and all pinned current source artifacts."""

from collections import Counter
import hashlib
import json
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(manifest, directory):
    root = directory.parents[2]
    rows = manifest.get("rows", [])
    if len(rows) != 46 or len({row["path"] for row in rows}) != 46:
        raise ValueError("expected all46 distinct source-reference rows")
    if Counter(row["group"] for row in rows) != {
        "MODEL-BOUNDARY": 11, "PARSER-STATIC": 11, "EQUIVALENCE-MUTATIONS": 24
    }:
        raise ValueError("unexpected reference-group coverage")
    if not manifest.get("artifacts"):
        raise ValueError("missing pinned current artifacts")
    for path, expected in manifest["artifacts"].items():
        if digest(root / path) != expected:
            raise ValueError(f"artifact hash mismatch: {path}")
    for row in rows:
        if digest(root / row["path"]) != row["upstream_sha256"]:
            raise ValueError(f"baseline hash mismatch: {row['path']}")
        if row["coordinator_validation"] != "pending":
            raise ValueError("this source inventory cannot certify coordinator completion")
        for key in ["portable_obligation", "expected_outcome", "target_only_residual",
                    "native_tests", "native_sources", "baseline_assertions"]:
            if not row.get(key):
                raise ValueError(f"missing {key}: {row['path']}")
        for path in row["native_sources"]:
            if not (directory / path).is_file():
                raise ValueError(f"missing native source: {path}")
        for reference in row["native_tests"]:
            path, name = reference.split("::", 1)
            if name not in (root / path).read_text():
                raise ValueError(f"missing native test reference: {reference}")
    provenance = json.loads((directory / "compiler-provenance.json").read_text())
    if len(provenance["fixtures"]) != 4:
        raise ValueError("expected four genuine compiler modules")
    for fixture in provenance["fixtures"]:
        for key in ["source", "assembly"]:
            if digest(directory / fixture[key]) != fixture[f"{key}_sha256"]:
                raise ValueError(f"compiler artifact mismatch: {fixture[key]}")
        for stage in ["compile", "assemble", "link"]:
            if fixture[stage]["exit_code"] != 0:
                raise ValueError(f"compiler stage did not pass: {stage}")
    syntax = json.loads((directory / "syntax-provenance.json").read_text())
    if syntax["status"] != "pass" or (syntax["positive_controls"], syntax["negative_controls"]) != (7, 31):
        raise ValueError("missing complete assembler syntax controls")
    for path_key, hash_key in [("native-controls.s", "source_sha256"),
                               ("syntax-mutations.tsv", "table_sha256"),
                               ("check_syntax.py", "checker_sha256")]:
        if digest(directory / path_key) != syntax[hash_key]:
            raise ValueError(f"syntax artifact mismatch: {path_key}")


def main():
    directory = Path(__file__).resolve().parent
    validate(json.loads((directory / "cases.json").read_text()), directory)
    print("PASS: all46 references, four compiler modules and38 assembler controls are pinned")


if __name__ == "__main__":
    main()
