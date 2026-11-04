#!/usr/bin/env python3
"""Assemble the exact CPU-only tensor mutation table; never load or launch it."""

import argparse
from collections import defaultdict
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_mutations(path):
    with path.open(newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames != ["id", "source", "kernel", "original", "occurrence", "replacement"]:
            raise ValueError("unexpected mutation schema")
        rows = list(reader)
    if not rows:
        raise ValueError("empty mutation inventory")
    groups = defaultdict(list)
    for row in rows:
        if set(row) != set(reader.fieldnames) or not all(isinstance(v, str) and v for v in row.values()):
            raise ValueError("incomplete mutation row")
        if row["source"] not in ["native-tensor-metadata.s", "native-tensor-publication.s",
                                 "native-tensor-descriptor-bytes.s"]:
            raise ValueError("unregistered source module")
        if not row["occurrence"].isdigit():
            raise ValueError("occurrence must be a nonnegative integer")
        if groups[row["id"]] and any(row[key] != groups[row["id"]][0][key] for key in ["source", "kernel"]):
            raise ValueError("one mutation cannot silently mix kernels or source modules")
        groups[row["id"]].append(row)
    return dict(groups)


def replace_entry(source, kernel, original, occurrence, replacement):
    marker = f"\n{kernel}:"
    if source.count(marker) != 1:
        raise ValueError("expected one named kernel")
    start = source.index(marker)
    end = source.index(".Lfunc_end", start)
    body = source[start:end]
    if not original:
        raise ValueError("empty original instruction")
    positions = []
    cursor = 0
    while (found := body.find(original, cursor)) >= 0:
        positions.append(found)
        cursor = found + len(original)
    if occurrence >= len(positions):
        raise ValueError("missing exact original instruction occurrence")
    at = positions[occurrence]
    return source[:start] + body[:at] + replacement + body[at + len(original):] + source[end:]


def build_mutant(directory, rows):
    source = (directory / rows[0]["source"]).read_text()
    decode = lambda value: value.replace("\\n", "\n").replace("\\t", "\t")
    for row in rows:
        padding = {"$NOP128": 128, "$NOP512": 512}.get(row["replacement"])
        replacement = "\n\t".join(["s_nop 0"] * padding) if padding else decode(row["replacement"])
        source = replace_entry(source, row["kernel"], decode(row["original"]),
                               int(row["occurrence"]), replacement)
    return source


def run_checks(directory, assembler):
    groups = read_mutations(directory / "mutations.tsv")
    sources = sorted(directory.glob("native-*.s"))
    if len(groups) != 7 or len(sources) != 4:
        raise ValueError("expected all seven mutants and four genuine source modules")
    version = subprocess.run([str(assembler), "--version"], check=True, capture_output=True,
                             text=True, timeout=30).stdout
    receipt = {
        "status": "incomplete", "schema_version": 1, "target": "gfx1250",
        "hardware_execution": False,
        "scope": "Encoding evidence only. Harmful mutants are evaluated by CPU tests and never launched.",
        "checker_sha256": digest(Path(__file__)),
        "table_sha256": digest(directory / "mutations.tsv"),
        "source_sha256": {path.name: digest(path) for path in sources},
        "assembler": {"path": str(assembler), "sha256": digest(assembler), "version": version},
        "controls": [],
    }
    with tempfile.TemporaryDirectory(prefix="ptx-gfx1250-tensor-mutants-") as temporary:
        scratch = Path(temporary)
        for case_id, source in [*[(path.stem, path.read_text()) for path in sources],
                                *[(case_id, build_mutant(directory, rows)) for case_id, rows in groups.items()]]:
            path = scratch / f"{case_id}.s"
            path.write_text(source)
            obj = path.with_suffix(".o")
            argv = [str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                    "-filetype=obj", str(path), "-o", str(obj)]
            result = subprocess.run(argv, text=True, capture_output=True, timeout=30)
            if result.returncode:
                raise ValueError(f"{case_id} was not assembler-legal: {result.stderr}")
            receipt["controls"].append({
                "id": case_id, "assembly_sha256": digest(path), "object_sha256": digest(obj),
                "argv": argv, "exit_code": result.returncode, "stderr": result.stderr,
            })
    receipt["status"] = "pass"
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembler", type=Path,
                        default=Path("/opt/rocm-7.2.0/lib/llvm/bin/llvm-mc"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    inputs = [*directory.glob("*.s"), *directory.glob("*.hip"), directory / "mutations.tsv",
              directory / "cases.json", Path(__file__), args.assembler]
    if any(args.output.resolve() == path.resolve() or
           (args.output.exists() and path.exists() and args.output.samefile(path)) for path in inputs):
        raise ValueError("output must not overwrite a source artifact")
    args.output.write_text('{"status":"incomplete","hardware_execution":false}\n')
    try:
        receipt = run_checks(directory, args.assembler)
    except Exception as error:
        args.output.write_text(json.dumps({"status": "fail", "hardware_execution": False,
                                          "error": str(error)}, indent=2) + "\n")
        raise
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print("PASS: four original modules and seven CPU-only mutants assemble unchanged")


if __name__ == "__main__":
    main()
