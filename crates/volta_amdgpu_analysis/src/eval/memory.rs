//! Byte-addressed memory with explicit symbolic granules. Unknown bit casts fail closed.
use super::value::Value;
use std::collections::BTreeMap;
use volta_expr::{ExprArena, ExprId};

#[derive(Debug, Clone, Copy)]
struct Cell {
    width: u64,
    value: Value,
}

#[derive(Debug, Default)]
pub(super) struct Memory {
    cells: BTreeMap<u64, Cell>,
    pub written: BTreeMap<u64, u64>,
}

impl Memory {
    pub fn initialize(&mut self, addr: u64, width: u64, value: Value) {
        self.cells.insert(addr, Cell { width, value });
    }

    pub fn read(&self, addr: u64, width: u64) -> Result<Value, String> {
        if let Some(cell) = self.cells.get(&addr) {
            if cell.width == width {
                return Ok(cell.value);
            }
        }
        if width == 4 {
            let bytes: Option<Vec<_>> = (0..4)
                .map(|index| match self.cells.get(&(addr + index)) {
                    Some(Cell {
                        width: 1,
                        value: Value::Byte(value),
                    }) => Some(*value),
                    _ => None,
                })
                .collect();
            if let Some(bytes) = bytes {
                return Ok(Value::Bytes(bytes.try_into().unwrap()));
            }
            if let (Some(lo), Some(hi)) = (self.cells.get(&addr), self.cells.get(&(addr + 2))) {
                if lo.width == 2 && hi.width == 2 {
                    if let (Value::BytePair(a, b), Value::BytePair(c, d)) = (lo.value, hi.value) {
                        return Ok(Value::Bytes([a, b, c, d]));
                    }
                    if let (Value::Half(lo), Value::Half(hi)) = (lo.value, hi.value) {
                        return Ok(Value::Halves(lo, hi));
                    }
                }
            }
        }
        if width == 2 {
            if let (Some(lo), Some(hi)) = (self.cells.get(&addr), self.cells.get(&(addr + 1))) {
                if lo.width == 1 && hi.width == 1 {
                    if let (Value::Byte(a), Value::Byte(b)) = (lo.value, hi.value) {
                        return Ok(Value::BytePair(a, b));
                    }
                }
            }
            if let Some((&start, cell)) = self.cells.range(..=addr).next_back() {
                if let Value::Halves(lo, hi) = cell.value {
                    if cell.width == 4 && (addr == start || addr == start + 2) {
                        return Ok(Value::Half(if addr == start { lo } else { hi }));
                    }
                }
                if let Value::PartialHalves(lo, hi) = cell.value {
                    if cell.width == 4 && (addr == start || addr == start + 2) {
                        return if addr == start { lo } else { hi }
                            .map(Value::Half)
                            .ok_or_else(|| {
                                "read of unknown half after partial register write".into()
                            });
                    }
                }
            }
        }
        if width == 1 {
            if let Some((
                &start,
                Cell {
                    width,
                    value: Value::BytePair(a, b),
                },
            )) = self.cells.range(..=addr).next_back()
            {
                if addr - start < *width {
                    return Ok(match addr - start {
                        0 => Value::Byte(*a),
                        1 => Value::Byte(*b),
                        _ => Value::Bits(0),
                    });
                }
            }
            if let Some((
                &start,
                Cell {
                    width: 4,
                    value: Value::Bytes(bytes),
                },
            )) = self.cells.range(..=addr).next_back()
            {
                if addr - start < 4 {
                    return Ok(Value::Byte(bytes[(addr - start) as usize]));
                }
            }
        }
        // Concrete fields may be read at any supported smaller width or combined.
        let mut result = 0u32;
        if width > 4 {
            return Err("memory granule wider than one register".into());
        }
        for offset in 0..width {
            let byte_addr = addr.checked_add(offset).ok_or("address overflow")?;
            let (&start, cell) = self
                .cells
                .range(..=byte_addr)
                .next_back()
                .ok_or_else(|| format!("uninitialized byte at {byte_addr:#x}"))?;
            let displacement = byte_addr - start;
            if displacement >= cell.width {
                return Err(format!("uninitialized byte at {byte_addr:#x}"));
            }
            let bits = cell.value.bits().map_err(|_| {
                format!(
                    "unsupported partial reinterpretation of symbolic {}-byte value at {start:#x}",
                    cell.width
                )
            })?;
            result |= (((bits as u64 >> (8 * displacement)) & 255) as u32) << (8 * offset);
        }
        Ok(Value::Bits(result))
    }

    /// Preserve holes in a native kernarg load instead of assigning values to
    /// padding. This path is deliberately not used for ordinary global/LDS
    /// memory: uninitialized data reads there retain their existing errors.
    pub fn read_partial_abi(&self, addr: u64, width: u64) -> Result<Value, String> {
        if width == 0 || width > 4 {
            return Err("partial ABI load must fit in one register".into());
        }
        let mut bits = 0u32;
        let mut defined = 0u32;
        for byte in 0..width {
            let byte_addr = addr.checked_add(byte).ok_or("ABI address overflow")?;
            if let Some((&start, cell)) = self.cells.range(..=byte_addr).next_back() {
                let displacement = byte_addr - start;
                if displacement < cell.width {
                    let selected = cell.value.selected_bits((8 * displacement) as u32, 8)?;
                    bits |= selected << (8 * byte);
                    defined |= 255 << (8 * byte);
                }
            }
        }
        if defined == 0 {
            return Err(format!("uninitialized ABI word at {addr:#x}"));
        }
        let mask = u32::MAX >> (32 - 8 * width);
        Ok(if defined == mask {
            Value::Bits(bits)
        } else {
            Value::PartialBits { bits, defined }
        })
    }

    pub fn write(&mut self, addr: u64, width: u64, value: Value) -> Result<Value, String> {
        let value = match (width, value) {
            (1, Value::BytePair(lo, _)) => Value::Byte(lo),
            (1 | 2, value @ Value::PartialBits { .. }) => {
                Value::Bits(value.selected_bits(0, (8 * width) as u32)?)
            }
            (_, Value::PartialBits { .. }) => {
                return Err("store observes undefined bits from ABI padding".into());
            }
            (_, Value::SharedApertureHi) => {
                return Err("opaque shared aperture cannot be stored as data bits".into());
            }
            (_, Value::RelocationWord { .. }) => {
                return Err("opaque PC relocation cannot be stored as data bits".into());
            }
            (_, Value::PredicateWord { .. }) => {
                return Err("symbolic predicate mask cannot be stored as data bits".into());
            }
            (1, Value::Bytes(bytes)) => Value::Byte(bytes[0]),
            (1 | 2, Value::Bits(bits)) => Value::Bits(bits & ((1u32 << (8 * width)) - 1)),
            (1 | 2, Value::Integer(bits)) => Value::Integer(bits & ((1u32 << (8 * width)) - 1)),
            (1 | 2, Value::SignedInteger(bits)) => {
                Value::Integer(bits as u32 & ((1u32 << (8 * width)) - 1))
            }
            (2, Value::Halves(lo, _)) => Value::Half(lo),
            (2, Value::PartialHalves(Some(lo), _)) => Value::Half(lo),
            (2, Value::PartialHalves(None, _) | Value::Byte(_) | Value::Bytes(_)) => {
                return Err("unsupported packed-byte/unknown-half reinterpretation".into());
            }
            (
                2,
                Value::Real(_)
                | Value::Input(_)
                | Value::IntExpr(_)
                | Value::NarrowInt { .. }
                | Value::WidePart { .. },
            ) => {
                return Err(
                    "partial f32-to-f16 bit reinterpretation is unsupported; convert first".into(),
                );
            }
            (
                1,
                Value::Real(_)
                | Value::Input(_)
                | Value::IntExpr(_)
                | Value::NarrowInt { .. }
                | Value::WidePart { .. }
                | Value::Half(_)
                | Value::Halves(..)
                | Value::PartialHalves(..),
            ) => return Err("symbolic byte truncation is unsupported".into()),
            (_, value) => value,
        };
        let end = addr.checked_add(width).ok_or("address overflow")?;
        // Cells never overlap: only the preceding cell can begin below addr
        // and still intersect this write. Scanning every lower address makes
        // stores to an output allocation repeatedly walk all symbolic inputs.
        let predecessor = self
            .cells
            .range(..addr)
            .next_back()
            .filter(|(start, cell)| **start + cell.width > addr)
            .map(|(&start, cell)| (start, *cell));
        let overlapping: Vec<_> = predecessor
            .into_iter()
            .chain(
                self.cells
                    .range(addr..end)
                    .map(|(&start, cell)| (start, *cell)),
            )
            .collect();
        for (start, cell) in overlapping {
            let old_end = start + cell.width;
            if start < addr || old_end > end {
                if cell.width == 4 && width == 2 && (addr == start || addr == start + 2) {
                    if let Value::Halves(lo, hi) = cell.value {
                        self.cells.remove(&start);
                        if addr == start {
                            self.initialize(start + 2, 2, Value::Half(hi));
                        } else {
                            self.initialize(start, 2, Value::Half(lo));
                        }
                        continue;
                    }
                }
                if cell.width == 2 && width == 1 && (addr == start || addr == start + 1) {
                    if let Value::BytePair(lo, hi) = cell.value {
                        self.cells.remove(&start);
                        self.initialize(
                            if addr == start { start + 1 } else { start },
                            1,
                            Value::Byte(if addr == start { hi } else { lo }),
                        );
                        continue;
                    }
                }
                // Preserve untouched concrete bytes. Partial writes into symbolic f32 storage
                // cannot preserve its exact bit representation in the real arithmetic model.
                let bits = cell
                    .value
                    .bits()
                    .map_err(|_| "partial overwrite of a symbolic granule is unsupported")?;
                self.cells.remove(&start);
                for byte in 0..cell.width {
                    if start + byte < addr || start + byte >= end {
                        self.initialize(start + byte, 1, Value::Bits((bits >> (8 * byte)) & 255));
                    }
                }
            } else {
                self.cells.remove(&start);
            }
        }
        self.initialize(addr, width, value);
        let mut written_start = addr;
        let mut written_end = end;
        let predecessor = self
            .written
            .range(..addr)
            .next_back()
            .filter(|(start, size)| **start + **size >= addr)
            .map(|(&start, &size)| (start, size));
        let merged: Vec<_> = predecessor
            .into_iter()
            .chain(
                self.written
                    .range(addr..=end)
                    .map(|(&start, &size)| (start, size)),
            )
            .collect();
        for (start, size) in merged {
            written_start = written_start.min(start);
            written_end = written_end.max(start + size);
            self.written.remove(&start);
        }
        self.written
            .insert(written_start, written_end - written_start);
        Ok(value)
    }

    pub fn expression(
        &self,
        addr: u64,
        width: u64,
        arena: &mut ExprArena,
    ) -> Result<ExprId, String> {
        if width == 8 {
            return match (self.read(addr, 4)?, self.read(addr + 4, 4)?) {
                (Value::Integer(lo), Value::Integer(hi)) => {
                    let value = lo as u64 | ((hi as u64) << 32);
                    // IntConst's arithmetic deliberately wraps at i64. Values
                    // in the upper half of u64 need an exact positive rational
                    // atom instead of an overflowing intermediate multiply.
                    Ok(match i64::try_from(value) {
                        Ok(value) => arena.int(value),
                        Err(_) => {
                            arena.real(volta_expr::Real::from_rational(rug::Rational::from(value)))
                        }
                    })
                }
                (
                    Value::WidePart {
                        expr: a,
                        high: false,
                        kind: ak,
                    },
                    Value::WidePart {
                        expr: b,
                        high: true,
                        kind: bk,
                    },
                ) if a == b && ak == bk => Ok(a),
                _ => Err(
                    "64-bit output requires matching ordered words of one mathematical value"
                        .into(),
                ),
            };
        }
        match self.read(addr, width)? {
            Value::Input(expr) | Value::IntExpr(expr) | Value::NarrowInt{expr,..} | Value::Real(expr) | Value::Half(expr)|Value::Byte(expr) => Ok(expr),
            Value::Integer(bits) => Ok(arena.int(bits as i64)),
            Value::SignedInteger(value)=>Ok(arena.int(value as i64)),
            Value::Bits(0) => Ok(arena.int(0)),
            Value::Bits(_) => Err("raw register bits have ambiguous integer/float output type; convert explicitly before storing".into()),
            Value::PartialBits { .. } => Err("output observes undefined bits from ABI padding".into()),
            Value::Halves(..)|Value::BytePair(..) => Err("packed output needs element-width extraction".into()),
            Value::PartialHalves(..)|Value::Bytes(..)=>Err("packed/partially initialized output needs element-width extraction".into()),
            Value::WidePart { .. } => Err("one word of a 64-bit mathematical value cannot be extracted as a scalar32".into()),
            Value::PredicateWord { .. } => Err("symbolic predicate mask cannot be extracted as data bits".into()),
            Value::RelocationWord { .. } => Err("opaque PC relocation cannot be extracted as data bits".into()),
            Value::SharedApertureHi => Err("opaque shared aperture cannot be extracted as data bits".into()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encoded_byte_pairs_roundtrip_at_two_bytes_without_defining_neighbor_memory() {
        let mut arena = ExprArena::new();
        let name = arena.intern_string("bytes");
        let a = arena.input_element(name, 0);
        let b = arena.input_element(name, 1);
        let c = arena.input_element(name, 2);
        let mut memory = Memory::default();
        memory.initialize(0, 1, Value::Byte(a));
        memory.initialize(1, 1, Value::Byte(b));
        let pair = memory.read(0, 2).unwrap();
        assert_eq!(pair, Value::BytePair(a, b));
        assert!(memory.read(0, 4).is_err());
        assert!(memory.read(2, 1).unwrap_err().contains("uninitialized"));
        memory.write(100, 2, pair).unwrap();
        assert_eq!(memory.read(100, 1).unwrap(), Value::Byte(a));
        assert_eq!(memory.read(101, 1).unwrap(), Value::Byte(b));
        memory.write(100, 1, Value::Byte(c)).unwrap();
        assert_eq!(memory.read(100, 2).unwrap(), Value::BytePair(c, b));
        assert!(memory.read(102, 1).unwrap_err().contains("uninitialized"));
    }

    #[test]
    fn partial_abi_words_preserve_padding_definedness_until_exact_selection() {
        let mut memory = Memory::default();
        memory.initialize(28, 2, Value::Bits((-3i16) as u16 as u32));
        memory.initialize(30, 1, Value::Bits(250));
        assert!(memory.read(28, 4).unwrap_err().contains("uninitialized"));
        let partial = memory.read_partial_abi(28, 4).unwrap();
        assert_eq!(
            partial,
            Value::PartialBits {
                bits: 0x00fa_fffd,
                defined: 0x00ff_ffff
            }
        );
        assert_eq!(partial.selected_bits(0, 16).unwrap(), 0xfffd);
        assert_eq!(partial.selected_bits(16, 8).unwrap(), 250);
        assert!(
            partial
                .selected_bits(24, 8)
                .unwrap_err()
                .contains("undefined")
        );
        assert!(partial.bits().unwrap_err().contains("undefined"));
        assert!(
            memory
                .write(100, 4, partial)
                .unwrap_err()
                .contains("undefined")
        );
        memory.write(100, 2, partial).unwrap();
        assert_eq!(memory.read(100, 2).unwrap().bits().unwrap(), 0xfffd);
        assert!(
            memory
                .read_partial_abi(32, 4)
                .unwrap_err()
                .contains("uninitialized")
        );
        memory.initialize(31, 1, Value::Bits(0xab));
        assert_eq!(
            memory.read_partial_abi(28, 4).unwrap(),
            Value::Bits(0xabfa_fffd)
        );
    }

    #[test]
    fn overlapping_concrete_writes_match_an_independent_byte_memory() {
        let mut memory = Memory::default();
        let mut expected = [0u8; 256];
        let mut written = [false; 256];
        for (address, byte) in expected.iter_mut().enumerate() {
            *byte = address as u8;
            memory.initialize(address as u64, 1, Value::Bits(*byte as u32));
        }
        let mut state = 0x9283_7165u32;
        for _ in 0..512 {
            state = state.wrapping_mul(1664525).wrapping_add(1013904223);
            let width = 1usize << (state as usize % 3);
            let address = 64 + ((state >> 8) as usize % 128);
            let bits = state.rotate_left(13);
            memory
                .write(address as u64, width as u64, Value::Bits(bits))
                .unwrap();
            for offset in 0..width {
                expected[address + offset] = (bits >> (8 * offset)) as u8;
                written[address + offset] = true;
            }
            for address in 0..256 {
                assert_eq!(
                    memory.read(address as u64, 1).unwrap().bits().unwrap(),
                    u32::from(expected[address])
                );
                let actual_written = memory
                    .written
                    .range(..=address as u64)
                    .next_back()
                    .is_some_and(|(&start, &size)| address as u64 - start < size);
                assert_eq!(actual_written, written[address], "written byte {address}");
            }
            let cells: Vec<_> = memory.cells.iter().collect();
            assert!(
                cells
                    .windows(2)
                    .all(|pair| pair[0].0 + pair[0].1.width <= *pair[1].0)
            );
        }
    }

    #[test]
    fn partial_half_overwrite_preserves_the_other_symbolic_half_and_neighbors() {
        let mut arena = ExprArena::new();
        let name = arena.intern_string("x");
        let lo = arena.input_element(name, 0);
        let hi = arena.input_element(name, 1);
        let replacement = arena.input_element(name, 2);
        let mut memory = Memory::default();
        memory.initialize(0, 4, Value::Bits(0x12345678));
        memory.initialize(100, 4, Value::Halves(lo, hi));
        memory.initialize(200, 4, Value::Bits(0xabcdef01));
        memory.write(100, 2, Value::Half(replacement)).unwrap();
        assert!(matches!(memory.read(100, 2).unwrap(), Value::Half(value) if value == replacement));
        assert!(matches!(memory.read(102, 2).unwrap(), Value::Half(value) if value == hi));
        assert_eq!(memory.read(0, 4).unwrap().bits().unwrap(), 0x12345678);
        assert_eq!(memory.read(200, 4).unwrap().bits().unwrap(), 0xabcdef01);
        assert!(
            memory
                .write(103, 1, Value::Bits(7))
                .unwrap_err()
                .contains("partial overwrite of a symbolic granule")
        );
    }
}
