#!/usr/bin/env python3
"""Check the source-reference ledger; consistent metadata is not a proof."""

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
DISPOSITIONS = {
    "aggregate_source_reference",
    "shared_engine_contract_candidate",
    "exact_native_counterpart_candidate",
    "target_mechanism_residual_candidate",
    "pending_exact_native_control",
    "pending_native_semantics_mapping",
    "pending_native_alignment_mapping",
    "pending_explicit_native_mapping",
    "pending_individual_review",
}


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
    require(ledger["schema_version"] == 1, "unsupported feature review schema")
    require(
        ledger["upstream_commit"] == inventory["upstream_commit"],
        "wrong baseline revision",
    )
    require(
        ledger["policy"]["coordinator_only_completion"] is True, "completion ownership"
    )
    require(
        ledger["policy"]["gfx950_status_not_inherited"] is True,
        "target status inheritance",
    )
    originals = {
        row["path"]: row for row in inventory["upstream_feature_reference_rows"]
    }
    rows = {row["path"]: row for row in ledger["rows"]}
    require(
        len(rows) == len(ledger["rows"]) == 520,
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
        require(
            group["completion"] == "coordinator_review_required",
            "unreviewed proof claim",
        )
        for field in (
            "portable_obligation",
            "remaining_gate",
            "target_specific_residual",
        ):
            require(
                isinstance(group[field], str) and group[field].strip(),
                f"missing {field}",
            )
        for candidate in group["native_candidates"]:
            text = (ROOT / candidate["path"]).read_text()
            require(
                re.search(
                    r"\bfn\s+" + re.escape(candidate["function"]) + r"\s*\(", text
                ),
                "native candidate function does not exist",
            )
            require(candidate["scope"].strip(), "native candidate lacks limits")
    for path, row in rows.items():
        original = originals[path]
        require(
            row["upstream_sha256"] == original["upstream_sha256"],
            "baseline hash mismatch",
        )
        require(
            row["proposed_disposition"] in DISPOSITIONS, "unreviewed acceptance status"
        )
        require(
            original["review_group"] == row["group"],
            "inventory group association mismatch",
        )
        require(
            original["gfx1250_review"] == row["proposed_disposition"],
            "inventory disposition association mismatch",
        )
        if row["proposed_disposition"] == "target_mechanism_residual_candidate":
            require(
                original["existing_gfx950_disposition"] == "ptx-only",
                "portable row cannot become target-only automatically",
            )
            require(
                row["baseline_assertions"], "mechanism residual lacks actual assertion"
            )
            require(
                not row.get("baseline_golden", {}).get("output_coordinates"),
                "target residual still contains an unreviewed data output obligation",
            )
        if path.endswith(".rs"):
            require(
                row["reference_kind"]
                == "aggregate_assertion_or_harness_source_not_one_acceptance_case",
                "aggregate Rust source counted as a kernel",
            )
        else:
            require(
                row.get("baseline_assertions"), f"missing baseline assertion: {path}"
            )
        if check_sources:
            data = pinned(ledger["upstream_commit"], path)
            require(
                digest(data) == row["upstream_sha256"], f"stale pinned source: {path}"
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
    expected = Counter(row["proposed_disposition"] for row in rows.values())
    require(
        dict(expected) == ledger["counts"]["by_proposed_disposition"],
        "wrong disposition counts",
    )
    require(ledger["counts"]["reference_files"] == 520, "wrong total references")
    return {
        "references": len(rows),
        "groups": len(groups),
        "dispositions": dict(expected),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, default=HERE / "feature-review.json")
    parser.add_argument("--inventory", type=Path, default=HERE / "gaps.json")
    args = parser.parse_args()
    result = validate(
        json.loads(args.ledger.read_text()), json.loads(args.inventory.read_text())
    )
    print(json.dumps(result, indent=2))
    print(
        "Consistent source-reference metadata only; no parity completion or runtime proof claimed."
    )


if __name__ == "__main__":
    main()
