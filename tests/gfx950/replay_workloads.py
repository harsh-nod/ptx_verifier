#!/usr/bin/env python3
"""Replay the existing native workload harness with bounded parallel resources.

Build the requested revision first. This driver never builds or substitutes a
binary. It calls check_races.check, including that harness's full spec and
footprint checks, and retains every command, verdict and resource measurement.
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "ai_compiler_kernels"))
import check_races as harness  # noqa: E402


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--kernel", action="append", default=[])
    parser.add_argument("--worker", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    binary = args.binary.resolve(strict=True)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    harness.VOLTA = binary
    variants = [v for family in harness.load_amdgpu_variants().values() for v in family]
    by_name = {v.name: v for v in variants}
    if len(by_name) != len(variants):
        raise ValueError("duplicate workload names")
    limits = {"address_space_bytes": 256 * 1024**3,
              "cpu_seconds_per_stage": 3600, "wall_seconds_per_stage": 5400}

    if args.worker:
        variant = by_name[args.worker]
        case_dir = output / variant.folder / variant.stem
        case_dir.mkdir(parents=True, exist_ok=True)
        stages = []

        def bounded_run(command, echo):
            del echo
            index = len(stages)
            usage = case_dir / f"stage-{index}.resources.txt"

            def set_limits():
                resource.setrlimit(resource.RLIMIT_AS,
                                   (limits["address_space_bytes"],) * 2)
                resource.setrlimit(resource.RLIMIT_CPU,
                                   (limits["cpu_seconds_per_stage"],) * 2)

            measured = ["/usr/bin/time", "-f",
                        "user=%U system=%S peak_rss_kib=%M wall=%e exit=%x",
                        "-o", str(usage), *command]
            start = time.monotonic()
            process = subprocess.Popen(measured, text=True, stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE, start_new_session=True,
                                       preexec_fn=set_limits)
            timed_out = False
            try:
                stdout, stderr = process.communicate(timeout=limits["wall_seconds_per_stage"])
            except subprocess.TimeoutExpired:
                timed_out = True
                os.killpg(process.pid, signal.SIGKILL)
                stdout, stderr = process.communicate()
            (case_dir / f"stage-{index}.stdout.txt").write_text(stdout)
            (case_dir / f"stage-{index}.stderr.txt").write_text(stderr)
            stages.append({"argv": command, "exit_code": process.returncode,
                           "timed_out": timed_out,
                           "elapsed_seconds": round(time.monotonic() - start, 3),
                           "resources": usage.read_text() if usage.exists() else None})
            if process.returncode or timed_out:
                raise harness.VoltaFailure(
                    f"stage {index} exit={process.returncode} timeout={timed_out}: {stderr[-2000:]}")
            return stdout, stderr

        harness.run_volta = bounded_run
        probe_start = time.monotonic()
        probe = subprocess.run([str(binary), "--help"], text=True,
                               capture_output=True, check=True, timeout=30)
        capability = {"argv": [str(binary), "--help"], "exit_code": probe.returncode,
                      "timeout_seconds": 30,
                      "elapsed_seconds": round(time.monotonic() - probe_start, 3),
                      "stdout_sha256": hashlib.sha256(probe.stdout.encode()).hexdigest()}
        has_logging = "--log-level" in probe.stdout
        harness.cli_has_logging = lambda *_: has_logging
        report = harness.check(variant, full=True, echo=None)
        accepted = report.outcome in {harness.Outcome.RACE_FREE,
                                      harness.Outcome.REDUCED_RACE_FREE}
        result = {"name": variant.name, "revision": args.revision,
                  "binary_sha256": sha(binary), "source": str(variant.path.relative_to(ROOT)),
                  "source_sha256": sha(variant.path),
                  "spec": str(variant.reference_spec.relative_to(ROOT))
                  if variant.reference_spec else None,
                  "spec_sha256": sha(variant.reference_spec) if variant.reference_spec else None,
                  "expected_outputs": variant.expected_outputs,
                  "reduced_case": variant.reduced_case, "sampling": False,
                  "outcome": report.outcome.value, "detail": report.detail,
                  "elapsed_seconds": round(report.seconds, 3), "limits": limits,
                  "capability_probe": capability, "stages": stages,
                  "passed_expected_native_contract": accepted}
        (case_dir / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result), flush=True)
        return 0 if accepted else 1

    unknown = set(args.kernel) - set(by_name)
    if unknown:
        parser.error(f"unknown workload names: {sorted(unknown)}")
    selected = [v for v in variants if not args.kernel or v.name in args.kernel]
    selected.sort(key=lambda v: (-v.expected_outputs, v.name))

    def run_worker(variant):
        command = [sys.executable, str(Path(__file__).resolve()), "--binary", str(binary),
                   "--output", str(output), "--revision", args.revision,
                   "--worker", variant.name]
        run = subprocess.run(command, text=True, capture_output=True)
        result_file = output / variant.folder / variant.stem / "result.json"
        if run.returncode == 0 and result_file.is_file():
            result = json.loads(result_file.read_text())
        else:
            result = {"name": variant.name, "passed_expected_native_contract": False,
                      "worker_exit": run.returncode, "stderr": run.stderr[-4000:]}
        result["worker_exit"] = run.returncode
        return result

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(run_worker, v): v.name for v in selected}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            print(json.dumps({"completed": len(results), "total": len(selected),
                              "name": result["name"], "outcome": result.get("outcome"),
                              "passed": result["passed_expected_native_contract"]}), flush=True)
            summary = {"revision": args.revision, "binary_sha256": sha(binary),
                       "driver_sha256": sha(Path(__file__)), "parallel_jobs": args.jobs,
                       "limits": limits, "expected_cases": len(selected),
                       "completed_cases": len(results), "results": sorted(results, key=lambda x: x["name"])}
            (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    return 0 if all(r["passed_expected_native_contract"] and r["worker_exit"] == 0
                    for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
