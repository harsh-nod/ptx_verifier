"""Native ABI and public configuration workflows use pinned compiler fixtures."""
import json
from pathlib import Path

import pytest
import volta


FIXTURES = (Path(__file__).resolve().parents[2] / "volta_amdgpu_analysis"
            / "src/frontend/fixtures")
CASES = json.loads((FIXTURES / "abi-cases.json").read_text())["cases"]
KINDS = {"in": volta.ArrayKind.Input, "out": volta.ArrayKind.Output,
         "inout": volta.ArrayKind.InputOutput, "index": volta.ArrayKind.IndexInput}


def configured(case, **overrides):
    config = volta.Config(block=tuple(case["block"]), grid=tuple(case["grid"]),
                          dynamic_shared_bytes=overrides.get("dynamic_shared", case.get("dynamic_shared", 0)),
                          backend="amdgpu", target="gfx950")
    for array in case["arrays"]:
        config.add_array(volta.ArrayDef(array["name"], array["base_address"],
                                        array["element_size"], array["length"], KINDS[array["kind"]]))
    for parameter in case["params"]:
        kind, value = parameter.split(":", 1)
        config.add_param(volta.Param.array_ptr(value) if kind == "ptr"
                         else volta.Param.int(int(value)))
    for name, value in case.get("global_values", []):
        config.set_global(name, value)
    return config


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["kernel"])
def test_native_abi_analysis_and_spec_cover_every_declared_output(case):
    source = (FIXTURES / case["assembly"]).read_text()
    config = configured(case)
    analysis = volta.analyze(source, config, kernel=case["kernel"])
    assert analysis.race_verified and not analysis.unresolved
    expected = {array["name"]: list(range(array["length"])) for array in case["arrays"]
                if array["kind"] in ("out", "inout")}
    assert {name: [index for index, _ in values] for name, values in analysis.outputs} == expected
    result = volta.verify(source, (FIXTURES / case["spec"]).read_text(), config,
                          kernel=case["kernel"], dims=case["dimensions"], verify_numeric=True)
    assert result.equivalent and result.race_verified
    assert result.elements_checked == sum(map(len, expected.values()))
    assert not result.mismatches


def test_unknown_module_binding_is_an_error_before_any_verified_result():
    case = next(case for case in CASES if case["kernel"] == "module_globals")
    config = configured(case)
    config.set_global("undeclared_object", 9)
    with pytest.raises(volta.VoltaError, match="undeclared_object|module.*global"):
        volta.analyze((FIXTURES / case["assembly"]).read_text(), config, kernel=case["kernel"])


def test_insufficient_dynamic_lds_preserves_incomplete_warning_and_error():
    case = next(case for case in CASES if case["kernel"] == "dynamic_lds")
    with pytest.warns(RuntimeWarning, match="UNKNOWN"):
        with pytest.raises(volta.VoltaError, match="out.of.bounds|bounds"):
            volta.analyze((FIXTURES / case["assembly"]).read_text(),
                          configured(case, dynamic_shared=4), kernel=case["kernel"])
