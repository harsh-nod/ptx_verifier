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
            if let (Some(lo), Some(hi)) = (self.cells.get(&addr), self.cells.get(&(addr + 2))) {
                if lo.width == 2 && hi.width == 2 {
                    if let (Value::Half(lo), Value::Half(hi)) = (lo.value, hi.value) {
                        return Ok(Value::Halves(lo, hi));
                    }
                }
            }
        }
        if width == 2 {
            if let Some((&start, cell)) = self.cells.range(..=addr).next_back() {
                if let Value::Halves(lo, hi) = cell.value {
                    if cell.width == 4 && (addr == start || addr == start + 2) {
                        return Ok(Value::Half(if addr == start { lo } else { hi }));
                    }
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

    pub fn write(&mut self, addr: u64, width: u64, value: Value) -> Result<(), String> {
        let value=match (width,value) {
            (2,Value::Halves(lo,_))=>Value::Half(lo),
            (2,Value::Real(_))=>return Err("partial f32-to-f16 bit reinterpretation is unsupported; convert first".into()),
            (1,Value::Real(_)|Value::Half(_)|Value::Halves(..))=>return Err("symbolic byte truncation is unsupported".into()),
            (_,value)=>value,
        };
        let end = addr.checked_add(width).ok_or("address overflow")?;
        let overlapping: Vec<_> = self
            .cells
            .range(..end)
            .filter_map(|(&start, cell)| (start + cell.width > addr).then_some((start, *cell)))
            .collect();
        for (start, cell) in overlapping {
            let old_end = start + cell.width;
            if start < addr || old_end > end {
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
        let mut written_start=addr;let mut written_end=end;
        let merged:Vec<_>=self.written.range(..=end).filter_map(|(&start,&size)|(start+size>=addr).then_some((start,size))).collect();
        for (start,size) in merged {written_start=written_start.min(start);written_end=written_end.max(start+size);self.written.remove(&start);}
        self.written.insert(written_start,written_end-written_start);
        Ok(())
    }

    pub fn expression(
        &self,
        addr: u64,
        width: u64,
        arena: &mut ExprArena,
    ) -> Result<ExprId, String> {
        match self.read(addr, width)? {
            Value::Real(expr) | Value::Half(expr) => Ok(expr),
            Value::Integer(bits) => Ok(arena.int(bits as i64)),
            Value::Bits(0) => Ok(arena.int(0)),
            Value::Bits(_) => Err("raw register bits have ambiguous integer/float output type; convert explicitly before storing".into()),
            Value::Halves(..) => Err("packed output needs element-width extraction".into()),
        }
    }
}
