"""First certified same-instruction conflict is a separate opt-in failure."""
from pathlib import Path

import pytest
import volta

ROOT = Path(__file__).resolve().parents[3]
SPEC = "dim N; array x[N]; array out[N]; out[i]=x[i];"


def source(target):
    path = (ROOT / "tests/gfx1250/fixtures/native-copy-add.s" if target == "gfx1250"
            else ROOT / "crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s")
    return path.read_text()


def collision(target):
    text = source(target)
    if target == "gfx1250":
        op = "global_store_b32 v0, v1, s[2:3] scale_offset"
        replacement = "v_mov_b32 v0, 0\n\t" + op
    else:
        op = "global_store_dword v[0:1], v2, off"
        replacement = "v_mov_b32 v0, 0x20000\n\tv_mov_b32 v1, 0\n\t" + op
    assert op in text
    return text.replace(op, replacement, 1)


def config(target, early=False, scalar=False):
    cfg = volta.Config(block=(32, 1, 1), backend="amdgpu", target=target,
                       early_memory_conflicts=early, early_readiness=scalar)
    cfg.add_array(volta.ArrayDef("x", 65536, 4, 32, volta.ArrayKind.Input))
    cfg.add_array(volta.ArrayDef("out", 131072, 4, 32, volta.ArrayKind.Output))
    cfg.add_param(volta.Param.array_ptr("x"))
    cfg.add_param(volta.Param.array_ptr("out"))
    cfg.add_param(volta.Param.int(32))
    return cfg


@pytest.mark.parametrize("target", ["gfx950", "gfx1250"])
def test_safe_enabled_retains_full_outputs_and_complete_math(target):
    assert config(target).early_memory_conflicts is False
    enabled = config(target, True)
    assert enabled.early_memory_conflicts is True
    assert enabled.early_readiness is False
    ordinary = volta.analyze(source(target), config(target), kernel="copy")
    result = volta.analyze(source(target), enabled, kernel="copy")
    assert result.race_verified and result.outputs == ordinary.outputs
    assert len(dict(result.outputs)["out"]) == 32
    proof = volta.verify(source(target), SPEC, enabled, kernel="copy", dims={"N": 32})
    assert proof.equivalent and proof.race_verified
    assert proof.elements_checked == proof.elements_total == 32


@pytest.mark.parametrize("target", ["gfx950", "gfx1250"])
def test_bad_analyze_and_verify_raise_typed_conflict_without_outputs(target):
    for call in [lambda: volta.analyze(collision(target), config(target, True), kernel="copy"),
                 lambda: volta.verify(collision(target), SPEC, config(target, True),
                                      kernel="copy", dims={"N": 32})]:
        with pytest.raises(volta.EarlyMemoryConflictError, match="certified memory-conflict prefix") as caught:
            call()
        error = caught.value
        assert isinstance(error, volta.DataRaceError)
        assert error.kind == "WriteWrite" and error.space == "Global" and error.address == 131072
        assert error.instruction_event < error.issue_event < error.earlier_event < error.later_event
        assert error.wave == 0 and error.earlier_thread != error.later_thread
        assert error.instructions > 0 and error.prefix_amd_records > 0
        assert error.prefix_graph_events > error.later_event
        assert "complete outputs and equivalence unavailable" in str(error)
        assert not hasattr(error, "outputs")
    with pytest.raises(volta.DataRaceError) as caught:
        volta.analyze(collision(target), config(target), kernel="copy")
    assert not isinstance(caught.value, volta.EarlyMemoryConflictError)


def test_composed_modes_do_not_replace_scalar_readiness_exception():
    cfg = config("gfx1250", True, scalar=True)
    assert cfg.early_readiness and cfg.early_memory_conflicts
    bad = collision("gfx1250").replace("s_wait_kmcnt 0x0", "s_nop 0", 1)
    with pytest.raises(volta.EarlyReadinessError):
        volta.analyze(bad, cfg, kernel="copy")
    with pytest.raises(volta.EarlyMemoryConflictError):
        volta.analyze(collision("gfx1250"), config("gfx1250", True, scalar=True), kernel="copy")


@pytest.mark.parametrize("backend,target", [("ptx", None), ("amdgpu", "gfx942")])
def test_unsupported_backend_cannot_ignore_enabled_option(backend, target):
    with pytest.raises(ValueError, match="early_memory_conflicts"):
        volta.Config(block=(1, 1, 1), backend=backend, target=target, early_memory_conflicts=True)
