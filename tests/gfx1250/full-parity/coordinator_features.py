#!/usr/bin/env python3
"""Prepare current per-reference reviews without rewriting historical planning."""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

from audit_feature_union import ROOT, SOURCES, audit, candidate_status, proposal_of


HERE = Path(__file__).resolve().parent


def validate_inventory(ledger, inventory, expected_count=520):
    originals = {
        row["path"]: row for row in inventory["upstream_feature_reference_rows"]
    }
    rows = {row["path"]: row for row in ledger["rows"]}
    if (
        len(originals) != expected_count
        or len(inventory["upstream_feature_reference_rows"]) != expected_count
        or len(ledger["rows"]) != expected_count
        or rows.keys() != originals.keys()
    ):
        raise ValueError("historical reference inventory is incomplete or duplicated")
    if ledger["upstream_commit"] != inventory["upstream_commit"]:
        raise ValueError("historical baseline revision changed")
    for path, row in rows.items():
        if (
            row["upstream_sha256"] != originals[path]["upstream_sha256"]
            or row["group"] != originals[path]["review_group"]
        ):
            raise ValueError(f"historical reference identity changed: {path}")


def digest(value):
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def file_identity(path, root):
    path = path.resolve()
    relative = path.relative_to(root.resolve())
    return {
        "path": str(relative),
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def include_sources(path, root, inventory):
    """Bind literal Rust includes and helper modules without executing macros."""
    identity = file_identity(path, root)
    if identity["path"] in inventory:
        return
    inventory[identity["path"]] = identity
    if path.suffix != ".rs":
        return
    text = path.read_text()
    includes = re.finditer(
        r'include_(?:str|bytes)!\s*\(\s*(?:r(?P<hashes>#{0,255})"(?P<raw>.*?)"(?P=hashes)|"(?P<normal>[^"]+)")\s*,?\s*\)',
        text,
        re.DOTALL,
    )
    for match in includes:
        relative = match["raw"] if match["raw"] is not None else match["normal"]
        include_sources(path.parent / relative, root, inventory)
    for relative in re.findall(r'#\[path\s*=\s*"([^"]+)"\]', text):
        include_sources(path.parent / relative, root, inventory)
    for name in re.findall(r"(?m)^\s*(?:pub(?:\([^)]*\))?\s+)?mod\s+(\w+)\s*;", text):
        for child in [path.parent / (name + ".rs"), path.parent / name / "mod.rs"]:
            if child.is_file():
                include_sources(child, root, inventory)


def portable_obligation(candidate, baseline, refs, groups):
    for field in [
        "portable_obligation",
        "remaining_portable_obligation",
        "native_property",
        "native_mapping",
        "reason",
    ]:
        if candidate.get(field):
            return candidate[field]
    anchors = baseline.get("baseline_assertions", [])
    assertions = ", ".join(
        anchor["path"] + "::" + anchor["function"] for anchor in anchors
    )
    if candidate.get("comparison"):
        return (
            f"Preserve exact {baseline['path']} as asserted by {assertions}. "
            f"Native kernel {candidate.get('kernel')} must satisfy: {candidate['comparison']}. "
            f"Typed input contract: {json.dumps(candidate.get('input'), sort_keys=True)}. "
            f"Typed complete output contract: {json.dumps(candidate.get('output'), sort_keys=True)}. "
            f"Pinned original golden: {candidate.get('golden_path')} SHA256 {candidate.get('golden_sha256')}."
        )
    group = groups.get(baseline["group"], {})
    obligation = baseline.get("portable_obligation") or group.get("portable_obligation")
    controls = ", ".join(
        ref["path"] + ("::" + ref["function"] if ref.get("function") else "")
        for ref in refs
    )
    return f"Exact source {baseline['path']}; pinned assertions {assertions or 'retained source contract'}; current controls {controls}. {obligation or 'Independently adjudicate this exact source/test obligation before review.'}"


def native_references(row, document, manifest, root):
    references = list(row.get("native_candidates", []))
    catalog = document.get("native_evidence_catalog", {})
    for value in row.get("native_evidence", []):
        references.append(catalog[value] if isinstance(value, str) else value)
    for field in ["native_tests", "related_tests"]:
        references.extend(row.get(field, []))
    if row.get("test"):
        references.append(row["test"])
    result = {}
    for value in references:
        if isinstance(value, str):
            path, function = value.rsplit("::", 1)
            value = {"path": path, "function": function}
        path = root / value["path"]
        identity = file_identity(path, root)
        if (
            value.get("source_sha256")
            and value["source_sha256"] != identity["source_sha256"]
        ):
            identity["historical_reference_sha256"] = value["source_sha256"]
            identity["source_changed_since_reference"] = True
        if value.get("function"):
            function = value["function"]
            text = path.read_text()
            # Several exact scalar/spec tests are generated by named macros.
            pattern = (
                r"\b(?:fn\s+"
                + re.escape(function)
                + r"\s*\(|"
                + re.escape(function)
                + r"\s*[:,])"
            )
            if not re.search(pattern, text):
                raise ValueError(
                    f"missing actual named test/assertion: {path}::{function}"
                )
            identity["function"] = function
        if value.get("kind"):
            identity["kind"] = value["kind"]
        result[(identity["path"], identity.get("function"))] = identity
    if not result:
        raise ValueError(
            f"no actual native/shared references: {manifest}:{row.get('path', row.get('baseline_path'))}"
        )
    return sorted(
        result.values(), key=lambda item: (item["path"], item.get("function", ""))
    )


def native_sources(row, manifest, root):
    values = [
        row[field]
        for field in ["native_source", "native_assembly", "additional_native_source"]
        if row.get(field)
    ]
    values.extend(row.get("native_sources", []))
    result = {}
    for value in values:
        path = root / value
        if not path.is_file():
            path = root / Path(manifest).parent / value
        identity = file_identity(path, root)
        field = (
            "native_source" if value == row.get("native_source") else "native_assembly"
        )
        expected = row.get(field + "_sha256")
        if expected and expected != identity["source_sha256"]:
            raise ValueError(f"native source pin changed: {identity['path']}")
        result[identity["path"]] = identity
    return sorted(result.values(), key=lambda item: item["path"])


def prepare(
    ledger,
    manifests,
    current_reviews,
    decisions=None,
    *,
    root=ROOT,
    mechanism_reviews=None,
):
    union = audit(ledger, manifests, current_reviews)
    if not union["ownership_complete"]:
        raise ValueError("current reference ownership/policy audit is not complete")
    originals = {row["path"]: row for row in ledger["rows"]}
    groups = {group["id"]: group for group in ledger.get("groups", [])}
    pending = {row["path"] for row in union["pending_current_portable_reviews"]}
    gaps = {row["path"] for row in union["explicit_portable_native_gaps"]}
    reviews = decisions or {"rows": []}
    if reviews["rows"] and reviews.get("authority") != "coordinator":
        raise ValueError("explicit coordinator decision authority is required")
    by_path = {}
    for decision in reviews["rows"]:
        path = decision["path"]
        if path not in originals or path in by_path:
            raise ValueError("unexpected or duplicate coordinator decision")
        by_path[path] = decision
    overlays = {}
    for name, document in [
        ("portable_review", current_reviews),
        ("mechanism_adjudication", mechanism_reviews or {"rows": []}),
    ]:
        seen = set()
        for review in document["rows"]:
            path = review["path"]
            if (
                path not in originals
                or path in seen
                or review.get("upstream_sha256") != originals[path]["upstream_sha256"]
            ):
                raise ValueError(
                    "current adjudication has a wrong or duplicate reference"
                )
            seen.add(path)
            overlays.setdefault(path, {})[name] = {
                "document_identity_sha256": digest(document),
                "row": review,
            }
    rows, candidates, inventory = [], [], {}
    for baseline in ledger["rows"]:
        reference = root / baseline["path"]
        include_sources(reference, root, inventory)
        if reference.suffix == ".ptx" and reference.with_suffix(".out").is_file():
            include_sources(reference.with_suffix(".out"), root, inventory)
        for assertion in baseline.get("baseline_assertions", []):
            include_sources(root / assertion["path"], root, inventory)
    # Dynamic test macros read from the finite original inventory. Bind the
    # complete inventory once, in addition to each literal dependency, so those
    # readers cannot retain an old decision after an included fixture changes.
    for path in [
        root / "Cargo.toml",
        root / "Cargo.lock",
        *root.glob("crates/*/Cargo.toml"),
        *root.glob("crates/*/src/**/*.rs"),
    ]:
        if path.is_file():
            include_sources(path, root, inventory)
    for manifest, document in manifests:
        for candidate in document["rows"]:
            path = candidate.get("path", candidate.get("baseline_path"))
            baseline = originals[path]
            refs = native_references(candidate, document, manifest, root)
            sources = native_sources(candidate, manifest, root)
            for overlay in overlays.get(path, {}).values():
                review = overlay["row"]
                sources.extend(native_sources(review, manifest, root))
                if any(
                    review.get(field)
                    for field in [
                        "native_candidates",
                        "native_evidence",
                        "native_tests",
                        "related_tests",
                        "test",
                    ]
                ):
                    refs.extend(native_references(review, {}, manifest, root))
            refs = sorted(
                {(ref["path"], ref.get("function")): ref for ref in refs}.values(),
                key=lambda ref: (ref["path"], ref.get("function", "")),
            )
            sources = sorted(
                {source["path"]: source for source in sources}.values(),
                key=lambda source: source["path"],
            )
            row_inventory = {}
            include_sources(root / path, root, row_inventory)
            for source in refs + sources:
                include_sources(root / source["path"], root, row_inventory)
            for assertion in baseline.get("baseline_assertions", []):
                include_sources(root / assertion["path"], root, row_inventory)
            reference = root / path
            if reference.suffix == ".ptx" and reference.with_suffix(".out").is_file():
                include_sources(reference.with_suffix(".out"), root, row_inventory)
            for assertion in candidate.get("baseline_assertions", []):
                include_sources(root / assertion["path"], root, row_inventory)
            if candidate.get("golden_path"):
                include_sources(root / candidate["golden_path"], root, row_inventory)
            inventory.update(row_inventory)
            candidates.append(
                (manifest, document, candidate, refs, sources, row_inventory)
            )
    input_inventory = sorted(inventory.values(), key=lambda source: source["path"])
    input_identity = digest(input_inventory)
    for manifest, document, candidate, refs, sources, row_inventory in candidates:
        manifest_identity = digest(document)
        path = candidate.get("path", candidate.get("baseline_path"))
        baseline = originals[path]
        current_reference = file_identity(root / path, root)
        identity = digest(
            {
                "path": path,
                "upstream_sha256": baseline["upstream_sha256"],
                "current_reference": current_reference,
                "owner_manifest_identity": manifest_identity,
                "current_references": refs,
                "native_sources": sources,
                "complete_input_inventory_sha256": input_identity,
                "current_review_overlays": overlays.get(path, {}),
            }
        )
        decision = by_path.get(path)
        if decision:
            if decision.get("proof_identity_sha256") != identity:
                raise ValueError(f"stale coordinator proof/source identity: {path}")
            if decision.get("status") not in {"reviewed", "pending"}:
                raise ValueError("unsupported coordinator decision status")
            if decision["status"] == "reviewed":
                if path in pending or path in gaps:
                    raise ValueError(
                        f"unresolved portable obligation cannot be reviewed complete: {path}"
                    )
                if decision.get("portable_obligation_satisfied") is not True:
                    raise ValueError(
                        "reviewed row needs explicit portable-obligation adjudication"
                    )
                if not decision.get("note", "").strip() or not decision.get(
                    "validation_commands"
                ):
                    raise ValueError(
                        "reviewed row needs a concrete note and reproduction commands"
                    )
        rows.append(
            {
                "path": path,
                "group": baseline["group"],
                "upstream_sha256": baseline["upstream_sha256"],
                "current_reference_source_sha256": current_reference["source_sha256"],
                "source_changed_since_historical_inventory": current_reference[
                    "source_sha256"
                ]
                != baseline["upstream_sha256"],
                "historical_planning_disposition": baseline["proposed_disposition"],
                "current_candidate_owner": manifest,
                "owner_manifest_identity_sha256": manifest_identity,
                "current_candidate_proposal": proposal_of(candidate),
                "current_candidate_status": candidate_status(candidate),
                "portable_obligation": portable_obligation(
                    candidate, baseline, refs, groups
                ),
                "baseline_assertions": baseline.get(
                    "baseline_assertions", candidate.get("baseline_assertions", [])
                ),
                "exact_target_residual": candidate.get("target_specific_residual")
                or candidate.get("target_contract_residual")
                or candidate.get("target_only_residual")
                or candidate.get("target_residual")
                or candidate.get("exact_target_contract"),
                "current_review_overlays": overlays.get(path, {}),
                "current_baseline_assertion_sources": [
                    {**assertion, **file_identity(root / assertion["path"], root)}
                    for assertion in baseline.get("baseline_assertions", [])
                ],
                "current_native_or_shared_references": refs,
                "native_source_pins": sources,
                "row_recursive_source_dependencies": sorted(
                    row_inventory.values(), key=lambda source: source["path"]
                ),
                "proof_identity_sha256": identity,
                "known_portable_gate_pending": path in pending or path in gaps,
                "coordinator_status": decision["status"] if decision else "pending",
                "coordinator_decision": decision,
            }
        )
    rows.sort(key=lambda row: row["path"])
    counts = Counter(row["coordinator_status"] for row in rows)
    return {
        "schema_version": 1,
        "scope": "Current candidate references and explicit per-row coordinator review. Historical planning/source observations are unchanged. Preparing this artifact does not execute tests, prove outputs, or accept any row by inference.",
        "historical_planning_unchanged": True,
        "complete_input_inventory": input_inventory,
        "complete_input_inventory_sha256": input_identity,
        "complete_input_inventory_scope": "Finite original references/goldens, current baseline assertions, native/shared control literal includes and helper modules, native sources, and workspace Rust/Cargo implementation. This shared inventory conservatively binds dynamic test macro readers; changes require fresh explicit decisions.",
        "proof_identity": "Canonical owning-manifest content, current portable/mechanism adjudication overlays for affected rows, historical reference identity, current baseline assertions and goldens, recursive literal Rust includes/helper modules, native source pins, and the finite shared Rust/Cargo implementation inventory. Explicit coordinator decisions must match this exact current identity; preparing rows never reuses an old passing observation.",
        "reference_count": len(rows),
        "reviewed_reference_count": counts["reviewed"],
        "pending_reference_count": counts["pending"],
        "known_pending_portable_obligations": sorted(pending | gaps),
        "all_references_coordinator_reviewed": counts["reviewed"] == len(rows),
        "rows": rows,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--decisions", type=Path, help="Explicit coordinator-authored per-row decisions"
    )
    parser.add_argument("--require-all-reviewed", action="store_true")
    args = parser.parse_args()
    protected = {
        HERE / "gaps.json",
        HERE / "feature-review.json",
        HERE / "portable-review-blockers.json",
        HERE / "mechanism-residual-review.json",
        *(ROOT / source for source in SOURCES),
    }
    if args.decisions:
        protected.add(args.decisions)
    if args.output.resolve() in {path.resolve() for path in protected}:
        raise SystemExit(
            "output must be separate from historical/source/decision inputs"
        )
    ledger = json.loads((HERE / "feature-review.json").read_text())
    validate_inventory(ledger, json.loads((HERE / "gaps.json").read_text()))
    manifests = [
        (source, json.loads((ROOT / source).read_text())) for source in SOURCES
    ]
    reviews = json.loads((HERE / "portable-review-blockers.json").read_text())
    decisions = json.loads(args.decisions.read_text()) if args.decisions else None
    mechanism_reviews = json.loads(
        (HERE / "mechanism-residual-review.json").read_text()
    )
    result = prepare(
        ledger, manifests, reviews, decisions, mechanism_reviews=mechanism_reviews
    )
    protected.update(
        ROOT / source["path"] for source in result["complete_input_inventory"]
    )
    for row in result["rows"]:
        protected.add(ROOT / row["path"])
        for source in (
            row["current_native_or_shared_references"] + row["native_source_pins"]
        ):
            protected.add(ROOT / source["path"])
    if args.output.resolve() in {path.resolve() for path in protected}:
        raise SystemExit("output must be separate from reviewed source inputs")
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"{result['reference_count']} exact reference rows; {result['reviewed_reference_count']} explicitly coordinator-reviewed, {result['pending_reference_count']} pending. Historical planning is unchanged."
    )
    if args.require_all_reviewed and not result["all_references_coordinator_reviewed"]:
        raise SystemExit(
            "incomplete coordinator review; candidate presence is not acceptance"
        )


if __name__ == "__main__":
    main()
