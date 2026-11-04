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


def require(condition, message):
    if not condition:
        raise ValueError(message)


def workspace_fingerprint(revision):
    """Tracked Rust workspace superset, including tests and embedded viewer assets."""
    entries = subprocess.check_output(
        [
            "git",
            "-C",
            str(ROOT),
            "ls-tree",
            "-rz",
            "--full-tree",
            revision,
            "--",
            "crates",
            "Cargo.toml",
            "Cargo.lock",
            "rust-toolchain",
            "rust-toolchain.toml",
            ".cargo",
        ]
    )
    records = [entry for entry in entries.split(b"\0") if entry]
    require(records, "empty Rust workspace fingerprint")
    return {
        "algorithm": "sha256-git-tree-v1",
        "sha256": sha(entries),
        "file_count": len(records),
    }


def build_identity(path, revision, binary):
    raw = path.read_bytes()
    record = json.loads(raw)
    require(
        record.get("schema_version") == 1 and record.get("trust") == "caller_attested",
        "build record must explicitly identify its caller-attested schema",
    )
    require(
        record.get("revision") == revision and record.get("source_clean") is True,
        "build source revision/clean state differs",
    )
    require(
        record.get("binary_sha256") == sha(binary.read_bytes()),
        "build executable hash differs",
    )
    require(
        record.get("rust_workspace_fingerprint") == workspace_fingerprint(revision),
        "build Rust workspace fingerprint differs",
    )
    require(
        record.get("profile") == "release"
        and record.get("features") == []
        and record.get("default_features") is True,
        "comparison requires release profile with Cargo default features",
    )
    require(
        record.get("command") == ["cargo", "build", "--release", "-p", "volta_cli"],
        "build command differs from the declared comparison profile",
    )
    require(
        all(
            isinstance(record.get(key), str) and record[key]
            for key in ("rustc", "cargo")
        ),
        "build compiler/tool versions are missing",
    )
    fields = (
        "schema_version",
        "trust",
        "revision",
        "source_clean",
        "binary_sha256",
        "rust_workspace_fingerprint",
        "profile",
        "features",
        "default_features",
        "command",
        "rustc",
        "cargo",
    )
    return {**{key: record[key] for key in fields}, "build_record_sha256": sha(raw)}


def mutations(source):
    require(
        source.count(LOAD) == 1 and source.count(STORE) == 1,
        "tensor mutation anchors changed",
    )
    load = source.replace(LOAD, f"s_mov_b32 s5, 256\n\t{LOAD}", 1)
    require("s_wait_kmcnt 0x0" in load, "pending-descriptor completion anchor missing")
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


def command(source, safe, spec=SPEC):
    args = (
        [
            "verify",
            str(source),
            str(spec),
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


PROPERTIES = (
    "AMD trace completeness",
    "AMD wait and register readiness",
    "AMD workgroup barrier generations",
    "AMD memory-conflict freedom",
)


def classify(stdout, stderr, code, safe, expected_access=None):
    combined = stdout + "\n" + stderr
    marker = "TENSOR_BOUNDS: CERTIFIED_REJECTION"
    marker_count = combined.count(marker)
    certified = re.findall(r"^TENSOR_BOUNDS: CERTIFIED_REJECTION$", stdout, re.M)
    verdicts = re.findall(r"^VERDICT: (\w+)$", combined, re.M)
    graph = re.findall(
        r"^GRAPH VERIFICATION: (VERIFIED|REJECTED|UNKNOWN)\b", combined, re.M
    )
    refused = re.search(
        r"execution (?:stopped|aborted):|trace generator aborted|unsupported AMD instruction|certificate invalid",
        combined,
        re.I,
    )
    require("EARLY_READINESS:" not in combined, "unexpected scalar-readiness outcome")
    counts = re.findall(r"^VC check:.*elements: (\d+)(?:/(\d+))?$", combined, re.M)
    if safe:
        require(
            code == 0
            and verdicts == ["ACCEPT"]
            and marker_count == 0
            and not refused
            and graph in ([], ["VERIFIED"]),
            "inconsistent safe outcome",
        )
        checks = [
            line.strip()
            for line in combined.splitlines()
            if line.strip().startswith("AMD ")
        ]
        require(
            len(checks) == len(PROPERTIES)
            and all(
                sum(
                    line.startswith(prop + " (") and line.endswith(" PASS")
                    for line in checks
                )
                == 1
                for prop in PROPERTIES
            ),
            "incomplete or failing native properties",
        )
        require(
            counts == [("128", "")]
            and len(re.findall(r"^[ \t]*VC check:.*$", combined, re.M)) == 1,
            "incomplete, duplicate or contradictory VC counts",
        )
        equivalents = re.findall(r"^\s*equivalence: (.*)$", combined, re.M)
        require(
            equivalents == ["all 128 compared elements proved equivalent"]
            and "NOT EQUIVALENT" not in combined,
            "missing or contradictory complete specification proof",
        )
        return "complete_specification_proof"
    if marker_count:
        require(
            marker_count == 1
            and len(certified) == 1
            and code == 1
            and verdicts == ["REJECT"]
            and not refused
            and graph in ([], ["UNKNOWN"]),
            "inconsistent certified rejection",
        )
        require(
            combined.count(
                "AMD tensor LDS bounds (independently validated attempted access) FAIL"
            )
            == 1,
            "missing or duplicate tensor bounds property",
        )
        witnesses = re.findall(
            r"TensorBoundsViolation \{[^{}\n]*access: (Read|Write), address: 256, bytes: 256, configured_lds_bytes: 256 \}",
            stdout,
        )
        require(
            len(witnesses) == 1
            and (expected_access is None or witnesses == [expected_access]),
            "missing, mismatched or duplicate typed attempted-access witness",
        )
        require(
            "transfer not issued" in stdout
            and "VC check:" not in combined
            and "output '" not in combined
            and "EQUIVALENT" not in combined,
            "certified prefix contains outputs or equivalence",
        )
        return "certified_tensor_bounds_rejection"
    require(
        code == 2
        and graph == ["UNKNOWN"]
        and verdicts in ([], ["UNKNOWN"])
        and "VC check:" not in combined
        and "EQUIVALENT" not in combined,
        "missing or contradictory inconclusive graph outcome",
    )
    return "unknown"


def run(binary, source, safe, spec=SPEC, expected_access=None):
    args = command(source, safe, spec)
    result = subprocess.run(
        [str(binary), *args], cwd=ROOT, capture_output=True, text=True, timeout=60
    )
    outcome = classify(
        result.stdout, result.stderr, result.returncode, safe, expected_access
    )
    args[args.index(str(source))] = "{case}.s"
    if safe:
        args[args.index(str(spec))] = "{spec}.spec"
    return {
        "command": args,
        "exit_code": result.returncode,
        "outcome": outcome,
        "stdout_sha256": sha(result.stdout.encode()),
        "stderr_sha256": sha(result.stderr.encode()),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fingerprint-revision",
        help="Print a tracked Rust workspace fingerprint; no measurement",
    )
    for role in ("baseline", "candidate"):
        parser.add_argument(f"--{role}", type=Path)
        parser.add_argument(f"--{role}-revision")
        parser.add_argument(f"--{role}-build-record", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.fingerprint_revision:
        print(
            json.dumps(
                workspace_fingerprint(
                    git("rev-parse", f"{args.fingerprint_revision}^{{commit}}")
                ),
                indent=2,
            )
        )
        return
    require(
        all(
            getattr(args, role)
            and getattr(args, role + "_revision")
            and getattr(args, role + "_build_record")
            for role in ("baseline", "candidate")
        )
        and args.output,
        "both binaries, revisions, build records and output are required",
    )
    require(not args.output.exists(), "output already exists; preserve prior results")
    paths = {
        ASSEMBLY: ROOT / ASSEMBLY,
        SPEC: ROOT / SPEC,
        "harness": Path(__file__).resolve(),
    }
    snapshots = {name: path.read_bytes() for name, path in paths.items()}
    source, spec = snapshots[ASSEMBLY], snapshots[SPEC]
    versions, binaries, build_paths = {}, {}, {}
    for role in ("baseline", "candidate"):
        revision = git("rev-parse", f"{getattr(args, role + '_revision')}^{{commit}}")
        for path, content in ((ASSEMBLY, source), (SPEC, spec)):
            pinned = subprocess.check_output(
                ["git", "-C", str(ROOT), "show", f"{revision}:{path}"]
            )
            require(pinned == content, f"{role} source contract differs: {path}")
        binaries[role] = getattr(args, role).resolve(strict=True)
        build_paths[role] = getattr(args, role + "_build_record").resolve(strict=True)
        versions[role] = build_identity(build_paths[role], revision, binaries[role])

    def unchanged():
        require(
            all(path.read_bytes() == snapshots[name] for name, path in paths.items()),
            "source, specification or harness changed during comparison",
        )
        for role, version in versions.items():
            require(
                sha(binaries[role].read_bytes()) == version["binary_sha256"],
                "binary changed",
            )
            require(
                sha(build_paths[role].read_bytes()) == version["build_record_sha256"],
                "build record changed",
            )

    rows = []
    with tempfile.TemporaryDirectory(prefix="volta-bounds-comparison-") as temp:
        frozen_spec = Path(temp) / "frozen.spec"
        frozen_spec.write_bytes(spec)
        for name, text in mutations(source.decode()).items():
            path = Path(temp) / (name + ".s")
            case_bytes = text.encode()
            path.write_bytes(case_bytes)
            row = {"case": name, "assembly_sha256": sha(case_bytes)}
            for role in versions:
                unchanged()
                require(
                    path.read_bytes() == case_bytes
                    and frozen_spec.read_bytes() == spec,
                    "frozen case inputs changed",
                )
                access = {"load_bounds": "Write", "store_bounds": "Read"}.get(name)
                row[role] = run(
                    binaries[role], path, name == "original", frozen_spec, access
                )
                require(
                    path.read_bytes() == case_bytes
                    and frozen_spec.read_bytes() == spec,
                    "frozen case inputs changed",
                )
                unchanged()
            rows.append(row)
    unchanged()
    hazards = [row for row in rows if row["case"] in ("load_bounds", "store_bounds")]
    require(
        len(hazards) == 2
        and all(row["baseline"]["outcome"] == "unknown" for row in hazards),
        "baseline seeded-bound outcomes changed",
    )
    require(
        all(
            row["candidate"]["outcome"] == "certified_tensor_bounds_rejection"
            for row in hazards
        ),
        "candidate seeded-bound outcomes changed",
    )
    require(
        all(row[role]["outcome"] == "unknown" for row in rows[3:] for role in versions),
        "a refusal control acquired detection credit",
    )
    report = {
        "schema_version": 2,
        "scope": "Two seeded configured-LDS bounds violations in one compiler kernel; functional outcomes only.",
        "source_sha256": {ASSEMBLY: sha(source), SPEC: sha(spec)},
        "harness_sha256": sha(snapshots["harness"]),
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
            "Build records are caller attestations, not an independent proof of binary-to-source correspondence. Hashes bind those records to the declared revision, tracked Rust workspace superset, executable and fixture contracts.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x") as output:
        output.write(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report["seeded_bounds_detected"]))


if __name__ == "__main__":
    main()
