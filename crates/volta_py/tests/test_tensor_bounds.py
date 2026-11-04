"""Attempted tensor access bounds are certified separately from full execution."""
from pathlib import Path

import pytest
import volta

SOURCE = (Path(__file__).resolve().parents[3] / "tests/gfx1250/fixtures/native-tensor-roundtrip.s").read_text()
LOAD = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]"
SPEC = (Path(__file__).resolve().parents[3] / "tests/gfx1250/specs/tensor-roundtrip.spec").read_text()


def config():
    c = volta.Config(block=(64, 1, 1), backend="amdgpu", target="gfx1250")
    c.add_array(volta.ArrayDef("x", 65536, 4, 128, volta.ArrayKind.Input))
    c.add_array(volta.ArrayDef("out", 131072, 4, 128, volta.ArrayKind.Output))
    c.add_param(volta.Param.array_ptr("x"))
    c.add_param(volta.Param.array_ptr("out"))
    return c


def test_certified_bounds_has_typed_details_and_never_returns_outputs():
    bad = SOURCE.replace(LOAD, "s_mov_b32 s5, 256\n\t" + LOAD, 1)
    for operation in [lambda: volta.analyze(bad, config(), kernel="tensor_roundtrip"),
                      lambda: volta.verify(bad, SPEC, config(), kernel="tensor_roundtrip", dims={"N": 128})]:
        with pytest.raises(volta.TensorBoundsError) as caught:
            operation()
        error = caught.value
        assert isinstance(error, volta.VoltaError)
        assert (error.address, error.bytes, error.configured_lds_bytes) == (256, 256, 256)
        assert error.access == "Write" and error.wave == 0
        assert not hasattr(error, "outputs")


def test_original_exact_boundary_keeps_complete_mathematical_proof():
    result = volta.verify(SOURCE, SPEC, config(), kernel="tensor_roundtrip", dims={"N": 128})
    assert result.equivalent and result.race_verified
    assert result.elements_total == result.elements_checked == 128
