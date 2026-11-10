#!/usr/bin/env python3
"""Catalog and locate the 16 original hostcall-bearing HipKittens modules.

This tool never extracts archives, compiles, executes or upgrades qualification.
Source contracts are partial: the original argument bytes and runtime premises
are absent. Raw search receipts contain machine paths and must stay outside Git.
"""
from __future__ import annotations

import argparse
import bz2
from collections import Counter
import gzip
import hashlib
import json
import lzma
import math
import os
from pathlib import Path
import re
import struct
import stat
import tarfile
import zipfile
import zlib

import hipkittens_inventory as inventory

EXTERNAL = Path(__file__).resolve().parents[1]
DEFAULT_FRONTIER = EXTERNAL / "hipkittens/corpus/frontier.json"
DEFAULT_BASELINE = EXTERNAL / "hipkittens/corpus/baseline.json"
DEFAULT_CATALOG = EXTERNAL / "hipkittens/corpus/device-call-recovery.json"
PRUNED = {".git", "target", "node_modules", ".venv", "__pycache__", ".cache"}


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def read(path):
    return json.loads(path.read_text())


def write(path, document):
    path.write_text(json.dumps(document, indent=2) + "\n")


def original_modules(frontier):
    modules = []
    for probe in frontier["probes"]:
        blocker = probe.get("parse", {}).get("first_blocker", {})
        if blocker.get("category") != "noninteger_assembly_constant":
            continue
        inventory.require(probe["target"] == "gfx950"
                          and blocker.get("preceding_function") == "__ockl_hostcall_internal",
                          "original hostcall frontier population changed")
        attempts = [a for a in probe["attempts"] if a["origin"] == probe["selected_attempt"]]
        inventory.require(len(attempts) == 1, "missing or duplicate selected compiler attempt")
        attempt = attempts[0]
        inventory.require(attempt.get("assembly_sha256") and attempt.get("object_sha256")
                          and attempt["emitted_entries"] == len(probe["entries"]),
                          "original module is not a complete MC-accepted entry-bearing attempt")
        inventory.require(len({e["symbol"] for e in probe["entries"]}) == len(probe["entries"]),
                          "duplicate original entry symbol")
        modules.append({"id": probe["id"], "target": probe["target"], "source": probe["source"],
                        "source_sha256": probe["source_sha256"], "selected_attempt": probe["selected_attempt"],
                        "compiler_attempt": attempt, "historical_first_blocker": blocker,
                        "entries": [{key: entry[key] for key in ("ordinal", "symbol", "metadata_sha256")}
                                    for entry in probe["entries"]]})
    inventory.require(len(modules) == 16 and sum(len(m["entries"]) for m in modules) == 18,
                      "original 16-module/18-entry denominator changed")
    inventory.require(len({m["id"] for m in modules}) == 16, "duplicate original module identity")
    return sorted(modules, key=lambda m: m["id"])


def build_catalog(source_root, frontier_path=DEFAULT_FRONTIER, baseline_path=DEFAULT_BASELINE):
    source_root = source_root.resolve()
    source_inventory = inventory.build_inventory(source_root)
    frontier, baseline = read(frontier_path), read(baseline_path)
    inventory.require(frontier["upstream"]["revision"] == source_inventory["revision"]
                      == baseline["upstream"]["revision"], "source/frontier/baseline revision differs")
    inventory.require(frontier["upstream"]["tree"] == source_inventory["tree"], "source tree differs")
    files = {}

    def source(path):
        data = (source_root / path).read_bytes()
        files[path] = hashlib.sha256(data).hexdigest()
        return data.decode()

    def evidence(path, *needles):
        lines = source(path).splitlines()
        result = []
        for needle in needles:
            matches = [i + 1 for i, line in enumerate(lines) if needle in line]
            inventory.require(bool(matches), "source anchor absent: " + path + ": " + needle)
            result.append({"path": path, "line": matches[0], "anchor": needle})
        return result

    def constant(text, name):
        matches = re.findall(r"constexpr int " + name + r"\s*=\s*(\d+)\s*;", text)
        inventory.require(len(matches) == 1, "missing/duplicate source constant " + name)
        return int(matches[0])

    modules = original_modules(frontier)
    for module in modules:
        path = module["source"]
        text = source(path)
        inventory.require(files[path] == module["source_sha256"], "original source hash differs")
        geometry_evidence = evidence(path, "dim3 grid()", "dim3 block()", "dynamic_shared_memory()")
        for entry in module["entries"]:
            contract = {"original_launch_snapshot": None, "original_argument_layout": None,
                        "original_allocation_bases": None, "complete_specification": None,
                        "replayed": False, "qualified": False}
            if "/layernorm/" in path:
                n = constant(text, "N")
                contract.update(family="layernorm_dropout", geometry={"grid": [n // 4, 16, 1],
                                "block": [256, 1, 1], "dynamic_shared_bytes": 0},
                                arrays={"x_residual_o_o_resid": {"dtype": "bf16", "host_shape": [16, n, 2048],
                                        "descriptor_shape": [1, 16, n, 2048]},
                                        "norm_weight_norm_bias": {"dtype": "bf16", "shape": [2048]}},
                                full_grid_outputs={"o": 16 * n * 2048, "o_resid": 16 * n * 2048},
                                per_workgroup_outputs={"o": 8192, "o_resid": 8192},
                                blockers=["clock64-seeded Philox dropout requires its actual clock/RNG contract"],
                                evidence=geometry_evidence + evidence(path, "constexpr int N =", "rocrand_init(clock64()",
                                         "float rand = rocrand_uniform", "if (rand < keep_prob)", "store(g.o_resid", "store(g.o,"))
            elif "/rotary/" in path:
                n = constant(text, "ATTN_N")
                contract.update(family="rotary", geometry={"grid": [16, 16, n // 32], "block": [64, 1, 1],
                                "dynamic_shared_bytes": 0}, arrays={"x_o": {"dtype": "bf16", "shape": [16, 16, n, 128]},
                                "sin_cos": {"dtype": "bf16", "host_shape": [n, 64], "descriptor_shape": [1, 1, n, 64]}},
                                full_grid_outputs={"o": 16 * 16 * n * 128}, per_workgroup_outputs={"o": 4096},
                                blockers=["BF16 packed operations and complete ABI/runtime contract remain required"],
                                evidence=geometry_evidence + evidence(path, "constexpr int ATTN_N", "__hsub2(",
                                                                         "__hadd2(", "store(g.o,"))
            elif "/paper_experiments/phases/" in path:
                width = 16 if "read_b128" in path else 12 if "read_b96" in path else 8
                write_access = "write_b64" in path
                host = str(Path(path).parent / "test_single.py")
                contract.update(family="lds_microbenchmark", geometry={"grid": [1, 1, 1], "block": [64, 1, 1],
                                "dynamic_shared_bytes": 160000}, arrays={"should_I_write_offset": {
                                "host_dtype": "uint32", "host_shape": [64], "descriptor_shape": [1, 1, 1, 64],
                                "declared_GL_dtype": "float", "device_interpretation": "raw uint32 words"}},
                                full_grid_outputs={}, per_workgroup_outputs={},
                                lds_access={"mode": "write" if write_access else "read", "bytes_per_enabled_lane": width,
                                            "initial_contents": "not initialized by kernel"},
                                blockers=["source profiles LDS accesses, supplies no numerical Global outputs",
                                          "read cases require justified LDS initialization premises"],
                                evidence=geometry_evidence + evidence(path, "reinterpret_cast<uint32_t*>",
                                "extern __shared__", "if (should_I_write)", f'ds_{"write" if write_access else "read"}_b{width * 8}')
                                + evidence(host, "should_I_write[0]", "should_I_write[1]", "offset[tid] =", "dispatch_micro"))
            else:
                inventory.require(path.endswith("attn_bkwd_prep.cpp"), "unrecognized original family")
                prep = "attend_prep_ker" in entry["symbol"]
                folder = Path(path).parent
                training = path.startswith("training/")
                make = str(folder / "Makefile")
                host = str(folder / ("test.py" if training else "test_python.py"))
                contract.update(family="attention_prep" if prep else "attention_dq_shuffle",
                                geometry={"grid_formula": ["ATTN_B", "ATTN_H", "ATTN_N/64"], "block": [256, 1, 1],
                                "dynamic_shared_bytes": 160000, "source_defaults": {"B": 16, "H": 64, "N": 1024},
                                "makefile_defaults": {"B": 8 if training else 16, "H": 64, "N": 2048 if training else 8192},
                                "original_compiler_defines": None},
                                full_grid_outputs={"delta": "B*H*N"} if prep else {"dQg_out": "B*H*N*128"},
                                per_workgroup_outputs={"delta": 64} if prep else {"dQg_out": 8192},
                                blockers=["source defaults differ from original Makefile defaults; recover exact compiler defines"]
                                + ([] if prep else ["producer-specific load_shuffled/store_shuffled layout needs an independent oracle"]),
                                evidence=geometry_evidence + evidence(path, "#ifndef ATTN_B", "#ifndef ATTN_H", "#ifndef ATTN_N",
                                "row_sum(delta_vec" if prep else "load_shuffled<2>", "store(g.delta" if prep else "store_shuffled<1>")
                                + evidence(make, "ATTN_B ?=", "ATTN_H ?=", "ATTN_N ?=", "CPPFLAGS += -DATTN_N")
                                + evidence(host, "Delta = (dO * O).sum", "dispatch_prep(" if prep else "dispatch_dq_shuffle("))
            entry["source_contract"] = contract
        module["missing_qualification_premises"] = ["complete original assembly bytes",
            "exact original compiler recipe/defines and runtime dependency identities",
            "checked by-value ABI offsets, padding and all argument bytes",
            "full allocation extents/bases and selected workgroup output coordinates",
            "complete independent specification and acceptance criteria",
            "reachable runtime/helper closure, private backing, completion and boundary controls"]
    common_evidence = (evidence("include/cdna4/types/global/gl.cuh", "T* raw_ptr", "batch_internal", "tma_descs")
                       + evidence("include/cdna4/types/global/util.cuh", "struct runtime_dim", "size_t v;")
                       + evidence("include/pyutils/pyutils.cuh", "Tensor must be contiguous", "shape[4 - dims + i]"))
    entries = [entry for module in modules for entry in module["entries"]]
    return {"schema_version": 1, "scope": "Recovery identities and partial public source contracts only; no original replay or qualification.",
            "upstream": frontier["upstream"], "frontier_sha256": sha(frontier_path), "baseline_sha256": sha(baseline_path),
            "compiler_reports": frontier["compiler_reports"], "original_toolchain": baseline["toolchain"],
            "common_abi": {"known": "one by-value globals aggregate; runtime GL dimensions are size_t, not int32",
                           "checked_original_layout": None, "evidence": common_evidence},
            "summary": {"modules": 16, "entry_occurrences": 18, "source_fixed_geometry_entries": 14,
                        "macro_dependent_geometry_entries": 4, "original_replays": 0, "qualified_originals": 0,
                        "families": dict(sorted(Counter(e["source_contract"]["family"] for e in entries).items()))},
            "source_file_sha256": dict(sorted(files.items())), "modules": modules,
            "limits": ["A source formula is not an original launch receipt or executable ABI proof.",
                       "A linked helper's presence does not establish reachable calls or justified runtime inputs.",
                       "Regeneration, metadata equality and normalized assembly equality do not recover original bytes.",
                       "Exact artifact recovery alone never establishes execution, graph safety or numerical equivalence."]}


class LimitedReader:
    """Bound actual bytes returned by a regular file or decompressor."""

    def __init__(self, stream, limit):
        self.stream, self.limit, self.consumed = stream, limit, 0

    def read(self, size=-1):
        remaining = self.limit - self.consumed
        request = remaining + 1 if size < 0 else min(size, remaining + 1)
        data = self.stream.read(request)
        self.consumed += len(data)
        if self.consumed > self.limit:
            raise ValueError("actual consumed bytes exceed byte limit")
        return data


def bounded_digest(stream, limit):
    reader = LimitedReader(stream, limit)
    digest = hashlib.sha256()
    while data := reader.read(1024 * 1024):
        digest.update(data)
    return digest.hexdigest(), reader.consumed


def scan(catalog, roots, max_member_bytes=256 * 1024 * 1024):
    """Hash candidate assembly/object files and regular tar/zip members, without extraction.

    Missing/unreadable roots, archive errors and size limits stay in the receipt;
    no negative search result is described as exhaustive in their presence.
    """
    inventory.require(max_member_bytes > 0, "member byte limit must be positive")
    expected = {}
    for module in catalog["modules"]:
        for role in ("assembly", "object"):
            expected.setdefault(module["compiler_attempt"][role + "_sha256"], []).append((module["id"], role))
    matches, errors, files, seen = [], [], [], set()
    stats = Counter()

    def consume(stream, size, location):
        if size > max_member_bytes:
            errors.append({"location": location, "reason": "candidate exceeds byte limit", "bytes": size})
            return
        digest, actual_size = bounded_digest(stream, max_member_bytes)
        inventory.require(actual_size == size, "candidate size changed while reading")
        stats["hashed_candidates"] += 1
        for identity, role in expected.get(digest, []):
            matches.append({"module_id": identity, "role": role, "sha256": digest,
                            "bytes": actual_size, **location})

    def candidate(name):
        return name.endswith((".s", ".asm", ".o"))

    def stamp(info):
        return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)

    def inspect(path, directory_fd=None):
        if not candidate(path.name) and not path.name.endswith((
                ".tar", ".tar.gz", ".tgz", ".tar.xz", ".tar.bz2", ".zip", ".tar.zst", ".tar.zstd")):
            return
        location = {"path": str(path)}
        first_match, first_archive = len(matches), len(files)
        try:
            name = path.name if directory_fd is not None else str(path)
            before = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
            inventory.require(stat.S_ISREG(before.st_mode), "candidate is not a regular file; symlinks/devices/FIFOs are refused")
            identity = (before.st_dev, before.st_ino)
            if identity in seen:
                return
            seen.add(identity)
            # NOFOLLOW rejects a raced leaf symlink; NONBLOCK prevents a raced
            # FIFO/device from blocking before fstat can reject its file kind.
            descriptor = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory_fd)
            with os.fdopen(descriptor, "rb") as stream:
                opened = os.fstat(stream.fileno())
                inventory.require(stat.S_ISREG(opened.st_mode) and stamp(opened) == stamp(before),
                                  "candidate identity changed before opening")
                inventory.require(opened.st_size <= max_member_bytes, "candidate exceeds byte limit")
                if candidate(path.name):
                    consume(stream, opened.st_size, location)
                else:
                    digest, size = bounded_digest(stream, max_member_bytes)
                    inventory.require(size == opened.st_size, "archive size changed while hashing")
                    stream.seek(0)
                    stats["archives"] += 1
                    if path.suffix == ".zip":
                        expanded = 0
                        with zipfile.ZipFile(stream) as archive:
                            for ordinal, member in enumerate(archive.infolist()):
                                stats["archive_members"] += 1
                                # DOS/Windows entries may omit Unix type bits.
                                # An explicit Unix symlink/device/FIFO is never
                                # a regular assembly member, even if its stored
                                # link-target bytes match an expected digest.
                                member_kind = stat.S_IFMT(member.external_attr >> 16)
                                if member_kind not in (0, stat.S_IFREG):
                                    stats["archive_nonregular_members"] += 1
                                    continue
                                if not member.is_dir() and candidate(member.filename):
                                    expanded += member.file_size
                                    inventory.require(expanded <= max_member_bytes, "archive expanded candidates exceed byte limit")
                                    with archive.open(member) as member_stream:
                                        consume(member_stream, member.file_size, {**location, "member": member.filename,
                                                "member_ordinal": ordinal, "member_header_offset": member.header_offset})
                    elif path.name.endswith((".tar.zst", ".tar.zstd")):
                        raise ValueError("zstd archive requires a separate supported decoder")
                    else:
                        if path.name.endswith((".tar.gz", ".tgz")):
                            decoded = gzip.GzipFile(fileobj=stream)
                        elif path.name.endswith(".tar.xz"):
                            decoded = lzma.LZMAFile(stream)
                        elif path.name.endswith(".tar.bz2"):
                            decoded = bz2.BZ2File(stream)
                        else:
                            decoded = stream
                        try:
                            with tarfile.open(fileobj=LimitedReader(decoded, max_member_bytes), mode="r|") as archive:
                                for ordinal, member in enumerate(archive):
                                    stats["archive_members"] += 1
                                    if member.isfile() and candidate(member.name):
                                        with archive.extractfile(member) as member_stream:
                                            consume(member_stream, member.size, {**location, "member": member.name,
                                                    "member_ordinal": ordinal, "member_header_offset": member.offset})
                        finally:
                            if decoded is not stream:
                                decoded.close()
                    stream.seek(0)
                    checked_digest, _ = bounded_digest(stream, max_member_bytes)
                    inventory.require(digest == checked_digest, "archive changed between hashing and member scan")
                    files.append({**location, "sha256": digest, "bytes": size})
                inventory.require(stamp(os.fstat(stream.fileno())) == stamp(opened)
                                  and stamp(os.stat(name, dir_fd=directory_fd, follow_symlinks=False)) == stamp(opened),
                                  "candidate changed during scan")
        except (OSError, ValueError, tarfile.TarError, zipfile.BadZipFile, RuntimeError, EOFError,
                zlib.error, lzma.LZMAError) as error:
            del matches[first_match:]
            del files[first_archive:]
            errors.append({"location": location, "reason": str(error)})

    absolute_roots = sorted({Path(os.path.abspath(root)) for root in roots})
    for root in absolute_roots:
        try:
            info = root.lstat()
            if stat.S_ISREG(info.st_mode):
                inspect(root)
            elif stat.S_ISDIR(info.st_mode):
                def walk_error(error):
                    errors.append({"location": {"path": error.filename}, "reason": str(error)})
                # Directory descriptors keep candidate opens anchored to the
                # traversed directory even if its path is renamed concurrently.
                for current, directories, names, directory_fd in os.fwalk(root, onerror=walk_error, follow_symlinks=False):
                    directories[:] = sorted(d for d in directories if d not in PRUNED and not d.endswith("-target"))
                    for name in sorted(names):
                        inspect(Path(current) / name, directory_fd)
            else:
                raise ValueError("search root is not a regular file or directory; symlinks are refused")
        except (OSError, ValueError) as error:
            errors.append({"location": {"path": str(root)}, "reason": str(error)})
    assembly_ids = {m["module_id"] for m in matches if m["role"] == "assembly"}
    return {"schema_version": 1, "scope": "Read-only hash search; archive members are never extracted or executed.",
            "roots": [str(root) for root in absolute_roots], "pruned_directory_names": sorted(PRUNED),
            "pruned_directory_suffix": "-target", "follow_directory_symlinks": False,
            "follow_file_symlinks": False, "regular_files_only": True,
            "candidate_suffixes": [".s", ".asm", ".o"],
            "archive_suffixes": [".tar", ".tar.gz", ".tgz", ".tar.xz", ".tar.bz2", ".zip"],
            "max_candidate_bytes": max_member_bytes, "max_archive_uncompressed_bytes": max_member_bytes,
            "statistics": dict(stats), "archives": files,
            "matches": matches, "errors": errors,
            "summary": {"expected_modules": len(catalog["modules"]), "assembly_recovered_modules": len(assembly_ids),
                        "assembly_missing_module_ids": sorted(m["id"] for m in catalog["modules"] if m["id"] not in assembly_ids),
                        "original_replays": 0, "qualified_originals": 0,
                        "search_complete_within_declared_scope": not errors}}


def rotary_inputs(module):
    """A source-derived WG0 attempt contract, never an original launch receipt.

    Full inputs and original descriptor extents are retained. Separate output
    half-row views cover all 4,096 physical WG0 writes; the rest of the original
    output allocation remains a recorded premise because arrays cannot overlap.
    Stream/padding are zero and must not become device runtime-input substitutes.
    """
    inventory.require(len(module["entries"]) == 1, "rotary requires its one original entry")
    entry = module["entries"][0]
    contract = entry["source_contract"]
    inventory.require(contract["family"] == "rotary", "only source-fixed rotary inputs are available")
    shape = contract["arrays"]["x_o"]["shape"]
    inventory.require(shape[:2] == [16, 16] and shape[3] == 128
                      and shape[2] in {1024, 2048, 4096, 8192, 16384}, "unrecognized original rotary shape")
    n = shape[2]
    bases = {"x": 0x100000000, "o": 0x200000000, "sin": 0x300000000, "cos": 0x400000000}
    arrays = [{"name": "x", "base": bases["x"], "shape": shape, "dtype": "bf16", "kind": "in"}]
    arrays += [{"name": name, "base": bases[name], "shape": [n, 64], "dtype": "bf16", "kind": "in"}
               for name in ("sin", "cos")]
    declarations = ["dim B; dim H; dim N; dim D; dim C;", "array x[B,H,N,D];",
                    "array sin[N,C];", "array cos[N,C];"]
    equations = []
    for row in range(32):
        for half in (0, 1):
            name = f"o{row}_{half}"
            arrays.append({"name": name, "base": bases["o"] + 2 * (row * 128 + half * 64),
                           "shape": [64], "dtype": "bf16", "kind": "out"})
            declarations.append(f"array {name}[C];")
            lower, upper = f"x[0,0,{row},d]", f"x[0,0,{row},d+64]"
            expression = (f"{lower}*cos[{row},d]-{upper}*sin[{row},d]" if half == 0 else
                          f"{upper}*cos[{row},d]+{lower}*sin[{row},d]")
            equations.append(f"{name}[d] = {expression};")
    payload = b"".join(struct.pack("<5Q8x", bases[name], *dims) for name, dims in (
        ("x", shape), ("o", shape), ("sin", [1, 1, n, 64]), ("cos", [1, 1, n, 64]))) + bytes(8)
    config = {"kernel": entry["symbol"], **contract["geometry"], "workgroup_id": [0, 0, 0],
              "arrays": arrays, "params": [{"bytes": list(payload)}]}
    details = {"scope": "New source-derived rotary WG0 contract; no recovered original launch or supplied runtime premises.",
               "module_id": module["id"], "source_sha256": module["source_sha256"], "required_output_elements": 4096,
               "spec_dimensions": {"B": 16, "H": 16, "N": n, "D": 128, "C": 64},
               "original_allocations": {name: {"base": bases[name], "shape": dims,
                                                "bytes": 2 * math.prod(dims)} for name, dims in (
                   ("x", shape), ("o", shape), ("sin", [n, 64]), ("cos", [n, 64]))},
               "output_views": "all 32 rows and both 64-column halves at original absolute BF16 addresses",
               "math_model": "Verifier mathematical reals; no hardware BF16 rounding or NaN equivalence claim.",
               "original_replayed": False, "qualified": False}
    layout = [f'#include "{module["source"]}"', "#include <cstddef>",
              "using CheckedGlobals = rotary_globals<128>;", "using CheckedGL = CheckedGlobals::x_gl;",
              "static_assert(sizeof(CheckedGL) == 48 && alignof(CheckedGL) == 8);",
              "static_assert(sizeof(CheckedGlobals) == 200 && alignof(CheckedGlobals) == 8);",
              f"static_assert(ATTN_B == 16 && ATTN_H == 16 && ATTN_N == {n} && HEAD_DIM == 128);",
              "static_assert(NUM_THREADS == 64 && BLOCK_SIZE == 32 && HALF_ROPE_DIM == 64);"]
    layout += [f"static_assert(offsetof(CheckedGL, {field}) == {offset});" for field, offset in (
        ("raw_ptr", 0), ("batch_internal", 8), ("depth_internal", 16), ("rows_internal", 24), ("cols_internal", 32))]
    layout += [f"static_assert(offsetof(CheckedGlobals, {field}) == {offset});" for field, offset in (
        ("x", 0), ("o", 48), ("sin", 96), ("cos", 144), ("stream", 192))]
    return config, "\n".join(declarations + equations) + "\n", "\n".join(layout) + "\n", details


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=inventory.DEFAULT_SOURCE)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    commands = parser.add_subparsers(dest="command", required=True)
    build = commands.add_parser("catalog", help="regenerate/check the partial source-bound catalog")
    build.add_argument("--check", action="store_true")
    search = commands.add_parser("scan", help="search files/directories/tar/zip archives by exact original hashes")
    search.add_argument("--root", type=Path, action="append", required=True)
    search.add_argument("--output", type=Path, required=True)
    search.add_argument("--max-candidate-bytes", type=int, default=256 * 1024 * 1024)
    rotary = commands.add_parser("rotary-inputs", help="generate a new source-derived full-input rotary WG0 attempt")
    rotary.add_argument("--module-id", required=True)
    rotary.add_argument("--output", type=Path, required=True)
    options = parser.parse_args()
    try:
        catalog = build_catalog(options.source_root)
        if options.command == "catalog" and not options.check:
            write(options.catalog, catalog)
        else:
            inventory.require(read(options.catalog) == catalog, "recovery catalog drift; review before regeneration")
        if options.command == "rotary-inputs":
            output = options.output.resolve()
            inventory.require(not output.exists() and not output.is_relative_to(EXTERNAL.parent)
                              and not output.is_relative_to(options.source_root.resolve()),
                              "new rotary inputs must use a fresh directory outside source repositories")
            modules = [m for m in catalog["modules"] if m["id"] == options.module_id]
            inventory.require(len(modules) == 1, "unknown or duplicate original module identity")
            config, spec, layout, details = rotary_inputs(modules[0])
            output.mkdir(parents=True)
            write(output / "launch.json", config)
            (output / "rotary.spec").write_text(spec)
            (output / "layout.cpp").write_text(layout)
            write(output / "contract.json", details)
            print(json.dumps({"module_id": options.module_id, "required_output_elements": 4096, "qualified": False}))
            return 0
        if options.command == "scan":
            output = options.output.resolve()
            inventory.require(not output.exists(), "search receipt must be a fresh file")
            inventory.require(not output.is_relative_to(EXTERNAL.parent)
                              and not output.is_relative_to(options.source_root.resolve()),
                              "machine-path search receipt must be outside source repositories")
            result = scan(catalog, options.root, options.max_candidate_bytes)
            result["catalog_sha256"] = sha(options.catalog)
            write(output, result)
            print(json.dumps(result["summary"], sort_keys=True))
            return 1 if result["errors"] or result["summary"]["assembly_missing_module_ids"] else 0
        print(json.dumps(catalog["summary"], sort_keys=True))
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.exit(2, "error: " + str(error) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
