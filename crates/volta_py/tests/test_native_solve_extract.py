"""Explicit native file APIs keep target, graph and private prefix evidence."""

import pytest
import volta

from test_early_memory_conflicts import collision, config, source, SPEC


@pytest.mark.parametrize("target", ["gfx942", "gfx950", "gfx1250"])
@pytest.mark.parametrize("equivalence", [False, True])
def test_explicit_native_file_solve_and_extract(target, equivalence, tmp_path):
    text = (
        source("gfx950").replace("--gfx950", "--gfx942")
        if target == "gfx942"
        else source(target)
    )
    path = tmp_path / "copy.s"
    path.write_text(text)
    cfg = config(target)
    solved = volta.solve(path, cfg, kernel="copy", spec=SPEC, dims={"N": 32})
    assert solved.isa == f"native AMD {target}"
    assert solved.verdict == "ACCEPT" and solved.race_verified is True
    assert solved.workgroup_id == (0, 0, 0)
    assert len(dict(solved.outputs)["out"]) == 32
    extracted = volta.extract_lean(path, cfg, kernel="copy", spec=SPEC, dims={"N": 32}, equivalence=equivalence)
    assert extracted.verdict == ("ACCEPT" if equivalence else None)
    assert extracted.statements == 32 and extracted.race_verified is True
    assert extracted.workgroup_id == (0, 0, 0)
    assert extracted.assumptions == solved.assumptions


@pytest.mark.parametrize("target", ["gfx950", "gfx1250"])
def test_certified_prefix_is_rejection_and_cannot_return_lean(target, tmp_path):
    path = tmp_path / "collision.s"
    path.write_text(collision(target))
    cfg = config(target, early=True)
    for spec_kwargs in [{}, {"spec": SPEC, "dims": {"N": 32}}]:
        result = volta.solve(path, cfg, kernel="copy", **spec_kwargs)
        assert result.verdict == "REJECT" and result.race_verified is False
        assert result.outputs == []
        assert any("certified memory-conflict" in item for item in result.evidence)
    with pytest.raises(volta.EarlyMemoryConflictError) as caught:
        volta.extract_lean(path, cfg, kernel="copy", spec=SPEC, dims={"N": 32})
    assert caught.value.address == 131072
    assert caught.value.earlier_thread != caught.value.later_thread
    assert not hasattr(caught.value, "lean")


def test_explicit_target_cannot_be_discarded_by_s_extension(tmp_path):
    path = tmp_path / "copy.s"
    path.write_text(source("gfx950"))
    with pytest.raises(volta.VoltaError, match="conflicts with source target"):
        volta.solve(path, config("gfx1250"), kernel="copy", spec=SPEC, dims={"N": 32})


def test_explicit_ptx_selection_is_not_overridden_by_s_extension(tmp_path):
    path = tmp_path / "copy.s"
    path.write_text(source("gfx950"))
    with pytest.raises(volta.VoltaError):
        volta.solve(path, volta.Config(block=(32, 1, 1), backend="ptx"), kernel="copy")


def test_selected_native_group_cannot_hide_full_spec_footprint_by_sampling(tmp_path):
    from test_selected_workgroup import config as selected_config

    path = tmp_path / "copy.s"
    path.write_text(source("gfx950"))
    cfg = selected_config()
    result = volta.solve(path, cfg, kernel="copy", spec=SPEC, dims={"N": 192}, sample=1)
    assert result.workgroup_id == (1, 0, 0) and result.race_verified is True
    assert result.verdict == "REJECT"
    assert [i for i, _ in dict(result.outputs)["out"]] == list(range(64, 128))
    with pytest.raises(volta.VoltaError, match="same set of indices"):
        volta.extract_lean(path, cfg, kernel="copy", spec=SPEC, dims={"N": 192})


def test_tensor_prefix_retains_typed_extraction_error(tmp_path):
    from test_tensor_bounds import (
        LOAD,
        SOURCE,
        SPEC as TENSOR_SPEC,
        config as tensor_config,
    )

    path = tmp_path / "bounds.s"
    path.write_text(SOURCE.replace(LOAD, "s_mov_b32 s5, 256\n\t" + LOAD, 1))
    cfg = tensor_config()
    result = volta.solve(
        path, cfg, kernel="tensor_roundtrip", spec=TENSOR_SPEC, dims={"N": 128}
    )
    assert (
        result.verdict == "REJECT"
        and result.race_verified is False
        and result.outputs == []
    )
    with pytest.raises(volta.TensorBoundsError) as caught:
        volta.extract_lean(
            path, cfg, kernel="tensor_roundtrip", spec=TENSOR_SPEC, dims={"N": 128}
        )
    assert (
        caught.value.address,
        caught.value.bytes,
        caught.value.configured_lds_bytes,
    ) == (256, 256, 256)


@pytest.mark.parametrize("target", ["gfx950", "gfx1250"])
@pytest.mark.parametrize("equivalence", [False, True])
def test_prover_rejects_certified_native_prefix_before_tool_discovery(
    target, equivalence, tmp_path
):
    path = tmp_path / "collision.s"
    path.write_text(collision(target))
    output = tmp_path / "proof"
    with pytest.raises(volta.EarlyMemoryConflictError) as caught:
        volta.prove_lean(
            path, config(target, early=True), kernel="copy", spec=SPEC,
            dims={"N": 32}, output_dir=output, equivalence=equivalence,
            claude=tmp_path / "missing-prover", lean_project=tmp_path / "missing-project",
        )
    assert caught.value.address == 131072
    assert caught.value.earlier_thread != caught.value.later_thread
    assert not output.exists()


def test_prover_preserves_native_target_validation_before_external_tools(tmp_path):
    path = tmp_path / "copy.s"
    path.write_text(source("gfx950"))
    with pytest.raises(volta.VoltaError, match="conflicts with source target"):
        volta.prove_lean(
            path, config("gfx1250"), kernel="copy", spec=SPEC, dims={"N": 32},
            output_dir=tmp_path / "proof", claude=tmp_path / "missing-prover",
            lean_project=tmp_path / "missing-project",
        )
    assert not (tmp_path / "proof").exists()
