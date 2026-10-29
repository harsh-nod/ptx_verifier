#!/usr/bin/env python3
"""Validate the complete upstream-to-native regression mapping and source pins."""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
INDEX = HERE / "feature-mappings-index.json"
SOURCES = [
    "tests/gfx1250/full-parity/scalar-mappings.json",
    "tests/gfx1250/portable-graph/feature-mappings.json",
    "tests/gfx1250/portable-graph/mechanism-mappings.json",
    "tests/gfx1250/fixtures/packed-data-contract.json",
    "tests/gfx1250/portable-tensor/cases.json",
    "tests/gfx1250/fixtures/matrix-feature-contract.json",
    "tests/gfx1250/full-parity/memory-payload-mappings.json",
]
KINDS = {
    "native_assertion",
    "native_memory_negative",
    "target_boundary",
    "target_contract_difference",
    "shared_assertion",
    "model_refusal",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def source_identity(path, root):
    path = path.resolve()
    return {
        "path": str(path.relative_to(root.resolve())),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def include_sources(path, root, inventory):
    """Resolve literal Rust fixture includes and helper modules without macros."""
    source = source_identity(path, root)
    if source["path"] in inventory:
        return
    inventory[source["path"]] = source
    if path.suffix != ".rs":
        return
    text = path.read_text()
    for match in re.finditer(
        r'include_(?:str|bytes)!\s*\(\s*(?:r(?P<hashes>#{0,255})"(?P<raw>.*?)"(?P=hashes)|"(?P<normal>[^"]+)")\s*,?\s*\)',
        text,
        re.DOTALL,
    ):
        relative = match["raw"] if match["raw"] is not None else match["normal"]
        include_sources(path.parent / relative, root, inventory)
    for relative in re.findall(r'#\[path\s*=\s*"([^"]+)"\]', text):
        include_sources(path.parent / relative, root, inventory)
    for name in re.findall(r"(?m)^\s*(?:pub(?:\([^)]*\))?\s+)?mod\s+(\w+)\s*;", text):
        for child in [path.parent / (name + ".rs"), path.parent / name / "mod.rs"]:
            if child.is_file():
                include_sources(child, root, inventory)


def test_references(row, document):
    values = list(row.get("native_candidates", []))
    catalog = document.get("native_evidence_catalog", {})
    values.extend(
        catalog[value] if isinstance(value, str) else value
        for value in row.get("native_evidence", [])
    )
    for key in ["native_tests", "related_tests"]:
        values.extend(row.get(key, []))
    if row.get("test"):
        values.append(row["test"])
    result = []
    for value in values:
        if isinstance(value, str):
            path, function = value.rsplit("::", 1)
            value = {"path": path, "function": function}
        result.append(value)
    return result


def validate(ledger, manifests, *, root=ROOT):
    references = {row["path"]: row for row in ledger["rows"]}
    require(
        bool(references) and len(references) == len(ledger["rows"]),
        "empty or duplicate reference inventory",
    )
    mapped, inventory = {}, {}
    for reference in references.values():
        source = root / reference["path"]
        include_sources(source, root, inventory)
        if source.suffix == ".ptx" and source.with_suffix(".out").is_file():
            include_sources(source.with_suffix(".out"), root, inventory)
        for assertion in reference.get("baseline_assertions", []):
            include_sources(root / assertion["path"], root, inventory)
        if reference.get("baseline_golden"):
            include_sources(
                root / reference["baseline_golden"]["path"], root, inventory
            )
    for manifest, document in manifests:
        for row in document["rows"]:
            path = row.get("path", row.get("baseline_path"))
            require(path in references, f"unexpected reference: {path}")
            require(path not in mapped, f"duplicate mapping: {path}")
            reference = references[path]
            require(
                row.get("upstream_sha256", row.get("baseline_sha256"))
                == reference["upstream_sha256"],
                f"wrong baseline source identity: {path}",
            )
            require(
                row.get("group", row.get("original_group")) == reference["group"],
                f"wrong reference group: {path}",
            )
            kind = row["mapping_kind"]
            require(kind in KINDS, f"unknown mapping kind: {path}")
            require(
                not ("/success/" in path and kind == "model_refusal"),
                f"required positive cannot be a model refusal: {path}",
            )
            if kind == "target_boundary":
                require(
                    not (reference.get("baseline_golden") or {}).get(
                        "output_coordinates"
                    ),
                    f"target boundary omits an original computation: {path}",
                )
            tests = test_references(row, document)
            require(tests, f"missing actual native/shared test: {path}")
            test_names = []
            for test in tests:
                source = root / test["path"]
                identity = source_identity(source, root)
                if test.get("source_sha256"):
                    require(
                        identity["sha256"] == test["source_sha256"],
                        f"test source pin changed: {test['path']}",
                    )
                name = test.get("function")
                if name:
                    pattern = (
                        r"\b(?:fn\s+"
                        + re.escape(name)
                        + r"\s*\(|"
                        + re.escape(name)
                        + r"\s*[:,])"
                    )
                    require(
                        re.search(pattern, source.read_text()),
                        f"missing actual test: {test['path']}::{name}",
                    )
                include_sources(source, root, inventory)
                test_names.append(test["path"] + ("::" + name if name else ""))
            for key in ["native_source", "native_assembly", "additional_native_source"]:
                if row.get(key):
                    source = root / row[key]
                    if not source.is_file():
                        source = root / Path(manifest).parent / row[key]
                    identity = source_identity(source, root)
                    if row.get(key + "_sha256"):
                        require(
                            identity["sha256"] == row[key + "_sha256"],
                            f"native source pin changed: {row[key]}",
                        )
                    include_sources(source, root, inventory)
            for source in row.get("native_sources", []):
                native = root / source
                if not native.is_file():
                    native = root / Path(manifest).parent / source
                include_sources(native, root, inventory)
            mapped[path] = {
                "path": path,
                "group": reference["group"],
                "manifest": manifest,
                "mapping_kind": kind,
                "tests": sorted(set(test_names)),
            }
    require(
        mapped.keys() == references.keys(),
        f"missing reference mappings: {sorted(references.keys() - mapped.keys())}",
    )
    rows = sorted(mapped.values(), key=lambda row: row["path"])
    return {
        "schema_version": 1,
        "reference_count": len(rows),
        "mapping_counts": dict(
            sorted(Counter(row["mapping_kind"] for row in rows).items())
        ),
        "source_inventory": sorted(
            inventory.values(), key=lambda source: source["path"]
        ),
        "rows": rows,
    }


def check_index(result, path=INDEX):
    instruction = (
        "regenerate with python3 tests/gfx1250/full-parity/validate_feature_mappings.py "
        "--output tests/gfx1250/full-parity/feature-mappings-index.json"
    )
    require(path.is_file(), "missing source/mapping index; " + instruction)
    require(
        json.loads(path.read_text()) == result,
        "stale source/mapping index; " + instruction,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output", type=Path, help="Explicitly regenerate the source/mapping index"
    )
    args = parser.parse_args()
    ledger = json.loads((HERE / "reference-contract.json").read_text())
    manifests = [(name, json.loads((ROOT / name).read_text())) for name in SOURCES]
    from feature_contract import validate as validate_references

    validate_references(ledger, json.loads((HERE / "gaps.json").read_text()))
    result = validate(ledger, manifests)
    if args.output:
        protected = {ROOT / source for source in SOURCES} | {
            HERE / "reference-contract.json"
        }
        protected.update(ROOT / row["path"] for row in result["source_inventory"])
        protected.add(HERE / "gaps.json")
        for row in ledger["rows"]:
            protected.add(ROOT / row["path"])
            protected.update(
                ROOT / anchor["path"] for anchor in row.get("baseline_assertions", [])
            )
            if row.get("baseline_golden"):
                protected.add(ROOT / row["baseline_golden"]["path"])
        require(
            args.output.resolve() not in {path.resolve() for path in protected},
            "output would overwrite a source contract",
        )
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    else:
        check_index(result)
    print(
        f"{result['reference_count']} distinct reference mappings; source pins, actual tests and required positive classifications match."
    )


if __name__ == "__main__":
    main()
