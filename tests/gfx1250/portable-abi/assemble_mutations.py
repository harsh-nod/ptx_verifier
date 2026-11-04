#!/usr/bin/env python3
"""Assemble the exact CPU-only ABI mutations, without executing a GPU kernel."""

import argparse
import csv
import hashlib
import json
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent
REQUIRED = {
    "extern_does_not_initialize_static",
    "undefined_nested_output",
    "missing_fourth_word",
    "subword_past_six_byte_end",
    "padding_is_not_zero",
    "undefined_low_half",
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def mutations(root=ROOT):
    provenance = json.loads((root / "compiler-provenance.json").read_text())
    pinned = {item["assembly"]: item["assembly_sha256"] for item in provenance["fixtures"]}
    with (root / "mutations.tsv").open(newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames != ["id", "source", "kernel", "old", "new"]:
            raise ValueError("mutation table must have exactly the five expected columns")
        rows = list(reader)
    ids = [row["id"] for row in rows]
    if len(ids) != len(REQUIRED) or set(ids) != REQUIRED:
        raise ValueError("mutation table must contain every required unique control")
    result = []
    for row in rows:
        if row["source"] not in pinned or pathlib.Path(row["source"]).name != row["source"]:
            raise ValueError("mutation source must name one pinned native assembly file")
        source = (root / row["source"]).read_text()
        if sha256(source.encode()) != pinned[row["source"]]:
            raise ValueError("mutation source differs from the compiler receipt")
        marker = row["kernel"] + ":"
        if source.count("\n" + marker) != 1:
            raise ValueError("mutation kernel must identify one actual native entry")
        begin = source.index("\n" + marker) + 1
        end = source.index("\t.section\t.rodata", begin)
        body = source[begin:end]
        if not row["old"] or body.count(row["old"]) != 1:
            raise ValueError("mutation must replace exactly one instruction in its kernel")
        if not row["new"] or any(c in row["new"] for c in "\n\r\t"):
            raise ValueError("replacement must be one nonempty instruction")
        changed = source[:begin] + body.replace(row["old"], row["new"], 1) + source[end:]
        result.append((row, changed))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembler", type=pathlib.Path,
                        default=pathlib.Path("/opt/rocm-7.2.0/lib/llvm/bin/llvm-mc"))
    parser.add_argument("--check", action="store_true", help="verify the existing current receipt")
    args = parser.parse_args()
    cases = mutations()
    assembler = args.assembler.resolve(strict=True)
    version = subprocess.check_output([str(assembler), "--version"], text=True, timeout=30)
    result = {
        "scope": "Exact assembly-valid CPU-only ABI negative controls; no GPU execution or semantic acceptance claim",
        "target": "gfx1250",
        "hardware_execution": False,
        "assembler": {"path": str(assembler), "sha256": sha256(assembler.read_bytes()),
                      "version": version},
        "table_sha256": sha256((ROOT / "mutations.tsv").read_bytes()),
        "controls": [],
    }
    with tempfile.TemporaryDirectory(prefix="ptx-gfx1250-abi-mc-") as directory:
        work = pathlib.Path(directory)
        for row, source in cases:
            assembly = work / (row["id"] + ".s")
            obj = assembly.with_suffix(".o")
            assembly.write_text(source)
            argv = [str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                    "-filetype=obj", str(assembly), "-o", str(obj)]
            run = subprocess.run(argv, capture_output=True, text=True, timeout=60, check=False)
            if run.returncode != 0 or not obj.is_file() or not obj.stat().st_size:
                raise RuntimeError(f"{row['id']}: assembler failed ({run.returncode}): {run.stderr}")
            result["controls"].append({
                **row, "source_sha256": sha256((ROOT / row["source"]).read_bytes()),
                "mutated_assembly_sha256": sha256(source.encode()),
                "object_sha256": sha256(obj.read_bytes()), "assembler_exit": run.returncode,
                "flags": argv[1:4],
            })
    path = ROOT / "assembler-mutation-provenance.json"
    if args.check:
        if json.loads(path.read_text()) != result:
            raise ValueError("current mutation receipt differs from exact assembler replay")
    else:
        path.write_text(json.dumps(result, indent=2) + "\n")
    print(f"PASS: {len(cases)} required ABI mutations assembled; GPU launches: 0")


if __name__ == "__main__":
    main()
