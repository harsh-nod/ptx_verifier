//! Parsing/lowering gate for genuine full-shape assembly; no execution claim.
use volta_amdgpu_analysis::{frontend, lower};

#[test]
fn original_matrix_native_module_keeps_all_six_entries_without_private_spills() {
    let source = include_str!("../../../tests/gfx1250/full/fixtures/original-matrix.s");
    let module = frontend::parse(source).expect("unchanged compiler output parses");
    assert_eq!(module.target.as_deref(), Some("gfx1250"));
    let entries = [
        ("gemm_f16_full", 65536, 1024),
        ("gemm_f8_full", 65536, 1024),
        ("gemm_add_silu_f16_full", 65536, 1024),
        ("gemm_add_silu_f8_full", 65536, 1024),
        ("bitdelta_full", 24576, 256),
        ("bitdelta_batched_full", 49152, 256),
    ];
    assert_eq!(module.kernels.len(), entries.len());
    for (name, lds, threads) in entries {
        let kernel = module.kernels.iter().find(|k| k.name == name).unwrap();
        assert_eq!(kernel.descriptor.get("group_segment_fixed_size"), Some(lds));
        assert_eq!(kernel.descriptor.get("private_segment_fixed_size"), Some(0));
        assert_eq!(
            kernel.descriptor.get("max_flat_workgroup_size"),
            Some(threads)
        );
        assert!(kernel.descriptor.get("next_free_vgpr").unwrap() <= 256);
        let mut wmma_sites = 0;
        for (index, instruction) in kernel.instructions.iter().enumerate() {
            if instruction.mnemonic == "v_wmma_f32_16x16x32_f16" {
                wmma_sites += 1;
                let spacing: Vec<_> = kernel.instructions[index + 1..]
                    .iter()
                    .take(4)
                    .map(|next| next.mnemonic.as_str())
                    .collect();
                assert_eq!(spacing, ["v_nop"; 4], "{name}: WMMA source spacing");
            }
        }
        assert!(wmma_sites > 0, "{name} must execute native WMMA");
        lower::lower_kernel_in_module(&module, kernel)
            .expect("native control flow and target validate");
    }
}
