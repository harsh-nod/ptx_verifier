#!/usr/bin/env python3
"""Compare functional tensor-bounds outcomes; no timing or GPU execution."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ASSEMBLY = "tests/gfx1250/fixtures/native-tensor-roundtrip.s"
SPEC = "tests/gfx1250/specs/tensor-roundtrip.spec"
LOAD = "tensor_load_to_lds s[4:7], s[12:19], s[20:23], s[20:23]"
STORE = "tensor_store_from_lds s[16:19], s[8:15], s[20:23], s[20:23]"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def mutations(source):
    assert source.count(LOAD) == 1 and source.count(STORE) == 1
    load = source.replace(LOAD, f"s_mov_b32 s5, 256\n\t{LOAD}", 1)
    assert "s_wait_kmcnt 0x0" in load
    return {
        "original": source,
        "load_bounds": load,
        "store_bounds": source.replace(STORE, f"s_mov_b32 s17, 256\n\t{STORE}", 1),
        "unsupported_descriptor": source.replace(
            LOAD, f"s_mov_b32 s20, 1\n\t{LOAD}", 1
        ),
        "pending_descriptor": load.replace("s_wait_kmcnt 0x0", "s_nop 0", 1),
        "exec_zero": source.replace(
            LOAD,
            f"s_mov_b32 s5, 256\n\ts_mov_b32 exec_lo, 0\n\t{LOAD}\n\ts_mov_b32 exec_lo, 1",
            1,
        ),
    }


def command(source, safe):
    args = (
        [
            "verify",
            str(source),
            SPEC,
            "--dim",
            "N=128",
            "--sample",
            "0",
        ]
        if safe
        else ["analyze", str(source)]
    )
    return [
        "--no-log-file",
        "--backend",
        "amdgpu",
        "--target",
        "gfx1250",
        *args,
        "--kernel",
        "tensor_roundtrip",
        "--block",
        "64",
        "--array",
        "x:65536:4:128:in",
        "--array",
        "out:131072:4:128:out",
        "--param",
        "ptr:x",
        "--param",
        "ptr:out",
        "--no-profile",
    ]


def run(binary, source, safe):
    args = command(source, safe)
    result = subprocess.run(
        [str(binary), *args], cwd=ROOT, capture_output=True, text=True, timeout=60
    )
    text = result.stdout
    certified = text.count("TENSOR_BOUNDS: CERTIFIED_REJECTION") == 1
    verdicts = re.findall(r"^VERDICT: (\w+)$", text, re.M)
    refused = any(
        marker in text + result.stderr
        for marker in (
            "execution stopped:",
            "unsupported AMD instruction",
            "certificate invalid",
        )
    )
    if safe:
        assert (
            result.returncode == 0
            and verdicts == ["ACCEPT"]
            and not certified
            and not refused
        ), (
            text,
            result.stderr,
        )
        checks = [
            line.strip()
            for line in text.splitlines()
            if line.strip().startswith("AMD ")
        ]
        properties = (
            "AMD trace completeness",
            "AMD wait and register readiness",
            "AMD workgroup barrier generations",
            "AMD memory-conflict freedom",
        )
        assert len(checks) == len(properties)
        assert all(
            sum(
                line.startswith(prop + " (") and line.endswith(" PASS")
                for line in checks
            )
            == 1
            for prop in properties
        )
        assert re.search(r"^VC check:.*elements: 128$", text, re.M)
        assert "equivalence: all 128 compared elements proved equivalent" in text
        outcome = "complete_specification_proof"
    elif certified:
        assert result.returncode == 1 and verdicts == ["REJECT"] and not refused, (
            text,
            result.stderr,
        )
        assert (
            "AMD tensor LDS bounds (independently validated attempted access) FAIL"
            in text
        )
        assert "TensorBoundsViolation" in text
        assert "transfer not issued" in text and "VC check:" not in text
        assert "output 'out'" not in text
        outcome = "certified_tensor_bounds_rejection"
    else:
        assert result.returncode == 2 and "UNKNOWN" in text, (text, result.stderr)
        outcome = "unknown"
    # A portable command template, rather than the temporary file's local path.
    args[args.index(str(source))] = "{case}.s"
    return {"command": args, "exit_code": result.returncode, "outcome": outcome}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for role in ("baseline", "candidate"):
        parser.add_argument(f"--{role}", type=Path, required=True)
        parser.add_argument(f"--{role}-revision", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("output already exists; preserve prior results")
    source = (ROOT / ASSEMBLY).read_bytes()
    spec = (ROOT / SPEC).read_bytes()
    versions = {}
    for role in ("baseline", "candidate"):
        revision = git("rev-parse", f"{getattr(args, role + '_revision')}^{{commit}}")
        for path, content in ((ASSEMBLY, source), (SPEC, spec)):
            pinned = subprocess.check_output(
                ["git", "-C", str(ROOT), "show", f"{revision}:{path}"]
            )
            assert pinned == content, f"{role} source contract differs: {path}"
        binary = getattr(args, role).resolve(strict=True)
        versions[role] = {
            "revision": revision,
            "binary_sha256": sha(binary.read_bytes()),
        }
    cases = mutations(source.decode())
    rows = []
    with tempfile.TemporaryDirectory(prefix="volta-bounds-comparison-") as temp:
        for name, text in cases.items():
            path = Path(temp) / (name + ".s")
            path.write_text(text)
            row = {"case": name, "assembly_sha256": sha(path.read_bytes())}
            for role in versions:
                row[role] = run(getattr(args, role).resolve(), path, name == "original")
            rows.append(row)
    for role, version in versions.items():
        assert (
            sha(getattr(args, role).resolve().read_bytes()) == version["binary_sha256"]
        ), "binary changed"
    hazards = [row for row in rows if row["case"] in ("load_bounds", "store_bounds")]
    assert all(row["baseline"]["outcome"] == "unknown" for row in hazards)
    assert all(
        row["candidate"]["outcome"] == "certified_tensor_bounds_rejection"
        for row in hazards
    )
    assert all(
        row[role]["outcome"] == "unknown" for row in rows[3:] for role in versions
    )
    report = {
        "schema_version": 1,
        "scope": "Two seeded configured-LDS bounds violations in one compiler kernel; functional outcomes only.",
        "source_sha256": {ASSEMBLY: sha(source), SPEC: sha(spec)},
        "harness_sha256": sha(Path(__file__).read_bytes()),
        "versions": versions,
        "configured_lds_bytes": 256,
        "invalid_interval_bytes": [256, 512],
        "safe_specification_elements": 128,
        "cases": rows,
        "seeded_bounds_detected": {"baseline": 0, "candidate": 2, "total": 2},
        "limitations": [
            "No latency, GPU speed, upstream comparison or whole-ISA claim.",
            "Harmful variants run only in the CPU verifier.",
            "The prior 77-configuration study and its historical 29/30 result are unchanged.",
            "Binary/source revisions are caller-supplied build provenance, verified by hashes and immutable fixture contracts.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x") as output:
        output.write(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["seeded_bounds_detected"]))


if __name__ == "__main__":
    main()
