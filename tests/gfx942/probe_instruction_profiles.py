#!/usr/bin/env python3
"""Compare exact observed instruction profiles with native LLVM assemblers.

Run in a checkout on a compiler host, for example mi300x:
  python3 tests/gfx942/probe_instruction_profiles.py --output /tmp/profiles.json

This reads the existing inventory without changing historical evidence. It is
an availability probe, not a hardware correctness or whole-kernel safety test.
"""
import argparse
import concurrent.futures
import hashlib
import json
import platform
import re
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--assembler", default="/opt/rocm/llvm/bin/llvm-mc")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    root = args.repository.resolve()
    inventory = root / "tests/gfx950/instruction-coverage.json"
    rows = []
    for op in json.loads(inventory.read_text())["opcodes"]:
        for profile in op["profiles"]:
            origin = profile["examples"][0]
            line = (root / origin["path"]).read_text().splitlines()[origin["line"] - 1].strip()
            label = ""
            if re.match(r"s_(?:cbranch_\w+|branch)\s", line):
                label = line.split()[1].strip(",") + ":\n"
            rows.append({"mnemonic": op["mnemonic"], "source": line,
                         "origin": origin, "label": label})

    def probe(row, target):
        source = (f'.amdgcn_target "amdgcn-amd-amdhsa--{target}"\n'
                  '.text\n.p2align 8\nk:\n' + row["source"] + "\n" +
                  row["label"] + "s_endpgm\n")
        result = subprocess.run([args.assembler, "--triple=amdgcn-amd-amdhsa",
                                 f"--mcpu={target}", "-filetype=obj", "-o", "/dev/null"],
                                input=source, text=True, capture_output=True, check=False)
        return {"target": target, "accepted": result.returncode == 0,
                "diagnostic": result.stderr.strip()}

    def run(row):
        return {**row, "gfx950": probe(row, "gfx950"), "gfx942": probe(row, "gfx942")}

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        cases = list(pool.map(run, rows))
    report = {
        "host": platform.node(),
        "compiler": subprocess.check_output([args.assembler, "--version"], text=True).splitlines()[:3],
        "input_inventory_sha256": hashlib.sha256(inventory.read_bytes()).hexdigest(),
        "scope": "One exact instruction per observed frontend profile; architecture availability, not hardware correctness or complete operand legality.",
        "comparison_summary": {
            "profile_cases": len(cases),
            "gfx950_assembler_accepted": sum(r["gfx950"]["accepted"] for r in cases),
            "gfx942_assembler_accepted": sum(r["gfx942"]["accepted"] for r in cases),
            "gfx950_only_mnemonics": sorted({r["mnemonic"] for r in cases
                                           if r["gfx950"]["accepted"] and not r["gfx942"]["accepted"]}),
        },
        "cases": cases,
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["comparison_summary"], indent=2))


if __name__ == "__main__":
    main()
