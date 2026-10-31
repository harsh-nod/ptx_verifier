"""Refuse unsupported, incomplete or contradictory measurement claims."""

from pathlib import Path
import subprocess
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

import measure_tensor_bounds as measure

SAFE = """AMD trace completeness (native) PASS
AMD wait and register readiness (native) PASS
AMD workgroup barrier generations (native) PASS
AMD memory-conflict freedom (native) PASS
VC check: 0.001s elements: 128
VERDICT: ACCEPT
equivalence: all 128 compared elements proved equivalent
"""
FAULT = """TENSOR_BOUNDS: CERTIFIED_REJECTION
AMD tensor LDS bounds (independently validated attempted access) FAIL
TensorBoundsViolation { event: EventId(1), wave: 0, access: Write, address: 256, bytes: 256, configured_lds_bytes: 256 }
transfer not issued
VERDICT: REJECT
"""


class MeasurementControls(unittest.TestCase):
    def classify(self, text, code, safe=False, stderr=""):
        with patch.object(
            measure.subprocess,
            "run",
            return_value=subprocess.CompletedProcess([], code, text, stderr),
        ):
            return measure.run(Path("/verifier"), Path("/case.s"), safe)

    def test_safe_requires_all_properties_and_all_128_specification_elements(self):
        self.assertEqual(
            self.classify(SAFE, 0, True)["outcome"], "complete_specification_proof"
        )
        for text in (
            SAFE.replace("AMD trace completeness (native) PASS\n", ""),
            SAFE + "AMD trace completeness (native) PASS\n",
            SAFE.replace(
                "memory-conflict freedom (native) PASS",
                "memory-conflict freedom (native) UNKNOWN",
            ),
            SAFE.replace("elements: 128", "elements: 64"),
            SAFE.replace("all 128 compared", "all 64 compared"),
            SAFE + "VERDICT: REJECT\n",
            SAFE + "TENSOR_BOUNDS: CERTIFIED_REJECTION\n" * 2,
            SAFE + "VC check: 0.001s elements: 64\n",
            SAFE + "VC check: malformed count\n",
            SAFE + "NOT EQUIVALENT\n",
            SAFE + "equivalence: not decided\n",
        ):
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.classify(text, 0, True)
        with self.assertRaises(ValueError):
            self.classify(SAFE, 0, True, "AMD memory-conflict freedom (native) FAIL")

    def test_certified_rejection_needs_matching_status_property_and_no_outputs(self):
        self.assertEqual(
            self.classify(FAULT, 1)["outcome"], "certified_tensor_bounds_rejection"
        )
        for text, code in (
            (FAULT, 2),
            (FAULT.replace(" FAIL", " UNKNOWN"), 1),
            (FAULT.replace("TensorBoundsViolation", "GenericError"), 1),
            (FAULT.replace("address: 256", "address: 512"), 1),
            (FAULT + "VERDICT: ACCEPT\n", 1),
            (FAULT + "TENSOR_BOUNDS: CERTIFIED_REJECTION\n", 1),
            (FAULT + "output 'out': 128 elements\n", 1),
            (FAULT + "VC check: 0.001s\n", 1),
        ):
            with self.subTest(text=text, code=code), self.assertRaises(ValueError):
                self.classify(text, code)

    def test_explicit_refusals_override_apparent_proofs_in_either_stream(self):
        for text, code, safe in ((SAFE, 0, True), (FAULT, 1, False)):
            for refusal in (
                "execution stopped: budget",
                "unsupported AMD instruction",
                "certificate invalid",
            ):
                for stdout, stderr in ((text + refusal, ""), (text, refusal)):
                    with (
                        self.subTest(refusal=refusal, stderr=bool(stderr)),
                        self.assertRaises(ValueError),
                    ):
                        self.classify(stdout, code, safe, stderr)

    def test_unknown_is_retained_without_detection_credit(self):
        self.assertEqual(
            self.classify("GRAPH VERIFICATION: UNKNOWN", 2)["outcome"], "unknown"
        )
        for text, code in [
            ("unrelated error", 1),
            ("error: UNKNOWN file failure", 2),
            ("GRAPH VERIFICATION: UNKNOWN\nVERDICT: ACCEPT", 2),
            ("GRAPH VERIFICATION: UNKNOWN\nVC check: 0.001s elements: 128", 2),
            ("GRAPH VERIFICATION: UNKNOWN\nGRAPH VERIFICATION: VERIFIED", 2),
        ]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.classify(text, code)

    def test_load_and_store_certificates_need_the_intended_access_direction(self):
        self.assertEqual(
            measure.classify(FAULT, "", 1, False, "Write"),
            "certified_tensor_bounds_rejection",
        )
        with self.assertRaises(ValueError):
            measure.classify(FAULT, "", 1, False, "Read")

    def test_claim_checks_remain_active_under_optimized_python(self):
        script = """import sys
sys.path.insert(0, sys.argv[1])
import measure_tensor_bounds as m
try:
    m.classify('', '', 7, True)
except ValueError:
    sys.exit(0)
sys.exit(9)
"""
        result = subprocess.run(
            [sys.executable, "-O", "-c", script, str(Path(measure.__file__).parent)],
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


class BuildAndInputControls(unittest.TestCase):
    def record(self, binary, revision="revision", fingerprint=None):
        return {
            "schema_version": 1,
            "trust": "caller_attested",
            "revision": revision,
            "source_clean": True,
            "binary_sha256": measure.sha(binary.read_bytes()),
            "rust_workspace_fingerprint": fingerprint
            or {"algorithm": "sha256-git-tree-v1", "sha256": "tree", "file_count": 1},
            "profile": "release",
            "features": [],
            "default_features": True,
            "command": ["cargo", "build", "--release", "-p", "volta_cli"],
            "rustc": "rustc fixture",
            "cargo": "cargo fixture",
        }

    def test_mislabeled_or_stale_build_record_is_refused(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            binary, record_path = root / "binary", root / "build.json"
            binary.write_bytes(b"original executable")
            original = self.record(binary)
            with patch.object(
                measure,
                "workspace_fingerprint",
                return_value=original["rust_workspace_fingerprint"],
            ):
                record_path.write_text(json.dumps(original))
                self.assertEqual(
                    measure.build_identity(record_path, "revision", binary)["revision"],
                    "revision",
                )
                for key, value in [
                    ("revision", "another revision"),
                    ("source_clean", False),
                    ("binary_sha256", "another executable"),
                    ("rust_workspace_fingerprint", {}),
                    ("features", ["logging"]),
                    ("profile", "dev"),
                    ("default_features", False),
                    ("trust", "independently_proven"),
                ]:
                    record_path.write_text(json.dumps({**original, key: value}))
                    with self.subTest(key=key), self.assertRaises(ValueError):
                        measure.build_identity(record_path, "revision", binary)

    def test_workspace_fingerprint_includes_embedded_viewer_assets(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            for path, text in [
                ("Cargo.toml", "[workspace]\n"),
                ("crates/viz/src/lib.rs", "// source\n"),
                ("crates/viz/viewer/app.js", "original asset\n"),
            ]:
                target = root / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text)
            subprocess.run(["git", "init", "-q", str(root)], check=True)

            def commit():
                subprocess.run(["git", "-C", str(root), "add", "."], check=True)
                subprocess.run(
                    [
                        "git",
                        "-C",
                        str(root),
                        "-c",
                        "user.name=Fixture",
                        "-c",
                        "user.email=fixture@example.invalid",
                        "commit",
                        "-qm",
                        "fixture",
                    ],
                    check=True,
                )

            commit()
            with patch.object(measure, "ROOT", root):
                original = measure.workspace_fingerprint("HEAD")
                self.assertEqual(original["file_count"], 3)
                (root / "crates/viz/viewer/app.js").write_text("changed asset\n")
                commit()
                self.assertNotEqual(
                    measure.workspace_fingerprint("HEAD")["sha256"], original["sha256"]
                )

    def main_fixture(self, root, mutation=None):
        source = f"s_wait_kmcnt 0x0\n{measure.LOAD}\n{measure.STORE}\n".encode()
        spec = b"dim N; array x[N]; array out[N]; out[i]=x[i]+1;\n"
        for path, data in [
            (measure.ASSEMBLY, source),
            (measure.SPEC, spec),
            ("harness.py", b"initial harness"),
        ]:
            target = root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        for role in ["baseline", "candidate"]:
            (root / role).write_bytes(role.encode())
            (root / (role + ".json")).write_text(json.dumps(self.record(root / role)))
        output = root / "output.json"
        argv = [
            "measure",
            "--baseline",
            str(root / "baseline"),
            "--baseline-revision",
            "baseline",
            "--candidate",
            str(root / "candidate"),
            "--candidate-revision",
            "candidate",
            "--baseline-build-record",
            str(root / "baseline.json"),
            "--candidate-build-record",
            str(root / "candidate.json"),
            "--output",
            str(output),
        ]
        calls = []

        def run(binary, case, safe, frozen_spec, access):
            self.assertEqual(frozen_spec.read_bytes(), spec)
            self.assertNotEqual(frozen_spec, root / measure.SPEC)
            calls.append((binary.name, case.stem))
            if mutation and len(calls) == 1:
                targets = {
                    "spec": root / measure.SPEC,
                    "source": root / measure.ASSEMBLY,
                    "harness": root / "harness.py",
                    "binary": root / "baseline",
                    "build": root / "baseline.json",
                    "frozen_spec": frozen_spec,
                    "case": case,
                }
                targets[mutation].write_bytes(b"changed during run")
            outcome = (
                "complete_specification_proof"
                if safe
                else "certified_tensor_bounds_rejection"
                if case.stem in {"load_bounds", "store_bounds"}
                and binary.name == "candidate"
                else "unknown"
            )
            return {"outcome": outcome}

        def pinned(command):
            path = command[-1].split(":", 1)[1]
            return {measure.ASSEMBLY: source, measure.SPEC: spec}[path]

        def build(path, revision, binary):
            return {
                **self.record(binary),
                "build_record_sha256": measure.sha(path.read_bytes()),
            }

        with (
            patch.object(measure, "ROOT", root),
            patch.object(measure, "__file__", str(root / "harness.py")),
            patch.object(
                measure, "git", side_effect=lambda *args: args[-1].split("^")[0]
            ),
            patch.object(measure.subprocess, "check_output", side_effect=pinned),
            patch.object(measure, "build_identity", side_effect=build),
            patch.object(measure, "run", side_effect=run),
            patch.object(sys, "argv", argv),
        ):
            measure.main()
        return output, calls

    def test_both_arms_use_the_same_snapshot_and_record_initial_harness_hash(self):
        with tempfile.TemporaryDirectory() as name:
            output, calls = self.main_fixture(Path(name))
            report = json.loads(output.read_text())
            self.assertEqual(len(calls), 12)
            self.assertEqual(report["harness_sha256"], measure.sha(b"initial harness"))
            self.assertEqual(
                report["seeded_bounds_detected"],
                {"baseline": 0, "candidate": 2, "total": 2},
            )

    def test_midrun_input_swaps_refuse_publication(self):
        for mutation in [
            "spec",
            "source",
            "harness",
            "binary",
            "build",
            "frozen_spec",
            "case",
        ]:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as name:
                with self.assertRaises(ValueError):
                    self.main_fixture(Path(name), mutation)
                self.assertFalse((Path(name) / "output.json").exists())


if __name__ == "__main__":
    unittest.main()
