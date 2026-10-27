"""Public Python API integration against untouched native compiler output."""
from pathlib import Path

import pytest
import volta


SOURCE = (Path(__file__).resolve().parents[2] / "volta_amdgpu_analysis" / "src"
          / "frontend" / "fixtures" / "clang22-copy-add.s").read_text()
SPEC = "dim N; array x[N]; array out[N]; out[i] = x[i];"


def config(block, n, **kwargs):
    result = volta.Config(block=(block, 1, 1), backend="amdgpu", target="gfx950", **kwargs)
    result.add_array(volta.ArrayDef("x", 0x10000, 4, n, volta.ArrayKind.Input))
    result.add_array(volta.ArrayDef("out", 0x20000, 4, n, volta.ArrayKind.Output))
    result.add_param(volta.Param.array_ptr("x"))
    result.add_param(volta.Param.array_ptr("out"))
    result.add_param(volta.Param.int(n))
    return result


@pytest.mark.parametrize("block,n", [(1, 1), (63, 63), (64, 64), (65, 65), (128, 65), (256, 256)])
def test_native_copy_analysis_and_math_spec(block, n):
    cfg = config(block, n)
    assert cfg.backend == "amdgpu" and cfg.target == "gfx950"
    volta.parse(SOURCE, backend="amdgpu", target="gfx950")
    analysis = volta.analyze(SOURCE, cfg, kernel="copy")
    assert analysis.race_verified and not analysis.unresolved
    assert [index for index, _ in dict(analysis.outputs)["out"]] == list(range(n))
    check = volta.verify(SOURCE, SPEC, cfg, kernel="copy", dims={"N": n})
    assert check.equivalent and check.race_verified
    assert check.elements_checked == n and not check.mismatches


def test_missing_wait_has_typed_python_exception():
    bad = SOURCE.replace("s_waitcnt vmcnt(0)", "s_nop 0")
    with pytest.raises(volta.DataRaceError, match="ReadBeforeReady"):
        volta.analyze(bad, config(65, 65), kernel="copy")


def test_backend_and_target_are_validated():
    with pytest.raises(ValueError, match="requires gfx950"):
        volta.Config(block=(64, 1, 1), backend="amdgpu", target="gfx942")
    with pytest.raises(volta.VoltaError):
        volta.parse(SOURCE.replace("--gfx950", "--gfx942"), backend="amdgpu", target="gfx950")


def test_instruction_budget_is_inconclusive():
    with pytest.warns(RuntimeWarning, match="UNKNOWN"):
        with pytest.raises(volta.VoltaError, match="[Bb]udget|instruction"):
            volta.analyze(SOURCE, config(64, 64, max_instructions=1), kernel="copy")
