#!/usr/bin/env python3
"""Strict alpha-renaming-safe comparison of complete .vexpr writer outputs.

Stdlib only. Node construction order/IDs and duplicate versus shared identical
subgraphs may differ; typed operations, atoms and child order may not. No
algebraic rewriting, symbol-ID renaming, raw ISA proof or safety verdict.

A mandatory independent coordinate contract prevents matching truncated exports.
The contract JSON is {"output_name": [exact ascending flat indices, ...], ...}.
Plain and gzip artifacts are decoded losslessly (gzip magic or .gz suffix);
corrupt/truncated gzip or CRC failures refuse. Both exact stored artifact bytes
and decoded expression bytes are hashed and counted separately.
The parser deliberately accepts the current writer profile, not every spelling
accepted by Rust read_text: dense children-first IDs, nodes before outputs,
canonical integer/rational literals and newline-terminated UTF-8 records.
Memory for node records is 33 bytes/node (32-byte SHA256 + 1 taint byte), plus
bytearray allocation overhead, bounded line/token temporaries and output roots.
No expression strings or recursive trees are retained. SHA256 collision
resistance is an explicit comparison assumption.
"""
from __future__ import annotations
import argparse
from contextlib import contextmanager
import gzip
import io
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import sys
import zlib

FORMAT_SOURCE_SHA256 = '0d7e4f2a4c4b9e7c259255489efee2b1a8a084dabf26c30a81b81e30456d000f'
UNARY = frozenset('neg exp log sqrt rcp abs sign bitnot not tofloat'.split())
BINARY = frozenset('add sub mul div rem max min bitand bitor bitxor shl shr lshr eq ne lt le gt ge and or'.split())
TERNARY = frozenset(('select', 'fma'))
LEAF = frozenset(('int', 'real', 'bool', 'sym', 'param', 'elem', 'discarded', 'undefined'))
SUPPORTED_OPS = UNARY | BINARY | TERNARY | LEAF | {'read'}
NODE_DOMAIN = b'volta-vexpr-structural-node-v1\0'
OUTPUT_DOMAIN = b'volta-vexpr-exact-output-map-v1\0'
COORD_DOMAIN = b'volta-vexpr-exact-coordinate-map-v1\0'
UINT = re.compile(r'(?:0|[1-9][0-9]*)\Z')
SINT = re.compile(r'(?:0|-[1-9][0-9]*|[1-9][0-9]*)\Z')
REF = re.compile(r'n(0|[1-9][0-9]*)\Z')
DEFAULT_MAX_NODES = 64_000_000
DEFAULT_MAX_LINE_BYTES = 1_048_576
MAX_REAL_DIGITS = 4096

class FormatError(ValueError):
    pass

class ArtifactReader(io.RawIOBase):
    """Hash exact stored bytes while a decoder consumes them once."""
    def __init__(self, source):
        self.source = source
        self.sha256 = hashlib.sha256()
        self.byte_count = 0
    def readable(self):
        return True
    def readinto(self, target):
        data = self.source.read(len(target))
        self.sha256.update(data)
        self.byte_count += len(data)
        target[:len(data)] = data
        return len(data)

@contextmanager
def decoded_stream(path):
    with Path(path).open('rb') as raw:
        magic = raw.read(2)
        raw.seek(0)
        is_gzip = magic == b'\x1f\x8b'
        require(is_gzip or Path(path).suffix.lower() != '.gz',
                'gzip suffix does not contain a gzip artifact')
        reader = ArtifactReader(raw)
        stream = gzip.GzipFile(fileobj=reader, mode='rb') if is_gzip else io.BufferedReader(reader)
        with stream:
            yield stream, reader, ('gzip' if is_gzip else 'none')

def require(ok, message):
    if not ok:
        raise FormatError(message)

def frame(value):
    return struct.pack('>Q', len(value)) + value

def text_bytes(value):
    try:
        return value.encode('utf-8', errors='strict')
    except UnicodeError as error:
        raise FormatError('invalid Unicode string') from error

def unsigned(word, bits=64):
    require(bool(UINT.fullmatch(word)) and len(word) <= 20, 'invalid unsigned integer')
    value = int(word)
    require(value < (1 << bits), 'unsigned integer overflow')
    return value

def signed64(word):
    require(bool(SINT.fullmatch(word)) and len(word) <= 20, 'invalid signed integer')
    value = int(word)
    require(-(1 << 63) <= value < (1 << 63), 'signed integer overflow')
    return value

def exact_real(word):
    if word in ('inf', '-inf'):
        return word.encode('ascii')
    parts = word.split('/')
    require(len(parts) in (1, 2), 'invalid exact real literal')
    numerator = parts[0]
    require(len(numerator.lstrip('-')) <= MAX_REAL_DIGITS and bool(SINT.fullmatch(numerator)),
            'noncanonical or over-budget real numerator')
    # Bounded conversion is below Python\'s default integer-decimal safety limit.
    number = int(numerator)
    if len(parts) == 2:
        denominator = parts[1]
        require(len(denominator) <= MAX_REAL_DIGITS and bool(UINT.fullmatch(denominator)),
                'noncanonical or over-budget real denominator')
        divisor = int(denominator)
        require(divisor > 1 and number != 0 and math.gcd(abs(number), divisor) == 1,
                'real fraction must be reduced with denominator greater than one')
    return word.encode('ascii')

def tokens(line):
    """Rust reader quote rules: a backslash escapes exactly the next character."""
    if '"' not in line:
        return [('w', value) for value in line.split()]
    result = []
    cursor = 0
    while cursor < len(line):
        if line[cursor].isspace():
            cursor += 1
            continue
        if line[cursor] != '"':
            start = cursor
            while cursor < len(line) and not line[cursor].isspace() and line[cursor] != '"':
                cursor += 1
            result.append(('w', line[start:cursor]))
            continue
        cursor += 1
        value = []
        while True:
            require(cursor < len(line), 'unterminated quoted name')
            ch = line[cursor]
            cursor += 1
            if ch == '"':
                break
            if ch == '\\':
                require(cursor < len(line), 'unterminated quoted-name escape')
                ch = line[cursor]
                cursor += 1
            value.append(ch)
        result.append(('q', ''.join(value)))
    return result

def validate_contract(expected):
    require(type(expected) is dict and bool(expected), 'a nonempty independent output-coordinate contract is required')
    checked = {}
    for name, values in expected.items():
        require(type(name) is str, 'output names must be strings')
        text_bytes(name)
        require(type(values) is list and bool(values), 'each expected output needs explicit nonempty coordinates')
        require(all(type(i) is int and 0 <= i < (1 << 64) for i in values), 'invalid expected output coordinate')
        require(all(a < b for a, b in zip(values, values[1:])), 'expected coordinates must be strictly ascending and unique')
        checked[name] = list(values)
    return checked

def parse_contract(raw):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'duplicate coordinate-contract key')
            result[key] = value
        return result
    try:
        return validate_contract(json.loads(raw.decode('utf-8'), object_pairs_hook=unique))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise FormatError('invalid coordinate-contract file') from error

def read_contract(path):
    try:
        return parse_contract(Path(path).read_bytes())
    except OSError as error:
        raise FormatError('cannot read coordinate-contract file') from error

def output_digest(roots, expected):
    h = hashlib.sha256(OUTPUT_DOMAIN)
    count = sum(len(indices) for indices in expected.values())
    h.update(struct.pack('>Q', count))
    c = hashlib.sha256(COORD_DOMAIN)
    c.update(struct.pack('>Q', count))
    for name in sorted(expected, key=text_bytes):
        for index in expected[name]:
            coordinate = frame(text_bytes(name)) + struct.pack('>Q', index)
            c.update(coordinate)
            h.update(coordinate)
            h.update(roots[(name, index)])
    return h.hexdigest(), c.hexdigest()

def scan(path, expected, *, max_nodes=DEFAULT_MAX_NODES, max_line_bytes=DEFAULT_MAX_LINE_BYTES):
    expected = validate_contract(expected)
    require(type(max_nodes) is int and 0 < max_nodes <= (1 << 32), 'invalid node budget')
    require(type(max_line_bytes) is int and max_line_bytes > 0, 'invalid line budget')
    hashes, incomplete = bytearray(), bytearray()
    roots, indices = {}, {}
    file_hash = hashlib.sha256()
    file_size = 0
    header = False
    output_started = False
    node_count = 0
    line_number = 0
    try:
        with decoded_stream(path) as (stream, artifact, compression):
            while True:
                raw = stream.readline(max_line_bytes + 1)
                if not raw:
                    break
                line_number += 1
                require(len(raw) <= max_line_bytes, 'line byte budget exceeded')
                require(raw.endswith(b'\n'), 'truncated or non-newline-terminated record')
                file_hash.update(raw)
                file_size += len(raw)
                line = raw.decode('utf-8', errors='strict').strip()
                if not line or line.startswith('#'):
                    continue
                if not header:
                    require(line == 'volta-expr 1', 'missing or unknown format header')
                    header = True
                    continue
                fields = tokens(line)

                def child(token):
                    require(token[0] == 'w', 'child must be a node reference')
                    match = REF.fullmatch(token[1])
                    require(match is not None, 'invalid node reference')
                    value = unsigned(match[1], 32)
                    require(value < node_count, 'dangling, self or forward node reference')
                    return value

                if fields and fields[0] == ('w', 'out'):
                    output_started = True
                    require(len(fields) == 4 and fields[1][0] == 'q' and fields[2][0] == 'w', 'malformed output record')
                    name, index = fields[1][1], unsigned(fields[2][1])
                    root = child(fields[3])
                    require(name in expected, 'unexpected output name')
                    require(not indices.get(name) or indices[name][-1] < index, 'duplicate or nonascending output coordinate')
                    position = len(indices.get(name, []))
                    require(position < len(expected[name]) and index == expected[name][position],
                            'missing, shifted or unexpected output coordinate')
                    require(not incomplete[root], 'output depends on undefined or discarded expression')
                    roots[(name, index)] = bytes(hashes[root * 32:(root + 1) * 32])
                    indices.setdefault(name, []).append(index)
                    continue
                require(not output_started, 'node record after output records')
                require(len(fields) >= 3 and fields[0] == ('w', 'n' + str(node_count))
                        and fields[1] == ('w', '=') and fields[2][0] == 'w',
                        'nodes must have unique dense children-first IDs')
                require(node_count < max_nodes, 'node budget exceeded')
                op = fields[2][1]
                args = fields[3:]
                require(op in SUPPORTED_OPS, 'unknown expression operation')
                atoms, children = [], []
                if op in ('discarded', 'undefined'):
                    require(not args, 'wrong nullary arity')
                elif op in ('int', 'real', 'bool', 'sym'):
                    require(len(args) == 1 and args[0][0] == 'w', 'wrong literal arity or type')
                    literal = args[0][1]
                    if op == 'int':
                        atoms = [struct.pack('>q', signed64(literal))]
                    elif op == 'real':
                        atoms = [exact_real(literal)]
                    elif op == 'sym':
                        atoms = [struct.pack('>Q', unsigned(literal))]
                    else:
                        require(literal in ('true', 'false'), 'invalid Boolean literal')
                        atoms = [b'\x01' if literal == 'true' else b'\x00']
                elif op == 'param':
                    require(len(args) == 1 and args[0][0] == 'q', 'wrong parameter arity or type')
                    atoms = [text_bytes(args[0][1])]
                elif op in ('elem', 'read'):
                    require(len(args) == 2 and args[0][0] == 'q', 'wrong input arity or type')
                    atoms = [text_bytes(args[0][1])]
                    if op == 'elem':
                        require(args[1][0] == 'w', 'input flat index must be numeric')
                        atoms.append(struct.pack('>Q', unsigned(args[1][1])))
                    else:
                        children = [child(args[1])]
                else:
                    arity = 1 if op in UNARY else 2 if op in BINARY else 3
                    require(len(args) == arity, 'wrong operation arity')
                    children = [child(arg) for arg in args]
                h = hashlib.sha256(NODE_DOMAIN)
                h.update(frame(op.encode('ascii')))
                h.update(struct.pack('>Q', len(atoms)))
                for atom in atoms:
                    h.update(frame(atom))
                h.update(struct.pack('>Q', len(children)))
                tainted = op in ('undefined', 'discarded')
                for ref in children:
                    h.update(hashes[ref * 32:(ref + 1) * 32])
                    tainted = tainted or bool(incomplete[ref])
                hashes.extend(h.digest())
                incomplete.append(int(tainted))
                node_count += 1
    except (OSError, EOFError, zlib.error, UnicodeError, OverflowError) as error:
        raise FormatError('line ' + str(line_number) + ': compression integrity, file or encoding failure') from error
    except FormatError as error:
        raise FormatError('line ' + str(line_number) + ': ' + str(error)) from error
    require(header, 'missing format header')
    require(indices == expected, 'incomplete or extra output-coordinate map')
    digest, coordinate_digest = output_digest(roots, expected)
    return {'artifact_sha256': artifact.sha256.hexdigest(), 'artifact_bytes': artifact.byte_count,
            'compression': compression, 'decoded_vexpr_sha256': file_hash.hexdigest(),
            'decoded_vexpr_bytes': file_size,
            'node_records': node_count, 'node_table_payload_bytes': len(hashes) + len(incomplete),
            'output_count': len(roots), 'output_counts': {k: len(v) for k, v in expected.items()},
            'coordinate_map_sha256': coordinate_digest, 'structural_output_map_sha256': digest,
            'roots': roots}

def summary(scan_result):
    return {key: value for key, value in scan_result.items() if key != 'roots'}

def compare(left, right, expected, **budgets):
    a = scan(left, expected, **budgets)
    b = scan(right, expected, **budgets)
    # Both scans already checked every independently expected coordinate.
    differences = [(name, index) for name, index in a['roots']
                   if a['roots'][(name, index)] != b['roots'][(name, index)]]
    return {'schema_version': 1, 'comparison': 'exact typed rooted expression structure modulo node IDs and construction order',
            'match': not differences, 'format_source_sha256': FORMAT_SOURCE_SHA256,
            'left': summary(a), 'right': summary(b), 'different_outputs': len(differences),
            'first_differences': [{'array': name, 'index': index,
                                   'left_root_sha256': a['roots'][(name, index)].hex(),
                                   'right_root_sha256': b['roots'][(name, index)].hex()}
                                  for name, index in sorted(differences)[:10]],
            'limits': ['SHA256 collision resistance is assumed.', 'No algebraic rewriting or machine SymbolId renaming.',
                       'Identical duplicated versus shared subgraphs compare equally; node count/arena order need not match.',
                       'Full coordinates require the independent supplied contract; structural agreement creates no ISA, graph-safety or mathematical proof.']}

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('left', type=Path)
    p.add_argument('right', type=Path)
    p.add_argument('--expected-coordinates', type=Path, required=True)
    p.add_argument('--output', type=Path)
    p.add_argument('--max-nodes', type=int, default=DEFAULT_MAX_NODES)
    p.add_argument('--max-line-bytes', type=int, default=DEFAULT_MAX_LINE_BYTES)
    args = p.parse_args()
    try:
        contract_bytes = args.expected_coordinates.read_bytes()
        result = compare(args.left, args.right, parse_contract(contract_bytes),
                         max_nodes=args.max_nodes, max_line_bytes=args.max_line_bytes)
        result['expected_contract_file_sha256'] = hashlib.sha256(contract_bytes).hexdigest()
        code = 0 if result['match'] else 1
    except (FormatError, OSError) as error:
        result = {'schema_version': 1, 'match': False, 'invalid': str(error)}
        code = 2
    encoded = json.dumps(result, indent=2, ensure_ascii=True) + '\n'
    if args.output:
        args.output.write_text(encoded)
    else:
        sys.stdout.write(encoded)
    return code

if __name__ == '__main__':
    raise SystemExit(main())
