use std::{
    collections::{BTreeMap, BTreeSet},
    error::Error,
    fmt,
};

use super::{Global, Kernel, Module, SourceSpan, instr, metadata};

// Explicit bounded object-data envelope. Larger ELF objects are rejected before
// allocating host storage; their bytes must never be silently discarded.
const MAX_OBJECT_BYTES: u64 = 16 * 1024 * 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParseError {
    pub message: String,
    pub span: SourceSpan,
}

impl fmt::Display for ParseError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            formatter,
            "{}:{}: {}",
            self.span.line, self.span.column, self.message
        )
    }
}

impl Error for ParseError {}

/// Parse native gfx950 assembly without executing it. Unsupported syntax remains
/// an error even if it occurs on a path the configured launch would not take.
pub fn parse(source: &str) -> Result<Module, ParseError> {
    parse_module(source)
}

pub fn parse_module(source: &str) -> Result<Module, ParseError> {
    let mut parser = Parser {
        module: Module {
            source: source.to_owned(),
            ..Module::default()
        },
        active: None,
        descriptor: None,
        functions: BTreeSet::new(),
        globals: BTreeSet::new(),
        text_section: true,
        metadata: None,
        metadata_start: SourceSpan::default(),
        metadata_blocks: Vec::new(),
        descriptors: BTreeSet::new(),
        in_block_comment: false,
        data_object: None,
        data_alignment: 1,
        data_read_only: false,
        data_section_supported: false,
    };
    let mut start = 0;
    for (line_index, raw) in source.split_inclusive('\n').enumerate() {
        let span = SourceSpan {
            line: line_index + 1,
            column: raw.len() - raw.trim_start().len() + 1,
            start: start + raw.len() - raw.trim_start().len(),
            end: start + raw.trim_end_matches(['\r', '\n']).len(),
        };
        start += raw.len();
        if let Some(buffer) = &mut parser.metadata {
            if raw.trim() == ".end_amdgpu_metadata" {
                let buffer = parser.metadata.take().unwrap();
                parser.metadata_blocks.push((buffer, parser.metadata_start));
            } else {
                buffer.push_str(raw);
            }
            continue;
        }
        let line = parser.strip_comments(raw);
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        parser.line(line, span)?;
    }
    if parser.in_block_comment {
        return Err(ParseError {
            message: "unterminated block comment".into(),
            span: SourceSpan {
                line: source.lines().count(),
                ..SourceSpan::default()
            },
        });
    }
    if parser.metadata.is_some() {
        return Err(ParseError {
            message: "unterminated .amdgpu_metadata".into(),
            span: parser.metadata_start,
        });
    }
    if let Some(index) = parser.descriptor {
        return Err(ParseError {
            message: format!(
                "unterminated .amdhsa_kernel {}",
                parser.module.kernels[index].name
            ),
            span: SourceSpan::default(),
        });
    }
    if let Some(index) = parser.data_object {
        return Err(ParseError {
            message: format!(
                "module object `{}` has no explicit .size",
                parser.module.globals[index].symbol
            ),
            span: parser.module.globals[index].span,
        });
    }
    if parser.metadata_blocks.len() > 1 {
        return Err(ParseError {
            message: "duplicate .amdgpu_metadata".into(),
            span: parser.metadata_blocks[1].1,
        });
    }
    for (buffer, span) in std::mem::take(&mut parser.metadata_blocks) {
        metadata::apply_metadata(&mut parser.module, &buffer, span)?;
    }
    for kernel in &mut parser.module.kernels {
        for instruction in &mut kernel.instructions {
            if instruction.opcode == super::Opcode::Branch {
                continue;
            }
            for operand in &mut instruction.operands {
                if let super::Operand::Symbol(name) = operand
                    && let Some(value) = parser.module.constants.get(name)
                {
                    *operand = super::Operand::Integer(*value);
                }
            }
            instr::validate_control(instruction)?;
            instr::normalize_f64_sources(instruction)?;
        }
    }
    if parser.module.kernels.is_empty() {
        return Err(ParseError {
            message: "no executable kernels found".into(),
            span: SourceSpan::default(),
        });
    }
    for kernel in &parser.module.kernels {
        if kernel.instructions.is_empty() {
            return Err(ParseError {
                message: format!("kernel `{}` has no instructions", kernel.name),
                span: SourceSpan::default(),
            });
        }
        validate_descriptor(kernel)?;
    }
    Ok(parser.module)
}

struct Parser {
    module: Module,
    active: Option<usize>,
    descriptor: Option<usize>,
    functions: BTreeSet<String>,
    globals: BTreeSet<String>,
    text_section: bool,
    metadata: Option<String>,
    metadata_start: SourceSpan,
    metadata_blocks: Vec<(String, SourceSpan)>,
    descriptors: BTreeSet<String>,
    in_block_comment: bool,
    data_object: Option<usize>,
    data_alignment: u64,
    data_read_only: bool,
    data_section_supported: bool,
}

impl Parser {
    fn strip_comments(&mut self, raw: &str) -> String {
        let mut result = String::new();
        let mut chars = raw.chars().peekable();
        let mut quoted = false;
        let mut escaped = false;
        while let Some(ch) = chars.next() {
            if self.in_block_comment {
                if ch == '*' && chars.peek() == Some(&'/') {
                    chars.next();
                    self.in_block_comment = false;
                }
                continue;
            }
            if quoted {
                result.push(ch);
                if escaped {
                    escaped = false;
                } else if ch == '\\' {
                    escaped = true;
                } else if ch == '"' {
                    quoted = false;
                }
                continue;
            }
            if ch == '"' {
                quoted = true;
                result.push(ch);
            } else if ch == ';' || ch == '#' || ch == '/' && chars.peek() == Some(&'/') {
                break;
            } else if ch == '/' && chars.peek() == Some(&'*') {
                chars.next();
                self.in_block_comment = true;
            } else {
                result.push(ch);
            }
        }
        result
    }

    fn line(&mut self, line: &str, span: SourceSpan) -> Result<(), ParseError> {
        let fail = |message| ParseError { message, span };
        // Labels are recognized before directives because local assembler labels
        // begin with a period. Do not confuse `offset:4` with a leading label.
        if let Some((label, rest)) = line.split_once(':')
            && !label.contains(char::is_whitespace)
            && !label.contains('[')
        {
            if !valid_symbol(label) {
                return Err(fail(format!("malformed label `{label}`")));
            }
            if self.text_section {
                if self.functions.contains(label)
                    || !label.starts_with('.') && self.active.is_none()
                {
                    let index = if let Some(index) = self
                        .module
                        .kernels
                        .iter()
                        .position(|kernel| kernel.name == label)
                    {
                        if !self.module.kernels[index].instructions.is_empty()
                            || !self.module.kernels[index].labels.is_empty()
                        {
                            return Err(fail(format!("duplicate kernel `{label}`")));
                        }
                        index
                    } else {
                        let index = self.module.kernels.len();
                        self.module.kernels.push(Kernel {
                            name: label.into(),
                            ..Kernel::default()
                        });
                        index
                    };
                    self.active = Some(index);
                }
                if let Some(index) = self.active {
                    let kernel = &mut self.module.kernels[index];
                    if kernel
                        .labels
                        .insert(label.into(), kernel.instructions.len())
                        .is_some()
                    {
                        return Err(fail(format!("duplicate label `{label}`")));
                    }
                } else if !label.starts_with(".Lfunc_end") {
                    return Err(fail(format!("label `{label}` outside executable function")));
                }
            } else if self.globals.contains(label) {
                if self.data_object.is_some() {
                    return Err(fail(
                        "a module object must have .size before the next object".into(),
                    ));
                }
                if !self.data_section_supported {
                    return Err(fail(
                        "module object is outside a supported data/rodata/bss section".into(),
                    ));
                }
                if self
                    .module
                    .globals
                    .iter()
                    .any(|object| object.symbol == label)
                {
                    return Err(fail(format!("duplicate module object `{label}`")));
                }
                self.data_object = Some(self.module.globals.len());
                self.module.globals.push(Global {
                    symbol: label.into(),
                    size: 0,
                    alignment: self.data_alignment,
                    initial_bytes: Vec::new(),
                    read_only: self.data_read_only,
                    span,
                });
                self.data_alignment = 1;
            }
            if !rest.trim().is_empty() {
                self.line(rest.trim(), span)?;
            }
            return Ok(());
        }
        if line.starts_with('.') {
            return self.directive(line, span);
        }
        if !self.text_section {
            return Err(fail("executable instruction outside .text section".into()));
        }
        if self.descriptor.is_some() {
            return Err(fail("instruction inside kernel descriptor".into()));
        }
        let index = self
            .active
            .ok_or_else(|| fail("instruction outside executable function".into()))?;
        let normalized =
            instr::resolve_register_indices(line, &self.module.constants).map_err(&fail)?;
        let mut instruction = instr::parse_instruction(&normalized, span)?;
        for operand in &mut instruction.operands {
            if let super::Operand::Symbol(name) = operand
                && let Some(value) = self.module.constants.get(name)
            {
                *operand = super::Operand::Integer(*value);
            }
        }
        self.module.kernels[index].instructions.push(instruction);
        Ok(())
    }

    fn directive(&mut self, line: &str, span: SourceSpan) -> Result<(), ParseError> {
        let fail = |message| ParseError { message, span };
        let (name, args) = line.split_once(char::is_whitespace).unwrap_or((line, ""));
        let args = args.trim();
        if let Some(field) = name.strip_prefix(".amdhsa_")
            && field != "kernel"
            && field != "code_object_version"
        {
            let index = self
                .descriptor
                .ok_or_else(|| fail(format!("`{name}` outside .amdhsa_kernel")))?;
            if !descriptor_fields().contains(&field) {
                return Err(fail(format!(
                    "unsupported kernel descriptor directive `{name}`"
                )));
            }
            let value = instr::integer(args)
                .filter(|value| *value >= 0)
                .ok_or_else(|| fail(format!("`{name}` requires a nonnegative integer")))?
                as u64;
            if self.module.kernels[index]
                .descriptor
                .fields
                .insert(field.into(), value)
                .is_some()
            {
                return Err(fail(format!("duplicate descriptor field `{name}`")));
            }
            return Ok(());
        }
        match name {
            ".amdgcn_target" => {
                let target = unquote(args);
                set_target(&mut self.module, target, span)?;
            }
            ".amdhsa_code_object_version" => {
                let version = instr::integer(args)
                    .filter(|value| (4..=6).contains(value))
                    .ok_or_else(|| {
                        fail("only AMDHSA code-object versions 4, 5 and 6 are supported".into())
                    })? as u32;
                if self.module.code_object_version.replace(version).is_some() {
                    return Err(fail("duplicate code-object version".into()));
                }
            }
            ".amdhsa_kernel" => {
                if self.descriptor.is_some() {
                    return Err(fail("nested .amdhsa_kernel".into()));
                }
                if !valid_symbol(args) {
                    return Err(fail("malformed kernel descriptor name".into()));
                }
                let index = if let Some(index) = self
                    .module
                    .kernels
                    .iter()
                    .position(|kernel| kernel.name == args)
                {
                    index
                } else {
                    let index = self.module.kernels.len();
                    self.module.kernels.push(Kernel {
                        name: args.into(),
                        ..Kernel::default()
                    });
                    index
                };
                if !self.descriptors.insert(args.into()) {
                    return Err(fail(format!("duplicate descriptor for `{args}`")));
                }
                self.descriptor = Some(index);
            }
            ".end_amdhsa_kernel" => {
                if !args.is_empty() {
                    return Err(fail(".end_amdhsa_kernel does not take operands".into()));
                }
                if self.descriptor.take().is_none() {
                    return Err(fail("unmatched .end_amdhsa_kernel".into()));
                }
            }
            ".amdgpu_metadata" => {
                if !args.is_empty() {
                    return Err(fail(".amdgpu_metadata does not take operands".into()));
                }
                if self.module.metadata_version.is_some() {
                    return Err(fail("duplicate .amdgpu_metadata".into()));
                }
                self.metadata = Some(String::new());
                self.metadata_start = span;
            }
            ".text" => {
                self.finish_section(span)?;
                self.text_section = true;
            }
            ".data" | ".rodata" | ".bss" => {
                self.finish_section(span)?;
                self.text_section = false;
                self.data_read_only = name == ".rodata";
                self.data_section_supported = true;
            }
            ".section" | ".pushsection" => {
                if name == ".pushsection" {
                    return Err(fail(
                        ".pushsection requires a section stack and is unsupported".into(),
                    ));
                }
                let section = args.split(',').next().unwrap_or_default().trim_matches('"');
                self.finish_section(span)?;
                self.text_section = section == ".text" || section.starts_with(".text.");
                let flags = args
                    .split(',')
                    .nth(1)
                    .unwrap_or_default()
                    .trim()
                    .trim_matches('"');
                if flags.contains('x') && !self.text_section {
                    return Err(fail("unsupported executable section".into()));
                }
                self.data_read_only = !flags.contains('w');
                self.data_section_supported = [".data", ".rodata", ".bss"].iter().any(|prefix| {
                    section == *prefix
                        || section
                            .strip_prefix(prefix)
                            .is_some_and(|rest| rest.starts_with('.'))
                });
            }
            ".type" => {
                let parts = instr::split_top_level(args, ',').map_err(&fail)?;
                if parts.len() != 2 || !valid_symbol(parts[0]) {
                    return Err(fail("malformed .type directive".into()));
                }
                match parts[1] {
                    "@function" | "%function" => {
                        if self.globals.contains(parts[0]) {
                            return Err(fail("symbol is both function and object".into()));
                        }
                        self.functions.insert(parts[0].into());
                    }
                    "@object" | "%object" => {
                        if self.functions.contains(parts[0]) {
                            return Err(fail("symbol is both function and object".into()));
                        }
                        self.globals.insert(parts[0].into());
                    }
                    _ => return Err(fail(format!("unsupported .type kind `{}`", parts[1]))),
                }
            }
            ".size" => {
                let parts = instr::split_top_level(args, ',').map_err(&fail)?;
                if parts.len() != 2 || !valid_symbol(parts[0]) || parts[1].is_empty() {
                    return Err(fail("malformed .size directive".into()));
                }
                if self
                    .active
                    .is_some_and(|index| self.module.kernels[index].name == parts[0])
                {
                    self.active = None;
                }
                if self.globals.contains(parts[0]) {
                    let index = self
                        .data_object
                        .ok_or_else(|| fail("object .size has no active definition".into()))?;
                    let object = &mut self.module.globals[index];
                    let size = instr::integer(parts[1])
                        .and_then(|value| u64::try_from(value).ok())
                        .filter(|size| *size > 0 && *size <= MAX_OBJECT_BYTES)
                        .ok_or_else(|| {
                            fail(
                                "module object size must be a positive integer at most16MiB".into(),
                            )
                        })?;
                    if object.symbol != parts[0] || object.initial_bytes.len() as u64 != size {
                        return Err(fail(
                            "module object .size must match its exact initialized bytes".into(),
                        ));
                    }
                    object.size = size;
                    self.data_object = None;
                }
            }
            ".set" | ".equ" | ".equiv" => {
                let parts = instr::split_top_level(args, ',').map_err(&fail)?;
                if parts.len() != 2 || !valid_symbol(parts[0]) {
                    return Err(fail("malformed constant definition".into()));
                }
                let value = instr::constant_expression(parts[1], &self.module.constants)
                    .ok_or_else(|| fail("only integer assembly constants are supported".into()))?;
                if self
                    .module
                    .constants
                    .insert(parts[0].into(), value)
                    .is_some()
                {
                    return Err(fail(format!("duplicate assembly constant `{}`", parts[0])));
                }
            }
            // Linkage, debugging, unwind and producer annotations have no value,
            // control-flow, register, or memory effect in this analysis model.
            ".globl" | ".global" | ".protected" | ".hidden" | ".local" | ".weak"
            | ".addrsig_sym" => {
                if !valid_symbol(args) {
                    return Err(fail(format!("malformed `{name}` symbol")));
                }
            }
            ".file"
            | ".loc"
            | ".ident"
            | ".addrsig"
            | ".cfi_startproc"
            | ".cfi_endproc"
            | ".cfi_sections"
            | ".cfi_def_cfa"
            | ".cfi_offset"
            | ".cfi_def_cfa_offset"
            | ".cfi_def_cfa_register" => {}
            ".p2align" | ".p2alignl" | ".balign" | ".align" => {
                let parts = instr::split_top_level(args, ',').map_err(&fail)?;
                if parts.is_empty()
                    || parts.len() > 3
                    || parts.iter().any(|part| instr::integer(part).is_none())
                {
                    return Err(fail(format!("malformed `{name}` alignment")));
                }
                if !self.text_section {
                    if parts.len() == 3 {
                        return Err(fail(
                            "conditional max-skip module-object alignment is unsupported".into(),
                        ));
                    }
                    if name == ".align" {
                        return Err(fail(
                            "module data requires explicit .p2align or .balign".into(),
                        ));
                    }
                    if self.data_object.is_some() {
                        return Err(fail(
                            "internal module-object alignment padding is unsupported".into(),
                        ));
                    }
                    let value = instr::integer(parts[0]).unwrap();
                    let alignment = if name.starts_with(".p2align") {
                        u32::try_from(value)
                            .ok()
                            .and_then(|shift| 1u64.checked_shl(shift))
                    } else {
                        u64::try_from(value).ok()
                    };
                    self.data_alignment = alignment
                        .filter(|alignment| {
                            alignment.is_power_of_two() && *alignment <= MAX_OBJECT_BYTES
                        })
                        .ok_or_else(|| fail("unsupported module-object alignment".into()))?;
                }
            }
            ".byte" | ".short" | ".hword" | ".long" | ".word" | ".quad" | ".zero" | ".space"
            | ".fill" | ".ascii" | ".asciz" | ".string" => {
                if self.text_section && self.active.is_some() {
                    return Err(fail(format!(
                        "raw data directive `{name}` inside executable kernel"
                    )));
                }
                if args.is_empty() {
                    return Err(fail(format!("missing data for `{name}`")));
                }
                if self.data_object.is_some() {
                    self.object_data(name, args, span)?;
                }
            }
            _ => return Err(fail(format!("unsupported assembly directive `{name}`"))),
        }
        Ok(())
    }

    fn finish_section(&mut self, span: SourceSpan) -> Result<(), ParseError> {
        if self.data_object.is_some() {
            return Err(ParseError {
                message: "module object changes section before explicit .size".into(),
                span,
            });
        }
        self.data_alignment = 1;
        Ok(())
    }

    fn object_data(
        &mut self,
        directive: &str,
        args: &str,
        span: SourceSpan,
    ) -> Result<(), ParseError> {
        let fail = |message: &str| ParseError {
            message: message.into(),
            span,
        };
        let parts = instr::split_top_level(args, ',').map_err(|_| fail("malformed module data"))?;
        let numbers = parts
            .iter()
            .map(|part| instr::constant_expression(part, &self.module.constants))
            .collect::<Option<Vec<_>>>()
            .ok_or_else(|| {
                fail(
                    "module data requires exact integer bytes; relocations/strings are unsupported",
                )
            })?;
        let mut bytes = Vec::new();
        let width = match directive {
            ".byte" => Some(1),
            ".short" => Some(2),
            ".long" => Some(4),
            ".quad" => Some(8),
            _ => None,
        };
        if let Some(width) = width {
            for value in numbers {
                bytes.extend_from_slice(&(value as u64).to_le_bytes()[..width]);
            }
        } else if matches!(directive, ".zero" | ".space") && (1..=2).contains(&numbers.len()) {
            let count = u64::try_from(numbers[0])
                .ok()
                .filter(|count| *count <= MAX_OBJECT_BYTES)
                .ok_or_else(|| fail("module zero/space data exceeds bounded object envelope"))?;
            let fill = numbers.get(1).copied().unwrap_or(0);
            if !(0..=255).contains(&fill) {
                return Err(fail("module data fill must be one byte"));
            }
            bytes.resize(count as usize, fill as u8);
        } else if directive == ".fill" && (1..=3).contains(&numbers.len()) {
            let count = u64::try_from(numbers[0])
                .ok()
                .ok_or_else(|| fail("negative module fill count"))?;
            let width = numbers.get(1).copied().unwrap_or(1);
            if ![1, 2, 4].contains(&width) {
                return Err(fail("module fill size must be1,2or4"));
            }
            let size = count
                .checked_mul(width as u64)
                .filter(|size| *size <= MAX_OBJECT_BYTES)
                .ok_or_else(|| fail("module fill data exceeds bounded object envelope"))?;
            let value = numbers.get(2).copied().unwrap_or(0) as u64;
            bytes.reserve(size as usize);
            for _ in 0..count {
                bytes.extend_from_slice(&value.to_le_bytes()[..width as usize]);
            }
        } else {
            return Err(fail("unsupported module object data directive"));
        }
        let object = &mut self.module.globals[self.data_object.unwrap()];
        if (object.initial_bytes.len() as u64)
            .checked_add(bytes.len() as u64)
            .is_none_or(|size| size > MAX_OBJECT_BYTES)
        {
            return Err(fail("module object exceeds bounded16MiB data envelope"));
        }
        object.initial_bytes.extend(bytes);
        Ok(())
    }
}

pub(super) fn unquote(value: &str) -> &str {
    value
        .strip_prefix('"')
        .and_then(|s| s.strip_suffix('"'))
        .unwrap_or(value)
}

fn valid_symbol(symbol: &str) -> bool {
    !symbol.is_empty()
        && !symbol.starts_with(|c: char| c.is_ascii_digit())
        && symbol
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || "_.$@".contains(character))
}

pub(super) fn set_target(
    module: &mut Module,
    target: &str,
    span: SourceSpan,
) -> Result<(), ParseError> {
    let base = target.strip_prefix("amdgcn-amd-amdhsa--").unwrap_or(target);
    let gpu = base.split(':').next().unwrap_or(base);
    if gpu != "gfx950" {
        return Err(ParseError {
            message: format!("unsupported AMD target `{target}`; expected gfx950"),
            span,
        });
    }
    let mut xnack = None;
    let mut sramecc = None;
    for feature in base.split(':').skip(1) {
        if !["xnack+", "xnack-", "sramecc+", "sramecc-"].contains(&feature) {
            return Err(ParseError {
                message: format!("unsupported target feature `{feature}`"),
                span,
            });
        }
        let selected = if feature.starts_with("xnack") {
            &mut xnack
        } else {
            &mut sramecc
        };
        if let Some(previous) = selected {
            let kind = if *previous == feature {
                "duplicate"
            } else {
                "conflicting"
            };
            return Err(ParseError {
                message: format!("{kind} target features `{previous}` and `{feature}`"),
                span,
            });
        }
        *selected = Some(feature);
    }
    if let Some(previous) = &module.target
        && previous != base
    {
        return Err(ParseError {
            message: format!("conflicting assembly and metadata targets `{previous}` and `{base}`"),
            span,
        });
    }
    module.target = Some(base.into());
    Ok(())
}

fn descriptor_fields() -> &'static [&'static str] {
    &[
        "group_segment_fixed_size",
        "private_segment_fixed_size",
        "kernarg_size",
        "user_sgpr_count",
        "user_sgpr_private_segment_buffer",
        "user_sgpr_dispatch_ptr",
        "user_sgpr_queue_ptr",
        "user_sgpr_kernarg_segment_ptr",
        "user_sgpr_dispatch_id",
        "user_sgpr_flat_scratch_init",
        "user_sgpr_private_segment_size",
        "user_sgpr_kernarg_preload_length",
        "user_sgpr_kernarg_preload_offset",
        "uses_dynamic_stack",
        "enable_private_segment",
        "system_sgpr_private_segment_wavefront_offset",
        "system_sgpr_workgroup_id_x",
        "system_sgpr_workgroup_id_y",
        "system_sgpr_workgroup_id_z",
        "system_sgpr_workgroup_info",
        "system_vgpr_workitem_id",
        "next_free_vgpr",
        "next_free_sgpr",
        "accum_offset",
        "reserve_vcc",
        "reserve_flat_scratch",
        "reserve_xnack_mask",
        "float_round_mode_32",
        "float_round_mode_16_64",
        "float_denorm_mode_32",
        "float_denorm_mode_16_64",
        "dx10_clamp",
        "ieee_mode",
        "fp16_overflow",
        "tg_split",
        "wavefront_size32",
        "exception_fp_ieee_invalid_op",
        "exception_fp_denorm_src",
        "exception_fp_ieee_div_zero",
        "exception_fp_ieee_overflow",
        "exception_fp_ieee_underflow",
        "exception_fp_ieee_inexact",
        "exception_int_div_zero",
    ]
}

fn validate_descriptor(kernel: &Kernel) -> Result<(), ParseError> {
    let fail = |message| ParseError {
        message: format!("kernel `{}`: {message}", kernel.name),
        span: SourceSpan::default(),
    };
    for (key, value) in &kernel.descriptor.fields {
        if (key.starts_with("system_sgpr_")
            || key.starts_with("reserve_")
            || key.starts_with("exception_")
            || key.starts_with("user_sgpr_")
                && ![
                    "user_sgpr_count",
                    "user_sgpr_kernarg_preload_length",
                    "user_sgpr_kernarg_preload_offset",
                ]
                .contains(&key.as_str())
            || [
                "uses_dynamic_stack",
                "enable_private_segment",
                "dx10_clamp",
                "ieee_mode",
                "fp16_overflow",
                "tg_split",
                "wavefront_size32",
            ]
            .contains(&key.as_str()))
            && *value > 1
        {
            return Err(fail(format!("descriptor `{key}` must be zero or one")));
        }
        if key == "wavefront_size32" && *value != 0 {
            return Err(fail("gfx950 backend requires wave64".into()));
        }
        if key == "system_vgpr_workitem_id" && *value > 2 {
            return Err(fail("system_vgpr_workitem_id must be 0, 1 or 2".into()));
        }
        if (key.starts_with("float_round_mode_") || key.starts_with("float_denorm_mode_"))
            && *value > 3
        {
            return Err(fail(format!("descriptor `{key}` must fit in two bits")));
        }
        if key == "next_free_vgpr" && *value > 256 {
            return Err(fail("next_free_vgpr exceeds gfx950 register range".into()));
        }
        if key == "next_free_sgpr" && *value > 102 {
            return Err(fail("next_free_sgpr exceeds gfx950 register range".into()));
        }
    }
    fn register(operand: &super::Operand) -> Option<super::Register> {
        match operand {
            super::Operand::Register(register) => Some(*register),
            super::Operand::Modified { value, .. } => register(value),
            _ => None,
        }
    }
    let registers = kernel
        .instructions
        .iter()
        .flat_map(|instruction| instruction.operands.iter())
        .filter_map(register)
        .collect::<Vec<_>>();
    let has_accumulators = registers
        .iter()
        .any(|register| register.class == super::RegisterClass::Accumulator);
    let accum_offset = if has_accumulators {
        let offset = kernel.descriptor.get("accum_offset").ok_or_else(|| fail("explicit AGPRs require an accum_offset descriptor to establish unified-register aliases".into()))?;
        if offset == 0 || offset > 256 || !offset.is_multiple_of(4) {
            return Err(fail(
                "accum_offset must be a multiple of four in 4..=256".into(),
            ));
        }
        Some(offset)
    } else {
        None
    };
    for register in registers {
        let end = u64::from(register.index) + u64::from(register.count);
        match register.class {
            super::RegisterClass::Scalar => {
                if kernel
                    .descriptor
                    .get("next_free_sgpr")
                    .is_some_and(|count| end > count)
                {
                    return Err(fail(format!(
                        "SGPR operand s{}..{} exceeds next_free_sgpr",
                        register.index,
                        end - 1
                    )));
                }
            }
            super::RegisterClass::Vector => {
                if kernel
                    .descriptor
                    .get("next_free_vgpr")
                    .is_some_and(|count| end > count)
                {
                    return Err(fail(format!(
                        "VGPR operand v{}..{} exceeds next_free_vgpr",
                        register.index,
                        end - 1
                    )));
                }
                if accum_offset.is_some_and(|offset| end > offset) {
                    return Err(fail("explicit VGPR aliases an AGPR physical allocation; overlapping unified register names are unsupported".into()));
                }
            }
            super::RegisterClass::Accumulator => {
                if let (Some(offset), Some(count)) =
                    (accum_offset, kernel.descriptor.get("next_free_vgpr"))
                    && offset + end > count
                {
                    return Err(fail(
                        "AGPR operand exceeds unified next_free_vgpr allocation".into(),
                    ));
                }
            }
            super::RegisterClass::Special => {}
        }
    }
    if kernel.descriptor.flag("tg_split")
        && kernel.instructions.iter().any(|instruction| {
            matches!(
                instruction.opcode,
                super::Opcode::Lds | super::Opcode::Barrier
            )
        })
    {
        return Err(fail(
            "tg_split kernels cannot use LDS or workgroup barriers".into(),
        ));
    }
    Ok(())
}

/// Used by metadata consistency checks without exposing parser implementation.
pub(super) fn merge_descriptor_fields(
    kernel: &mut Kernel,
    fields: BTreeMap<String, u64>,
    span: SourceSpan,
) -> Result<(), ParseError> {
    for (name, value) in fields {
        if kernel.descriptor.get(&name).is_some_and(|old| old != value) {
            return Err(ParseError {
                message: format!(
                    "metadata disagrees with `{}` descriptor field `{name}`",
                    kernel.name
                ),
                span,
            });
        }
        kernel.descriptor.fields.entry(name).or_insert(value);
    }
    Ok(())
}
