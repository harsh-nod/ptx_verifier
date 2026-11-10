//! Native lane register storage. A row is allocated only after its first write.
//!
//! Architectural register numbers and lane numbers already form a bounded dense
//! address. Keep an explicit `None` per lane so allocating a row never defines
//! another lane, including inactive lanes of partial waves. Lowering has already
//! validated the physical register indices (0..256); the pointer table grows to
//! the highest touched register, without allocating rows for the intervening holes.

use super::value::Value;

#[derive(Debug, Clone, PartialEq)]
pub(super) struct LaneRegisters {
    width: usize,
    rows: Vec<Option<Box<[Option<Value>]>>>,
}

impl LaneRegisters {
    pub fn new(width: u32) -> Self {
        Self {
            width: width as usize,
            rows: Vec::new(),
        }
    }

    pub fn get(&self, &(register, lane): &(u16, u8)) -> Option<&Value> {
        self.rows
            .get(register as usize)?
            .as_ref()?
            .get(lane as usize)?
            .as_ref()
    }

    pub fn insert(&mut self, (register, lane): (u16, u8), value: Value) -> Option<Value> {
        let register = register as usize;
        if self.rows.len() <= register {
            self.rows.resize_with(register + 1, || None);
        }
        let row =
            self.rows[register].get_or_insert_with(|| vec![None; self.width].into_boxed_slice());
        row[lane as usize].replace(value)
    }

    #[cfg(test)]
    pub fn remove(&mut self, &(register, lane): &(u16, u8)) -> Option<Value> {
        self.rows
            .get_mut(register as usize)?
            .as_mut()?
            .get_mut(lane as usize)?
            .take()
    }
}

#[cfg(test)]
impl std::ops::Index<&(u16, u8)> for LaneRegisters {
    type Output = Value;

    fn index(&self, key: &(u16, u8)) -> &Self::Output {
        self.get(key).expect("uninitialized lane register")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::BTreeMap;

    #[test]
    fn writes_preserve_undefined_lanes_and_sparse_high_registers() {
        for width in [32, 64] {
            let mut actual = LaneRegisters::new(width);
            let mut expected = BTreeMap::new();
            for register in [0, 255, 1, 127, 63] {
                for lane in (0..width as u8).step_by(3) {
                    let key = (register, lane);
                    let value = Value::partial_bits(u32::from(register), 0xffff);
                    assert_eq!(actual.insert(key, value), expected.insert(key, value));
                }
            }
            for register in 0..256 {
                for lane in 0..width as u8 {
                    assert_eq!(
                        actual.get(&(register, lane)),
                        expected.get(&(register, lane))
                    );
                }
            }
            // A VOPD component computes against a snapshot. A write in either
            // snapshot must leave both the source and the other component alone.
            let source = actual.clone();
            let mut component = actual.clone();
            let key = (255, width as u8 - 1);
            let original = actual.get(&key).copied();
            component.insert(key, Value::Bits(0x1234));
            assert_eq!(actual.get(&key).copied(), original);
            assert_eq!(source.get(&key).copied(), original);
            actual.insert((1, 0), Value::Bits(0x5678));
            assert_ne!(actual.get(&(1, 0)), source.get(&(1, 0)));
            assert_ne!(actual.get(&(1, 0)), component.get(&(1, 0)));
        }
    }

    #[test]
    fn overwrites_and_removals_match_the_previous_storage() {
        for width in [32, 64] {
            let mut actual = LaneRegisters::new(width);
            let mut expected = BTreeMap::new();
            let mut state = 0x4e4154495645u64;
            for step in 0..4096 {
                state ^= state << 13;
                state ^= state >> 7;
                state ^= state << 17;
                let key = (
                    ((state >> 16) & 255) as u16,
                    (state % u64::from(width)) as u8,
                );
                if step % 7 == 0 {
                    assert_eq!(actual.remove(&key), expected.remove(&key));
                } else {
                    let value = Value::Bits(state as u32);
                    assert_eq!(actual.insert(key, value), expected.insert(key, value));
                }
                assert_eq!(actual.get(&key), expected.get(&key));
            }
            for register in 0..256 {
                for lane in 0..width as u8 {
                    assert_eq!(
                        actual.get(&(register, lane)),
                        expected.get(&(register, lane))
                    );
                }
            }
        }
    }

    #[test]
    fn sparse_high_registers_allocate_only_touched_rows_at_the_wave_width() {
        for width in [32, 64] {
            // Many waves must not eagerly allocate 256 complete register rows.
            let mut waves: Vec<_> = (0..32).map(|_| LaneRegisters::new(width)).collect();
            for bank in &mut waves {
                assert!(bank.rows.is_empty());
                bank.insert((255, 0), Value::Bits(9));
                assert_eq!(bank.rows.iter().flatten().count(), 1);
                assert_eq!(bank.rows[255].as_ref().unwrap().len(), width as usize);
                for lane in 1..width as u8 {
                    assert_eq!(bank.get(&(255, lane)), None);
                }
                assert_eq!(bank.get(&(254, 0)), None);
            }
        }
    }
}
