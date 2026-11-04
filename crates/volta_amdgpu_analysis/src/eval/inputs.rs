//! Input defaults are materialized on access; allocation bounds remain in the config.
use super::{
    memory::Memory,
    value::{Value, WideKind},
};
use crate::config::{ArrayDef, ArrayKind};
use std::collections::{BTreeMap, BTreeSet};
use volta_expr::{ExprArena, StringId};

#[derive(Debug)]
struct InputRegion {
    array: usize,
    name: StringId,
    // Cell starts can disappear after stores split or replace a granule. This
    // independent history prevents a later access from resurrecting defaults.
    materialized: BTreeSet<u64>,
}

#[derive(Debug, Default)]
pub(super) struct InputBacking {
    regions: BTreeMap<u64, InputRegion>,
}

impl InputBacking {
    // Interpreter::new has validated widths, nonempty/checked extents and
    // disjoint array regions before constructing this backing.
    pub fn new(arrays: &[ArrayDef], arena: &mut ExprArena) -> Self {
        Self {
            regions: arrays
                .iter()
                .enumerate()
                .filter(|(_, a)| a.kind.is_input())
                .map(|(array, a)| {
                    (
                        a.base,
                        InputRegion {
                            array,
                            name: arena.intern_string(&a.name),
                            materialized: BTreeSet::new(),
                        },
                    )
                })
                .collect(),
        }
    }

    /// Called before both reads and writes, after instruction allocation checks.
    /// Initialize entire elements so partial stores retain the existing granule
    /// rules, including refusals for unknown bit reinterpretations.
    pub fn ensure(
        &mut self,
        arrays: &[ArrayDef],
        memory: &mut Memory,
        arena: &mut ExprArena,
        addr: u64,
        width: u64,
    ) -> Result<(), String> {
        if width == 0 {
            return Err("input access has zero width".into());
        }
        let Some((&base, region)) = self.regions.range_mut(..=addr).next_back() else {
            return Ok(());
        };
        let array = &arrays[region.array];
        let offset = addr - base;
        let size = array.size_bytes();
        if offset >= size {
            return Ok(());
        }
        if width > size - offset {
            return Err("input access crosses allocation boundaries".into());
        }
        let first = offset / array.elem_width;
        let last = (offset + width - 1) / array.elem_width;
        for index in first..=last {
            if region.materialized.insert(index) {
                initialize_element(memory, arena, array, region.name, index);
            }
        }
        Ok(())
    }

    /// The previous full-array setup, deliberately independent of lazy lookup.
    /// Only small test fixtures use it; there is no public execution mode.
    #[cfg(test)]
    pub fn initialize_eager(
        &mut self,
        arrays: &[ArrayDef],
        memory: &mut Memory,
        arena: &mut ExprArena,
    ) {
        for array in arrays.iter().filter(|a| a.kind.is_input()) {
            let region = self.regions.get_mut(&array.base).unwrap();
            for index in 0..array.len {
                initialize_element(memory, arena, array, region.name, index);
                region.materialized.insert(index);
            }
        }
    }
}

fn initialize_element(
    memory: &mut Memory,
    arena: &mut ExprArena,
    array: &ArrayDef,
    name: StringId,
    index: u64,
) {
    let addr = array.base + index * array.elem_width;
    if array.elem_width == 8 {
        let (expr, kind) = if array.kind == ArrayKind::IndexInput {
            (arena.int(index as i64), WideKind::Integer)
        } else {
            (arena.input_element(name, index), WideKind::Input)
        };
        for high in [false, true] {
            memory.initialize(
                addr + u64::from(high) * 4,
                4,
                Value::WidePart { expr, high, kind },
            );
        }
    } else {
        let value = if array.kind == ArrayKind::IndexInput {
            Value::Integer(index as u32)
        } else {
            let expr = arena.input_element(name, index);
            match array.elem_width {
                1 => Value::Byte(expr),
                2 => Value::Half(expr),
                _ => Value::Input(expr),
            }
        };
        memory.initialize(addr, array.elem_width, value);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use volta_expr::ExprNode;

    #[test]
    fn initial_value_forms_and_linked_wide_parts_are_exact() {
        for kind in [
            ArrayKind::Input,
            ArrayKind::InputOutput,
            ArrayKind::IndexInput,
        ] {
            for width in [1, 2, 4, 8] {
                let array = ArrayDef {
                    name: "x".into(),
                    base: 0x10000,
                    elem_width: width,
                    len: 8,
                    kind,
                };
                let mut arena = ExprArena::new();
                let name = arena.intern_string("x");
                let mut memory = Memory::default();
                initialize_element(&mut memory, &mut arena, &array, name, 3);
                let addr = array.base + 3 * width;
                if width == 8 {
                    let Value::WidePart {
                        expr,
                        high: false,
                        kind: actual,
                    } = memory.read(addr, 4).unwrap()
                    else {
                        panic!("low wide word")
                    };
                    assert_eq!(
                        actual,
                        if kind == ArrayKind::IndexInput {
                            WideKind::Integer
                        } else {
                            WideKind::Input
                        }
                    );
                    assert_eq!(
                        memory.read(addr + 4, 4).unwrap(),
                        Value::WidePart {
                            expr,
                            high: true,
                            kind: actual
                        }
                    );
                    if kind == ArrayKind::IndexInput {
                        assert_eq!(arena.as_int_const(expr), Some(3));
                    } else {
                        assert!(
                            matches!(arena.node(expr),ExprNode::InputElement{array,index:3}if arena.string(*array)=="x")
                        );
                    }
                } else if kind == ArrayKind::IndexInput {
                    assert_eq!(memory.read(addr, width).unwrap(), Value::Integer(3));
                } else {
                    let expr = match (width, memory.read(addr, width).unwrap()) {
                        (1, Value::Byte(expr))
                        | (2, Value::Half(expr))
                        | (4, Value::Input(expr)) => expr,
                        other => panic!("incorrect initial value {other:?}"),
                    };
                    assert!(
                        matches!(arena.node(expr),ExprNode::InputElement{array,index:3}if arena.string(*array)=="x")
                    );
                }
                assert!(
                    memory.written.is_empty(),
                    "initialization is not a program store"
                );
                assert!(memory.read(array.base, width.min(4)).is_err());
            }
        }
    }

    #[test]
    fn one_array_identity_survives_sparse_touch_order_and_full_stores() {
        let arrays = [ArrayDef {
            name: "x".into(),
            base: 0x10000,
            elem_width: 4,
            len: 4,
            kind: ArrayKind::InputOutput,
        }];
        let mut arena = ExprArena::new();
        let mut memory = Memory::default();
        let mut input = InputBacking::new(&arrays, &mut arena);
        assert_eq!(arena.node_count(), 0);
        for index in [3, 1, 3] {
            input
                .ensure(&arrays, &mut memory, &mut arena, 0x10000 + 4 * index, 4)
                .unwrap();
        }
        assert_eq!(arena.node_count(), 2);
        let Value::Input(a) = memory.read(0x1000c, 4).unwrap() else {
            panic!("input")
        };
        let Value::Input(b) = memory.read(0x10004, 4).unwrap() else {
            panic!("input")
        };
        let (ExprNode::InputElement { array: a, .. }, ExprNode::InputElement { array: b, .. }) =
            (arena.node(a), arena.node(b))
        else {
            panic!("identity")
        };
        assert_eq!(a, b, "format ownership is shared across all indices");
        memory.write(0x10004, 4, Value::Integer(91)).unwrap();
        input
            .ensure(&arrays, &mut memory, &mut arena, 0x10004, 4)
            .unwrap();
        assert_eq!(memory.read(0x10004, 4).unwrap(), Value::Integer(91));
        assert_eq!(input.regions[&0x10000].materialized.len(), 2);
        assert_eq!(memory.written.get(&0x10004), Some(&4));
    }
}
