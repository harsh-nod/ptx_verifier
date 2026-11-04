#!/usr/bin/env python3
"""Refuse incomplete tensor reference/fixture/mutation associations."""

from collections import Counter
import hashlib
import json
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(manifest, directory):
    root = directory.parents[2]
    rows = manifest.get("rows", [])
    if len(rows) != 18 or len({row["path"] for row in rows}) != 18:
        raise ValueError("expected all18 distinct tensor source-reference rows")
    if Counter(row["group"] for row in rows) != {"TENSOR-EDGE-LAYOUT": 5, "TENSOR-METADATA-LIFETIME": 13}:
        raise ValueError("unexpected tensor reference groups")
    if not manifest.get("artifacts"):
        raise ValueError("missing pinned artifacts")
    for path, expected in manifest["artifacts"].items():
        if digest(root / path) != expected:
            raise ValueError(f"current artifact hash mismatch: {path}")
    for row in rows:
        if digest(root / row["path"]) != row["upstream_sha256"]:
            raise ValueError(f"baseline source hash mismatch: {row['path']}")
        if golden := row.get("baseline_golden"):
            if digest(root / golden["path"]) != golden["sha256"]:
                raise ValueError(f"baseline golden hash mismatch: {golden['path']}")
        for key in ["baseline_assertions", "portable_obligation", "native_tests", "native_sources",
                    "configuration", "expected_outcome", "target_only_residual"]:
            if not row.get(key):
                raise ValueError(f"missing {key}: {row['path']}")
        for source in row["native_sources"]:
            if not (directory / source).is_file():
                raise ValueError(f"missing actual native source: {source}")
        for reference in row["native_tests"]:
            path, name = reference.split("::", 1)
            if name not in (root / path).read_text():
                raise ValueError(f"missing actual native test: {reference}")
    provenance = json.loads((directory / "compiler-provenance.json").read_text())
    if len(provenance["fixtures"]) != 4:
        raise ValueError("expected four genuine compiler modules")
    for fixture in provenance["fixtures"]:
        for key in ["source", "assembly"]:
            if digest(directory / fixture[key]) != fixture[f"{key}_sha256"]:
                raise ValueError(f"compiler artifact mismatch: {fixture[key]}")
        if any(fixture[stage]["exit_code"] != 0 for stage in ["compile", "assemble", "link"]):
            raise ValueError("compiler/assembler/linker did not pass")
    mutants = json.loads((directory / "assembler-mutants.json").read_text())
    if mutants["status"] != "pass" or len(mutants["controls"]) != 11:
        raise ValueError("missing complete four-source/seven-mutant assembler evidence")
    if digest(directory / "mutations.tsv") != mutants["table_sha256"]:
        raise ValueError("mutation table hash mismatch")
    if digest(directory / "check_mutants.py") != mutants["checker_sha256"]:
        raise ValueError("mutation checker hash mismatch")
    for source, expected in mutants["source_sha256"].items():
        if digest(directory / source) != expected:
            raise ValueError(f"mutated source baseline hash mismatch: {source}")
    projection = manifest["native_edge_configuration"]
    if projection["input"]["shape"] != [8, 8] or projection["logical_tile_shape"] != [4, 4]:
        raise ValueError("original tensor input/tile shape was reduced")
    if projection["input"]["dtype"] != "F16" or projection["output"]["length"] != 16:
        raise ValueError("original dtype or complete native tile is missing")


def main():
    directory = Path(__file__).resolve().parent
    validate(json.loads((directory / "cases.json").read_text()), directory)
    print("PASS: all18 references, four compiler modules and seven legal mutants are pinned")


if __name__ == "__main__":
    main()
