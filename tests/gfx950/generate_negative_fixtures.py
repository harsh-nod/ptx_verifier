#!/usr/bin/env python3
"""Emit handwritten native counterparts of the pinned negative-equivalence corpus.

These sources preserve each computation/mutation, using native waits and an
explicit two-pointer AMDHSA ABI. They are not translations executed through PTX.
Run --check to verify checked-in files; assemble with pinned gfx950 llvm-mc.
"""
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "tests/gfx950/portable-negative"
CASES = {
    "constant_perturbation_ref": "v_mul_f32 v8, 0.5, v4",
    "constant_perturbation_mut": "v_mul_f32 v8, 0x3f000002, v4",
    "dropped_term_ref": "v_add_f32 v8, v4, v5\nv_add_f32 v8, v8, v6\nv_add_f32 v8, v8, v7",
    "dropped_term_mut": "v_add_f32 v8, v4, v5\nv_add_f32 v8, v8, v6",
    "swapped_noncommutative_ref": "v_sub_f32 v8, v4, v5\nv_rcp_f32 v10, v5\ns_nop 0\nv_mul_f32 v9, v4, v10",
    "swapped_noncommutative_mut": "v_sub_f32 v8, v5, v4\nv_rcp_f32 v10, v4\ns_nop 0\nv_mul_f32 v9, v5, v10",
    "off_by_one_index_ref": "v_mov_b32 v8, v4",
    "off_by_one_index_mut": "v_mov_b32 v8, v4",
    "missing_relu_clamp_ref": "v_fma_f16 v8, v4, v5, v6\nv_max_f16 v8, 0, v8",
    "missing_relu_clamp_mut": "v_fma_f16 v8, v4, v5, v6",
    "sentinel_off_by_one_ref": "v_mov_b32 v10, 0\nv_add_u32 v8, -1, v10",
    "sentinel_off_by_one_mut": "v_mov_b32 v10, 0\nv_add_u32 v8, -2, v10",
    "fma_different_addend_ref": "v_fma_f32 v8, v4, v5, v6",
    "fma_different_addend_mut": "v_mul_f32 v8, v4, v5\nv_add_f32 v8, v8, v7",
    "linear_chain_sum": "v_add_f32 v8, v4, v5\nv_add_f32 v8, v8, v6\nv_add_f32 v8, v8, v7",
    "balanced_tree_sum": "v_add_f32 v8, v4, v5\nv_add_f32 v9, v6, v7\nv_add_f32 v8, v8, v9",
    "balanced_tree_sum_doubled_leaf": "v_add_f32 v8, v4, v5\nv_add_f32 v9, v7, v7\nv_add_f32 v9, v6, v9\nv_add_f32 v8, v8, v9",
    "max_vs_min_ref": "v_max_f32 v8, v4, v5",
    "max_vs_min_mut": "v_min_f32 v8, v4, v5",
    "exp_product_of_exps": "v_mul_f32 v8, 0x3fb8aa3b, v4\nv_exp_f32 v8, v8\nv_mul_f32 v9, 0x3fb8aa3b, v5\nv_exp_f32 v9, v9\ns_nop 0\nv_mul_f32 v8, v8, v9",
    "exp_of_sum": "v_add_f32 v8, v4, v5\nv_mul_f32 v8, 0x3fb8aa3b, v8\nv_exp_f32 v8, v8",
    "exp_of_product": "v_mul_f32 v8, v4, v5\nv_mul_f32 v8, 0x3fb8aa3b, v8\nv_exp_f32 v8, v8",
    "integer_sign_bit_xor_ref": "v_xor_b32 v8, 0x80000000, v4",
    "integer_sign_bit_xor_mut": "v_sub_u32 v8, 0, v4",
}


def configuration(name):
    return {
        "block": [4 if name.startswith("off_by_one_index") else 1, 1, 1],
        "input_elements": 8 if name.startswith("off_by_one_index") else 4,
        "output_elements": 4 if name.startswith("off_by_one_index") else
                           2 if name.startswith("swapped_noncommutative") else 1,
        "element_size": 2 if name.startswith("missing_relu_clamp") else 4,
    }


def assembly(name, body):
    config = configuration(name)
    width = config["element_size"]
    if name.startswith("off_by_one_index"):
        offset = 4 if name.endswith("_mut") else 0
        loads = f"global_load_dword v4, v2, s[4:5] offset:{offset}"
    elif width == 2:
        loads = "\n".join(f"global_load_ushort v{i+4}, v2, s[4:5] offset:{i*2}" for i in range(4))
    else:
        loads = "global_load_dwordx4 v[4:7], v2, s[4:5]"
    store = "global_store_short" if width == 2 else "global_store_dword"
    stores = f"{store} v2, v8, s[6:7]"
    if config["output_elements"] == 2:
        stores += f"\n{store} v2, v9, s[6:7] offset:4"
    return f'''// Handwritten native counterpart: negative_equivalence/{name}.ptx
// Explicit AMDHSA x/out ABI; unused input slots remain ordinary declared data.
.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
.amdhsa_code_object_version 6
.text
.globl k
.type k,@function
k:
s_load_dwordx4 s[4:7], s[0:1], 0
s_waitcnt lgkmcnt(0)
v_lshlrev_b32 v2, 2, v0
v_mov_b32 v3, 0
{loads}
s_waitcnt vmcnt(0)
{body}
{stores}
s_endpgm
.size k, .-k
.section .rodata,"a",@progbits
.p2align 6
.amdhsa_kernel k
.amdhsa_group_segment_fixed_size 0
.amdhsa_private_segment_fixed_size 0
.amdhsa_kernarg_size 16
.amdhsa_user_sgpr_count 2
.amdhsa_user_sgpr_kernarg_segment_ptr 1
.amdhsa_system_vgpr_workitem_id 0
.amdhsa_next_free_sgpr 16
.amdhsa_next_free_vgpr 32
.amdhsa_accum_offset 32
.amdhsa_reserve_vcc 1
.end_amdhsa_kernel
.amdgpu_metadata
---
amdhsa.version: [1, 2]
amdhsa.kernels:
  - .name: k
    .symbol: k.kd
    .group_segment_fixed_size: 0
    .private_segment_fixed_size: 0
    .kernarg_segment_size: 16
    .kernarg_segment_align: 8
    .wavefront_size: 64
    .sgpr_count: 18
    .vgpr_count: 32
    .max_flat_workgroup_size: 64
    .args:
      - .name: x
        .address_space: global
        .offset: 0
        .size: 8
        .value_kind: global_buffer
      - .name: out
        .address_space: global
        .offset: 8
        .size: 8
        .value_kind: global_buffer
...
.end_amdgpu_metadata
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    files = {OUTPUT / f"{name}.s": assembly(name, body) for name, body in CASES.items()}
    rows = [{"baseline_path": f"crates/volta_pipeline/tests/ptx/negative_equivalence/{name}.ptx",
             "native_source": str((OUTPUT / f"{name}.s").relative_to(ROOT)),
             "configuration": configuration(name)}
            for name in CASES]
    files[OUTPUT / "cases.json"] = json.dumps({"baseline": "e8f819919e5d4628b68aa735deacaaa48d46cf23", "cases": rows}, indent=2) + "\n"
    for path, content in files.items():
        if args.check:
            if not path.is_file() or path.read_text() != content:
                raise SystemExit(f"Generated source differs: {path}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists() and path.read_text() != content:
                raise SystemExit(f"Refusing to overwrite changed source: {path}")
            path.write_text(content)
    print(f"{'Checked' if args.check else 'Generated'} {len(CASES)} native negative-equivalence fixtures")


if __name__ == "__main__":
    main()
