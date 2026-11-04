"""Tests for `volta.verify` (a PTX kernel checked against a math spec)."""

import pytest

import volta
from kernels import COPY_KERNEL, copy_config

# out[i] = in[i], matching COPY_KERNEL exactly.
COPY_SPEC = "dim N; array in[N]; array out[N]; out[i] = in[i];"

# Deliberately wrong: the kernel doesn't add anything.
WRONG_SPEC = "dim N; array in[N]; array out[N]; out[i] = in[i] + 1.0;"

BAD_SPEC = "dim N array in[N];"  # missing semicolon after N


def test_verify_matching_spec_is_equivalent():
    result = volta.verify(COPY_KERNEL, COPY_SPEC, copy_config(), dims={"N": 4})

    assert result.equivalent
    assert result.mismatches == []
    assert result.elements_checked == 4
    assert result.elements_total == 4
    assert result.stats.instructions == 4 * 11


def test_verify_wrong_spec_reports_mismatches():
    result = volta.verify(COPY_KERNEL, WRONG_SPEC, copy_config(), dims={"N": 4})

    assert not result.equivalent
    assert result.mismatches == [("out", 0), ("out", 1), ("out", 2), ("out", 3)]


def test_verify_sample_limits_checked_elements():
    result = volta.verify(
        COPY_KERNEL, COPY_SPEC, copy_config(), dims={"N": 4}, sample=2
    )

    assert result.equivalent
    assert result.elements_checked == 2
    assert result.elements_total == 4


def test_verify_spec_syntax_error_raises_volta_error():
    with pytest.raises(volta.VoltaError, match="spec parse error"):
        volta.verify(COPY_KERNEL, BAD_SPEC, copy_config(), dims={"N": 4})


def test_verify_missing_dim_value_raises_volta_error():
    with pytest.raises(volta.VoltaError, match="no value given for dim 'N'"):
        volta.verify(COPY_KERNEL, COPY_SPEC, copy_config(), dims={})


def test_verify_requires_declared_output_array():
    spec = "dim N; array in[N]; array missing[N]; missing[i] = in[i];"
    with pytest.raises(volta.VoltaError, match="declared output array named 'missing'"):
        volta.verify(COPY_KERNEL, spec, copy_config(), dims={"N": 4})


@pytest.mark.parametrize("threads, n", [(2, 4), (4, 2)])
def test_sample_cannot_hide_missing_or_extra_output_indices(threads, n):
    config = volta.Config(block=(threads, 1, 1))
    for name, base, kind in [
        ("in", 0x10000, volta.ArrayKind.Input),
        ("out", 0x20000, volta.ArrayKind.Output),
    ]:
        config.add_array(
            volta.ArrayDef(name, base=base, elem_width=4, len=4, kind=kind)
        )
        config.add_param(volta.Param.array_ptr(name))
    for sample in [0, 2]:
        with pytest.raises(volta.VoltaError, match="index set mismatch"):
            volta.verify(COPY_KERNEL, COPY_SPEC, config, dims={"N": n}, sample=sample)


def test_duplicate_output_equations_are_rejected():
    spec = COPY_SPEC + " out[i] = in[i] + 1.0;"
    with pytest.raises(volta.VoltaError, match="more than one equation"):
        volta.verify(COPY_KERNEL, spec, copy_config(), dims={"N": 4})


def test_overflowing_spec_shape_cannot_be_an_empty_positive():
    source = (
        ".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }"
    )
    config = volta.Config(block=(1, 1, 1))
    config.add_array(
        volta.ArrayDef(
            "out", base=0x20000, elem_width=4, len=1, kind=volta.ArrayKind.Output
        )
    )
    with pytest.raises(volta.VoltaError, match="shape overflows"):
        volta.verify(
            source,
            "dim N;dim M;array out[N,M];out[i,j]=0;",
            config,
            dims={"N": 1 << 32, "M": 1 << 32},
        )
