"""Hardware catalog/provenance/failure controls. These tests never contact a GPU."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

import suite
from profiles import suite_names, validate_inventory


def valid_identity(target="gfx950"):
    return dict(architecture=target + ":sramecc+:xnack-", wave_size=32 if target == "gfx1250" else 64,
                visible_device_count=1, logical_ordinal=0, name="test device", pci_bus_id="0000:01:00.0",
                hip_runtime_version=1, hip_driver_version=1, uuid_status="all_zero", uuid_hex=None, uuid_hip_error=0)


def expected_receipt():
    return dict(invocation_id="unique-current-invocation", target="gfx950", source_revision="a"*40,
                source_tree="b"*40, payload_sha256="c"*64, physical_device=0)


def valid_receipt():
    return dict(expected_receipt(), status="PASS", sources_unchanged=True,
                device_identity=valid_identity(),
                commands=[dict(returncode=0)],
                suites=[dict(name=name, status="PASS") for name in suite_names("gfx950")])


class CatalogControls(unittest.TestCase):
    def test_canonical_output_labels_keep_exact_accounting(self):
        expected = (30, 16640, 38400, 655360)
        for qualifier in ("", "original/native "):
            summary = (f"PASS: 30 launches, 16640 complete {qualifier}outputs, "
                       "38400 input bytes, 655360 guard bytes\n")
            with self.subTest(qualifier=qualifier):
                suite.validate_output_accounting(summary, expected)

    def test_output_summary_cannot_hide_changed_counts_omission_or_duplicate(self):
        expected = (30, 16640, 38400, 655360)
        summary = ("PASS: 30 launches, 16640 complete outputs, "
                   "38400 input bytes, 655360 guard bytes\n")
        for token in ("30 launches", "16640 complete", "38400 input", "655360 guard"):
            changed = summary.replace(token, token.replace(token.split()[0], "0"))
            with self.subTest(token=token), self.assertRaisesRegex(ValueError, "accounting"):
                suite.validate_output_accounting(changed, expected)
        for changed in ("PASS\n", summary + summary, summary.replace("complete outputs", "complete sampled outputs"),
                        summary.replace("complete outputs", "complete original outputs"),
                        summary.replace("complete outputs", "complete native outputs"),
                        summary.replace(", 655360 guard bytes", "")):
            with self.subTest(summary=changed), self.assertRaisesRegex(ValueError, "accounting"):
                suite.validate_output_accounting(changed, expected)

    def test_all_existing_positive_host_drivers_are_registered(self):
        for target, count in (("gfx942", 3), ("gfx950", 12), ("gfx1250", 18)):
            validate_inventory(suite.ROOT, target)
            self.assertEqual(len(suite_names(target)), count)
        self.assertIn("matrix_features", suite_names("gfx1250"))
        self.assertIn("mechanism_features", suite_names("gfx1250"))

    def test_missing_or_unregistered_driver_refuses_complete_gate(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            with self.assertRaisesRegex(ValueError, "inventory mismatch"):
                validate_inventory(root, "gfx942")
            directory = root / "tests/gfx942/hardware"
            directory.mkdir(parents=True)
            (directory / "native.cpp").write_text("")
            (directory / "forgotten.cpp").write_text("")
            with self.assertRaisesRegex(ValueError, "unregistered"):
                validate_inventory(root, "gfx942")

    def test_wrong_target_and_conflicting_identity_are_refused(self):
        with self.assertRaises(ValueError):
            suite.validate_identity(valid_identity("gfx942"), "gfx950")
        for key, value in (("wave_size", 32), ("visible_device_count", 2), ("logical_ordinal", 1)):
            identity = valid_identity()
            identity[key] = value
            with self.assertRaises(ValueError):
                suite.validate_identity(identity, "gfx950")

    def test_host_device_and_rocm_parameters_are_validated_without_ssh(self):
        request = dict(target="gfx950", host="gpu-host", device=0)
        for update in (dict(host="-oProxyCommand=bad"), dict(host="host;command"), dict(host="host\nother"),
                       dict(device=-1), dict(device=True), dict(target="gfx9999"), dict(rocm="relative"),
                       dict(rocm="/opt/rocm\ncommand"), dict(local=True)):
            with self.subTest(update=update), self.assertRaises(ValueError):
                suite.validate_request(dict(request, **update))
        self.assertEqual(suite.validate_request(request)["rocm"], "/opt/rocm")
        with self.assertRaises(ValueError):
            suite.requests_from_config(dict(targets=[request, request]))


class ReceiptControls(unittest.TestCase):
    def test_valid_receipt_requires_every_suite_and_exact_provenance(self):
        suite.validate_remote_receipt(valid_receipt(), expected_receipt())
        for key in expected_receipt():
            bad = valid_receipt()
            bad[key] = "different"
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "mismatch"):
                suite.validate_remote_receipt(bad, expected_receipt())
        for change in (dict(status="INCOMPLETE"), dict(status="FAIL"), dict(sources_unchanged=False),
                       dict(suites=valid_receipt()["suites"][:-1]), dict(commands=[]), dict(commands=[dict(returncode=1)])):
            with self.subTest(change=change), self.assertRaises(ValueError):
                suite.validate_remote_receipt(dict(valid_receipt(), **change), expected_receipt())

    def test_stale_missing_or_malformed_remote_receipt_never_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            receipt = Path(tmp) / "receipt.json"
            with self.assertRaises(FileNotFoundError):
                suite.load_remote_receipt(receipt, expected_receipt())
            receipt.write_text('{"status":"PASS"}')
            with self.assertRaisesRegex(ValueError, "mismatch"):
                suite.load_remote_receipt(receipt, expected_receipt())
            receipt.write_text("[]")
            with self.assertRaisesRegex(ValueError, "not an object"):
                suite.load_remote_receipt(receipt, expected_receipt())
            receipt.write_text("not json")
            with self.assertRaises(json.JSONDecodeError):
                suite.load_remote_receipt(receipt, expected_receipt())

    def test_preflight_failure_replaces_previous_pass(self):
        with tempfile.TemporaryDirectory() as tmp, mock.patch.object(suite, "ROOT", Path(tmp) / "repo"):
            out = Path(tmp) / "results"
            out.mkdir()
            (out / "result.json").write_text('{"status":"PASS"}')
            with mock.patch.dict(suite.os.environ, {}, clear=True), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(suite.main(["--target", "gfx950", "--host", "gpu", "--device", "-1", "--work-dir", str(out)]), 1)
            self.assertEqual(json.loads((out / "result.json").read_text())["status"], "FAIL")

    def test_target_failure_does_not_hide_other_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = root / "config.json"
            config.write_text(json.dumps(dict(targets=[dict(target=t, host=t+"-host", device=0) for t in ("gfx942", "gfx950", "gfx1250")])))
            snapshot = dict(revision="a"*40, tree="b"*40, files={"source": "hash"})
            def stage(_root, staging, _snapshot, target, volta):
                (staging / "source-manifest.json").write_text("{}")
                return dict(verifier=None)
            def remote(request, staging, out, expected):
                if request["target"] != "gfx950":
                    raise RuntimeError("target-specific failure")
                record = dict(device_identity=valid_identity())
                record["suites"] = [dict(name=n, status="PASS") for n in suite_names("gfx950")]
                (out / "remote-result.json").write_text(json.dumps(record))
                return record
            with mock.patch.object(suite, "ROOT", root / "repo"), mock.patch.object(suite, "committed_sources", return_value=snapshot), mock.patch.object(suite, "validate_inventory"), mock.patch.object(suite, "stage", side_effect=stage), mock.patch.object(suite, "remote_run", side_effect=remote), mock.patch.object(suite, "verify_payload"), mock.patch.dict(suite.os.environ, {}, clear=True), contextlib.redirect_stdout(io.StringIO()):
                out = root / "results"
                self.assertEqual(suite.main(["--config", str(config), "--work-dir", str(out)]), 1)
            result = json.loads((out / "result.json").read_text())
            self.assertEqual({k:v["status"] for k,v in result["targets"].items()}, dict(gfx942="FAIL", gfx950="PASS", gfx1250="FAIL"))


class SourceControls(unittest.TestCase):
    def test_supplied_verifier_binary_is_hash_bound_and_mutation_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            binary = root / "verifier"
            binary.write_bytes(b"original binary")
            snapshot = dict(revision="a"*40, tree="b"*40, files={})
            first = root / "first"
            first.mkdir()
            with mock.patch.object(suite, "verify", return_value=[]):
                result = suite.stage(root, first, snapshot, "gfx950", binary)
            self.assertEqual(result["verifier_identity"]["binary_sha256"], suite.sha(binary))
            self.assertEqual(result["verifier_identity"]["trust"], "caller_supplied_binary")
            second = root / "second"
            second.mkdir()
            def change(*args):
                binary.write_bytes(b"different binary")
                return []
            with mock.patch.object(suite, "verify", side_effect=change), self.assertRaisesRegex(ValueError, "binary changed"):
                suite.stage(root, second, snapshot, "gfx950", binary)

    def test_changed_or_symlinked_payload_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.s"
            source.write_text("exact assembly")
            manifest = dict(files={"source.s": suite.sha(source)})
            suite.verify_payload(root, manifest)
            source.write_text("changed assembly")
            with self.assertRaisesRegex(ValueError, "mismatch"):
                suite.verify_payload(root, manifest)
            source.unlink()
            source.symlink_to(root / "missing")
            with self.assertRaisesRegex(ValueError, "mismatch"):
                suite.verify_payload(root, manifest)
            with self.assertRaisesRegex(ValueError, "mismatch"):
                suite.verify_payload(root, dict(files={"../outside": "anything"}))

    def test_revision_binding_rejects_changed_committed_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "tests/amdgpu/hardware/suite.py"
            source.parent.mkdir(parents=True)
            source.write_text("source bytes")
            for argv in (["git", "init", "-q"], ["git", "add", "."], ["git", "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture"]):
                subprocess.run(argv, cwd=root, check=True, capture_output=True)
            snapshot = suite.committed_sources(root, None)
            self.assertEqual(snapshot["files"]["tests/amdgpu/hardware/suite.py"], suite.sha(source))
            untracked = source.parent / "new-driver.cpp"
            untracked.write_text("unregistered code")
            with self.assertRaisesRegex(ValueError, "uncommitted"):
                suite.committed_sources(root, snapshot["revision"])
            untracked.unlink()
            source.write_text("changed bytes")
            with self.assertRaisesRegex(ValueError, "differs from stated revision"):
                suite.committed_sources(root, snapshot["revision"])


class ProcessControls(unittest.TestCase):
    def execution(self, directory):
        execution = object.__new__(suite.Execution)
        execution.root = execution.out = directory
        execution.request = dict(target="gfx950")
        execution.env = {}
        execution.record = dict(status="INCOMPLETE", commands=[], suites=[])
        return execution

    def test_failed_process_with_pass_text_cannot_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            execution = self.execution(directory)
            result = subprocess.CompletedProcess(["driver"], 1, "PASS stale text\n", "actual failure\n")
            with mock.patch.object(suite.subprocess, "run", return_value=result), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(RuntimeError):
                execution.run("driver", ["driver"])
            record = json.loads((directory / "result.json").read_text())
            self.assertEqual(record["commands"][0]["returncode"], 1)
            self.assertEqual(record["status"], "INCOMPLETE")
            self.assertEqual((directory / record["commands"][0]["stdout"]["path"]).read_text(), "PASS stale text\n")

    def test_timeout_retains_partial_output_and_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            execution = self.execution(directory)
            error = subprocess.TimeoutExpired(["driver"], 3, output=b"partial output", stderr=b"partial error")
            with mock.patch.object(suite.subprocess, "run", side_effect=error), contextlib.redirect_stdout(io.StringIO()), self.assertRaises(RuntimeError):
                execution.run("driver", ["driver"], timeout=3)
            command = execution.record["commands"][0]
            self.assertTrue(command["timed_out"])
            self.assertIsNone(command["returncode"])
            self.assertEqual((directory / command["stderr"]["path"]).read_text(), "partial error")

    def test_success_text_without_nested_receipt_is_insufficient(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            execution = self.execution(directory)
            with mock.patch.object(execution, "run", return_value="PASS"), self.assertRaises(FileNotFoundError):
                execution.nested("missing", [], directory / "missing.json")
            self.assertEqual(execution.record["suites"], [])


if __name__ == "__main__":
    unittest.main()
