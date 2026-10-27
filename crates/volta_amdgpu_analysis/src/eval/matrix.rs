//! Stateless gfx950 dense MFMA mathematics and explicit lane/item layouts.
//!
//! CDNA4 ISA (5-Aug-2025) §7.1.4 defines ordinary inputs/outputs; §7.1.5
//! interleaves FP8 F8F6F4 inputs in groups of sixteen K values. The latter is
//! deliberately separate: applying the ordinary layout to FP8 K128 is wrong.
//! All arguments below are already decoded mathematical values. This module
//! does not reinterpret arbitrary symbolic bits or apply floating-point rounding.

use volta_expr::{ExprArena, ExprId};
use volta_graph::AmdMatrixKind;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum InputKind {
    F32,
    F16,
    Bf16,
    Fp8E4m3,
    Fp8E5m2,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct Form {
    pub m: usize,
    pub n: usize,
    pub k: usize,
    pub input_kind: InputKind,
    pub input_kind_b: InputKind,
    scaled: bool,
    interleaved_fp8: bool,
}

impl Form {
    pub fn from_mnemonic(name: &str) -> Option<Self> {
        use InputKind::*;
        let (m, k, input, scaled, interleaved_fp8) = match name {
            "v_mfma_f32_16x16x4_f32" | "v_mfma_f32_16x16x4f32" => (16, 4, F32, false, false),
            "v_mfma_f32_32x32x2_f32" | "v_mfma_f32_32x32x2f32" => (32, 2, F32, false, false),
            "v_mfma_f32_16x16x16_f16" | "v_mfma_f32_16x16x16f16" => (16, 16, F16, false, false),
            "v_mfma_f32_32x32x8_f16" | "v_mfma_f32_32x32x8f16" => (32, 8, F16, false, false),
            "v_mfma_f32_16x16x32_f16" => (16, 32, F16, false, false),
            "v_mfma_f32_32x32x16_f16" => (32, 16, F16, false, false),
            "v_mfma_f32_16x16x16_bf16" | "v_mfma_f32_16x16x16bf16_1k" => {
                (16, 16, Bf16, false, false)
            }
            "v_mfma_f32_32x32x8_bf16" | "v_mfma_f32_32x32x8bf16_1k" => (32, 8, Bf16, false, false),
            "v_mfma_f32_16x16x32_bf16" => (16, 32, Bf16, false, false),
            "v_mfma_f32_32x32x16_bf16" => (32, 16, Bf16, false, false),
            "v_mfma_f32_16x16x128_f8f6f4" => (16, 128, Fp8E4m3, false, true),
            "v_mfma_f32_32x32x64_f8f6f4" => (32, 64, Fp8E4m3, false, true),
            "v_mfma_scale_f32_16x16x128_f8f6f4" => (16, 128, Fp8E4m3, true, true),
            "v_mfma_scale_f32_32x32x64_f8f6f4" => (32, 64, Fp8E4m3, true, true),
            _ => return None,
        };
        Some(Self {
            m,
            n: m,
            k,
            input_kind: input,
            input_kind_b: input,
            scaled,
            interleaved_fp8,
        })
    }
    pub fn is_scaled(self) -> bool {
        self.scaled
    }
    pub fn input_items_per_lane(self) -> usize {
        self.m * self.k / 64
    }
    pub fn accumulator_items_per_lane(self) -> usize {
        self.m * self.n / 64
    }
    pub fn input_registers_per_operand(self) -> usize {
        let per_register = match self.input_kind {
            InputKind::F32 => 1,
            InputKind::F16 | InputKind::Bf16 => 2,
            InputKind::Fp8E4m3 | InputKind::Fp8E5m2 => 4,
        };
        self.input_items_per_lane() / per_register
    }
    /// F8F6F4 format controls: only the native OCP FP8/BF8 formats are supported.
    pub fn with_fp8_formats(mut self, cbsz: u8, blgp: u8) -> Option<Self> {
        if !self.interleaved_fp8 {
            return None;
        }
        let format = |value| match value {
            0 => Some(InputKind::Fp8E4m3),
            1 => Some(InputKind::Fp8E5m2),
            _ => None,
        };
        self.input_kind = format(cbsz)?;
        self.input_kind_b = format(blgp)?;
        Some(self)
    }
    pub fn graph_kind(self) -> AmdMatrixKind {
        use AmdMatrixKind::*;
        use InputKind::*;
        match (self.m, self.k, self.input_kind, self.scaled) {
            (16, 4, F32, _) => F32_16x16x4,
            (32, 2, F32, _) => F32_32x32x2,
            (16, 16, F16, _) => F16_16x16x16,
            (32, 8, F16, _) => F16_32x32x8,
            (16, 32, F16, _) => F16_16x16x32,
            (32, 16, F16, _) => F16_32x32x16,
            (16, 16, Bf16, _) => Bf16_16x16x16,
            (32, 8, Bf16, _) => Bf16_32x32x8,
            (16, 32, Bf16, _) => Bf16_16x16x32,
            (32, 16, Bf16, _) => Bf16_32x32x16,
            (16, 128, Fp8E4m3 | Fp8E5m2, false) => Fp8_16x16x128,
            (32, 64, Fp8E4m3 | Fp8E5m2, false) => Fp8_32x32x64,
            (16, 128, Fp8E4m3 | Fp8E5m2, true) => Fp8Scale_16x16x128,
            (32, 64, Fp8E4m3 | Fp8E5m2, true) => Fp8Scale_32x32x64,
            _ => unreachable!("Form is constructed from a pinned native instruction"),
        }
    }
    /// Location of A[row,k] (or B[k,column], replacing row by column).
    pub fn input_location(self, row: usize, k: usize) -> (usize, usize) {
        if self.interleaved_fp8 {
            let groups = 64 / self.m;
            (
                row + self.m * ((k / 16) % groups),
                k % 16 + 16 * (k / (16 * groups)),
            )
        } else {
            let items = self.input_items_per_lane();
            (row + self.m * (k / items), k % items)
        }
    }
    /// Matrix coordinate represented by an output register item in a lane.
    pub fn output_coordinate(self, lane: usize, item: usize) -> (usize, usize) {
        let rows_per_item = 64 / self.n;
        (
            (lane / self.n) * 4 + (item % 4) + (item / 4) * (4 * rows_per_item),
            lane % self.n,
        )
    }
}

/// Compute one complete wave's output, preserving each accumulator element.
/// Unit-scaled forms require the caller to validate the actual scale operands are
/// E8M0 exponent127; this function never silently chooses scale values.
pub(crate) fn compute(
    arena: &mut ExprArena,
    form: Form,
    a: &[Vec<ExprId>],
    b: &[Vec<ExprId>],
    c: &[Vec<ExprId>],
) -> Result<Vec<Vec<ExprId>>, String> {
    let inputs = form.input_items_per_lane();
    let outputs = form.accumulator_items_per_lane();
    if a.len() != 64
        || b.len() != 64
        || c.len() != 64
        || a.iter().chain(b).any(|r| r.len() != inputs)
        || c.iter().any(|r| r.len() != outputs)
    {
        return Err(format!(
            "MFMA requires wave64 with {inputs} input and {outputs} accumulator items per lane"
        ));
    }
    if a.iter()
        .chain(b)
        .chain(c)
        .flatten()
        .any(|&value| arena.as_f64(value).is_some_and(|value| !value.is_finite()))
    {
        return Err("MFMA mathematical arithmetic requires finite concrete operands".into());
    }
    let mut result = Vec::with_capacity(64);
    for lane in 0..64 {
        let mut row = Vec::with_capacity(outputs);
        for item in 0..outputs {
            let (i, j) = form.output_coordinate(lane, item);
            let mut value = c[lane][item];
            for k in 0..form.k {
                let (al, ai) = form.input_location(i, k);
                let (bl, bi) = form.input_location(j, k);
                let product = arena.mul(a[al][ai], b[bl][bi]);
                value = arena.add(value, product);
            }
            row.push(value);
        }
        result.push(row);
    }
    Ok(result)
}

/// Decode concrete packed values. Symbolic values must come from a typed storage
/// path; they cannot be converted by inventing their unknown bits.
pub(crate) fn decode_bits(kind: InputKind, bits: u32) -> Result<f64, String> {
    use InputKind::*;
    if kind == F32 {
        let value = f32::from_bits(bits) as f64;
        return if !value.is_finite() {
            Err("nonfinite value is outside mathematical MFMA arithmetic".into())
        } else {
            Ok(value)
        };
    }
    if kind == Bf16 {
        let value = f32::from_bits((bits & 0xffff) << 16) as f64;
        return if !value.is_finite() {
            Err("nonfinite BF16 is outside mathematical MFMA arithmetic".into())
        } else {
            Ok(value)
        };
    }
    let (exponent_bits, mantissa_bits, bias) = match kind {
        F16 => (5, 10, 15),
        Fp8E4m3 => (4, 3, 7),
        Fp8E5m2 => (5, 2, 15),
        _ => unreachable!(),
    };
    let sign = if bits & (1 << (exponent_bits + mantissa_bits)) == 0 {
        1.0
    } else {
        -1.0
    };
    let mantissa = bits & ((1 << mantissa_bits) - 1);
    let exponent = (bits >> mantissa_bits) & ((1 << exponent_bits) - 1);
    if exponent == (1 << exponent_bits) - 1 {
        if kind == Fp8E4m3 {
            if mantissa == 7 {
                return Err("OCP E4M3 NaN is outside mathematical MFMA arithmetic".into());
            }
        } else {
            return Err("nonfinite value is outside mathematical MFMA arithmetic".into());
        }
    }
    let fraction = mantissa as f64 / (1u32 << mantissa_bits) as f64;
    Ok(if exponent == 0 {
        sign * fraction * 2f64.powi(1 - bias)
    } else {
        sign * (1.0 + fraction) * 2f64.powi(exponent as i32 - bias)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const FORMS: [&str; 14] = [
        "v_mfma_f32_16x16x4_f32",
        "v_mfma_f32_32x32x2_f32",
        "v_mfma_f32_16x16x16_f16",
        "v_mfma_f32_32x32x8_f16",
        "v_mfma_f32_16x16x32_f16",
        "v_mfma_f32_32x32x16_f16",
        "v_mfma_f32_16x16x16_bf16",
        "v_mfma_f32_32x32x8_bf16",
        "v_mfma_f32_16x16x32_bf16",
        "v_mfma_f32_32x32x16_bf16",
        "v_mfma_f32_16x16x128_f8f6f4",
        "v_mfma_f32_32x32x64_f8f6f4",
        "v_mfma_scale_f32_16x16x128_f8f6f4",
        "v_mfma_scale_f32_32x32x64_f8f6f4",
    ];

    #[test]
    fn independent_dense_row_major_reference_covers_all_shapes_and_items() {
        // Pack independently by the manual's lane groups, then compare every
        // output with ordinary row-major loops. No production layout helper is
        // used to construct either side of this reference.
        for name in FORMS {
            let form = Form::from_mnemonic(name).unwrap();
            let mut arena = ExprArena::new();
            let mut a = vec![Vec::new(); 64];
            let mut b = vec![Vec::new(); 64];
            let mut c = vec![Vec::new(); 64];
            let av = |row: usize, k: usize| ((row * 13 + k * 7 + row * k) % 11) as i64 - 5;
            let bv = |k: usize, col: usize| ((col * 3 + k * 5 + col * k) % 13) as i64 - 6;
            for lane in 0..64 {
                for item in 0..form.input_items_per_lane() {
                    let k = if name.contains("f8f6f4") {
                        (lane / form.m) * 16 + item % 16 + (item / 16) * (64 / form.m) * 16
                    } else {
                        (lane / form.m) * form.input_items_per_lane() + item
                    };
                    a[lane].push(arena.int(av(lane % form.m, k)));
                    b[lane].push(arena.int(bv(k, lane % form.m)));
                }
                for item in 0..form.accumulator_items_per_lane() {
                    c[lane].push(arena.int((lane * 17 + item * 3) as i64));
                }
            }
            let output = compute(&mut arena, form, &a, &b, &c).unwrap();
            for lane in 0..64 {
                for item in 0..form.accumulator_items_per_lane() {
                    let row = if form.m == 16 {
                        lane / 16 * 4 + item
                    } else {
                        lane / 32 * 4 + item % 4 + item / 4 * 8
                    };
                    let col = lane % form.n;
                    let expected = (lane * 17 + item * 3) as i64
                        + (0..form.k).map(|k| av(row, k) * bv(k, col)).sum::<i64>();
                    assert_eq!(
                        arena.as_i64(output[lane][item]),
                        Some(expected),
                        "{name}, lane={lane}, item={item}, row={row}, col={col}"
                    );
                }
            }
            let kind = form.graph_kind();
            assert_eq!(
                kind.destination_registers(),
                form.accumulator_items_per_lane()
            );
            assert_eq!(kind.input_registers(), form.input_registers_per_operand());
            assert_eq!(kind.scale_registers(), if form.is_scaled() { 2 } else { 0 });
        }
    }

    #[test]
    fn fp8_manual_interleave_anchors_and_basis_crosses_k_groups() {
        let f = Form::from_mnemonic("v_mfma_scale_f32_16x16x128_f8f6f4").unwrap();
        assert_eq!(f.input_location(3, 0), (3, 0));
        assert_eq!(f.input_location(3, 16), (19, 0));
        assert_eq!(f.input_location(3, 63), (51, 15));
        assert_eq!(f.input_location(3, 64), (3, 16));
        assert_eq!(f.input_location(3, 127), (51, 31));
        assert_eq!(f.output_coordinate(49, 3), (15, 1));
        let f32 = Form::from_mnemonic("v_mfma_f32_32x32x64_f8f6f4").unwrap();
        assert_eq!(f32.input_location(31, 32), (31, 16));
        assert_eq!(f32.input_location(31, 63), (63, 31));
    }

    #[test]
    fn malformed_wave_dimensions_and_unmodeled_formats_are_rejected() {
        let f = Form::from_mnemonic(FORMS[0]).unwrap();
        let mut arena = ExprArena::new();
        assert!(compute(&mut arena, f, &[], &[], &[]).is_err());
        assert!(Form::from_mnemonic("v_smfmac_f32_16x16x32_f16").is_none());
        assert!(Form::from_mnemonic("v_mfma_f64_16x16x4_f64").is_none());
        assert!(f.with_fp8_formats(0, 0).is_none());
        let fp = Form::from_mnemonic(FORMS[10]).unwrap();
        for format in 2..8 {
            assert!(fp.with_fp8_formats(format, 0).is_none());
        }
        let mixed = fp.with_fp8_formats(1, 0).unwrap();
        assert_eq!(mixed.input_kind, InputKind::Fp8E5m2);
        assert_eq!(mixed.input_kind_b, InputKind::Fp8E4m3);
    }

    #[test]
    fn nonfinite_concrete_values_reject_in_every_matrix_operand() {
        let form = Form::from_mnemonic(FORMS[0]).unwrap();
        let mut arena = ExprArena::new();
        let zero = arena.int(0);
        let infinity = arena.float_from_f64(f64::INFINITY).unwrap();
        for operand in 0..3 {
            let mut a = vec![vec![zero]; 64];
            let mut b = a.clone();
            let mut c = vec![vec![zero; 4]; 64];
            match operand {
                0 => a[63][0] = infinity,
                1 => b[0][0] = infinity,
                _ => c[31][3] = infinity,
            }
            assert!(compute(&mut arena, form, &a, &b, &c).is_err());
        }
        for kind in [
            InputKind::F32,
            InputKind::F16,
            InputKind::Bf16,
            InputKind::Fp8E5m2,
        ] {
            let positive_infinity = match kind {
                InputKind::F32 => 0x7f800000,
                InputKind::F16 => 0x7c00,
                InputKind::Bf16 => 0x7f80,
                _ => 0x7c,
            };
            assert!(decode_bits(kind, positive_infinity).is_err());
        }
    }

    #[test]
    fn packed_ieee_and_ocp_decode_boundaries() {
        assert_eq!(decode_bits(InputKind::F16, 0x3c00).unwrap(), 1.0);
        assert_eq!(decode_bits(InputKind::F16, 0xbc00).unwrap(), -1.0);
        assert_eq!(decode_bits(InputKind::F16, 1).unwrap(), 2f64.powi(-24));
        assert_eq!(decode_bits(InputKind::F16, 0x7bff).unwrap(), 65504.0);
        assert_eq!(decode_bits(InputKind::Bf16, 0x3f80).unwrap(), 1.0);
        assert_eq!(decode_bits(InputKind::Bf16, 1).unwrap(), 2f64.powi(-133));
        assert_eq!(decode_bits(InputKind::Fp8E4m3, 0x38).unwrap(), 1.0);
        assert_eq!(decode_bits(InputKind::Fp8E4m3, 1).unwrap(), 2f64.powi(-9));
        assert_eq!(decode_bits(InputKind::Fp8E4m3, 0x7e).unwrap(), 448.0);
        assert_eq!(decode_bits(InputKind::Fp8E4m3, 0xfe).unwrap(), -448.0);
        assert_eq!(decode_bits(InputKind::Fp8E5m2, 0x3c).unwrap(), 1.0);
        assert_eq!(decode_bits(InputKind::Fp8E5m2, 1).unwrap(), 2f64.powi(-16));
        assert_eq!(decode_bits(InputKind::Fp8E5m2, 0x7b).unwrap(), 57344.0);
        assert!(decode_bits(InputKind::Fp8E5m2, 0x7c).is_err());
        assert!(decode_bits(InputKind::Fp8E4m3, 0x7f).is_err());
        assert!(decode_bits(InputKind::Fp8E4m3, 0xff).is_err());
        assert!(decode_bits(InputKind::Fp8E5m2, 0x7d).is_err());
        assert!(decode_bits(InputKind::F16, 0x7fff).is_err());
        assert!(decode_bits(InputKind::Bf16, 0x7fff).is_err());
    }
}
