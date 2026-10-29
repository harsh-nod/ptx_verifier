#!/usr/bin/env python3
"""Audit finite reference ownership and declared gaps, never certify acceptance."""

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SOURCES = [
    "tests/gfx1250/full-parity/scalar-feature-review.json",
    "tests/gfx1250/portable-graph/feature-review-proposal.json",
    "tests/gfx1250/portable-graph/mechanism-review-proposal.json",
    "tests/gfx1250/fixtures/packed-data-contract.json",
    "tests/gfx1250/portable-tensor/cases.json",
    "tests/gfx1250/fixtures/matrix-feature-contract.json",
    "tests/gfx1250/full-parity/memory-payload-feature-review.json",
]
EXPLICIT_GAPS = {"portable_native_gap", "portable_property_gap_with_target_residual"}
NATIVE_CANDIDATES = {
    "exact_original_native_assertion_for_coordinator_review",
    "portable_exact_native_counterpart_for_coordinator_review",
    "portable_native_counterpart_for_coordinator_review",
    "portable_static_native_counterpart_for_coordinator_review",
    "exact_native_public_workflow_counterpart_for_coordinator_review",
    "portable_native_safety_property_with_precise_execution_residual",
    "narrow_ptx_precision_contract_with_portable_controls_for_coordinator_review",
    "exact_native_consumer_chain_for_coordinator_review",
    "native_assertion_candidate",
    "native_property_candidate_with_target_residual",
    "positive_computation",
    "exact_portable_counterpart_with_narrow_target_residual_for_coordinator_review",
    "portable_feature",
    "portable_positive_payload",
}


def proposal_of(row):
    return row.get(
        "proposal", row.get("candidate_kind", row.get("proposed_disposition"))
    )


def candidate_status(row):
    proposal = proposal_of(row)
    if proposal in EXPLICIT_GAPS:
        return "explicit_portable_native_gap"
    if proposal == "precise_target_contract_residual_candidate":
        return "precise_target_residual_candidate"
    if proposal in {
        "retained_shared_spec_assertion_for_coordinator_review",
        "retained_aggregate_source_guard_for_coordinator_review",
    }:
        return "retained_shared_source_guard"
    if proposal == "model_domain_refusal":
        return "intentional_negative_model_control"
    if proposal in {
        "target_storage_residual_with_native_payload",
        "native_contract_difference_candidate",
    }:
        return "native_target_contract_difference_candidate"
    if proposal == "portable_typed_memory_negative":
        return "completed_typed_native_negative_candidate"
    if proposal in NATIVE_CANDIDATES:
        return "native_test_candidate_requires_coordinator_review"
    return "unclassified_candidate"


def audit(ledger, manifests, current_reviews=None):
    references = {row["path"]: row for row in ledger["rows"]}
    if not references or len(references) != len(ledger["rows"]):
        raise ValueError("reference inventory is empty or duplicates a path")
    claims = defaultdict(list)
    duplicates, unexpected, violations = [], [], []
    for source, document in manifests:
        seen = set()
        for row in document["rows"]:
            path = row.get("path", row.get("baseline_path"))
            if not path:
                raise ValueError(f"{source}: missing reference path")
            if path in seen:
                duplicates.append({"path": path, "source": source})
            seen.add(path)
            if path not in references:
                unexpected.append({"path": path, "source": source})
                continue
            expected = references[path]
            original_hash = row.get("upstream_sha256", row.get("baseline_sha256"))
            if original_hash != expected["upstream_sha256"]:
                violations.append(
                    {
                        "path": path,
                        "source": source,
                        "reason": "wrong historical source identity",
                    }
                )
            group = row.get("group", row.get("original_group"))
            if group != expected["group"]:
                violations.append(
                    {"path": path, "source": source, "reason": "wrong reference group"}
                )
            if (
                row.get("completion", "coordinator_review_required")
                != "coordinator_review_required"
                or row.get("coordinator_acceptance", "pending") != "pending"
            ):
                violations.append(
                    {
                        "path": path,
                        "source": source,
                        "reason": "candidate cannot certify coordinator acceptance",
                    }
                )
            status = candidate_status(row)
            if status == "unclassified_candidate":
                violations.append(
                    {
                        "path": path,
                        "source": source,
                        "reason": "unknown candidate disposition",
                    }
                )
            if "/success/" in path and status == "intentional_negative_model_control":
                violations.append(
                    {
                        "path": path,
                        "source": source,
                        "reason": "negative model refusal cannot satisfy a required positive",
                    }
                )
            claim = {
                "source": source,
                "candidate_status": status,
                "proposal": proposal_of(row),
                "completion": "coordinator_review_required",
            }
            if status == "explicit_portable_native_gap":
                claim["remaining_gate"] = (
                    row.get("actual_native_gap")
                    or row.get("remaining_gate")
                    or row.get("remaining_portable_obligation")
                )
            elif status == "precise_target_residual_candidate" and row.get(
                "actual_native_gap"
            ):
                claim["residual_review_gate"] = row["actual_native_gap"]
            claims[path].append(claim)
    review_blockers = []
    for row in (current_reviews or {}).get("rows", []):
        path = row["path"]
        if (
            path not in references
            or row.get("upstream_sha256") != references[path]["upstream_sha256"]
        ):
            violations.append(
                {
                    "path": path,
                    "reason": "current review refers to a wrong historical source",
                }
            )
        if row.get("completion") != "coordinator_review_required" or row.get(
            "status"
        ) not in {"pending", "resolved_candidate"}:
            violations.append(
                {"path": path, "reason": "current review cannot certify acceptance"}
            )
        if row.get("status") == "resolved_candidate" and not row.get("native_evidence"):
            violations.append(
                {
                    "path": path,
                    "reason": "resolved current review needs actual native evidence",
                }
            )
        if row.get("status") == "pending":
            review_blockers.append(row)
    missing = [
        {"path": path, "group": row["group"]}
        for path, row in references.items()
        if path not in claims
    ]
    overlap = [
        {
            "path": path,
            "group": references[path]["group"],
            "sources": [claim["source"] for claim in sources],
        }
        for path, sources in claims.items()
        if len(sources) > 1
    ]
    rows = [
        {
            "path": path,
            "group": row["group"],
            "claims": claims.get(path, []),
            "completion": "coordinator_review_required",
        }
        for path, row in references.items()
    ]
    gaps = [
        {"path": row["path"], "group": row["group"], **claim}
        for row in rows
        for claim in row["claims"]
        if claim["candidate_status"] == "explicit_portable_native_gap"
    ]
    residuals = [
        {"path": row["path"], "group": row["group"], **claim}
        for row in rows
        for claim in row["claims"]
        if "residual_review_gate" in claim
    ]
    groups = Counter(row["group"] for row in references.values())
    covered = Counter(references[path]["group"] for path in claims)
    return {
        "schema_version": 1,
        "scope": "Finite reference ownership and declared candidate statuses. Presence is not implementation completion or acceptance; supporting graph/target residual proposals remain separate from actual native assertions.",
        "completion": "coordinator_review_required",
        "reference_count": len(references),
        "claimed_reference_count": len(claims),
        "ownership_complete": not (
            missing or overlap or duplicates or unexpected or violations
        ),
        "missing_rows": missing,
        "overlapping_rows": overlap,
        "duplicate_rows_within_manifest": duplicates,
        "unexpected_rows": unexpected,
        "policy_violations": violations,
        "explicit_portable_native_gaps": gaps,
        "target_residual_review_gates": residuals,
        "pending_current_portable_reviews": review_blockers,
        "known_current_review_blockers_resolved": not review_blockers,
        "candidate_status_counts": dict(
            sorted(
                Counter(
                    claim["candidate_status"]
                    for sources in claims.values()
                    for claim in sources
                ).items()
            )
        ),
        "groups": [
            {
                "id": group,
                "reference_count": count,
                "claimed_reference_count": covered[group],
            }
            for group, count in sorted(groups.items())
        ],
        "rows": rows,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--matrix-contract",
        type=Path,
        help="Pending matrix source contract, reported under its repository path",
    )
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    manifests, inputs = [], []
    for source in SOURCES:
        path = ROOT / source
        if source.endswith("matrix-feature-contract.json") and args.matrix_contract:
            path = args.matrix_contract
        if not path.is_file():
            raise SystemExit(f"missing source contract: {source}")
        content = path.read_bytes()
        manifests.append((source, json.loads(content)))
        inputs.append(
            {
                "path": source,
                "sha256": hashlib.sha256(content).hexdigest(),
                "state": "pending_external_contract"
                if path != ROOT / source
                else "repository_contract",
            }
        )
    current_review_path = Path(__file__).with_name("portable-review-blockers.json")
    current_reviews = json.loads(current_review_path.read_text())
    inputs.append(
        {
            "path": str(current_review_path.relative_to(ROOT)),
            "sha256": hashlib.sha256(current_review_path.read_bytes()).hexdigest(),
            "state": "current_review_overlay_not_duplicate_ownership",
        }
    )
    result = audit(
        json.loads(Path(__file__).with_name("feature-review.json").read_text()),
        manifests,
        current_reviews,
    )
    result["source_manifests"] = inputs
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"{result['claimed_reference_count']}/{result['reference_count']} reference paths claimed; {len(result['missing_rows'])} missing, {len(result['overlapping_rows'])} overlapping, {len(result['unexpected_rows'])} extra, {len(result['policy_violations'])} policy violations."
    )
    print(
        f"Declared portable-native gaps: {len(result['explicit_portable_native_gaps'])}; precise residual review gates: {len(result['target_residual_review_gates'])}. Coordinator acceptance stays pending."
    )
    print(
        f"Known current portable review blockers: {len(result['pending_current_portable_reviews'])}. Candidate ownership never overrides these obligations."
    )
    return 0 if result["ownership_complete"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
