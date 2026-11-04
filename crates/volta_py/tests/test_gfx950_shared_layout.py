"""Configured source LDS boundaries are explicit premises, never inferred names."""
import pytest
import volta

SOURCE = '''
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.text
.globl k
.type k,@function
k:
v_mov_b32 v0, 32
v_mov_b32 v8, 0
ds_write_b32 v0, v8
ds_write_b32 v0, v8 offset:4
ds_write_b32 v0, v8 offset:8
ds_write_b32 v0, v8 offset:12
s_waitcnt lgkmcnt(0)
ds_read_b128 v[12:15], v0
s_waitcnt lgkmcnt(0)
s_endpgm
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 112
.amdhsa_kernarg_size 0
.end_amdhsa_kernel
'''


def config(a_size=None):
    cfg = volta.Config(block=(1, 1, 1), backend="amdgpu", target="gfx950")
    if a_size is not None:
        cfg.add_shared_allocation("A", 0, a_size)
        cfg.add_shared_allocation("B", a_size, 64)
    return cfg


def test_optional_bounds_accept_one_object_and_reject_a_straddling_vector():
    assert volta.analyze(SOURCE, config()).race_verified
    cfg = config(48)
    assert cfg.shared_allocations == [("A", 0, 48), ("B", 48, 64)]
    assert volta.analyze(SOURCE, cfg).race_verified
    with pytest.warns(RuntimeWarning, match="UNKNOWN"):
        with pytest.raises(volta.VoltaError, match="configured allocation boundaries"):
            volta.analyze(SOURCE, config(40))


@pytest.mark.parametrize("name,offset,size", [("", 40, 1), ("A", 40, 1),
                                              ("B", 39, 2), ("B", 40, 0),
                                              ("B", 2**64 - 1, 1)])
def test_bad_layout_edits_are_rejected_without_changing_existing_regions(name, offset, size):
    cfg = volta.Config(block=(1, 1, 1), backend="amdgpu", target="gfx950")
    cfg.add_shared_allocation("A", 0, 40)
    with pytest.raises(ValueError):
        cfg.add_shared_allocation(name, offset, size)
    assert cfg.shared_allocations == [("A", 0, 40)]


def test_ptx_cannot_silently_ignore_a_native_layout():
    cfg = volta.Config(block=(1, 1, 1))
    cfg.add_shared_allocation("A", 0, 40)
    with pytest.raises(volta.VoltaError, match="shared_allocations"):
        volta.analyze(".version 8.6\n.target sm_100a\n.address_size 64\n.visible .entry k() { ret; }", cfg)
