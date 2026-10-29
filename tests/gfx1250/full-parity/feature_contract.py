#!/usr/bin/env python3
"""Validate pinned upstream references, assertion regions and complete golden outputs."""

from __future__ import annotations

import argparse
from collections import Counter
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


@lru_cache(maxsize=None)
def pinned(revision, path):
    require(
        not Path(path).is_absolute() and ".." not in Path(path).parts, "unsafe path"
    )
    result = subprocess.run(
        ["git", "show", f"{revision}:{path}"],
        cwd=ROOT,
        capture_output=True,
        timeout=30,
    )
    require(result.returncode == 0, f"missing pinned source: {revision}:{path}")
    return result.stdout


def check_anchor(anchor, revision):
    data = pinned(revision, anchor["path"])
    require(
        digest(data) == anchor["source_sha256"], "baseline assertion source changed"
    )
    text = data.decode()
    name = anchor["function"]
    if anchor.get("macro") == "proved_equivalent!":
        require(
            re.search(r"(?m)^\s*" + re.escape(name) + r":\s*", text),
            "missing shared spec assertion",
        )
        return
    starts = list(re.finditer(r"(?m)^\s*(?:pub\s+)?fn\s+(\w+)\s*\(", text))
    matches = [(index, match) for index, match in enumerate(starts) if match[1] == name]
    require(len(matches) == 1, f"missing/ambiguous baseline assertion: {name}")
    index, match = matches[0]
    end = starts[index + 1].start() if index + 1 < len(starts) else len(text)
    require(
        digest(text[match.start() : end].encode()) == anchor["function_region_sha256"],
        "baseline assertion region changed",
    )


def validate(ledger, inventory, *, check_sources=True):
    require(ledger["schema_version"] == 1, "unsupported reference schema")
    require(
        ledger["upstream_commit"] == inventory["upstream_commit"],
        "wrong baseline revision",
    )
    originals = {
        row["path"]: row for row in inventory["upstream_feature_reference_rows"]
    }
    rows = {row["path"]: row for row in ledger["rows"]}
    require(
        len(rows)
        == len(ledger["rows"])
        == len(inventory["upstream_feature_reference_rows"])
        == len(originals)
        == 520,
        "missing or duplicate source references",
    )
    require(rows.keys() == originals.keys(), "source-reference set changed")
    groups = {group["id"]: group for group in ledger["groups"]}
    require(len(groups) == len(ledger["groups"]), "duplicate obligation group")
    counts = Counter(row["group"] for row in rows.values())
    require(counts.keys() == groups.keys(), "missing/unused obligation group")
    for identity, group in groups.items():
        require(
            group["reference_count"] == counts[identity],
            "wrong grouped reference count",
        )
        require(group["portable_obligation"].strip(), "missing portable obligation")
    for path, row in rows.items():
        original = originals[path]
        require(
            row["upstream_sha256"] == original["upstream_sha256"],
            "baseline hash mismatch",
        )
        require(
            original["group"] == row["group"], "inventory group association mismatch"
        )
        if path.endswith(".rs"):
            require(
                row["reference_kind"] == "aggregate_source",
                "aggregate Rust source counted as a kernel",
            )
        else:
            require(
                row.get("baseline_assertions"), f"missing baseline assertion: {path}"
            )
        if check_sources:
            require(
                digest(pinned(ledger["upstream_commit"], path))
                == row["upstream_sha256"],
                f"stale pinned source: {path}",
            )
            for anchor in row.get("baseline_assertions", []):
                check_anchor(anchor, ledger["upstream_commit"])
            golden = row.get("baseline_golden")
            if golden:
                require(
                    digest(pinned(ledger["upstream_commit"], golden["path"]))
                    == golden["sha256"],
                    "baseline golden changed",
                )
    return {"references": len(rows), "groups": len(groups)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=HERE / "reference-contract.json")
    parser.add_argument("--inventory", type=Path, default=HERE / "gaps.json")
    args = parser.parse_args()
    result = validate(
        json.loads(args.ledger.read_text()), json.loads(args.inventory.read_text())
    )
    print(json.dumps(result, indent=2))
    print(
        "Source, assertion and golden-output contracts match the pinned upstream revision."
    )


if __name__ == "__main__":
    main()
