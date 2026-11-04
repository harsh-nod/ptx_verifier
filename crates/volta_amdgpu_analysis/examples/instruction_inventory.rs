//! Emit typed frontend instruction profiles for the checked-in coverage generator.
//! This records syntax, not execution coverage or a successful verification.
use std::{env, fs};
use volta_amdgpu_analysis::frontend::{self, Instruction, Operand};

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
        Operand::HardwareRegister {
            name,
            offset,
            width,
        } => format!(
            "{{\"kind\":\"hardware_register\",\"name\":\"{}\",\"offset\":{},\"width\":{}}}",
            name, offset, width
        ),
        Operand::Dual(_, _) => "{\"kind\":\"dual_vector_instruction\"}".into(),
        Operand::BranchTarget(_) => "{\"kind\":\"lowered_branch\"}".into(),
    }
}

fn emit(path: &str, kernel: &str, instruction: &Instruction, component: Option<&str>) {
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
    let component = component
        .map(|slot| format!(",\"component_slot\":{}", quoted(slot)))
        .unwrap_or_default();
    println!(
        "{{\"path\":{},\"kernel\":{},\"line\":{},\"mnemonic\":{},\"family\":\"{:?}\",\"operands\":[{operands}],\"modifiers\":[{modifiers}]{component}}}",
        quoted(path),
        quoted(kernel),
        instruction.span.line,
        quoted(&instruction.mnemonic),
        instruction.opcode
    );
}

fn main() {
    let mut components = false;
    let mut lower = false;
    for path in env::args().skip(1) {
        if path == "--components" {
            components = true;
            continue;
        }
        if path == "--lower" {
            lower = true;
            continue;
        }
        let source = fs::read_to_string(&path).unwrap_or_else(|error| panic!("{path}: {error}"));
        let module = frontend::parse(&source).unwrap_or_else(|error| panic!("{path}: {error}"));
        if lower {
            for kernel in &module.kernels {
                volta_amdgpu_analysis::lower::lower_kernel_in_module(&module, kernel)
                    .unwrap_or_else(|error| panic!("{path}: {}: {error}", kernel.name));
            }
        }
        for kernel in module.kernels {
            for instruction in kernel.instructions {
                if components && let [Operand::Dual(x, y)] = instruction.operands.as_slice() {
                    emit(&path, &kernel.name, x, Some("X"));
                    emit(&path, &kernel.name, y, Some("Y"));
                    continue;
                }
                emit(&path, &kernel.name, &instruction, None);
            }
        }
    }
}
