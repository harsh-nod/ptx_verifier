#!/usr/bin/env python3
"""Validate original workload registrations; metadata consistency is not proof.

Run --require-all for the final32-case registration gate. Ordinary invocation
reports missing registrations explicitly and never claims execution acceptance.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
INVENTORY = Path(__file__).with_name("gaps.json")
REGISTRY = ROOT / "tests/gfx1250/full/cases.json"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def output_indices(row: dict) -> dict[str, set[int]]:
    """Expand the exact original selected-CTA footprint, including sparse views."""
    footprint = row["original"]["output_footprint"]
    rule = footprint["rule"]
    if rule == "all declared output/inout elements":
        return {name: set(range(count)) for name, count in footprint["arrays"].items()}
    if rule == "row * 4096 + column":
        indices = {
            row * 4096 + col
            for row in range(footprint["rows"])
            for col in range(footprint["columns"])
        }
    elif rule == "channel * 2916 + spatial":
        indices = {
            channel * 2916 + spatial
            for channel in range(footprint["channels"])
            for spatial in range(footprint["spatial"])
        }
    elif rule == "row * 1024 + feature":
        indices = {
            row * 1024 + feature
            for row in range(footprint["rows"])
            for feature in range(footprint["features"])
        }
    else:
        raise ValueError(f"unrecognized original footprint: {rule}")
    return {name: set(indices) for name in footprint["arrays"]}


def validate_inventory(data: dict, root: Path = ROOT) -> dict[str, dict]:
    require(data.get("schema_version") == 1, "unsupported inventory schema")
    rows = data.get("workloads", [])
    require(len(rows) == 32, "all 32 original workload rows are required")
    require(
        {row["id"] for row in rows} == {f"W{i:02}" for i in range(1, 33)},
        "duplicate/missing original IDs",
    )
    require(len({row["baseline_path"] for row in rows}) == 32, "duplicate original artifact")
    require(len({row["family"] for row in rows}) == 20, "original families omitted")
    total = 0
    for row in rows:
        original = row["original"]
        require(
            digest(root / row["baseline_path"]) == row["baseline_sha256"],
            f"{row['id']}: original source changed",
        )
        require(
            digest(root / row["baseline_config_path"]) == row["baseline_config_sha256"],
            f"{row['id']}: original config changed",
        )
        require(
            json.loads((root / row["baseline_config_path"]).read_text())
            == original["launch_metadata"],
            f"{row['id']}: metadata changed",
        )
        arrays = {a["name"]: a for a in original["arrays"]}
        require(len(arrays) == len(original["arrays"]), f"{row['id']}: duplicate original arrays")
        indices = output_indices(row)
        require(
            sum(map(len, indices.values())) == original["expected_outputs"],
            f"{row['id']}: original output footprint shrank",
        )
        for name, values in indices.items():
            require(
                arrays[name]["kind"] in {"out", "inout"}
                and values
                and max(values) < arrays[name]["length"],
                f"{row['id']}: invalid output index set",
            )
        require(
            original["reduction_rewrite_permitted"] is False,
            f"{row['id']}: reduced execution is not full parity",
        )
        total += original["expected_outputs"]
    require(total == 395394, "original 395394-output scope changed")
    return {row["id"]: row for row in rows}


def expected_dimensions(row: dict) -> dict | None:
    original, family = row["original"], row["family"]
    if family in {"ReLUKernel", "SigmoidKernel", "SiLUKernel", "SwiGLUKernel"}:
        return {"N": original["expected_outputs"]}
    if family == "RoPEKernel":
        return {"H": 2, "D": 64}
    if family == "RMSNormKernel":
        return {"R": 1, "N": 4096}
    if family == "SoftmaxKernel":
        return {"R": 16, "C": 256}
    if family == "MatrixVectorMultiplicationKernel":
        return {"M": original["expected_outputs"], "K": 4096}
    if family == "ReductionSumKernel":
        return {"R": 1, "TILE": original["arrays"][0]["length"]}
    if row["id"] in {"W27", "W28", "W29", "W30"}:
        return {"M": 4096, "N": 4096, "K": 4096, "TILE": 256}
    if row["id"] in {"W31", "W32"}:
        return {"M": 4096, "N": 4096, "K": 4096, "WORDS": 128,
                "TILE": original["shape_and_layout"]["tile_N"]}
    # Later native source slices can use named output views in their specs. Their
    # shape/output projections remain mandatory; numerical equivalence proves
    # semantics rather than treating a dimension-label convention as evidence.
    return None


def launch_config(case: dict) -> dict:
    """Translate existing case fields to the existing strict public LaunchFile."""
    params = []
    for parameter in case["params"]:
        if isinstance(parameter, dict):
            require(
                len(parameter) == 1
                and next(iter(parameter)) in {"ptr", "int", "float", "sym", "bytes"},
                "unknown parameter object",
            )
            params.append(parameter)
        else:
            kind, value = parameter.split(":", 1)
            require(kind in {"ptr", "int", "float", "sym"}, "unknown parameter kind")
            params.append(
                {kind: int(value) if kind == "int" else float(value) if kind == "float" else value}
            )
    config = {
        "kernel": case["kernel"],
        "block": case["block"],
        "grid": case["grid"],
        "dynamic_shared_bytes": case.get("dynamic_shared_bytes", case.get("dynamic_shared", 0)),
        "arrays": [
            {
                "name": a["name"],
                "base": a["base_address"],
                "elem_width": a["element_size"],
                "len": a["length"],
                "kind": a["kind"],
            }
            for a in case["arrays"]
        ],
        "params": params,
    }
    if "max_instructions" in case:
        config["max_instructions"] = case["max_instructions"]
    if "shared_allocations" in case:
        config["shared_allocations"] = case["shared_allocations"]
    if "global_values" in case:
        config["globals"] = dict(case["global_values"])
    return config


def validate_registry(
    data: dict, rows: dict[str, dict], directory: Path, *, require_all: bool = False
) -> list[str]:
    require(
        data.get("schema_version") == 1 and data.get("target") == "gfx1250",
        "registry must select gfx1250 schema1",
    )
    require(
        set(data.get("required_baseline_ids", [])) == set(rows), "required original scope changed"
    )
    cases = data.get("cases", [])
    require(cases, "empty native registry cannot pass")
    registered = set()
    for case in cases:
        identifier = case["baseline_id"]
        require(
            identifier in rows and identifier not in registered,
            "unknown/duplicate original registration",
        )
        registered.add(identifier)
        row, original = rows[identifier], rows[identifier]["original"]
        require(
            case["baseline_path"] == row["baseline_path"]
            and case["baseline_sha256"] == row["baseline_sha256"],
            f"{identifier}: wrong original source",
        )
        require(
            case["family"] == row["family"]
            and case["original_shape"] == original["shape_and_layout"],
            f"{identifier}: original problem shape changed",
        )
        require(
            case.get("required") is True and case.get("reduced_case") is False,
            f"{identifier}: required full case was reduced/disabled",
        )
        require(
            case["expected_outputs"] == original["expected_outputs"],
            f"{identifier}: output count changed",
        )
        matrix = identifier in {"W27", "W28", "W29", "W30", "W31", "W32"}
        native_block = [1024 if identifier in {"W27", "W28", "W29", "W30"} else 256, 1, 1]
        if matrix:
            require(case.get("launch_mapping") == {
                "kind": "gfx1250_wave32_wmma_partition",
                "baseline_block": original["block"], "native_block": native_block,
                "selected_workgroup": [0, 0, 0],
            }, f"{identifier}: missing reviewed WMMA launch mapping")
        require(
            case["block"] == (native_block if matrix else original["block"])
            and case["grid"] == original["grid"],
            f"{identifier}: native launch requires an explicitly reviewed mapping, not an implicit override",
        )
        dimensions = expected_dimensions(row)
        require(
            dimensions is None or case["dimensions"] == dimensions,
            f"{identifier}: original spec dimensions changed",
        )
        native = {a["name"]: a for a in case["arrays"]}
        require(len(native) == len(case["arrays"]), f"{identifier}: duplicate native array")
        original_names = {a["name"] for a in original["arrays"]}
        views = set()
        if matrix:
            rows_count = original["shape_and_layout"]["tile_M"]
            columns = original["shape_and_layout"]["tile_N"]
            views = {f"out{i:03}" for i in range(rows_count)}
            require(case.get("array_view_mapping") == {
                "baseline_array": "c", "native_arrays": sorted(views),
                "row_pitch_elements": 4096, "rows": rows_count, "columns": columns,
            }, f"{identifier}: missing original sparse row-view mapping")
        require(set(native) == ((original_names - {"c"}) | views if matrix else original_names),
                f"{identifier}: missing or extra native arrays")
        for array in original["arrays"]:
            dtype = "e4m3" if array["dtype"] == "ocp_e4m3_fp8" else array["dtype"]
            if matrix and array["name"] == "c":
                for i, name in enumerate(sorted(views)):
                    actual = native[name]
                    require(actual["element_size"] == array["element_size"]
                            and actual["dtype"] == dtype
                            and actual["length"] == columns
                            and actual["kind"] == array["kind"]
                            and actual["base_address"] == array["base_address"] + i * 4096 * array["element_size"],
                            f"{identifier}: {name} sparse original output storage changed")
                continue
            actual = native[array["name"]]
            for field in ("element_size", "length", "kind", "base_address"):
                require(actual[field] == array[field],
                        f"{identifier}: {array['name']} {field} changed")
            require(actual.get("dtype") == dtype,
                    f"{identifier}: {array['name']} storage dtype changed")
        params = ["ptr:out000" if matrix and p == "ptr:c" else p for p in original["params"]]
        require(case["params"] == params,
                f"{identifier}: native ABI requires an explicit reviewed mapping")
        if matrix:
            require(case.get("parameter_mapping") == {"ptr:c": "ptr:out000"},
                    f"{identifier}: missing same-address output pointer mapping")
        expected, covered, native_covered = output_indices(row), {}, {}
        for projection in case["output_projection"]:
            name, target = projection["baseline_array"], projection["native_array"]
            count = projection["length"]
            require(type(count) is int and count > 0, f"{identifier}: empty projection")
            start, native_start = projection["baseline_start"], projection["native_start"]
            require(
                type(start) is int
                and start >= 0
                and type(native_start) is int
                and native_start >= 0,
                f"{identifier}: invalid projection start",
            )
            require(
                target in native and native[target]["kind"] in {"out", "inout"},
                f"{identifier}: projection is not an output",
            )
            require(
                native_start + count <= native[target]["length"],
                f"{identifier}: native projection exceeds storage",
            )
            baseline_array = next(a for a in original["arrays"] if a["name"] == name)
            width = baseline_array["element_size"]
            require(
                native[target]["element_size"] == width,
                f"{identifier}: projected dtype width changed",
            )
            require(
                native[target]["base_address"] + native_start * width
                == baseline_array["base_address"] + start * width,
                f"{identifier}: projected native bytes do not match original coordinates",
            )
            native_values = set(range(native_start, native_start + count))
            require(
                not native_covered.setdefault(target, set()).intersection(native_values),
                f"{identifier}: duplicate native output projection",
            )
            native_covered[target].update(native_values)
            values = set(range(start, start + count))
            require(
                not covered.setdefault(name, set()).intersection(values),
                f"{identifier}: duplicate output projection",
            )
            covered[name].update(values)
        require(
            covered == expected, f"{identifier}: complete sparse original output projection differs"
        )
        for kind in ("source", "assembly", "spec", "launch_config"):
            path = directory / case[kind]
            require(
                path.is_file() and digest(path) == case[kind + "_sha256"],
                f"{identifier}: changed/missing {kind}",
            )
        require(
            json.loads((directory / case["launch_config"]).read_text())
            == (launch_config(case) | {"description": case["mapping"]}),
            f"{identifier}: public launch JSON differs from registration",
        )
    pending = sorted(set(rows) - registered)
    require(data.get("pending_baseline_ids") == pending, "pending original cases were hidden")
    require(
        data.get("registered_original_outputs")
        == sum(rows[i]["original"]["expected_outputs"] for i in registered),
        "registered output count changed",
    )
    require(
        not require_all or not pending,
        "full original 32 registration is incomplete: " + ",".join(pending),
    )
    return pending


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, default=INVENTORY)
    parser.add_argument("--registry", type=Path, default=REGISTRY)
    parser.add_argument("--require-all", action="store_true")
    args = parser.parse_args()
    try:
        rows = validate_inventory(json.loads(args.inventory.read_text()))
        pending = validate_registry(
            json.loads(args.registry.read_text()),
            rows,
            args.registry.parent,
            require_all=args.require_all,
        )
        print(
            f"Metadata consistent: original 32 cases /395394 outputs; registered={32 - len(pending)}, missing={len(pending)}. No execution/proof claim."
        )
        return 0
    except (KeyError, TypeError, ValueError, OSError) as error:
        print(f"Original-shape registration rejected: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
