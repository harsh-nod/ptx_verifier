#!/usr/bin/env python3
"""Independent ordinary CPU formulas and public lane/descriptor ABI packing.

This module never imports the Rust emulator, parser, or graph checker. Its
self-checks validate the oracle construction, not execution on gfx1250 hardware.
Lane edges are independently pinned to public FlyDSL MmaAtom.cpp at f37f7a2;
tensor descriptor fields are crosschecked with public LLVM 5fd50ec8 lowering.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct


def source_coordinate(lane, item, dtype):
    row = lane % 16
    k = (lane // 16) * 2 + item if dtype == "f32" else (item // 8) * 16 + (lane // 16) * 8 + item % 8
    return row, k


def output_coordinate(lane, item):
    return (lane // 16) * 8 + item, lane % 16


def pack_source(matrix, dtype):
    count = 2 if dtype == "f32" else 16
    return [matrix[row][k] for lane in range(32) for item in range(count)
            for row, k in [source_coordinate(lane, item, dtype)]]


def dense_gemm(a, b, c=None):
    """B is N-by-K, matching the native WMMA/GEMM fixture external ABI."""
    return [[sum(a[row][k] * b[col][k] for k in range(len(a[row]))) + (0 if c is None else c[row][col])
             for col in range(len(b))] for row in range(len(a))]


def pack_output(matrix):
    return [matrix[row][col] for lane in range(32) for item in range(8)
            for row, col in [output_coordinate(lane, item)]]


def wmma_from_raw(a, b, dtype, c=None):
    """Decode at the ABI edge, then use ordinary row-major CPU loops."""
    ksize, count = (4, 2) if dtype == "f32" else (32, 16)
    a_matrix = [[None] * ksize for _ in range(16)]
    b_matrix = [[None] * ksize for _ in range(16)]
    for lane in range(32):
        for item in range(count):
            row, k = source_coordinate(lane, item, dtype)
            a_matrix[row][k] = a[lane * count + item]
            b_matrix[row][k] = b[lane * count + item]
    c_matrix = None
    if c is not None:
        c_matrix = [[0] * 16 for _ in range(16)]
        for lane in range(32):
            for item in range(8):
                row, col = output_coordinate(lane, item)
                c_matrix[row][col] = c[lane * 8 + item]
    return pack_output(dense_gemm(a_matrix, b_matrix, c_matrix))


def tensor_descriptor(global_address, lds_address, inner=64, outer=1, stride=64):
    if not 0 <= global_address < 1 << 57:
        raise ValueError("tensor global address must fit 57 bits")
    return ([1, lds_address, global_address & 0xffffffff, (global_address >> 32) | 0x80000000],
            [2 << 16, (inner & 0xffff) << 16,
             (inner >> 16) | ((outer & 0xffff) << 16),
             (outer >> 16) | (inner << 16), outer, stride, 0, 0])


def tensor_footprint(d0, d1):
    """Narrow no-padding/no-iterate F32 2-D profile used by the real fixture."""
    if len(d0) != 4 or len(d1) != 8 or d0[0] != 1 or d0[3] >> 30 != 2 or d1[0] != 2 << 16:
        raise ValueError("not the pinned predicated F32 2-D descriptor profile")
    inner = (d1[1] >> 16) | ((d1[2] & 0xffff) << 16)
    outer = (d1[2] >> 16) | ((d1[3] & 0xffff) << 16)
    tile_inner, tile_outer = d1[3] >> 16, d1[4] & 0xffff
    if d1[1] & 0xffff or d1[4] >> 16 or d1[6:] != [0, 0] or (inner, outer) != (tile_inner, tile_outer):
        raise ValueError("atomic barrier, higher dimension, or partial bounds not in this oracle")
    global_base = d0[2] | ((d0[3] & 0x1ffffff) << 32)
    return [(global_base + 4 * (row * d1[5] + col), d0[1] + 4 * (row * tile_inner + col))
            for row in range(tile_outer) for col in range(tile_inner)]


def attention(q, k, v):
    """Full ordinary softmax(QK^T/8)V, no subsampling or omitted denominator."""
    output = []
    for query in q:
        weights = [math.exp(sum(a * b for a, b in zip(query, key)) / 8) for key in k]
        denom = sum(weights)
        output.extend(sum(weights[t] * v[t][d] for t in range(len(k))) / denom for d in range(len(v[0])))
    return output


def limb_mul_mad(a, b, c):
    """Independent 32-bit limb algorithm, checked against Python's integer product."""
    mask = (1 << 32) - 1
    al, ah, bl, bh = a & mask, a >> 32, b & mask, b >> 32
    lo = al * bl
    middle = (lo >> 32) + ah * bl + al * bh
    high = ah * bh + (middle >> 32)
    low = (lo & mask) | ((middle & mask) << 32)
    wide_mask = (1 << 64) - 1
    added = low + c
    return [high & wide_mask, low, (high + (added >> 64)) & wide_mask, added & wide_mask]


def signed_limb_mul_mad(a_bits, b_bits, c_bits):
    mask = (1 << 64) - 1
    high, low, _, _ = limb_mul_mad(a_bits, b_bits, 0)
    high = (high - (b_bits if a_bits >> 63 else 0) - (a_bits if b_bits >> 63 else 0)) & mask
    added = low + c_bits
    added_high = (high - (1 if c_bits >> 63 else 0) + (added >> 64)) & mask
    return [high, low, added_high, added & mask]


def encoded_value(value, dtype):
    if dtype == "f32":
        return struct.unpack("<I", struct.pack("<f", value))[0]
    if dtype == "f16":
        return struct.unpack("<H", struct.pack("<e", value))[0]
    bits = struct.unpack("<I", struct.pack("<f", value))[0]
    return ((bits + 0x7fff + ((bits >> 16) & 1)) >> 16) & 0xffff


def decoded_value(bits, dtype):
    if dtype == "f32":
        return struct.unpack("<f", struct.pack("<I", bits))[0]
    if dtype == "f16":
        return struct.unpack("<e", struct.pack("<H", bits))[0]
    return struct.unpack("<f", struct.pack("<I", bits << 16))[0]


def encoded_wmma_vectors():
    cases = []
    for dtype, depth in [("f32", 4), ("f16", 32), ("bf16", 32)]:
        for salt in range(3):
            a = [[((row * 3 + k * 7 + salt * 2) % 11 - 5) / 4 for k in range(depth)] for row in range(16)]
            b = [[((col * 5 + k * 2 + salt * 3) % 13 - 6) / 4 for k in range(depth)] for col in range(16)]
            a_bits = [encoded_value(x, dtype) for x in pack_source(a, dtype)]
            b_bits = [encoded_value(x, dtype) for x in pack_source(b, dtype)]
            # All values/products/sums are small dyadics exactly representable in
            # F32, so these finite controls do not need a rounding tolerance.
            native_expected = wmma_from_raw([decoded_value(x, dtype) for x in a_bits],
                                            [decoded_value(x, dtype) for x in b_bits], dtype)
            assert native_expected == pack_output(dense_gemm(a, b))
            cases.append({"kernel": "wmma_" + dtype, "pattern": salt, "input_dtype": dtype,
                          "input_word_bits": 32 if dtype == "f32" else 16,
                          "a_bits": a_bits, "b_bits": b_bits,
                          "expected_lane_major_outputs": native_expected,
                          "expected_complete_outputs": 256, "absolute_tolerance": 0})
    return {"schema_version": 1, "target": "gfx1250", "cases": cases,
            "scope": "Independent finite CPU lane ABI and dtype oracle vectors; no gfx1250 execution claim"}


def self_check():
    basis_cases = 0
    for dtype, ksize in [("f32", 4), ("f16", 32), ("bf16", 32)]:
        count = ksize // 2
        coordinates = [source_coordinate(l, i, dtype) for l in range(32) for i in range(count)]
        assert len(set(coordinates)) == 16 * ksize
        assert set(coordinates) == {(r, k) for r in range(16) for k in range(ksize)}
        # Every A coordinate is independently selected; nonzero B weights distinguish
        # every N coordinate. This also exercises every physical output register.
        for row in range(16):
            for selected_k in range(ksize):
                a = [[int(r == row and k == selected_k) for k in range(ksize)] for r in range(16)]
                b = [[(col + 1) * int(k == selected_k) for k in range(ksize)] for col in range(16)]
                result = wmma_from_raw(pack_source(a, dtype), pack_source(b, dtype), dtype)
                for lane in range(32):
                    for item in range(8):
                        r, col = output_coordinate(lane, item)
                        assert result[lane * 8 + item] == (col + 1 if r == row else 0)
                basis_cases += 1
        assert len(set(output_coordinate(l, i) for l in range(32) for i in range(8))) == 256
    for stage in range(2):
        d0, d1 = tensor_descriptor(0x10000 + stage * 256, 0)
        assert tensor_footprint(d0, d1) == [(0x10000 + stage * 256 + i * 4, i * 4) for i in range(64)]
    boundaries = [0, 1, (1 << 32) - 1, 1 << 32, (1 << 32) + 1, 1 << 63, (1 << 64) - 1]
    integer_cases = 0
    for a in boundaries:
        for b in boundaries:
            for c in boundaries:
                p, added = a * b, a * b + c
                mask = (1 << 64) - 1
                assert limb_mul_mad(a, b, c) == [(p >> 64) & mask, p & mask, (added >> 64) & mask, added & mask]
                signed = lambda x: x if x < 1 << 63 else x - (1 << 64)
                p = signed(a) * signed(b)
                added = p + signed(c)
                assert signed_limb_mul_mad(a, b, c) == [(p >> 64) & mask, p & mask, (added >> 64) & mask, added & mask]
                integer_cases += 1
    q = [[((r * 3 + d * 7) % 11 - 5) / 32 for d in range(32)] for r in range(16)]
    k = [[((t * 5 + d * 2) % 13 - 6) / 32 for d in range(32)] for t in range(32)]
    v = [[((t * 7 + d * 3) % 17 - 8) / 8 for d in range(32)] for t in range(32)]
    assert len(attention(q, k, v)) == 512
    return {"wmma_basis_cases": basis_cases, "wmma_outputs_per_case": 256,
            "integer_boundary_cases_per_signedness": integer_cases, "integer_signednesses": 2,
            "encoded_wmma_dense_cases": len(encoded_wmma_vectors()["cases"]), "tdm_complete_stages": 2,
            "attention_complete_outputs": 512,
            "scope": "Independent CPU oracle self-checks only; no native execution or graph validation claim"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--vectors-output", type=Path)
    args = parser.parse_args()
    result = self_check()
    result["oracle_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n")
    if args.vectors_output:
        vectors = encoded_wmma_vectors()
        vectors["oracle_sha256"] = result["oracle_sha256"]
        args.vectors_output.write_text(json.dumps(vectors, indent=2) + "\n")
    print(json.dumps(result))


if __name__ == "__main__":
    main()
