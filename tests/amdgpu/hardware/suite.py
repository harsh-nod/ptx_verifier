#!/usr/bin/env python3
"""Run the complete positive-only AMD hardware catalog from exact committed sources.

Use --config for several independent targets, or --target with --host/--local.
All builds, generated probes, logs and receipts stay in an external work directory.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tarfile
import uuid

from profiles import GFX1250_RUNNERS, drivers, suite_names, validate_inventory
from probes import TARGETS, prepare, verify

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tests/gfx1250/hardware"))
from portable_run import device_environment, write_receipt

INPUT_ROOTS = ("tests/amdgpu/hardware", "tests/gfx942", "tests/gfx950", "tests/gfx1250",
               "tests/amdgpu/original-kernel-qualification",
               "crates/volta_amdgpu_analysis/src/frontend/fixtures")
SCOPE = ("Complete existing positive host-driver catalog and bounded address/launch probes, "
         "using exact assembly and full driver output obligations. Numerical execution is "
         "separate from graph/equivalence proofs; no whole-ISA or exhaustive IEEE claim.")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def timestamp() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def validate_request(request: dict) -> dict:
    if not isinstance(request, dict) or set(request) - {"target", "host", "local", "device", "rocm"}:
        raise ValueError("target request has unknown fields")
    target, device = request.get("target"), request.get("device")
    if target not in TARGETS or type(device) is not int or device < 0:
        raise ValueError("require a supported target and nonnegative physical device")
    host, local = request.get("host"), request.get("local", False)
    if type(local) is not bool or bool(host) == local:
        raise ValueError("select exactly one SSH host or local execution")
    if host is not None and (not isinstance(host, str) or not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.@-]*", host)):
        raise ValueError("SSH host must be a host alias, optionally user@host")
    rocm = request.get("rocm", "/opt/rocm")
    if not isinstance(rocm, str) or not Path(rocm).is_absolute() or any(c in rocm for c in "\n\r\0"):
        raise ValueError("ROCm root must be an absolute path")
    return dict(target=target, device=device, host=host, local=local, rocm=rocm)


def requests_from_config(document: dict) -> list[dict]:
    if not isinstance(document, dict) or set(document) != {"targets"} or not isinstance(document["targets"], list) or not document["targets"]:
        raise ValueError("config requires a nonempty targets list")
    requests = [validate_request(row) for row in document["targets"]]
    if len({r["target"] for r in requests}) != len(requests):
        raise ValueError("each target may appear only once")
    return requests


def committed_sources(root: Path, revision: str | None) -> dict:
    revision = revision or subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        raise ValueError("revision must be an exact 40-character commit ID")
    tree = subprocess.check_output(["git", "rev-parse", revision + "^{tree}"], cwd=root, text=True).strip()
    entries = subprocess.check_output(["git", "ls-tree", "-rz", revision, "--", *INPUT_ROOTS], cwd=root)
    files = {}
    for entry in entries.split(b"\0"):
        if not entry:
            continue
        header, name = entry.split(b"\t", 1)
        mode, kind, digest = header.decode().split()
        relative = name.decode()
        path = root / relative
        if kind != "blob" or mode not in ("100644", "100755") or path.is_symlink() or not path.is_file():
            raise ValueError("staging requires ordinary committed files: " + relative)
        content = path.read_bytes()
        actual = hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest()
        if actual != digest:
            raise ValueError("source differs from stated revision: " + relative)
        files[relative] = hashlib.sha256(content).hexdigest()
    if not files or "tests/amdgpu/hardware/suite.py" not in files:
        raise ValueError("hardware entry point is absent from the stated revision")
    tracked = subprocess.check_output(["git", "ls-files", "-z", "--", *INPUT_ROOTS], cwd=root)
    untracked = subprocess.check_output(["git", "ls-files", "--others", "--exclude-standard", "-z", "--", *INPUT_ROOTS], cwd=root)
    if {name.decode() for name in tracked.split(b"\0") if name} != set(files) or untracked:
        raise ValueError("uncommitted or differently versioned AMD hardware inputs are present")
    return dict(revision=revision, tree=tree, files=files)


def verify_payload(root: Path, manifest: dict) -> None:
    if not isinstance(manifest.get("files"), dict) or not manifest["files"]:
        raise ValueError("empty source payload")
    for name, expected in manifest["files"].items():
        relative = Path(name)
        path = root / relative
        if relative.is_absolute() or ".." in relative.parts or path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root.resolve()) or sha(path) != expected:
            raise ValueError("source/payload mismatch: " + name)


def validate_identity(identity: dict, target: str) -> None:
    if not isinstance(identity, dict) or not isinstance(identity.get("architecture"), str):
        raise ValueError("physical device identity must include its architecture")
    if any(type(identity.get(name)) is not int for name in ("wave_size", "visible_device_count", "logical_ordinal")):
        raise ValueError("physical device selection fields must be integers")
    if (identity.get("architecture", "").split(":", 1)[0], identity.get("wave_size"),
            identity.get("visible_device_count"), identity.get("logical_ordinal")) != (target, 32 if target == "gfx1250" else 64, 1, 0):
        raise ValueError("physical device target, wave size or selection differs")
    if not identity.get("name") or not re.fullmatch(r"[0-9a-fA-F]{4,8}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]", identity.get("pci_bus_id", "")):
        raise ValueError("physical device identity is incomplete")
    for name in ("hip_runtime_version", "hip_driver_version"):
        if type(identity.get(name)) is not int or identity[name] <= 0:
            raise ValueError("HIP version is missing: " + name)
    status, value, error = (identity.get(name) for name in ("uuid_status", "uuid_hex", "uuid_hip_error"))
    if type(error) is not int or error < 0:
        raise ValueError("HIP UUID availability is missing")
    if status == "available":
        if error != 0 or not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{32}", value) or int(value, 16) == 0:
            raise ValueError("selected device UUID is invalid")
    elif status == "all_zero":
        if error != 0 or value is not None:
            raise ValueError("all-zero UUID must be disclosed")
    elif status == "not_supported":
        if error == 0 or value is not None:
            raise ValueError("unsupported UUID query must be disclosed")
    else:
        raise ValueError("HIP UUID availability is missing")


def validate_remote_receipt(record: dict, expected: dict) -> None:
    if not isinstance(record, dict):
        raise ValueError("remote receipt is not an object")
    for key in ("invocation_id", "target", "source_revision", "source_tree", "payload_sha256", "physical_device"):
        if record.get(key) != expected[key]:
            raise ValueError("remote receipt mismatch: " + key)
    if record.get("status") != "PASS":
        raise ValueError("remote target did not pass: " + str(record.get("error", record.get("status"))))
    names = [row.get("name") for row in record.get("suites", [])]
    if names != list(suite_names(expected["target"])) or any(row.get("status") != "PASS" for row in record["suites"]):
        raise ValueError("remote receipt has missing or incomplete suites")
    if record.get("sources_unchanged") is not True:
        raise ValueError("remote sources were not rechecked")
    commands = record.get("commands")
    if not isinstance(commands, list) or not commands or any(row.get("returncode") != 0 for row in commands):
        raise ValueError("remote receipt contains failed or missing command evidence")
    validate_identity(record.get("device_identity", {}), expected["target"])


def load_remote_receipt(path: Path, expected: dict) -> dict:
    record = json.loads(path.read_text())
    validate_remote_receipt(record, expected)
    return record


class Execution:
    def __init__(self, root: Path, out: Path, request: dict, manifest: dict, record: dict):
        self.root, self.out, self.request, self.manifest, self.record = root, out, request, manifest, record
        self.out.mkdir(parents=True, exist_ok=True)
        self.build = out / "build"
        self.build.mkdir()
        self.env = device_environment(request["device"], dict(os.environ))
        if self.env.get("LD_PRELOAD"):
            raise ValueError("LD_PRELOAD interposition is forbidden")
        self.rocm = Path(request["rocm"]).resolve(strict=True)
        self.tools = {name: self.rocm / "llvm/bin" / name for name in ("clang++", "llvm-mc", "ld.lld", "llvm-readelf")}
        self.modules = {}

    def save(self):
        write_receipt(self.out / "result.json", self.record)

    def run(self, name, argv, timeout=180, *, nested=False):
        argv = list(map(str, argv))
        row = dict(name=name, argv=argv, timeout_seconds=timeout)
        self.record["commands"].append(row)
        self.save()
        env = dict(self.env)
        if nested:
            env.pop("HIP_VISIBLE_DEVICES")
        print("RUN " + self.request["target"] + " " + name, flush=True)
        try:
            result = subprocess.run(argv, cwd=self.root, env=env, text=True, capture_output=True, timeout=timeout)
            stdout, stderr = result.stdout, result.stderr
            row["returncode"] = result.returncode
        except subprocess.TimeoutExpired as error:
            decode = lambda value: value.decode(errors="replace") if isinstance(value, bytes) else value or ""
            stdout, stderr = decode(error.stdout), decode(error.stderr)
            row.update(returncode=None, timed_out=True)
        for label, content in (("stdout", stdout), ("stderr", stderr)):
            path = self.out / f"{len(self.record['commands']):03d}-{name}.{label}"
            path.write_text(content)
            row[label] = dict(path=path.name, sha256=sha(path))
        self.save()
        if row["returncode"] != 0:
            raise RuntimeError(name + " failed; see retained command logs")
        return stdout

    def compile(self, name, source, includes=()):
        binary = self.build / name
        source = self.root / source
        self.run("compile-" + name, [self.tools["clang++"], "-std=c++17", "-O2", "-Wall", "-Wextra", "-Werror",
                 "-D__HIP_PLATFORM_AMD__", "-I" + str(self.rocm / "include"),
                 *("-I" + str(path) for path in includes), source,
                 "-L" + str(self.rocm / "lib"), "-lamdhip64", "-Wl,-rpath," + str(self.rocm / "lib"), "-o", binary])
        linking = self.run("linkage-" + name, ["ldd", binary])
        lines = [line for line in linking.splitlines() if line.strip().startswith("libamdhip64.so") and "=>" in line]
        if len(lines) != 1 or Path(lines[0].split("=>", 1)[1].split()[0]).resolve(strict=True) != (self.rocm / "lib/libamdhip64.so").resolve(strict=True):
            raise ValueError("host driver resolves a different HIP runtime")
        self.record.setdefault("binaries", {})[name] = dict(sha256=sha(binary), source_sha256=sha(source))
        return binary

    def assemble(self, relative, destination=None):
        source = self.root / relative
        if source in self.modules:
            return self.modules[source]
        destination = destination or self.build / (source.stem + ".hsaco")
        destination.parent.mkdir(parents=True, exist_ok=True)
        obj = destination.with_suffix(".o")
        self.run("assemble-" + source.stem, [self.tools["llvm-mc"], "--triple=amdgcn-amd-amdhsa", "--mcpu=" + self.request["target"], "--filetype=obj", source, "-o", obj])
        self.run("link-" + source.stem, [self.tools["ld.lld"], "-shared", obj, "-o", destination])
        self.record.setdefault("modules", {})[str(relative)] = dict(source_sha256=sha(source), object_sha256=sha(obj), module_sha256=sha(destination))
        self.modules[source] = destination
        return destination

    def passed(self, name, **details):
        self.record["suites"].append(dict(name=name, status="PASS", **details))
        self.save()

    def nested(self, name, argv, receipt):
        if receipt.exists():
            raise ValueError("nested receipt must be fresh")
        self.run("test-" + name, [sys.executable, *argv], timeout=1200, nested=True)
        child = json.loads(receipt.read_text())
        if child.get("status", "").lower() != "pass" or child.get("source_revision", child.get("fixture_source_commit")) != self.manifest["revision"] or child.get("selected_physical_device", child.get("physical_device")) != self.request["device"]:
            raise ValueError("nested driver receipt failed source/device/status validation")
        self.passed(name, receipt=receipt.name, receipt_sha256=sha(receipt))

    def execute(self):
        verify_payload(self.root, self.manifest)
        validate_inventory(self.root, self.request["target"])
        self.record["toolchains"] = {name: dict(path=str(path.resolve(strict=True)), sha256=sha(path)) for name, path in self.tools.items()}
        runtime = self.rocm / "lib/libamdhip64.so"
        self.record["toolchains"]["HIP"] = dict(path=str(runtime.resolve(strict=True)), sha256=sha(runtime))
        for name in ("clang++", "llvm-mc"):
            self.record["toolchains"][name]["version"] = self.run("version-" + name.replace("+", "p"), [self.tools[name], "--version"])
        identity = self.compile("identity", "tests/amdgpu/hardware/identity.cpp")
        self.record["device_identity"] = json.loads(self.run("identity", [identity], timeout=30))
        validate_identity(self.record["device_identity"], self.request["target"])
        if self.request["target"] == "gfx1250":
            base = self.root / "tests/gfx1250"
            common = ["--local", "--device", str(self.request["device"]), "--rocm", str(self.rocm), "--revision", self.manifest["revision"]]
            receipt = self.out / "core.json"
            self.nested("core", [base / "hardware/run.py", "--device", str(self.request["device"]), "--rocm", self.rocm,
                        "--source-commit", self.manifest["revision"], "--build-dir", self.build / "core", "--receipt", receipt], receipt)
            receipt = self.out / "portable.json"
            self.nested("portable", [base / "hardware/portable_run.py", *common, "--result", receipt], receipt)
            for name in GFX1250_RUNNERS:
                receipt = self.out / (name + ".json")
                self.nested(name, [base / f"full/hardware/{name}_run.py", *common, "--timeout", "900", "--result", receipt], receipt)
        for profile in drivers(self.request["target"]):
            modules = [self.assemble(relative) for relative in profile.assemblies]
            if profile.assembly_directory:
                directory = self.build / profile.name
                sources = sorted((self.root / profile.assembly_directory).glob("*.s"))
                if not sources:
                    raise ValueError("missing exact assembly directory: " + profile.assembly_directory)
                for source in sources:
                    self.assemble(source.relative_to(self.root), directory / (source.stem + ".hsaco"))
                modules = [directory]
            binary = self.compile(profile.name + "-driver", profile.source)
            output = self.run("test-" + profile.name, [binary, *modules], timeout=900)
            if not any(re.fullmatch(r"(?:PASS\b.*|SUMMARY\b.*\bPASS(?:\b.*)?)", line) for line in output.splitlines()):
                raise ValueError("driver exited without a complete positive summary")
            if profile.expected_counts:
                expected = profile.expected_counts
                match = re.search(r"^PASS: (\d+) launches, (\d+) complete (?:original/native )?outputs, (\d+) input bytes, (\d+) guard bytes$", output, re.M)
                if not match or tuple(map(int, match.groups())) != expected:
                    raise ValueError("feature driver output accounting is incomplete")
            self.passed(profile.name, summary=output.splitlines()[-1])
        probes = self.root / "generated-probes" / self.request["target"]
        cases = json.loads((probes / "cases.json").read_text())["cases"]
        for row in cases:
            source = probes / (row["name"] + ".s")
            module = self.assemble(source.relative_to(self.root), self.build / "probes" / (source.stem + ".hsaco"))
            symbols = self.run("symbols-" + source.stem, [self.tools["llvm-readelf"], "--symbols", "--wide", module])
            for symbol, alignment in ((source.stem, 256), (source.stem + ".kd", 64)):
                values = re.findall(r"^\s*\d+:\s+([0-9a-fA-F]+)\s+.*\s" + re.escape(symbol) + r"$", symbols, re.M)
                if not values or any(int(v, 16) % alignment for v in values):
                    raise ValueError("probe symbol missing or misaligned: " + symbol)
        binary = self.compile("address-launch-probes", "tests/amdgpu/hardware/probes.cpp", (probes,))
        observed = json.loads(self.run("test-address-launch-probes", [binary, self.request["target"], self.build / "probes"], timeout=900))
        expected = dict(status="pass", target=self.request["target"], cases=len(cases), outputs=sum(len(row["expected"]) for row in cases))
        if observed != expected:
            raise ValueError("address/launch probe output accounting differs")
        self.passed("address-launch-probes", validation=observed)
        verify_payload(self.root, self.manifest)
        self.record["sources_unchanged"] = True
        if [r["name"] for r in self.record["suites"]] != list(suite_names(self.request["target"])):
            raise ValueError("complete target suite inventory was not executed")


def stage(root: Path, directory: Path, snapshot: dict, target: str, volta: Path | None) -> dict:
    files = dict(snapshot["files"])
    for name in files:
        destination = directory / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / name, destination)
    probes = directory / "generated-probes" / target
    rows = prepare(probes, target)
    verifier_identity = None
    if volta:
        verifier_identity = dict(binary=str(volta.resolve(strict=True)), binary_sha256=sha(volta),
                                 trust="caller_supplied_binary",
                                 scope="Exact binary bytes only; no source/build attestation is inferred.")
    verifier = verify(probes, target, volta, rows) if volta else None
    if volta and sha(volta) != verifier_identity["binary_sha256"]:
        raise ValueError("supplied verifier binary changed during probe verification")
    for path in probes.iterdir():
        if path.suffix in (".s", ".hpp", ".json"):
            files[path.relative_to(directory).as_posix()] = sha(path)
    manifest = dict(snapshot, files=files)
    write_receipt(directory / "source-manifest.json", manifest)
    verify_payload(directory, manifest)
    return dict(manifest=manifest, verifier=verifier, verifier_identity=verifier_identity)


def remote_run(request, stage_dir, out, expected):
    host = request["host"]
    remote = subprocess.check_output(["ssh", host, "mktemp -d /tmp/volta-amd-hardware.XXXXXX"], text=True, timeout=45).strip()
    if not re.fullmatch(r"/tmp/volta-amd-hardware\.[A-Za-z0-9]+", remote):
        raise ValueError("unexpected remote staging directory")
    transport = dict(host=host, directory=remote)
    write_receipt(out / "transport.json", transport)
    archive = out / "inputs.tar.gz"
    manifest = json.loads((stage_dir / "source-manifest.json").read_text())
    with tarfile.open(archive, "w:gz") as tar:
        for name in (*manifest["files"], "source-manifest.json"):
            tar.add(stage_dir / name, arcname=name, recursive=False)
    subprocess.run(["scp", str(archive), host + ":" + remote + "/inputs.tar.gz"], check=True, timeout=120, capture_output=True)
    subprocess.run(["ssh", host, shlex.join(["tar", "--no-same-owner", "-xzf", remote + "/inputs.tar.gz", "-C", remote])], check=True, timeout=120, capture_output=True)
    argv = ["python3", remote + "/tests/amdgpu/hardware/suite.py", "--execute-staged", "--target", request["target"], "--device", str(request["device"]),
            "--rocm", request["rocm"], "--invocation-id", expected["invocation_id"], "--work-dir", remote + "/results"]
    transport.update(archive_sha256=sha(archive), argv=argv)
    write_receipt(out / "transport.json", transport)
    completed = subprocess.run(["ssh", host, shlex.join(argv)], capture_output=True, text=True, timeout=21600)
    (out / "remote.stdout").write_text(completed.stdout)
    (out / "remote.stderr").write_text(completed.stderr)
    # Fetch even after a failed remote command; absence or stale identity is a failure.
    subprocess.run(["scp", host + ":" + remote + "/results/result.json", str(out / "remote-result.json")], check=True, timeout=60, capture_output=True)
    # Download the small, reviewable receipts/logs; built modules remain in the
    # unique remote directory and are identified by their recorded hashes.
    subprocess.run(["ssh", host, shlex.join(["tar", "-czf", remote + "/records.tar.gz", "--exclude=build", "-C", remote + "/results", "."])], check=True, timeout=120, capture_output=True)
    archive_records = out / "records.tar.gz"
    subprocess.run(["scp", host + ":" + remote + "/records.tar.gz", str(archive_records)], check=True, timeout=120, capture_output=True)
    with tarfile.open(archive_records, "r:gz") as tar:
        tar.extractall(out / "records", filter="data")
    transport["records_sha256"] = sha(archive_records)
    write_receipt(out / "transport.json", transport)
    if completed.returncode:
        raise RuntimeError("remote execution failed; see retained receipt/logs")
    record = load_remote_receipt(out / "remote-result.json", expected)
    record["remote_execution"] = dict(transport, returncode=completed.returncode)
    return record


def execute_staged(args):
    out = args.work_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    record = dict(status="INCOMPLETE", invocation_id=args.invocation_id, target=args.target, started_utc=timestamp(), commands=[], suites=[], scope=SCOPE)
    write_receipt(out / "result.json", record)
    try:
        request = validate_request(dict(target=args.target, local=True, device=args.device, rocm=args.rocm))
        manifest = json.loads((ROOT / "source-manifest.json").read_text())
        record.update(source_revision=manifest["revision"], source_tree=manifest["tree"], payload_sha256=sha(ROOT / "source-manifest.json"), physical_device=args.device)
        execution = Execution(ROOT, out, request, manifest, record)
        execution.execute()
        record["status"] = "PASS"
    except BaseException as error:
        record.update(status="FAIL", error=type(error).__name__ + ": " + str(error))
        raise
    finally:
        record["finished_utc"] = timestamp()
        write_receipt(out / "result.json", record)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, help="JSON targets list, each with target/host/device/rocm")
    parser.add_argument("--target", choices=TARGETS)
    parser.add_argument("--host")
    parser.add_argument("--local", action="store_true")
    parser.add_argument("--device", type=int)
    parser.add_argument("--rocm", default="/opt/rocm")
    parser.add_argument("--work-dir", type=Path, required=True)
    parser.add_argument("--revision")
    parser.add_argument("--volta", type=Path, help="also compare generated probes against this local verifier")
    parser.add_argument("--execute-staged", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--invocation-id", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    if args.execute_staged:
        execute_staged(args)
        return 0
    directory = args.work_dir.resolve()
    if directory == ROOT or ROOT in directory.parents:
        parser.error("work directory must be outside the repository")
    directory.mkdir(parents=True, exist_ok=True)
    summary = dict(status="INCOMPLETE", invocation_id=str(uuid.uuid4()), started_utc=timestamp(), scope=SCOPE, targets={})
    result = directory / "result.json"
    write_receipt(result, summary)
    try:
        if args.config:
            if args.target or args.host or args.local or args.device is not None or args.rocm != "/opt/rocm":
                raise ValueError("config cannot be mixed with per-target arguments")
            requests = requests_from_config(json.loads(args.config.read_text()))
        else:
            requests = [validate_request(dict(target=args.target, host=args.host, local=args.local, device=args.device, rocm=args.rocm))]
        # Refuse identity overrides on the controlling host as well as each GPU host.
        device_environment(0, dict(os.environ))
        if os.environ.get("LD_PRELOAD"):
            raise ValueError("LD_PRELOAD interposition is forbidden")
        snapshot = committed_sources(ROOT, args.revision)
        summary.update(source_revision=snapshot["revision"], source_tree=snapshot["tree"])
        verifier = args.volta.resolve(strict=True) if args.volta else None
        summary["probe_verifier"] = dict(binary=str(verifier), binary_sha256=sha(verifier), trust="caller_supplied_binary") if verifier else None
        for request in requests:
            target = request["target"]
            out = directory / (target + "-" + str(uuid.uuid4()))
            out.mkdir()
            row = dict(status="INCOMPLETE", target=target, invocation_id=str(uuid.uuid4()), source_revision=snapshot["revision"], source_tree=snapshot["tree"], physical_device=request["device"], requested=request)
            summary["targets"][target] = row
            write_receipt(result, summary)
            write_receipt(out / "result.json", row)
            try:
                validate_inventory(ROOT, target)
                if verifier and sha(verifier) != summary["probe_verifier"]["binary_sha256"]:
                    raise ValueError("supplied verifier binary changed between targets")
                staging = out / "source"
                staging.mkdir()
                preparation = stage(ROOT, staging, snapshot, target, verifier)
                row["payload_sha256"] = sha(staging / "source-manifest.json")
                row["probe_verifier_runs"] = preparation["verifier"]
                row["probe_verifier"] = preparation.get("verifier_identity")
                if request["host"]:
                    observed = remote_run(request, staging, out, row)
                else:
                    argv = [sys.executable, staging / "tests/amdgpu/hardware/suite.py", "--execute-staged", "--target", target, "--device", str(request["device"]), "--rocm", request["rocm"], "--invocation-id", row["invocation_id"], "--work-dir", out / "local-results"]
                    process = subprocess.run(list(map(str, argv)), capture_output=True, text=True, timeout=21600)
                    (out / "local.stdout").write_text(process.stdout)
                    (out / "local.stderr").write_text(process.stderr)
                    observed = json.loads((out / "local-results/result.json").read_text())
                    if process.returncode:
                        raise RuntimeError("local staged execution failed: " + str(observed.get("error")))
                    validate_remote_receipt(observed, row)
                verify_payload(ROOT, snapshot)
                row.update(status="PASS", device_identity=observed["device_identity"], suites=observed["suites"], receipt_sha256=sha(out / ("remote-result.json" if request["host"] else "local-results/result.json")))
            except Exception as error:
                row.update(status="FAIL", error=type(error).__name__ + ": " + str(error))
            if (out / "transport.json").is_file():
                row["transport"] = json.loads((out / "transport.json").read_text())
            row["receipt_directory"] = str(out)
            write_receipt(out / "result.json", row)
            write_receipt(result, summary)
        summary["status"] = "PASS" if all(r["status"] == "PASS" for r in summary["targets"].values()) else "FAIL"
    except Exception as error:
        summary.update(status="FAIL", error=type(error).__name__ + ": " + str(error))
    finally:
        summary["finished_utc"] = timestamp()
        write_receipt(result, summary)
    print(json.dumps(dict(status=summary["status"], targets={k: v["status"] for k, v in summary["targets"].items()}, receipt=str(result))))
    return 0 if summary["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
