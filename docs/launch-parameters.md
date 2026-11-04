# Kernel parameters and aggregate layouts

Arguments bind in kernel declaration order. A launch argument's optional `name`
is a label; it does not select a parameter or change its ABI offset. Arrays are
separate bounded allocations, and `ptr` names an array's configured base.

| Value form | Rust configuration | CLI launch JSON | Python |
| --- | --- | --- | --- |
| Integer, float, symbolic float, array pointer | `ParamValue::{Int, Float, SymFloat, ArrayPtr}` | `int`, `float`, `sym`, `ptr` | `Param.int`, `float`, `sym_float`, `array_ptr` |
| PTX by-value aggregate | `ParamValue::Struct` | `struct` | No constructor |
| Native AMD by-value payload | `ParamValue::Bytes` | `bytes` | `Param.bytes` |

CLI `--param` supports only `int:N`, `float:X`, `sym:name` and `ptr:array`.
Use `--config FILE` for aggregates or byte payloads. Each JSON argument has
exactly one value form. PTX rejects native `bytes`; native AMD rejects PTX
`struct` fields, including host tensor maps.

## PTX by-value fields

A PTX aggregate binds a declaration such as `.param .align 8 .b8 args[16]`.
Its fields specify byte offsets inside that parameter:

```json
{
  "block": 1,
  "arrays": [
    {"name": "x", "dtype": "f32", "shape": [16], "kind": "in"}
  ],
  "params": [{"name": "args", "struct": [
    {"offset": 0, "ptr": "x"},
    {"offset": 8, "u32": 16}
  ]}]
}
```

This describes the argument layout, not a complete kernel. Bytes 0–7 hold the
array pointer; bytes 8–11 hold the integer in little-endian order. Bytes 12–15
remain undefined. A load that observes an uncovered byte fails; omitted padding
does not become zero.

Each field has `offset` and one of `ptr`, an integer width, or `tensor_map`.
Integer keys include `u8/u16/u32/u64`, `s8/s16/s32/s64`, `b8/b16/b32/b64` and
the `i8/i16/i32/i64` aliases. These keys choose storage width; the value holds
two's-complement bits and must fit the corresponding signed-or-unsigned range.
A pointer field occupies eight bytes. Fields cannot overlap, overflow or extend
past the PTX parameter's declared size. A `struct` cannot bind a scalar parameter.

## Host tensor maps for PTX

A `tensor_map` field describes a host-encoded 128-byte TMA descriptor by its
semantic fields. For an aggregate declared with at least 128 bytes:

```json
{
  "block": 32,
  "arrays": [
    {"name": "x", "dtype": "f32", "shape": [4, 8], "kind": "in"}
  ],
  "params": [{"struct": [{"offset": 0, "tensor_map": {
    "array": "x", "dtype": "f32", "dims": [8, 4],
    "strides": [32], "box": [8, 4]
  }}]}]
}
```

`dims` lists sizes in elements, innermost first. `strides` gives byte strides
for every dimension except the innermost. Rank is 1–5. Supply exactly one of
`box` for a tiled map or `im2col` for its bounding-box fields. `element_strides`
defaults to one for each dimension; `swizzle`, `swizzle_atomicity`, `interleave`
and `fill` have explicit named modes. See
[the JSON schema](../crates/volta_ptx_analysis/src/launch_file.rs) for the current
mode spellings and im2col fields.

The interpreter keeps descriptor fields in a separate tensor-map table; it does
not invent readable descriptor bytes. Ordinary byte loads cannot inspect that
opaque encoding. Common configuration validates field ranges and vector lengths;
the selected PTX tensor operation also checks its descriptor, address, alignment
and transfer restrictions. A descriptor accepted by the launch reader does not
establish support for every TMA operation or mode.

This host format belongs to PTX. Native gfx1250 tensor instructions use their own
SGPR descriptor profiles; they do not consume a `CUtensorMap` through this API.

## Native AMD byte payloads

For an AMDHSA `by_value` argument, supply its exact metadata-sized byte sequence,
including padding, through `{"bytes": [0, 1, ...]}` or `Param.bytes(...)`.
Metadata determines argument offsets and sizes. Every supplied byte is concrete;
the interpreter does not reconstruct a source-language struct from member names.
Use the kernel's actual compiler ABI layout when packing the payload.

Rust callers use the shared types in `volta_common::config`; tensor-map enums
live in `volta_common::tensor_map`. `LaunchFile::from_json` is exposed by
`volta_ptx_analysis` and reads launch JSON for both backends. Python currently
has neither a structured-field constructor nor a launch-JSON loader.

The [usage guide](usage.md) covers geometry and complete output footprints.
Configuration validation and backend ABI checks are separate from graph safety
and mathematical equivalence; supplying a valid argument layout is not a kernel
verification result.
