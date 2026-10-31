"""First certified scalar-readiness finding is an explicit opt-in exception."""
from pathlib import Path

import pytest
import volta

SOURCE = (Path(__file__).resolve().parents[3] / "tests/gfx1250/fixtures/native-copy-add.s").read_text()
SPEC = "dim N; array x[N]; array out[N]; out[i]=x[i];"


def config(early=False):
    cfg = volta.Config(block=(32, 1, 1), backend="amdgpu", target="gfx1250", early_readiness=early)
    cfg.add_array(volta.ArrayDef("x", 65536, 4, 32, volta.ArrayKind.Input))
    cfg.add_array(volta.ArrayDef("out", 131072, 4, 32, volta.ArrayKind.Output))
    cfg.add_param(volta.Param.array_ptr("x"))
    cfg.add_param(volta.Param.array_ptr("out"))
    cfg.add_param(volta.Param.int(32))
    return cfg


def test_safe_opt_in_keeps_all_outputs_and_complete_spec_verification():
    assert config().early_readiness is False
    enabled = config(True)
    assert enabled.early_readiness is True
    ordinary = volta.analyze(SOURCE, config(), kernel="copy")
    result = volta.analyze(SOURCE, enabled, kernel="copy")
    assert result.race_verified and result.outputs == ordinary.outputs
    assert len(dict(result.outputs)["out"]) == 32
    proof = volta.verify(SOURCE, SPEC, enabled, kernel="copy", dims={"N": 32})
    assert proof.equivalent and proof.race_verified
    assert proof.elements_checked == proof.elements_total == 32


def test_bad_opt_in_raises_a_specific_first_finding_without_outputs():
    assert "s_wait_kmcnt 0x0" in SOURCE
    bad = SOURCE.replace("s_wait_kmcnt 0x0", "s_nop 0", 1)
    for call in [lambda: volta.analyze(bad, config(True), kernel="copy"),
                 lambda: volta.verify(bad, SPEC, config(True), kernel="copy", dims={"N": 32})]:
        with pytest.raises(volta.EarlyReadinessError, match="certified scalar readiness prefix") as caught:
            call()
        assert isinstance(caught.value, volta.DataRaceError)
        assert caught.value.issue_event < caught.value.use_event
        assert caught.value.wave == 0 and caught.value.register_file == "Scalar"
        assert caught.value.instructions > 0 and caught.value.prefix_amd_records > 0
        assert "complete outputs and equivalence unavailable" in str(caught.value)
    with pytest.raises(volta.DataRaceError) as ordinary:
        volta.analyze(bad, config(), kernel="copy")
    assert not isinstance(ordinary.value, volta.EarlyReadinessError)


@pytest.mark.parametrize("backend,target", [("ptx", None), ("amdgpu", "gfx942"), ("amdgpu", "gfx950")])
def test_other_targets_cannot_silently_ignore_the_option(backend, target):
    with pytest.raises(ValueError, match="early_readiness"):
        volta.Config(block=(1, 1, 1), backend=backend, target=target, early_readiness=True)
