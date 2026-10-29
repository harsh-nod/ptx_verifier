#!/usr/bin/env python3
"""Pin legal controls and malformed native forms against the actual LLVM assembler.

These are CPU-only encoding checks. They do not execute traps or malformed/racy
programs on a GPU, and they do not substitute for the Rust semantic tests.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_cases(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames != ["id", "kernel", "original", "replacement"]:
            raise ValueError("syntax table has an unexpected schema")
        rows = list(reader)
    if not rows or any(not all(row.values()) for row in rows):
        raise ValueError("syntax table must contain complete, nonempty cases")
    if len({row["id"] for row in rows}) != len(rows):
        raise ValueError("syntax table contains duplicate case IDs")
    return rows


def replace_entry(source: str, kernel: str, original: str, replacement: str) -> str:
    marker = f"\n{kernel}:"
    if source.count(marker) != 1:
        raise ValueError(f"expected exactly one entry for {kernel}")
    start = source.index(marker)
    end = source.index(".Lfunc_end", start)
    body = source[start:end]
    if body.count(original) != 1:
        raise ValueError(f"expected exactly one original instruction in {kernel}")
    return source[:start] + body.replace(original, replacement, 1) + source[end:]


def run_checks(directory: Path, assembler: Path) -> dict:
    table = directory / "syntax-mutations.tsv"
    source_path = directory / "native-controls.s"
    cases = load_cases(table)
    source = source_path.read_text()
    tools = subprocess.run(
        [str(assembler), "--version"], check=True, text=True, capture_output=True, timeout=30
    )
    receipt = {
        "schema_version": 1,
        "target": "gfx1250",
        "status": "incomplete",
        "hardware_execution": False,
        "scope": "Assembler syntax evidence only; semantic controls are separate Rust tests.",
        "trap_limit": "LLVM encodes 16 SOPP immediate bits; verifier supports only IDs0..255 and never assumes a returning trap handler.",
        "source_sha256": sha256(source_path),
        "table_sha256": sha256(table),
        "checker_sha256": sha256(Path(__file__)),
        "assembler": {
            "path": str(assembler),
            "sha256": sha256(assembler),
            "version": tools.stdout,
        },
        "controls": [],
    }
    with tempfile.TemporaryDirectory(prefix="ptx-gfx1250-boundary-syntax-") as temporary:
        scratch = Path(temporary)

        def assemble(case_id: str, text: str, accepted: bool) -> None:
            assembly = scratch / f"{case_id}.s"
            assembly.write_text(text)
            argv = [
                str(assembler), "--triple=amdgcn-amd-amdhsa", "--mcpu=gfx1250",
                "-filetype=obj", str(assembly), "-o", str(assembly.with_suffix(".o")),
            ]
            result = subprocess.run(argv, text=True, capture_output=True, timeout=30)
            actual = result.returncode == 0
            receipt["controls"].append({
                "id": case_id,
                "expected_accepted": accepted,
                "accepted": actual,
                "assembly_sha256": sha256(assembly),
                "object_sha256": sha256(assembly.with_suffix(".o")) if actual else None,
                "argv": argv,
                "exit_code": result.returncode,
                "stderr": result.stderr,
            })
            if actual != accepted:
                raise ValueError(f"unexpected assembler outcome for {case_id}: {result.stderr}")

        # First prove the precise source forms being mutated are legal.
        assemble("canonical_compiler_module", source, True)
        for immediate in [0, 65535]:
            assemble(f"end_immediate_{immediate}", replace_entry(
                source, "control_end", "s_endpgm", f"s_endpgm {immediate}"), True)
        for immediate in [0, 255, 256, 65535]:
            assemble(f"trap_immediate_{immediate}", replace_entry(
                source, "control_trap", "s_trap 7", f"s_trap {immediate}"), True)
        for case in cases:
            bad = case["replacement"]
            wrappers = {
                "live": bad,
                "unreachable": f"s_branch .Lboundary_skip\n{bad}\n.Lboundary_skip:",
                "empty_exec": f"s_mov_b32 exec_lo, 0\n{bad}",
            }
            for profile, replacement in wrappers.items():
                assemble(f"{case['id']}_{profile}", replace_entry(
                    source, case["kernel"], case["original"], replacement), False)
        assemble("unknown_directive", ".not_a_real_native_directive\n" + source, False)
    receipt["status"] = "pass"
    receipt["positive_controls"] = sum(row["accepted"] for row in receipt["controls"])
    receipt["negative_controls"] = sum(not row["accepted"] for row in receipt["controls"])
    return receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assembler", type=Path,
                        default=Path("/opt/rocm-7.2.0/lib/llvm/bin/llvm-mc"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    inputs = [Path(__file__), directory / "syntax-mutations.tsv", directory / "native-controls.s",
              args.assembler]
    if any(args.output.resolve() == path.resolve() for path in inputs):
        raise ValueError("output must not overwrite an input artifact")
    args.output.write_text(json.dumps({"status": "incomplete", "hardware_execution": False}) + "\n")
    try:
        receipt = run_checks(directory, args.assembler)
    except Exception as error:
        args.output.write_text(json.dumps({
            "status": "fail", "hardware_execution": False, "error": str(error)
        }, indent=2) + "\n")
        raise
    args.output.write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"PASS: {receipt['positive_controls']} legal and {receipt['negative_controls']} malformed forms")


if __name__ == "__main__":
    main()
