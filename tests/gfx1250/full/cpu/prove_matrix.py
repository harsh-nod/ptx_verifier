#!/usr/bin/env python3
"""Run complete W27-W32 CLI proofs on a frozen CPU-only snapshot."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import resource
import shutil
import signal
import socket
import subprocess
import time

REQUIRED = {
    "gemm_f16_full": ("W27", 256, 256),
    "gemm_f8_full": ("W28", 256, 256),
    "gemm_add_silu_f16_full": ("W29", 256, 256),
    "gemm_add_silu_f8_full": ("W30", 256, 256),
    "bitdelta_full": ("W31", 64, 128),
    "bitdelta_batched_full": ("W32", 128, 256),
}
PROPERTIES = (
    "AMD trace completeness", "AMD wait and register readiness",
    "AMD workgroup barrier generations", "AMD memory-conflict freedom",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def atomic_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def snapshot_file(source, target, expected):
    require(sha(source) == expected, f"stale source: {source}")
    if target.exists():
        require(sha(target) == expected, f"conflicting snapshot input: {target}")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    require(sha(target) == expected, f"snapshot copy mismatch: {target}")
    target.chmod(0o444)


def checked_cases(document, selected):
    cases = {c["kernel"]: c for c in document["cases"] if c["kernel"] in REQUIRED}
    require(len(cases) == 6, "all six original matrix registrations are required")
    require(len([c for c in document["cases"] if c["kernel"] in REQUIRED]) == 6, "duplicate matrix entry")
    require(not set(selected) - cases.keys(), "unknown selected matrix kernel")
    require(len(selected) == len(set(selected)), "duplicate selection")
    names = selected or list(REQUIRED)
    require(names, "empty matrix selection")
    for name in names:
        case = cases[name]
        identity, rows, columns = REQUIRED[name]
        require(case["baseline_id"] == identity and case["required"] and not case["reduced_case"], "wrong original identity")
        require(case["dimensions"]["K"] == 4096, "K4096 required")
        require(case["dimensions"]["M"] == case["dimensions"]["N"] == 4096, "original global matrix extents required")
        require(case["expected_outputs"] == rows * columns, "incomplete output count")
        require(case["block"] == [1024 if name.startswith("gemm") else 256, 1, 1], "wrong native block")
        require(case["grid"] == [1, 1, 1] and case["workgroup"] == [0, 0, 0], "selected original CTA0 required")
        expected = [{"baseline_array": "c", "baseline_start": row * 4096,
                     "native_array": f"out{row:03}", "native_start": 0,
                     "length": columns} for row in range(rows)]
        require(case["output_projection"] == expected, "incomplete or remapped original output tile")
    return [cases[name] for name in names]


def check_stdout(stdout, expected):
    counts = re.findall(r"^VC check:.*  elements: (\d+)\s*$", stdout, re.M)
    require(counts == [str(expected)], "missing or sampled/incomplete VC count")
    require(re.findall(r"^VERDICT: (\w+)\s*$", stdout, re.M) == ["ACCEPT"], "missing final acceptance")
    require(re.findall(r"^EQUIVALENT \(matches spec\)\s*$", stdout, re.M) == ["EQUIVALENT (matches spec)"], "missing equivalence")
    for prop in PROPERTIES:
        require(re.search(r"^\s+" + re.escape(prop) + r" \([^\n]+\)\s+PASS\s*$", stdout, re.M), prop)


def process_rss(pid):
    pending, visited, total = [pid], set(), 0
    while pending:
        child = pending.pop()
        if child in visited:
            continue
        visited.add(child)
        try:
            status = Path(f"/proc/{child}/status").read_text()
            match = re.search(r"^VmRSS:\s+(\d+) kB$", status, re.M)
            total += int(match[1]) * 1024 if match else 0
            pending.extend(map(int, Path(f"/proc/{child}/task/{child}/children").read_text().split()))
        except (FileNotFoundError, ProcessLookupError):
            pass
    return total


def bounded(command, directory, env, limits):
    usage = directory / "resources.txt"
    usage.unlink(missing_ok=True)
    measured = ["/usr/bin/time", "-f", "user=%U system=%S peak_rss_kib=%M wall=%e exit=%x",
                "-o", str(usage), *command]

    def limit():
        resource.setrlimit(resource.RLIMIT_AS, (limits["address_space_bytes"],) * 2)
        resource.setrlimit(resource.RLIMIT_CPU, (limits["cpu_seconds"],) * 2)

    start = time.monotonic()
    peak, killed, process = 0, None, None
    with (directory / "stdout.txt").open("wb") as stdout, (directory / "stderr.txt").open("wb") as stderr:
        try:
            process = subprocess.Popen(measured, stdout=stdout, stderr=stderr, env=env,
                                       start_new_session=True, preexec_fn=limit)
            while process.poll() is None:
                peak = max(peak, process_rss(process.pid))
                if time.monotonic() - start > limits["wall_seconds"]:
                    killed = "wall_timeout"
                elif peak > limits["rss_bytes"]:
                    killed = "rss_limit"
                if killed:
                    os.killpg(process.pid, signal.SIGKILL)
                    break
                time.sleep(.5)
            code = process.wait()
        finally:
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
    return {"argv": command, "measured_argv": measured, "exit_code": code,
            "termination": killed, "elapsed_seconds": round(time.monotonic() - start, 3),
            "monitored_peak_rss_bytes": peak,
            "resources": usage.read_text() if usage.exists() else None,
            "stdout_sha256": sha(directory / "stdout.txt"),
            "stderr_sha256": sha(directory / "stderr.txt")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--fixture-root", required=True, type=Path)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--mode", choices=("default", "logging"), default="default")
    parser.add_argument("--log-level", choices=("info", "debug"), default="info")
    parser.add_argument("--kernel", action="append", default=[])
    parser.add_argument("--wall-seconds", type=int, default=7200)
    parser.add_argument("--cpu-seconds", type=int, default=6900)
    parser.add_argument("--rss-gib", type=int, default=384)
    parser.add_argument("--address-space-gib", type=int, default=512)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    receipt = {"status": "incomplete", "hardware_execution": False, "sampling": False,
               "required_kernels": list(REQUIRED), "results": [],
               "host": socket.gethostname(), "platform": platform.platform(),
               "revision_supplied_by_builder": args.revision, "mode": args.mode,
               "driver_sha256": sha(__file__), "started_unix": time.time()}
    destination = output / "receipt.json"
    atomic_json(destination, receipt)
    try:
        require(all(v > 0 for v in (args.wall_seconds, args.cpu_seconds, args.rss_gib, args.address_space_gib)), "positive resource limits required")
        require(args.address_space_gib >= args.rss_gib, "address-space cap must cover RSS cap")
        full = args.fixture_root.resolve(strict=True)
        manifest = full / "cases.json"
        document = json.loads(manifest.read_text())
        cases = checked_cases(document, args.kernel)
        receipt["selected_kernels"] = [c["kernel"] for c in cases]
        snapshot = output / f"snapshot-{time.time_ns()}"
        snapshot.mkdir()
        binary = snapshot / "volta"
        shutil.copy2(args.binary.resolve(strict=True), binary)
        binary.chmod(0o555)
        files = {"cases.json": sha(manifest)}
        shutil.copy2(manifest, snapshot / "cases.json")
        for case in cases:
            for key in ("source", "assembly", "spec", "launch_config"):
                relative = Path(case[key])
                require(not relative.is_absolute() and ".." not in relative.parts, "snapshot path must be relative")
                source, target = full / relative, snapshot / relative
                snapshot_file(source, target, case[key + "_sha256"])
                files[str(relative)] = sha(target)
        receipt.update(binary_sha256=sha(binary), input_sha256=files, snapshot=str(snapshot))
        env = dict(os.environ)
        require(not any(name in env for name in ("LD_PRELOAD", "LD_AUDIT")), "loader injection is outside this replay profile")
        for name in ("VOLTA_VIZ_DIR", "RUST_LOG"):
            env.pop(name, None)
        env.update(HIP_VISIBLE_DEVICES="", ROCR_VISIBLE_DEVICES="", CUDA_VISIBLE_DEVICES="")
        probe = subprocess.run(["ldd", str(binary)], capture_output=True, text=True, timeout=30, env=env)
        receipt["ldd"] = {"exit_code": probe.returncode, "stdout": probe.stdout, "stderr": probe.stderr}
        require(probe.returncode == 0 and "not found" not in probe.stdout + probe.stderr, "binary runtime mismatch")
        libraries = re.findall(r"(?:=>\s+)?(/[^\s]+)\s+\(", probe.stdout)
        receipt["runtime_sha256"] = {str(Path(p).resolve(strict=True)): sha(p) for p in libraries}
        help_run = subprocess.run([str(binary), "--help"], capture_output=True, text=True, timeout=30, env=env)
        receipt["capability_probe"] = {"argv": [str(binary), "--help"], "exit_code": help_run.returncode,
                                       "stdout_sha256": hashlib.sha256(help_run.stdout.encode()).hexdigest()}
        require(help_run.returncode == 0, "binary capability probe failed")
        require(args.mode != "logging" or "--log-level" in help_run.stdout, "logging build required")
        limits = {"wall_seconds": args.wall_seconds, "cpu_seconds": args.cpu_seconds,
                  "rss_bytes": args.rss_gib * 1024**3, "address_space_bytes": args.address_space_gib * 1024**3}
        receipt["limits"] = limits
        atomic_json(destination, receipt)
        for case in cases:
            name = case["kernel"]
            directory = output / name
            directory.mkdir(exist_ok=True)
            command = [str(binary), "--no-log-file", "--backend", "amdgpu", "--target", "gfx1250"]
            if args.mode == "logging":
                command += ["--log-level", args.log_level]
            command += ["verify", str(snapshot / case["assembly"]), str(snapshot / case["spec"]),
                        "--kernel", name, "--config", str(snapshot / case["launch_config"]),
                        "--sample", "0", "--verify-numeric"]
            for dim, value in sorted(case["dimensions"].items()):
                command += ["--dim", f"{dim}={value}"]
            result = {"kernel": name, "expected_outputs": case["expected_outputs"], "passed": False}
            receipt["results"].append(result)
            atomic_json(destination, receipt)
            result.update(bounded(command, directory, env, limits))
            require(result["exit_code"] == 0 and result["termination"] is None, f"process failed: {name}")
            check_stdout((directory / "stdout.txt").read_text(), case["expected_outputs"])
            require(sha(binary) == receipt["binary_sha256"], "binary mutated")
            require(all(sha(snapshot / p) == digest for p, digest in files.items()), "snapshot mutated")
            result["passed"] = True
            atomic_json(destination, receipt)
            print(json.dumps({"kernel": name, "passed": True, "seconds": result["elapsed_seconds"],
                              "peak_rss_bytes": result["monitored_peak_rss_bytes"]}), flush=True)
        receipt["all_required_complete"] = set(receipt["selected_kernels"]) == set(REQUIRED)
        receipt["status"] = "pass" if receipt["all_required_complete"] else "partial"
        return 0
    except BaseException as error:
        receipt.update(status="incomplete", error=f"{type(error).__name__}: {error}")
        return 1
    finally:
        receipt["finished_unix"] = time.time()
        atomic_json(destination, receipt)


if __name__ == "__main__":
    raise SystemExit(main())
