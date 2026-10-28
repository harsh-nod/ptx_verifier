//! Emit typed frontend instruction profiles for the checked-in coverage generator.
//! This records syntax, not execution coverage or a successful verification.
use std::{env, fs};
use volta_amdgpu_analysis::frontend::{self, Operand};

fn quoted(value: &str) -> String {
    let mut out = String::from("\"");
    for character in value.chars() {
        match character {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            control if control < ' ' => out.push_str(&format!("\\u{:04x}", control as u32)),
            other => out.push(other),
        }
    }
    out.push('"');
    out
}

fn shape(operand: &Operand) -> String {
    match operand {
        Operand::Register(register) => format!(
            "{{\"kind\":\"register\",\"class\":\"{:?}\",\"words\":{},\"special\":{}}}",
            register.class,
            register.count,
            quoted(&format!("{:?}", register.special))
        ),
        Operand::Integer(_) => "{\"kind\":\"integer\"}".into(),
        Operand::Float(_) => "{\"kind\":\"float\"}".into(),
        Operand::Symbol(symbol) => format!(
            "{{\"kind\":\"symbol\",\"value\":{}}}",
            quoted(if symbol == "off" {
                "off"
            } else {
                "label_or_constant"
            })
        ),
        Operand::Relocation(relocation) => format!(
            "{{\"kind\":\"relocation\",\"relocation_kind\":\"{:?}\"}}",
            relocation.kind
        ),
        Operand::Modified {
            value,
            negate,
            absolute,
        } => format!(
            "{{\"kind\":\"modified\",\"negate\":{negate},\"absolute\":{absolute},\"value\":{}}}",
            shape(value)
        ),
        Operand::WaitCounter { name, .. } => {
            format!("{{\"kind\":\"wait_counter\",\"name\":{}}}", quoted(name))
        }
        Operand::BranchTarget(_) => "{\"kind\":\"lowered_branch\"}".into(),
    }
}

fn main() {
    for path in env::args().skip(1) {
        let source = fs::read_to_string(&path).unwrap_or_else(|error| panic!("{path}: {error}"));
        let module = frontend::parse(&source).unwrap_or_else(|error| panic!("{path}: {error}"));
        for kernel in module.kernels {
            for instruction in kernel.instructions {
                let operands = instruction
                    .operands
                    .iter()
                    .map(shape)
                    .collect::<Vec<_>>()
                    .join(",");
                let modifiers = instruction
                    .modifiers
                    .iter()
                    .map(|modifier| {
                        format!(
                            "{{\"name\":{},\"value\":{}}}",
                            quoted(&modifier.name),
                            modifier
                                .value
                                .as_ref()
                                .map(|value| quoted(value))
                                .unwrap_or("null".into())
                        )
                    })
                    .collect::<Vec<_>>()
                    .join(",");
                println!(
                    "{{\"path\":{},\"kernel\":{},\"line\":{},\"mnemonic\":{},\"family\":\"{:?}\",\"operands\":[{operands}],\"modifiers\":[{modifiers}]}}",
                    quoted(&path),
                    quoted(&kernel.name),
                    instruction.span.line,
                    quoted(&instruction.mnemonic),
                    instruction.opcode
                );
            }
        }
    }
}
