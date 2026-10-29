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
import re
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
    require(
        len({row["baseline_path"] for row in rows}) == 32, "duplicate original artifact"
    )
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
        require(
            len(arrays) == len(original["arrays"]),
            f"{row['id']}: duplicate original arrays",
        )
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
    advanced = {
        "W21": {"R": 32, "T": 1024, "D": 64},
        "W22": {"Q": 128, "T": 1024, "D": 64},
        "W23": {"Q": 128, "T": 1024, "D": 64},
        "W24": {"Q": 128, "T": 128, "D": 64, "HALF": 64, "ONE": 1, "TWO": 2},
        "W25": {"T": 256, "PITCH": 512, "M": 64, "N": 128},
        "W26": {"R": 32, "N": 128, "S": 32, "T": 128, "XPITCH": 1024, "CPITCH": 64},
    }
    if row["id"] in advanced:
        return advanced[row["id"]]
    if row["id"] in {"W19", "W20"}:
        return {
            "C": 64,
            "H": 56,
            "W": 56,
            "O": 128,
            "R": 3,
            "S": 3,
            "SPATIAL": original["shape_and_layout"]["selected_spatial_positions"],
        }
    if row["id"] in {"W27", "W28", "W29", "W30"}:
        return {"M": 4096, "N": 4096, "K": 4096, "TILE": 256}
    if row["id"] in {"W31", "W32"}:
        return {
            "M": 4096,
            "N": 4096,
            "K": 4096,
            "WORDS": 128,
            "TILE": original["shape_and_layout"]["tile_N"],
        }
    # Later native source slices can use named output views in their specs. Their
    # shape/output projections remain mandatory; numerical equivalence proves
    # semantics rather than treating a dimension-label convention as evidence.
    return None


def row_view_mappings(row: dict) -> list[dict]:
    identifier, shape = row["id"], row["original"]["shape_and_layout"]
    if identifier == "W26":
        return [
            {
                "baseline_array": name,
                "native_arrays": [f"{prefix}{i:03}" for i in range(32)],
                "row_pitch_elements": 1024,
                "rows": 32,
                "columns": 128,
            }
            for name, prefix in (("out", "out"), ("out_x", "outx"))
        ]
    if identifier in {"W19", "W20"}:
        name, rows, columns, pitch = (
            "out",
            128,
            shape["selected_spatial_positions"],
            2916,
        )
    elif identifier in {"W27", "W28", "W29", "W30", "W31", "W32"}:
        name, rows, columns, pitch = "c", shape["tile_M"], shape["tile_N"], 4096
    else:
        return []
    return [
        {
            "baseline_array": name,
            "native_arrays": [f"out{i:03}" for i in range(rows)],
            "row_pitch_elements": pitch,
            "rows": rows,
            "columns": columns,
        }
    ]


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
                {
                    kind: int(value)
                    if kind == "int"
                    else float(value)
                    if kind == "float"
                    else value
                }
            )
    config = {
        "kernel": case["kernel"],
        "block": case["block"],
        "grid": case["grid"],
        "dynamic_shared_bytes": case.get(
            "dynamic_shared_bytes", case.get("dynamic_shared", 0)
        ),
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
        set(data.get("required_baseline_ids", [])) == set(rows),
        "required original scope changed",
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
        require(
            case.get("workgroup") == original["selected_workgroup"],
            f"{identifier}: selected original workgroup changed",
        )
        matrix = identifier in {"W27", "W28", "W29", "W30", "W31", "W32"}
        native_block = [
            1024 if identifier in {"W27", "W28", "W29", "W30"} else 256,
            1,
            1,
        ]
        if matrix:
            require(
                case.get("launch_mapping")
                == {
                    "kind": "gfx1250_wave32_wmma_partition",
                    "baseline_block": original["block"],
                    "native_block": native_block,
                    "selected_workgroup": [0, 0, 0],
                },
                f"{identifier}: missing reviewed WMMA launch mapping",
            )
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
        if identifier == "W23":
            require(
                case.get("physical_grid_mapping")
                == {
                    "symbolic_selected_workgroup": [0, 0, 0],
                    "symbolic_query_rows": 128,
                    "physical_grid": [16, 1, 1],
                    "physical_query_rows": 1024,
                    "logical_sequence_length": 1024,
                    "odd_x_workgroups": "return without writes",
                },
                f"{identifier}: full physical FlashAttention grid mapping differs",
            )
        native = {a["name"]: a for a in case["arrays"]}
        require(
            len(native) == len(case["arrays"]), f"{identifier}: duplicate native array"
        )
        original_names = {a["name"] for a in original["arrays"]}
        convolution = identifier in {"W19", "W20"}
        if convolution:
            fixed = 24576 if identifier == "W19" else 16384
            require(
                case.get("shared_memory_mapping")
                == {
                    "original_dynamic_budget": 232448,
                    "native_dynamic": 0,
                    "native_fixed": fixed,
                    "kind": "two_slot_K32_WMMA_staging",
                }
                and case.get("dynamic_shared_bytes") == 0,
                f"{identifier}: incorrect native fixed-LDS staging mapping",
            )
            assembly = (directory / case["assembly"]).read_text()
            require(
                re.search(
                    r"\.amdhsa_kernel\s+"
                    + re.escape(case["kernel"])
                    + r"\s+\.amdhsa_group_segment_fixed_size\s+"
                    + str(fixed)
                    + r"\b",
                    assembly,
                )
                is not None,
                f"{identifier}: native fixed-LDS descriptor differs",
            )
        plans = row_view_mappings(row)
        if plans:
            require(
                (
                    case.get("array_view_mapping") == plans[0]
                    if len(plans) == 1
                    else case.get("array_view_mappings") == plans
                ),
                f"{identifier}: missing original sparse row-view mapping",
            )
        views_by_original = {plan["baseline_array"]: plan for plan in plans}
        views = {name for plan in plans for name in plan["native_arrays"]}
        require(
            set(native) == ((original_names - views_by_original.keys()) | views),
            f"{identifier}: missing or extra native arrays",
        )
        for array in original["arrays"]:
            dtype = "e4m3" if array["dtype"] == "ocp_e4m3_fp8" else array["dtype"]
            if array["name"] in views_by_original:
                plan = views_by_original[array["name"]]
                for i, name in enumerate(plan["native_arrays"]):
                    actual = native[name]
                    require(
                        actual["element_size"] == array["element_size"]
                        and actual["dtype"] == dtype
                        and actual["length"] == plan["columns"]
                        and actual["kind"] == array["kind"]
                        and actual["base_address"]
                        == array["base_address"]
                        + i * plan["row_pitch_elements"] * array["element_size"],
                        f"{identifier}: {name} sparse original output storage changed",
                    )
                continue
            actual = native[array["name"]]
            for field in ("element_size", "length", "kind", "base_address"):
                require(
                    actual[field] == array[field],
                    f"{identifier}: {array['name']} {field} changed",
                )
            require(
                actual.get("dtype") == dtype,
                f"{identifier}: {array['name']} storage dtype changed",
            )
        pointer_mapping = {
            "ptr:" + name: "ptr:" + plan["native_arrays"][0]
            for name, plan in views_by_original.items()
        }
        params = [pointer_mapping.get(p, p) for p in original["params"]]
        require(
            case["params"] == params,
            f"{identifier}: native ABI requires an explicit reviewed mapping",
        )
        if plans:
            require(
                case.get("parameter_mapping") == pointer_mapping,
                f"{identifier}: missing same-address output pointer mapping",
            )
        expected, covered, native_covered = output_indices(row), {}, {}
        for projection in case["output_projection"]:
            name, target = projection["baseline_array"], projection["native_array"]
            count = projection["length"]
            require(type(count) is int and count > 0, f"{identifier}: empty projection")
            start, native_start = (
                projection["baseline_start"],
                projection["native_start"],
            )
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
                not native_covered.setdefault(target, set()).intersection(
                    native_values
                ),
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
            covered == expected,
            f"{identifier}: complete sparse original output projection differs",
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
    require(
        data.get("pending_baseline_ids") == pending,
        "pending original cases were hidden",
    )
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
