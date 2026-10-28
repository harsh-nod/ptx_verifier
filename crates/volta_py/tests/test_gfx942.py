"""Real CDNA3 compiler output through the explicit Python target API."""
import json
from pathlib import Path

import pytest
import volta

ROOT = Path(__file__).resolve().parents[3]
FIXTURES = ROOT / "tests/gfx942"
CASES = json.loads((FIXTURES / "cases.json").read_text())["cases"]
KINDS = {"in": volta.ArrayKind.Input, "out": volta.ArrayKind.Output,
         "inout": volta.ArrayKind.InputOutput, "index": volta.ArrayKind.IndexInput}


def configured(case):
    config = volta.Config(block=tuple(case["block"]), grid=tuple(case["grid"]),
                          backend="amdgpu", target="gfx942")
    for array in case["arrays"]:
        config.add_array(volta.ArrayDef(array["name"], array["base_address"],
                                        array["element_size"], array["length"], KINDS[array["kind"]]))
    for parameter in case["params"]:
        kind, value = parameter.split(":", 1)
        config.add_param(volta.Param.array_ptr(value) if kind == "ptr" else volta.Param.int(int(value)))
    return config


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["kernel"])
def test_genuine_gfx942_compiler_outputs_and_full_math_spec(case):
    source = (FIXTURES / case["assembly"]).read_text()
    config = configured(case)
    assert config.backend == "amdgpu" and config.target == "gfx942"
    volta.parse(source, backend="amdgpu", target="gfx942")
    result = volta.analyze(source, config, kernel=case["kernel"])
    assert result.race_verified and not result.unresolved
    expected = {a["name"]: list(range(a["length"])) for a in case["arrays"]
                if a["kind"] in {"out", "inout"}}
    assert {name: [i for i, _ in values] for name, values in result.outputs} == expected
    check = volta.verify(source, (FIXTURES / case["spec"]).read_text(), config,
                         kernel=case["kernel"], dims=case["dimensions"])
    assert check.race_verified and check.equivalent
    assert check.elements_checked == case["expected_outputs"] and not check.mismatches


def test_explicit_target_selection_rejects_conflicting_source():
    source = (FIXTURES / "fixtures/native-copy-add.s").read_text()
    with pytest.raises(volta.VoltaError, match="conflicts with source target gfx942"):
        volta.parse(source, backend="amdgpu", target="gfx950")
    with pytest.raises(volta.VoltaError, match="conflicts with source target gfx950"):
        volta.parse(source.replace("gfx942", "gfx950"), backend="amdgpu", target="gfx942")


def test_gfx942_missing_wait_keeps_typed_safety_failure():
    case = CASES[0]
    source = (FIXTURES / case["assembly"]).read_text().replace("s_waitcnt vmcnt(0)", "s_nop 0")
    with pytest.raises(volta.DataRaceError, match="ReadBeforeReady"):
        volta.analyze(source, configured(case), kernel="copy")


def test_gfx942_lds_capacity_and_fp8_format_are_not_gfx950_aliases():
    source = '.amdgcn_target "amdgcn-amd-amdhsa--gfx942"\n.text\n.type k,@function\nk:\ns_endpgm\n.amdhsa_kernel k\n.amdhsa_group_segment_fixed_size 65537\n.end_amdhsa_kernel\n'
    with pytest.raises(volta.VoltaError, match="gfx942 capacity"):
        volta.analyze(source, volta.Config(block=(1, 1, 1), backend="amdgpu", target="gfx942"))
    source = source.replace("s_endpgm", "v_cvt_f32_fp8_e32 v0, v1\ns_endpgm")
    with pytest.raises(volta.VoltaError, match="FNUZ"):
        volta.parse(source, backend="amdgpu", target="gfx942")
