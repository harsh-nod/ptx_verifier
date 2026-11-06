#!/usr/bin/env python3
"""Check source hashes and actual code/test references in native AMD inventories.

This read-only audit does not execute a kernel or promote a parser row to support.
Run the target-specific generators with --check to repeat their parser/lower checks.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]


def checked_hash(path, expected):
    actual = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
    if actual != expected:
        raise ValueError(f"stale source hash: {path}: {actual} != {expected}")


def check_references(value):
    count = 0
    if isinstance(value, dict):
        if "path" in value and "function" in value:
            path = ROOT / value["path"]
            text = path.read_text()
            match = re.search(r"\bfn\s+" + re.escape(value["function"]) + r"\s*\(", text)
            if match is None:
                raise ValueError(f"missing function: {value['path']}::{value['function']}")
            line = text.count("\n", 0, match.start()) + 1
            if "line" in value and value["line"] != line:
                raise ValueError(f"stale function line: {value['path']}::{value['function']}")
            count += 1
        count += sum(check_references(item) for item in value.values())
    elif isinstance(value, list):
        count += sum(check_references(item) for item in value)
    return count


def cdna(target):
    inventory = json.loads((ROOT / f"tests/{target}/instruction-coverage.json").read_text())
    sources = inventory["inputs"] if target == "gfx942" else inventory["sources"]
    for row in sources:
        checked_hash(row["path"], row["sha256"])
    return {"source_inventory": inventory["totals"], "checked_source_hashes": len(sources),
            "checked_code_and_test_references": check_references(inventory),
            "scope": "recorded parse/lower profiles and named bounded semantic controls; no per-PC execution coverage"}


def gfx1250():
    directory = ROOT / "tests/gfx1250/fixtures"
    inventory = json.loads((directory / "emitted-instructions.json").read_text())
    module_path = ROOT / "tests/gfx1250/compile_fixtures.py"
    spec = importlib.util.spec_from_file_location("gfx1250_fixture_inventory", module_path)
    compiler = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(compiler)
    instructions = components = 0
    mnemonics = set()
    for name, row in inventory.items():
        path = directory / name
        checked_hash(path.relative_to(ROOT), row["sha256"])
        if row["instructions"] != compiler.instruction_rows(path.read_text()):
            raise ValueError(f"stale instruction lines or components: {path.relative_to(ROOT)}")
        instructions += len(row["instructions"])
        for instruction in row["instructions"]:
            components += len(instruction["components"])
            for component in instruction["components"]:
                mnemonic = component.split()[0]
                if not re.fullmatch(r"[a-z][a-z0-9_]*", mnemonic):
                    raise ValueError(f"label/directive classified as instruction: {name}: {component}")
                mnemonics.add(mnemonic)
    stage_table = (ROOT / "tests/gfx1250/full-parity/stage-support.md").read_text()
    tests = sorted(set(re.findall(r"`([a-z0-9_]+\.rs)`", stage_table)))
    for name in tests:
        if not (ROOT / "crates/volta_pipeline/tests" / name).is_file():
            raise ValueError(f"missing gfx1250 stage-table test: {name}")
    return {"source_inventory": {"modules": len(inventory), "instructions": instructions,
                                 "components": components, "mnemonic_spellings": len(mnemonics)},
            "checked_source_hashes": len(inventory), "checked_stage_table_tests": len(tests),
            "scope": "original ten-file source inventory; newer fixtures and per-form execution remain separately scoped"}


def main():
    print(json.dumps({"gfx942": cdna("gfx942"), "gfx950": cdna("gfx950"),
                      "gfx1250": gfx1250()}, indent=2))


if __name__ == "__main__":
    main()
