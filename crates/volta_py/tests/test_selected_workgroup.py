"""Native results describe one selected group and retain absolute written indices."""
from pathlib import Path

import pytest
import volta

ROOT = Path(__file__).resolve().parents[3]
SOURCE = (ROOT / "crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s").read_text()
SPEC = "dim N; array x[N]; array out[N]; out[i]=x[i];"


def config(target="gfx950", workgroup_id=(1, 0, 0), grid=(3, 1, 1)):
    cfg = volta.Config(block=(64, 1, 1), grid=grid, backend="amdgpu", target=target,
                       workgroup_id=workgroup_id)
    for name, base, kind in [("x", 65536, volta.ArrayKind.Input),
                             ("out", 131072, volta.ArrayKind.Output)]:
        cfg.add_array(volta.ArrayDef(name, base, 4, 192, kind))
        cfg.add_param(volta.Param.array_ptr(name))
    cfg.add_param(volta.Param.int(192))
    return cfg


@pytest.mark.parametrize("target", ["gfx942", "gfx950", "gfx1250"])
def test_selected_copy_keeps_absolute_indices_and_graph_scope(target):
    source = ((ROOT / "tests/gfx1250/fixtures/native-copy-add.s").read_text()
              if target == "gfx1250" else SOURCE.replace("--gfx950", f"--{target}"))
    cfg = config(target)
    assert cfg.workgroup_id == (1, 0, 0)
    result = volta.analyze(source, cfg, kernel="copy")
    assert result.race_verified
    assert result.workgroup_id == (1, 0, 0)
    assert any("only the selected AMD workgroup" in item for item in result.assumptions)
    assert dict(result.outputs)["out"] == [(i, f"x[{i}]") for i in range(64, 128)]
    with pytest.raises(volta.VoltaError, match="unwritten"):
        volta.verify(source, SPEC, cfg, kernel="copy", dims={"N": 192}, sample=1)


def test_default_and_verify_results_retain_the_selected_group_scope():
    cfg = volta.Config(block=(64, 1, 1), backend="amdgpu", target="gfx950")
    assert cfg.workgroup_id == (0, 0, 0)
    for name, base, kind in [("x", 65536, volta.ArrayKind.Input),
                             ("out", 131072, volta.ArrayKind.Output)]:
        cfg.add_array(volta.ArrayDef(name, base, 4, 64, kind))
        cfg.add_param(volta.Param.array_ptr(name))
    cfg.add_param(volta.Param.int(64))
    result = volta.verify(SOURCE, SPEC, cfg, kernel="copy", dims={"N": 64})
    assert result.equivalent and result.race_verified
    assert result.workgroup_id == (0, 0, 0)
    assert any("inter-workgroup conflicts" in item for item in result.assumptions)


def test_nonzero_selected_group_can_verify_a_matching_complete_output_contract():
    source = (ROOT / "crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-ids-3d.s").read_text()
    cfg = volta.Config(block=(4, 3, 2), grid=(2, 3, 4), backend="amdgpu",
                       target="gfx950", workgroup_id=(1, 2, 3))
    cfg.add_array(volta.ArrayDef("out", 65536, 4, 24, volta.ArrayKind.Output))
    cfg.add_param(volta.Param.array_ptr("out"))
    spec = "dim X; dim Y; dim Z; array out[Z,Y,X]; out[z,y,x]=x+10*y+100*z+321000;"
    result = volta.verify(source, spec, cfg, kernel="ids_3d", dims={"X": 4, "Y": 3, "Z": 2})
    assert result.equivalent and result.race_verified
    assert result.elements_checked == result.elements_total == 24
    assert result.workgroup_id == (1, 2, 3)


@pytest.mark.parametrize("selection", [(3, 0, 0), (0, 1, 0), (0, 0, 1)])
def test_outside_grid_selection_is_rejected(selection):
    with pytest.raises(volta.VoltaError, match="workgroup_id"):
        volta.analyze(SOURCE, config(workgroup_id=selection), kernel="copy")


def test_ptx_cannot_ignore_a_native_selection():
    cfg = volta.Config(block=(1, 1, 1), grid=(2, 1, 1), workgroup_id=(1, 0, 0))
    with pytest.raises(volta.VoltaError, match="workgroup_id"):
        volta.analyze(".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }", cfg)
