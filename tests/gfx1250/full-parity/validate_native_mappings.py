#!/usr/bin/env python3
"""Validate exact source/test mappings; metadata is not runtime acceptance."""

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
DEFAULT = ROOT / "tests/gfx1250/fixtures/packed-data-contract.json"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate(document, ledger, root=ROOT):
    require(
        document["schema_version"] == 1 and document["target"] == "gfx1250",
        "wrong mapping schema/target",
    )
    groups = set(document["reference_groups"])
    references = {row["path"]: row for row in ledger["rows"] if row["group"] in groups}
    if "source_selection" in document:
        selection = document["source_selection"]
        proposal = root / selection["path"]
        require(sha(proposal) == selection["sha256"], "reference selection changed")
        require(
            selection["proposal"] == "native_property_candidate_with_target_residual"
            and selection.get("previous_proposal")
            == "portable_property_gap_with_target_residual",
            "unknown reference selection",
        )
        selected = {
            row["path"]
            for row in json.loads(proposal.read_text())["rows"]
            if row["proposal"] == selection["proposal"]
            and row.get("previous_proposal") == selection["previous_proposal"]
        }
        selected.update(selection.get("additional_paths", []))
        require(
            len(selected) == selection["required_rows"]
            and selected <= references.keys(),
            "explicit obligation selection changed",
        )
        references = {path: row for path, row in references.items() if path in selected}
    rows = {row["baseline_path"]: row for row in document["rows"]}
    require(len(rows) == len(document["rows"]), "duplicate native mapping")
    require(rows.keys() == references.keys(), "dropped or extra reference mapping")
    positive_cases = {}
    if "positive_abi_inventory" in document:
        inventory = root / document["positive_abi_inventory"]
        require(
            sha(inventory) == document["positive_abi_inventory_sha256"],
            "safe ABI inventory changed",
        )
        cases = json.loads(inventory.read_text())["cases"]
        positive_cases = {case["kernel"]: case for case in cases}
        require(len(positive_cases) == len(cases), "duplicate safe ABI kernel")
    for path, row in rows.items():
        reference = references[path]
        require(
            row["group"] == reference["group"]
            and row["baseline_sha256"] == reference["upstream_sha256"],
            "wrong original feature identity",
        )
        require(sha(root / path) == row["baseline_sha256"], "baseline source changed")
        require(
            row["baseline_assertions"] == reference["baseline_assertions"],
            "wrong original assertions",
        )
        require(
            row["coordinator_acceptance"] == "pending",
            "mapping is not coordinator acceptance",
        )
        require(
            row["candidate_kind"]
            in (
                "positive_computation",
                "model_domain_refusal",
                "target_storage_residual_with_native_payload",
                "portable_feature",
            ),
            "unreviewed exclusion",
        )
        test, name = row["test"].rsplit("::", 1)
        sources = document.get("test_sources", [document.get("test_source")])
        require(test in sources, "mapping points to another test corpus")
        test_source = (root / test).read_text()
        require(
            re.search(r"\bfn\s+" + re.escape(name) + r"\s*\(", test_source)
            or re.search(r"\boriginal!\(\s*" + re.escape(name) + r"\s*,", test_source),
            "missing native test",
        )
        for key in ("native_source", "native_assembly"):
            require(
                sha(root / row[key]) == row[key + "_sha256"], "native source changed"
            )
        require(
            re.search(
                r"(?m)^" + re.escape(row["kernel"]) + ":",
                (root / row["native_assembly"]).read_text(),
            ),
            "missing native compiler entry",
        )
        if row["candidate_kind"] == "positive_computation":
            golden = reference["baseline_golden"]
            require(
                row["golden_path"] == golden["path"]
                and row["golden_sha256"] == golden["sha256"],
                "wrong original golden",
            )
            require(
                sha(root / row["golden_path"]) == row["golden_sha256"],
                "original golden changed",
            )
            actual = re.findall(
                r"(?m)^out\[(\d+)\] =", (root / row["golden_path"]).read_text()
            )
            require(
                [int(index) for index in actual] == row["output"]["written_indices"],
                "missing, additional or shifted output coordinate",
            )
            require(
                row["output"]["written_indices"]
                and max(row["output"]["written_indices"]) < row["output"]["elements"],
                "invalid output view",
            )
        else:
            require(
                row.get("reason", "").strip(), "missing exact domain/storage residual"
            )
        if row["candidate_kind"] == "portable_feature":
            outcome = row["expected_native_outcome"]
            require(
                outcome
                in (
                    "complete_outputs",
                    "verified_empty_outputs",
                    "typed_domain_refusal",
                ),
                "missing explicit output/refusal contract",
            )
            require(
                bool(row["native_outputs"]) == (outcome == "complete_outputs"),
                "native output obligation was dropped",
            )
            require(
                outcome != "typed_domain_refusal"
                or "/failing/" in path
                or "/soundness/" in path,
                "required positive cannot become a domain refusal",
            )
            if row["kernel"] in positive_cases and outcome != "typed_domain_refusal":
                case = positive_cases[row["kernel"]]
                require(
                    row["native_outputs"]
                    == {
                        array["name"]: array["elements"]
                        for array in case["arrays"]
                        if array["kind"] == "out"
                    },
                    "native output view changed",
                )
            require(
                row.get("native_property", "").strip()
                and row.get("target_residual", "").strip(),
                "missing portable property or precise target residual",
            )
            golden = reference.get("baseline_golden")
            if golden:
                require(
                    not golden["output_coordinates"] or outcome == "complete_outputs",
                    "original output-bearing positive cannot become empty",
                )
                require(
                    row["golden_path"] == golden["path"]
                    and row["golden_sha256"] == golden["sha256"]
                    and sha(root / row["golden_path"]) == row["golden_sha256"],
                    "wrong original golden",
                )
                require(
                    row["original_output_coordinates"] == golden["output_coordinates"],
                    "original projection changed",
                )
            for related in row.get("related_tests", []):
                related_path, related_name = related.rsplit("::", 1)
                require(
                    related_path in sources
                    and re.search(
                        r"\bfn\s+" + re.escape(related_name) + r"\s*\(",
                        (root / related_path).read_text(),
                    ),
                    "missing related native control",
                )
    return len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", type=Path, default=DEFAULT)
    args = parser.parse_args()
    count = validate(
        json.loads(args.contract.read_text()),
        json.loads(Path(__file__).with_name("feature-review.json").read_text()),
    )
    print(
        f"Source/test metadata consistent: {count} mapping candidates. Coordinator acceptance remains pending."
    )


if __name__ == "__main__":
    main()
