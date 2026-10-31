//! Independent expected bits and public encoding boundaries for five scalar operations.
use std::collections::BTreeSet;
use volta_amdgpu_analysis::{
    AnalysisConfig, AnalysisResult, ArrayDef, ArrayKind, ParamValue, analyze, frontend, ir, lower,
};
use volta_graph::{AmdEventKind, AmdRegisterFile};
use volta_graph_check::{GraphConclusion, Property, Verdict, check_graph};

const TARGETS: [&str; 3] = ["gfx942", "gfx950", "gfx1250"];
const MARKER: &str = "s_mov_b32 s6,0x89abcdef\ns_mov_b32 s7,0x01234567";

fn source(target: &str, body: &str) -> String {
    let template = match target {
        "gfx942" => include_str!("fixtures/scalar-inline64/gfx942.s"),
        "gfx950" => include_str!("fixtures/scalar-inline64/gfx950.s"),
        "gfx1250" => include_str!("fixtures/scalar-inline64/gfx1250.s"),
        _ => panic!("unselected target"),
    };
    // These are new synthetic controls with explicitly declared scratch SGPRs.
    // The checked-in complete modules remain unchanged.
    template
        .replace("s_mov_b64 s[8:9],1.0", body)
        .replace(".amdhsa_next_free_sgpr 10", ".amdhsa_next_free_sgpr 32")
        .replace(".sgpr_count: 10", ".sgpr_count: 32")
}

fn module(target: &str, body: &str) -> frontend::Module {
    frontend::parse(&source(target, body)).unwrap()
}

fn execute(module: &frontend::Module) -> AnalysisResult {
    let lowered = lower::lower_module_kernel(module, "k").unwrap();
    for instruction in &lowered.instructions {
        if [
            "s_mov_b64",
            "s_or_b64",
            "s_xor_b64",
            "s_lshl_b64",
            "s_lshr_b64",
        ]
        .contains(&instruction.mnemonic().as_str())
        {
            assert!(instruction.operands()[1..].iter().all(|source| matches!(
                source,
                ir::Operand::Register(_) | ir::Operand::EncodedImmediate(_)
            )));
        }
    }
    let mut config = AnalysisConfig::new((1, 1, 1));
    config.arrays.push(ArrayDef {
        name: "out".into(),
        base: 0x10000,
        elem_width: 4,
        len: 2,
        kind: ArrayKind::Output,
    });
    config.params.push(ParamValue::ArrayPtr("out".into()));
    let result = analyze(module, Some("k"), config).unwrap();
    result.graph().validate().unwrap();
    result
}

fn words(result: &AnalysisResult, expected: [u32; 2]) {
    let outputs = result.symbolic_outputs().unwrap();
    assert_eq!(outputs.outputs.len(), 1);
    assert_eq!(outputs.outputs[0].0, "out");
    assert_eq!(
        outputs.outputs[0]
            .1
            .iter()
            .map(|(i, _)| *i)
            .collect::<Vec<_>>(),
        vec![0, 1]
    );
    for (index, expected) in expected.into_iter().enumerate() {
        assert_eq!(
            outputs
                .arena
                .as_int_const(outputs.element("out", index as u64).unwrap()),
            Some(i64::from(expected)),
            "word {index}"
        );
    }
}

fn safe_words(result: &AnalysisResult, expected: [u32; 2]) {
    words(result, expected);
    let checks = check_graph(result.graph());
    assert_eq!(
        checks.conclusion(),
        GraphConclusion::Verified,
        "{checks:#?}"
    );
}

fn verified(target: &str, body: &str, expected: [u32; 2]) {
    let module = module(target, body);
    let result = execute(&module);
    words(&result, expected);
    let checks = check_graph(result.graph());
    assert_eq!(
        checks.conclusion(),
        GraphConclusion::Verified,
        "{target}: {body}\n{checks:#?}"
    );
    assert_eq!(
        result.stats.instructions as usize,
        module.kernels[0].instructions.len()
    );
}

#[derive(Clone, Copy)]
enum Encoding {
    Inline(u8),
    Word(u32),
    Wide(u64),
}

fn immediate(
    module: &frontend::Module,
    opcode: &str,
    position: usize,
    kind: ir::ScalarSourceType,
    encoding: Encoding,
    bits: u64,
) {
    let lowered = lower::lower_module_kernel(module, "k").unwrap();
    let instruction = lowered
        .instructions
        .iter()
        .find(|i| i.mnemonic() == opcode)
        .unwrap();
    let ir::Operand::EncodedImmediate(value) = &instruction.operands()[position] else {
        panic!("numeric source {position} of {opcode} must have a checked encoding");
    };
    assert_eq!(value.source_type(), kind);
    assert_eq!(value.bits(), bits);
    match (value.encoding(), encoding) {
        (ir::ImmediateEncoding::Inline(selector), Encoding::Inline(expected)) => {
            assert_eq!(selector.code(), expected);
        }
        (ir::ImmediateEncoding::Literal32(word), Encoding::Word(expected)) => {
            assert_eq!(word, expected)
        }
        (ir::ImmediateEncoding::Literal64(wide), Encoding::Wide(expected)) => {
            assert_eq!(wide, expected)
        }
        (actual, _) => panic!("unexpected source encoding {actual:?}"),
    }
    let original = module.kernels[0]
        .instructions
        .iter()
        .find(|i| i.mnemonic == opcode)
        .unwrap();
    assert_eq!(instruction.span(), original.span);
    assert_eq!(instruction.mnemonic(), &original.mnemonic);
}

#[test]
fn all_nine_positions_distinguish_inline_source_width_without_raw_numeric_fallback() {
    for target in TARGETS {
        let mov = module(target, "s_mov_b64 s[8:9],1.0");
        immediate(
            &mov,
            "s_mov_b64",
            1,
            ir::ScalarSourceType::Binary64,
            Encoding::Inline(242),
            0x3ff0_0000_0000_0000,
        );
        safe_words(&execute(&mov), [0, 0x3ff0_0000]);
        for operation in ["s_or_b64", "s_xor_b64"] {
            for position in [1, 2] {
                let sources = if position == 1 { "1.0,0" } else { "0,1.0" };
                let module = module(target, &format!("{operation} s[8:9],{sources}"));
                immediate(
                    &module,
                    operation,
                    position,
                    ir::ScalarSourceType::Binary64,
                    Encoding::Inline(242),
                    0x3ff0_0000_0000_0000,
                );
                safe_words(&execute(&module), [0, 0x3ff0_0000]);
            }
        }
        for (operation, data, expected) in
            [("s_lshl_b64", "1", [8, 0]), ("s_lshr_b64", "16", [2, 0])]
        {
            let module = module(
                target,
                &format!("{operation} s[8:9],{data},0.15915494309189532"),
            );
            immediate(
                &module,
                operation,
                1,
                ir::ScalarSourceType::Binary64,
                Encoding::Inline(if data == "1" { 129 } else { 144 }),
                if data == "1" { 1 } else { 16 },
            );
            immediate(
                &module,
                operation,
                2,
                ir::ScalarSourceType::Bits32,
                Encoding::Inline(248),
                0x3e22_f983,
            );
            safe_words(&execute(&module), expected);
        }
    }
}

#[test]
fn independently_tabulated_inline_and_literal_words_survive_complete_output_extraction() {
    // Exact public inline patterns, not f64 casts or the production resolver.
    for target in TARGETS {
        for (literal, selector, expected) in [
            ("0.0", 128, [0, 0]),
            ("0.5", 240, [0, 0x3fe0_0000]),
            ("1.0", 242, [0, 0x3ff0_0000]),
            ("2.0", 244, [0, 0x4000_0000]),
            ("4.0", 246, [0, 0x4010_0000]),
            ("0.15915494309189532", 248, [0x6dc9_c882, 0x3fc4_5f30]),
            ("-1", 193, [u32::MAX, u32::MAX]),
            ("-16", 208, [0xffff_fff0, u32::MAX]),
            ("64", 192, [64, 0]),
        ] {
            let body = format!("s_mov_b64 s[8:9],{literal}");
            let module = module(target, &body);
            immediate(
                &module,
                "s_mov_b64",
                1,
                ir::ScalarSourceType::Binary64,
                Encoding::Inline(selector),
                u64::from(expected[0]) | (u64::from(expected[1]) << 32),
            );
            verified(target, &body, expected);
        }
        for literal in ["0x100", "0x3f800000", "0x7fffffff"] {
            let (word, expected) = match literal {
                "0x100" => (0x100, [0x100, 0]),
                "0x3f800000" => (0x3f80_0000, [0x3f80_0000, 0]),
                _ => (0x7fff_ffff, [0x7fff_ffff, 0]),
            };
            let body = format!("s_mov_b64 s[8:9],{literal}");
            immediate(
                &module(target, &body),
                "s_mov_b64",
                1,
                ir::ScalarSourceType::Binary64,
                Encoding::Word(word),
                u64::from(word),
            );
            verified(target, &body, expected);
        }
    }
    for (literal, bits, expected) in [
        ("0xffffffff", 0x0000_0000_ffff_ffff, [u32::MAX, 0]),
        ("-17", 0xffff_ffff_ffff_ffef, [0xffff_ffef, u32::MAX]),
        ("0x100000000", 0x0000_0001_0000_0000, [0, 1]),
    ] {
        let body = format!("s_mov_b64 s[8:9],{literal}");
        immediate(
            &module("gfx1250", &body),
            "s_mov_b64",
            1,
            ir::ScalarSourceType::Binary64,
            Encoding::Wide(bits),
            bits,
        );
        verified("gfx1250", &body, expected);
    }
}

#[test]
fn both_logical_slots_preserve_high_low_bits_and_aliased_sources() {
    for target in TARGETS {
        for (literal, or_words, xor_words) in [
            (
                "1.0",
                [0x89ab_cdef, 0x3ff3_4567],
                [0x89ab_cdef, 0x3ed3_4567],
            ),
            (
                "0x3f800000",
                [0xbfab_cdef, 0x0123_4567],
                [0xb62b_cdef, 0x0123_4567],
            ),
            (
                "0.15915494309189532",
                [0xedeb_cdef, 0x3fe7_5f77],
                [0xe462_056d, 0x3ee7_1a57],
            ),
        ] {
            for (operation, expected) in [("s_or_b64", or_words), ("s_xor_b64", xor_words)] {
                for (left, right) in [(literal, "s[8:9]"), ("s[8:9]", literal)] {
                    verified(
                        target,
                        &format!(
                            "{MARKER}\ns_mov_b64 s[8:9],s[6:7]\n{operation} s[8:9],{left},{right}"
                        ),
                        expected,
                    );
                }
            }
        }
    }
}

#[test]
fn shifts_keep_binary64_data_and_bits32_counts_separate() {
    for target in TARGETS {
        for count in ["0.15915494309189532", "0.15915494", "0x3e22f983"] {
            verified(target, &format!("s_lshl_b64 s[8:9],1,{count}"), [8, 0]);
            verified(target, &format!("s_lshr_b64 s[8:9],16,{count}"), [2, 0]);
        }
        for (operation, data, expected) in [
            ("s_lshl_b64", "1.0", [0, 0x7fe0_0000]),
            ("s_lshr_b64", "1.0", [0, 0x1ff8_0000]),
            (
                "s_lshl_b64",
                "0.15915494309189532",
                [0xdb93_9104, 0x7f88_be60],
            ),
            (
                "s_lshr_b64",
                "0.15915494309189532",
                [0x36e4_e441, 0x1fe2_2f98],
            ),
        ] {
            verified(target, &format!("{operation} s[8:9],{data},1"), expected);
        }
        verified(target, "s_lshl_b64 s[8:9],1,-1", [0, 0x8000_0000]);
        immediate(
            &module(target, "s_lshl_b64 s[8:9],1,-1"),
            "s_lshl_b64",
            2,
            ir::ScalarSourceType::Bits32,
            Encoding::Inline(193),
            0xffff_ffff,
        );
        verified(
            target,
            &format!("{MARKER}\ns_lshr_b64 s[8:9],s[6:7],64"),
            [0x89ab_cdef, 0x0123_4567],
        );
        // Count aliases destination low; its undefined adjacent word is unused.
        verified(
            target,
            "s_mov_b32 s6,1\ns_mov_b32 s7,0\ns_mov_b32 s8,3\ns_lshl_b64 s[8:9],s[6:7],s8",
            [8, 0],
        );
    }
}

#[test]
fn independently_qualified_noninline_float_counts_keep_their_finite_f32_bits() {
    for target in TARGETS {
        for (count, encoding, bits) in [
            ("1.5", Encoding::Word(0x3fc0_0000), 0x3fc0_0000),
            ("0.25", Encoding::Word(0x3e80_0000), 0x3e80_0000),
            ("65.0", Encoding::Word(0x4282_0000), 0x4282_0000),
            ("1.0000000001", Encoding::Inline(242), 0x3f80_0000),
        ] {
            for (operation, data, expected) in
                [("s_lshl_b64", "1", [1, 0]), ("s_lshr_b64", "16", [16, 0])]
            {
                let body = format!("{operation} s[8:9],{data},{count}");
                immediate(
                    &module(target, &body),
                    operation,
                    2,
                    ir::ScalarSourceType::Bits32,
                    encoding,
                    bits,
                );
                verified(target, &body, expected);
            }
        }
        for operation in ["s_lshl_b64", "s_lshr_b64"] {
            let body = format!("{operation} s[8:9],0x3fc00000,1.5");
            let module = module(target, &body);
            immediate(
                &module,
                operation,
                1,
                ir::ScalarSourceType::Binary64,
                Encoding::Word(0x3fc0_0000),
                0x3fc0_0000,
            );
            immediate(
                &module,
                operation,
                2,
                ir::ScalarSourceType::Bits32,
                Encoding::Word(0x3fc0_0000),
                0x3fc0_0000,
            );
            safe_words(&execute(&module), [0x3fc0_0000, 0]);
            source_refused(
                target,
                &format!("{operation} s[8:9],0x3fc00000,0.25"),
                operation,
                2,
                "one shared literal payload and width",
            );
            source_refused(
                target,
                &format!("{operation} s[8:9],1.5,1"),
                operation,
                1,
                "Binary64 source requires an exact floating inline constant",
            );
        }
    }
    source_refused(
        "gfx1250",
        "s_lshl_b64 s[8:9],0x100000000,1.5",
        "s_lshl_b64",
        2,
        "one shared literal payload and width",
    );
}

fn source_error(message: &str, operation: &str, position: usize, reason: &str) {
    assert!(message.contains("scalar source encoding"), "{message}");
    assert!(
        message.contains(&format!("`{operation}` source{position}")),
        "{message}"
    );
    assert!(message.contains(reason), "{message}");
}

fn source_refused(target: &str, body: &str, operation: &str, position: usize, reason: &str) {
    let message = match frontend::parse(&source(target, body)) {
        Err(error) => error.to_string(),
        Ok(module) => lower::lower_module_kernel(&module, "k")
            .unwrap_err()
            .to_string(),
    };
    source_error(&message, operation, position, reason);
}

#[test]
fn all_twenty_new_refusals_are_explicit_compatibility_boundaries() {
    let mut unproved = 0;
    for target in ["gfx942", "gfx950"] {
        for (operation, position, body) in [
            ("s_mov_b64", 1, "s_mov_b64 s[8:9],0x80000000"),
            ("s_mov_b64", 1, "s_mov_b64 s[8:9],-17"),
            ("s_or_b64", 2, "s_or_b64 s[8:9],0,0x80000000"),
            ("s_xor_b64", 1, "s_xor_b64 s[8:9],-17,0"),
            ("s_lshl_b64", 1, "s_lshl_b64 s[8:9],0x80000000,1"),
            ("s_lshr_b64", 1, "s_lshr_b64 s[8:9],-17,1"),
        ] {
            source_refused(
                target,
                body,
                operation,
                position,
                "legacy Binary64 noninline data requires a nonnegative low31-bit literal; high-bit expansion and literal64 are unsupported",
            );
            unproved += 1;
        }
    }
    assert_eq!(unproved, 12);
    let mut invalid_encoding = 0;
    for target in ["gfx942", "gfx950"] {
        source_refused(
            target,
            "s_mov_b64 s[8:9],0x100000000",
            "s_mov_b64",
            1,
            "legacy Binary64 noninline data requires a nonnegative low31-bit literal; high-bit expansion and literal64 are unsupported",
        );
        invalid_encoding += 1;
    }
    for target in TARGETS {
        for (operation, body, reason) in [
            (
                "s_xor_b64",
                "s_xor_b64 s[8:9],0x100,0x200",
                "one shared literal payload and width",
            ),
            (
                "s_lshr_b64",
                "s_lshr_b64 s[8:9],16,0x100000001",
                "Bits32 source requires a 32-bit integer, not a truncated wide literal",
            ),
        ] {
            source_refused(target, body, operation, 2, reason);
            invalid_encoding += 1;
        }
    }
    assert_eq!(invalid_encoding, 8);
    // Neither group asserts a valid-ISA kernel bug or hardware behavior.
}

#[test]
fn literal_sharing_is_instruction_wide_including_mixed_source_widths() {
    for target in TARGETS {
        for (body, expected) in [
            ("s_or_b64 s[8:9],0x100,0x100", [0x100, 0]),
            ("s_xor_b64 s[8:9],0x100,0x100", [0, 0]),
            ("s_lshl_b64 s[8:9],0x100,0x100", [0x100, 0]),
        ] {
            verified(target, body, expected);
        }
        let mixed = module(target, "s_lshl_b64 s[8:9],0x100,0x100");
        immediate(
            &mixed,
            "s_lshl_b64",
            1,
            ir::ScalarSourceType::Binary64,
            Encoding::Word(0x100),
            0x100,
        );
        immediate(
            &mixed,
            "s_lshl_b64",
            2,
            ir::ScalarSourceType::Bits32,
            Encoding::Word(0x100),
            0x100,
        );
        for (operation, body) in [
            ("s_or_b64", "s_or_b64 s[8:9],0x100,0x200"),
            ("s_or_b64", "s_or_b64 s[8:9],0x200,0x100"),
            ("s_xor_b64", "s_xor_b64 s[8:9],0x200,0x100"),
            ("s_lshl_b64", "s_lshl_b64 s[8:9],0x100,0x200"),
        ] {
            source_refused(
                target,
                body,
                operation,
                2,
                "one shared literal payload and width",
            );
        }
        verified(
            target,
            ".set WORD,0x3f800000\ns_mov_b64 s[8:9],WORD",
            [0x3f80_0000, 0],
        );
    }
    source_refused(
        "gfx1250",
        "s_lshl_b64 s[8:9],0x100000100,0x100",
        "s_lshl_b64",
        2,
        "one shared literal payload and width",
    );
}

#[test]
fn fifteen_existing_refusals_keep_their_syntax_encoding_or_runtime_boundary() {
    let mut retained = 0;
    for target in TARGETS {
        for wrapper in ["lit(0x3f800000)", "lit64(-1)"] {
            let body = format!("s_mov_b64 s[8:9],{wrapper}");
            let source = source(target, &body);
            let error = frontend::parse(&source).unwrap_err();
            assert!(error.message.contains("unsupported or malformed operand"));
            assert!(error.message.contains(wrapper));
            assert_eq!(
                error.span.line,
                source.lines().position(|line| line == body).unwrap() + 1
            );
            retained += 1;
        }
        source_refused(
            target,
            "s_mov_b64 s[8:9],1.0000000001",
            "s_mov_b64",
            1,
            "Binary64 source requires an exact floating inline constant",
        );
        retained += 1;
        for (body, reason) in [
            ("s_mov_b64 s[8:9],src_shared_base", "opaque shared aperture"),
            (
                "s_mov_b32 s8,7\ns_mov_b64 s[8:9],s[8:9]",
                "uninitialized Scalar register 9",
            ),
        ] {
            let result = execute(&module(target, body));
            assert!(
                result
                    .symbolic_outputs()
                    .unwrap_err()
                    .to_string()
                    .contains(reason)
            );
            assert!(matches!(
                check_graph(result.graph()).conclusion(),
                GraphConclusion::Unknown { .. }
            ));
            retained += 1;
        }
    }
    assert_eq!(retained, 15);
}

#[test]
fn public_ast_clients_get_the_same_encoding_checks_and_exact_negative_inlines() {
    for target in TARGETS {
        for (value, selector, high) in [
            (-0.5, 241, 0xbfe0_0000),
            (-1.0, 243, 0xbff0_0000),
            (-2.0, 245, 0xc000_0000),
            (-4.0, 247, 0xc010_0000),
        ] {
            let mut module = module(target, "s_mov_b64 s[8:9],0.5");
            let instruction = module.kernels[0]
                .instructions
                .iter_mut()
                .find(|i| i.mnemonic == "s_mov_b64")
                .unwrap();
            instruction.operands[1] = frontend::Operand::Float(value);
            immediate(
                &module,
                "s_mov_b64",
                1,
                ir::ScalarSourceType::Binary64,
                Encoding::Inline(selector),
                u64::from(high) << 32,
            );
            safe_words(&execute(&module), [0, high]);
        }
        let mut xor_module = module(target, "s_xor_b64 s[8:9],0x100,0x100");
        let instruction = xor_module.kernels[0]
            .instructions
            .iter_mut()
            .find(|i| i.mnemonic == "s_xor_b64")
            .unwrap();
        instruction.operands[2] = frontend::Operand::Integer(0x200);
        source_error(
            &lower::lower_module_kernel(&xor_module, "k")
                .unwrap_err()
                .message,
            "s_xor_b64",
            2,
            "one shared literal payload and width",
        );
        if target != "gfx1250" {
            let mut module = module(target, "s_mov_b64 s[8:9],0x100");
            let instruction = module.kernels[0]
                .instructions
                .iter_mut()
                .find(|i| i.mnemonic == "s_mov_b64")
                .unwrap();
            instruction.operands[1] = frontend::Operand::Integer(-17);
            source_error(
                &lower::lower_kernel_in_module(&module, &module.kernels[0])
                    .unwrap_err()
                    .message,
                "s_mov_b64",
                1,
                "legacy Binary64 noninline data requires a nonnegative low31-bit literal",
            );
        }
    }
}

#[test]
fn flags_aliases_and_empty_exec_preserve_scalar_semantics() {
    for target in TARGETS {
        let exec = if target == "gfx1250" {
            "s_mov_b32 exec_lo"
        } else {
            "s_mov_b64 exec"
        };
        for (body, expected) in [
            (
                "s_cmp_eq_u32 0,1\ns_mov_b64 s[8:9],1.0\ns_cselect_b32 s8,1,0",
                [0, 0x3ff0_0000],
            ),
            (
                "s_cmp_eq_u32 0,0\ns_mov_b64 s[8:9],1.0\ns_cselect_b32 s8,1,0",
                [1, 0x3ff0_0000],
            ),
            (
                "s_or_b64 s[8:9],0,1.0\ns_cselect_b32 s8,1,0",
                [1, 0x3ff0_0000],
            ),
            ("s_xor_b64 s[8:9],1.0,1.0\ns_cselect_b32 s8,1,0", [0, 0]),
            (
                "s_lshl_b64 s[8:9],1.0,1\ns_cselect_b32 s8,1,0",
                [1, 0x7fe0_0000],
            ),
            ("s_lshr_b64 s[8:9],0,1\ns_cselect_b32 s8,1,0", [0, 0]),
        ] {
            verified(target, &format!("{exec},0\n{body}\n{exec},1"), expected);
        }
        let result = execute(&module(
            target,
            "s_mov_b64 s[8:9],1.0\ns_cselect_b32 s8,1,0",
        ));
        assert!(
            result
                .symbolic_outputs()
                .unwrap_err()
                .to_string()
                .contains("uninitialized SCC")
        );
    }
}

struct RegisterCase {
    operation: &'static str,
    sources: &'static str,
    slots: &'static [(u16, [u32; 2])],
}

fn register_cases() -> [RegisterCase; 5] {
    [
        RegisterCase {
            operation: "s_mov_b64",
            sources: "s[6:7]",
            slots: &[(6, [0x10000, 0]), (7, [0, 0x10000])],
        },
        RegisterCase {
            operation: "s_or_b64",
            sources: "s[6:7],s[10:11]",
            slots: &[
                (6, [0x10000, 0]),
                (7, [0, 0x10000]),
                (10, [0x10000, 0]),
                (11, [0, 0x10000]),
            ],
        },
        RegisterCase {
            operation: "s_xor_b64",
            sources: "s[6:7],s[10:11]",
            slots: &[
                (6, [0x10000, 0]),
                (7, [0, 0x10000]),
                (10, [0x10000, 0]),
                (11, [0, 0x10000]),
            ],
        },
        RegisterCase {
            operation: "s_lshl_b64",
            sources: "s[6:7],s12",
            slots: &[(6, [0x20000, 0]), (7, [0, 0x20000]), (12, [0, 0])],
        },
        RegisterCase {
            operation: "s_lshr_b64",
            sources: "s[6:7],s12",
            slots: &[(6, [0x8000, 0]), (7, [0, 0x8000]), (12, [0, 0])],
        },
    ]
}

#[test]
fn all_sixteen_actual_source_words_keep_independent_readiness_and_register_roles() {
    for target in TARGETS {
        let (load, completed, wrong) = if target == "gfx1250" {
            ("s_load_b32", "s_wait_kmcnt 0", "s_wait_loadcnt 0")
        } else {
            ("s_load_dword", "s_waitcnt lgkmcnt(0)", "s_waitcnt vmcnt(0)")
        };
        let mut slots = 0;
        for case in register_cases() {
            for &(index, expected) in case.slots {
                slots += 1;
                for wait in ["", wrong, completed] {
                    let body = format!(
                        "s_mov_b32 s6,0\ns_mov_b32 s7,0\ns_mov_b32 s10,0\ns_mov_b32 s11,0\ns_mov_b32 s12,1\n{load} s{index},s[0:1],0\n{wait}\n{} s[8:9],{}",
                        case.operation, case.sources
                    );
                    let module = module(target, &body);
                    let pc = module.kernels[0]
                        .instructions
                        .iter()
                        .position(|i| i.mnemonic == case.operation)
                        .unwrap();
                    let result = execute(&module);
                    words(&result, expected);
                    let checks = check_graph(result.graph());
                    assert_eq!(checks.verdict(Property::AmdTrace), Verdict::Pass);
                    if wait == completed {
                        assert_eq!(
                            checks.conclusion(),
                            GraphConclusion::Verified,
                            "{target}: {body}\n{checks:#?}"
                        );
                    } else {
                        assert_eq!(checks.verdict(Property::AmdWaitReadiness), Verdict::Fail);
                        assert!(
                            checks
                                .amd
                                .as_ref()
                                .unwrap()
                                .wait_readiness
                                .violations()
                                .iter()
                                .any(|h| h.register.file == AmdRegisterFile::Scalar
                                    && h.register.index == index)
                        );
                        assert!(matches!(
                            checks.conclusion(),
                            GraphConclusion::Rejected { .. }
                        ));
                    }
                    let record = result
                        .graph()
                        .amd_events()
                        .iter()
                        .find(|r| {
                            result
                                .graph()
                                .event(r.event)
                                .pc
                                .is_some_and(|p| p.0 as usize == pc)
                                && matches!(r.kind, AmdEventKind::Instruction { .. })
                        })
                        .unwrap();
                    let AmdEventKind::Instruction { reads, writes, .. } = &record.kind else {
                        unreachable!()
                    };
                    assert_eq!(
                        reads.iter().map(|r| r.index).collect::<BTreeSet<_>>(),
                        case.slots.iter().map(|(i, _)| *i).collect()
                    );
                    assert!(
                        reads
                            .iter()
                            .all(|r| r.file == AmdRegisterFile::Scalar && r.lanes == u64::MAX)
                    );
                    assert_eq!(
                        writes.iter().map(|r| r.index).collect::<Vec<_>>(),
                        vec![8, 9]
                    );
                }
            }
        }
        assert_eq!(slots, 16);
    }
}

#[test]
fn count_neighbor_is_not_a_64bit_source_or_a_phantom_readiness_dependency() {
    for target in TARGETS {
        let load = if target == "gfx1250" {
            "s_load_b32"
        } else {
            "s_load_dword"
        };
        for operation in ["s_lshl_b64", "s_lshr_b64"] {
            let body = format!(
                "s_mov_b32 s6,4\ns_mov_b32 s7,0\ns_mov_b32 s12,1\n{load} s13,s[0:1],0\n{operation} s[8:9],s[6:7],s12"
            );
            verified(
                target,
                &body,
                if operation == "s_lshl_b64" {
                    [8, 0]
                } else {
                    [2, 0]
                },
            );
        }
    }
}
