//! Semantic distinctions that must survive instruction-family normalization.
use volta_amdgpu_analysis::{frontend, ir::*, lower};

fn lower(target: &str, body: &str) -> LoweredKernel {
    let wave = if target == "gfx1250" {
        ".amdhsa_wavefront_size32 1"
    } else {
        ""
    };
    let module = frontend::parse(&format!(
        ".amdgcn_target \"amdgcn-amd-amdhsa--{target}\"\n.text\n.type k,@function\nk:\n{body}\ns_endpgm\n.size k,.-k\n.amdhsa_kernel k\n{wave}\n.end_amdhsa_kernel\n"
    )).unwrap();
    lower::lower_module_kernel(&module, "k").unwrap()
}

fn operation(kernel: &LoweredKernel, index: usize) -> AluOperation {
    kernel.instructions[index]
        .alu_operation()
        .expect("ALU family")
}

#[test]
fn integer_families_preserve_scalar_vector_signedness_and_carry_roles() {
    let kernel = lower(
        "gfx950",
        "s_add_i32 s2,s3,1\ns_add_u32 s2,s3,1\nv_add_u32 v0,v1,v2\nv_add_co_u32 v0,vcc,v1,v2\nv_addc_co_u32 v0,vcc,v1,v2,vcc\nv_subbrev_co_u32 v0,vcc,v1,v2,vcc",
    );
    for (index, domain, kind, signed, form) in [
        (
            0,
            AluDomain::Scalar,
            IntegerKind::Add,
            true,
            IntegerForm::Plain,
        ),
        (
            1,
            AluDomain::Scalar,
            IntegerKind::Add,
            false,
            IntegerForm::Plain,
        ),
        (
            2,
            AluDomain::Vector,
            IntegerKind::Add,
            false,
            IntegerForm::Plain,
        ),
        (
            3,
            AluDomain::Vector,
            IntegerKind::Add,
            false,
            IntegerForm::CarryOut,
        ),
        (
            4,
            AluDomain::Vector,
            IntegerKind::Add,
            false,
            IntegerForm::CarryInOut,
        ),
        (
            5,
            AluDomain::Vector,
            IntegerKind::Sub,
            false,
            IntegerForm::ReverseCarryInOut,
        ),
    ] {
        assert_eq!(
            operation(&kernel, index),
            AluOperation::Integer {
                domain,
                kind,
                ty: IntegerType {
                    width: BitWidth::B32,
                    signed
                },
                source_bits: 32,
                form,
            }
        );
    }
    assert_eq!(kernel.instructions[3].operands().len(), 4);
    assert_eq!(kernel.instructions[4].operands().len(), 5);
    assert!(
        matches!(kernel.instructions[4].operands()[1], Operand::Register(r) if r.special == Some(SpecialRegister::Vcc))
    );
    assert!(
        matches!(kernel.instructions[4].operands()[4], Operand::Register(r) if r.special == Some(SpecialRegister::Vcc))
    );
}

#[test]
fn shifts_retain_source_order_instead_of_globally_swapping_arguments() {
    let kernel = lower("gfx950", "s_lshl_b32 s2,s3,s4\nv_lshlrev_b32_e32 v0,7,v1");
    for (index, domain, reverse) in [(0, AluDomain::Scalar, false), (1, AluDomain::Vector, true)] {
        assert_eq!(
            operation(&kernel, index),
            AluOperation::Shift {
                domain,
                kind: ShiftKind::Left,
                width: BitWidth::B32,
                reverse,
            }
        );
    }
    assert!(matches!(kernel.instructions[0].operands()[1], Operand::Register(r) if r.index == 3));
    assert!(matches!(kernel.instructions[0].operands()[2], Operand::Register(r) if r.index == 4));
    assert_eq!(kernel.instructions[1].operands()[1], Operand::Integer(7));
    assert!(matches!(kernel.instructions[1].operands()[2], Operand::Register(r) if r.index == 1));
}

#[test]
fn multiply_source_width_is_independent_of_result_width() {
    let narrow = lower(
        "gfx950",
        "v_mul_i32_i24 v0,v1,v2\nv_mul_lo_i32 v0,v1,v2\nv_mul_lo_u32 v0,v1,v2",
    );
    for (index, signed, source_bits) in [(0, true, 24), (1, true, 32), (2, false, 32)] {
        assert_eq!(
            operation(&narrow, index),
            AluOperation::Integer {
                domain: AluDomain::Vector,
                kind: IntegerKind::Mul,
                ty: IntegerType {
                    width: BitWidth::B32,
                    signed
                },
                source_bits,
                form: IntegerForm::Plain,
            }
        );
    }
    let wide = lower("gfx1250", "v_mul_u64_e32 v[2:3],s[36:37],v[10:11]");
    assert_eq!(
        operation(&wide, 0),
        AluOperation::Integer {
            domain: AluDomain::Vector,
            kind: IntegerKind::Mul,
            ty: IntegerType {
                width: BitWidth::B64,
                signed: false
            },
            source_bits: 64,
            form: IntegerForm::Plain,
        }
    );
    assert!(
        wide.instructions[0]
            .operands()
            .iter()
            .all(|o| matches!(o, Operand::Register(r) if r.count == 2))
    );
}

#[test]
fn scalar_comparisons_keep_the_immediate_encoding_and_relation() {
    let kernel = lower(
        "gfx950",
        "s_cmp_lt_u32 s2,s3\ns_cmpk_lt_u32 s2,65535\ns_cmp_eq_i32 s2,s3\ns_cmp_lg_u64 s[2:3],s[4:5]",
    );
    for (index, relation, ty, immediate) in [
        (0, Relation::Lt, CompareType::U32, false),
        (1, Relation::Lt, CompareType::U32, true),
        (2, Relation::Eq, CompareType::I32, false),
        (3, Relation::Lg, CompareType::U64, false),
    ] {
        assert_eq!(
            operation(&kernel, index),
            AluOperation::ScalarCompare {
                relation,
                ty,
                immediate
            }
        );
    }
    assert_eq!(
        kernel.instructions[1].operands()[1],
        Operand::Integer(65535)
    );
}

#[test]
fn packed_and_conversion_forms_keep_lane_width_and_rounding_contracts() {
    let kernel = lower(
        "gfx950",
        "v_pk_add_f16 v0,v1,v2\nv_pk_add_f32 v[0:1],v[2:3],v[4:5]\nv_cvt_pk_f16_f32 v0,v1,v2\nv_cvt_pkrtz_f16_f32 v0,v1,v2\nv_cvt_pk_f32_fp8 v[0:1],v2",
    );
    assert_eq!(
        operation(&kernel, 0),
        AluOperation::Packed {
            kind: PackedKind::Add,
            ty: PackedType::F16
        }
    );
    assert_eq!(
        operation(&kernel, 1),
        AluOperation::Packed {
            kind: PackedKind::Add,
            ty: PackedType::F32
        }
    );
    for (index, mode) in [
        (2, ConversionMode::Pack),
        (3, ConversionMode::PackRoundToZero),
    ] {
        assert_eq!(
            operation(&kernel, index),
            AluOperation::Conversion {
                domain: AluDomain::Vector,
                source: ConversionType::F32,
                destination: ConversionType::F16,
                mode,
            }
        );
    }
    assert_eq!(
        operation(&kernel, 4),
        AluOperation::Conversion {
            domain: AluDomain::Vector,
            source: ConversionType::Fp8,
            destination: ConversionType::F32,
            mode: ConversionMode::UnpackPair,
        }
    );
}

#[test]
fn number_max_and_ordinary_max_do_not_collapse_to_one_semantic_operation() {
    let ordinary = lower("gfx950", "v_max3_f32 v0,v1,v2,v3");
    let number = lower("gfx1250", "v_max3_num_f32 v0,v1,v2,v3");
    for (kernel, kind) in [(&ordinary, FloatKind::Max3), (&number, FloatKind::Max3Num)] {
        assert_eq!(
            operation(kernel, 0),
            AluOperation::Float {
                domain: AluDomain::Vector,
                kind,
                ty: FloatType::F32,
            }
        );
    }
    assert_ne!(operation(&ordinary, 0), operation(&number, 0));
}
