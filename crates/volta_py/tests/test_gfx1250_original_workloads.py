"""Original registered shapes/dtypes through the existing Python API; no sampling."""

import json
import os
from pathlib import Path

import pytest
import volta

ROOT = Path(__file__).resolve().parents[3] / "tests/gfx1250/full"
MANIFEST = json.loads((ROOT / "cases.json").read_text())
CASES = MANIFEST["cases"]
assert CASES, "an empty native registry is not acceptance"
assert len(CASES) + len(MANIFEST["missing_baseline_ids"]) == 32
if "VOLTA_GFX1250_ORIGINAL_FULL" in os.environ:
    assert not MANIFEST["missing_baseline_ids"], "full32 gate requires all original registrations"
else:
    CASES = [case for case in CASES if case["baseline_id"] <= "W18"]
    assert len(CASES) == 18, "fast gate requires every first-family original case"
KINDS = {
    "in": volta.ArrayKind.Input,
    "out": volta.ArrayKind.Output,
    "inout": volta.ArrayKind.InputOutput,
    "index": volta.ArrayKind.IndexInput,
}


def configured(case):
    launch = json.loads((ROOT / case["launch_config"]).read_text())
    supported = {
        "description",
        "kernel",
        "block",
        "grid",
        "dynamic_shared_bytes",
        "max_instructions",
        "arrays",
        "params",
        "globals",
        "shared_allocations",
    }
    assert set(launch) <= supported, "an unhandled launch field must not be silently ignored"
    config = volta.Config(
        block=tuple(launch["block"]),
        grid=tuple(launch["grid"]),
        dynamic_shared_bytes=launch.get("dynamic_shared_bytes", 0),
        max_instructions=launch.get("max_instructions", 2_000_000_000),
        backend="amdgpu",
        target="gfx1250",
    )
    for array in launch["arrays"]:
        config.add_array(
            volta.ArrayDef(
                array["name"],
                array["base"],
                array["elem_width"],
                array["len"],
                KINDS[array["kind"]],
            )
        )
    constructors = {
        "ptr": volta.Param.array_ptr,
        "int": volta.Param.int,
        "float": volta.Param.float,
        "sym": volta.Param.sym_float,
        "bytes": volta.Param.bytes,
    }
    for parameter in launch["params"]:
        assert len(parameter) == 1 and set(parameter) <= constructors.keys()
        kind, value = next(iter(parameter.items()))
        config.add_param(constructors[kind](value))
    for name, value in launch.get("globals", {}).items():
        config.set_global(name, value)
    for region in launch.get("shared_allocations", []):
        config.add_shared_allocation(region["name"], region["offset"], region["size"])
    return config


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["kernel"])
def test_registered_original_case_analyzes_every_index_and_matches_full_spec(case):
    source = (ROOT / case["assembly"]).read_text()
    config = configured(case)
    volta.parse(source, backend="amdgpu", target="gfx1250")
    result = volta.analyze(source, config, kernel=case["kernel"])
    assert result.race_verified and not result.unresolved
    expected = {}
    for projection in case["output_projection"]:
        indices = expected.setdefault(projection["native_array"], set())
        new = set(
            range(projection["native_start"], projection["native_start"] + projection["length"])
        )
        assert not indices.intersection(new)
        indices.update(new)
    assert {name: [index for index, _ in values] for name, values in result.outputs} == {
        name: sorted(values) for name, values in expected.items()
    }
    check = volta.verify(
        source,
        (ROOT / case["spec"]).read_text(),
        config,
        kernel=case["kernel"],
        dims=case["dimensions"],
        sample=0,
        verify_numeric=True,
    )
    assert check.race_verified and check.equivalent
    assert check.elements_checked == case["expected_outputs"]
    assert not check.mismatches
