"""CPU-only public API validation against unchanged gfx1250 compiler output."""
import json
from pathlib import Path

import pytest
import volta

FIXTURES = Path(__file__).resolve().parents[3] / "tests/gfx1250"
CASES = json.loads((FIXTURES / "cases.json").read_text())["cases"]
KINDS = {"in": volta.ArrayKind.Input, "out": volta.ArrayKind.Output,
         "inout": volta.ArrayKind.InputOutput, "index": volta.ArrayKind.IndexInput}


def configured(case, **overrides):
    config = volta.Config(block=tuple(case["block"]), grid=tuple(case["grid"]),
                          dynamic_shared_bytes=case.get("dynamic_shared", 0),
                          backend="amdgpu", target="gfx1250", **overrides)
    for array in case["arrays"]:
        config.add_array(volta.ArrayDef(array["name"], array["base_address"],
                                        array["element_size"], array["length"], KINDS[array["kind"]]))
    for parameter in case["params"]:
        if isinstance(parameter, dict):
            assert set(parameter) == {"bytes"}
            config.add_param(volta.Param.bytes(parameter["bytes"]))
        else:
            kind, value = parameter.split(":", 1)
            config.add_param(volta.Param.array_ptr(value) if kind == "ptr"
                             else volta.Param.int(int(value)))
    for name, value in case.get("global_values", []):
        config.set_global(name, value)
    return config


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["kernel"])
def test_native_gfx1250_corpus_has_complete_safety_and_math_results(case):
    source = (FIXTURES / case["assembly"]).read_text()
    config = configured(case)
    assert config.backend == "amdgpu" and config.target == "gfx1250"
    volta.parse(source, backend="amdgpu", target="gfx1250")
    result = volta.analyze(source, config, kernel=case["kernel"])
    assert result.race_verified and not result.unresolved
    outputs = {a["name"]: list(range(a["length"])) for a in case["arrays"]
               if a["kind"] in {"out", "inout"}}
    assert {name: [i for i, _ in values] for name, values in result.outputs} == outputs
    check = volta.verify(source, (FIXTURES / case["spec"]).read_text(), config,
                         kernel=case["kernel"], dims=case["dimensions"], verify_numeric=True)
    assert check.race_verified and check.equivalent
    assert check.elements_checked == case["expected_outputs"] and not check.mismatches


def test_gfx1250_requires_its_actual_source_target_and_rejects_neighbor_aliases():
    source = (FIXTURES / "fixtures/native-copy-add.s").read_text()
    for target in ["gfx942", "gfx950"]:
        with pytest.raises(volta.VoltaError, match="conflicts with source target gfx1250"):
            volta.parse(source, backend="amdgpu", target=target)
    for target in ["gfx1251", "gfx1250-strict"]:
        with pytest.raises(ValueError, match="unsupported AMD target"):
            volta.Config(block=(32, 1, 1), backend="amdgpu", target=target)
    assert volta.Config(block=(1, 1, 1), backend="amdgpu").target == "gfx950"


def test_gfx1250_missing_wait_has_typed_failure_and_budget_is_incomplete():
    case = next(case for case in CASES if case["kernel"] == "copy")
    source = (FIXTURES / case["assembly"]).read_text()
    assert "s_wait_loadcnt 0x0" in source
    bad = source.replace("s_wait_loadcnt 0x0", "s_nop 0")
    with pytest.raises(volta.DataRaceError, match="ReadBeforeReady"):
        volta.analyze(bad, configured(case), kernel="copy")
    with pytest.warns(RuntimeWarning, match="UNKNOWN"):
        with pytest.raises(volta.VoltaError, match="[Bb]udget|instruction"):
            volta.analyze(source, configured(case, max_instructions=1), kernel="copy")
