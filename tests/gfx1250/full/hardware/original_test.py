"""CPU-only negative controls for the full-shape hardware receipt gate."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import tarfile
import unittest

SCRIPT = Path(__file__).with_name("original_run.py")
SPEC = importlib.util.spec_from_file_location("original_run", SCRIPT)
runner = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = runner
SPEC.loader.exec_module(runner)


def result():
    return {
        "status": "pass", "architecture": "gfx1250", "wave_size": 32,
        "reference_controls": "pass", "patterns": 3,
        "cases": [{"kernel": name, "outputs": outputs * 3, "launches": 3,
                   "unchanged_input_bytes": inputs * 3,
                   "unchanged_guard_bytes": buffers * 8192 * 3,
                   "max_absolute_error": 0.0}
                  for name, (outputs, inputs, buffers) in runner.CONTRACT.items()],
    }


def identity():
    return {
        "logical_ordinal": 0,
        "visible_device_count": 1,
        "name": "AMD Instinct test device",
        "architecture": "gfx1250:xnack+",
        "wave_size": 32,
        "pci_bus_id": "0000:43:00.0",
        "uuid_status": "available",
        "uuid_hex": "00112233445566778899aabbccddeeff",
        "uuid_hip_error": 0,
        "hip_runtime_version": 10020000,
        "hip_driver_version": 10010000,
    }


class ReceiptControls(unittest.TestCase):
    def test_staging_bundle_retains_exact_files_and_rejects_ambiguous_paths(self):
        from dataclasses import replace

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "nested").mkdir()
            (root / "nested/input.s").write_bytes(b"exact compiler output\n")
            (root / "runner.py").write_bytes(b"print('gate')\n")
            files = ("nested/input.s", "runner.py")
            profile = replace(runner.BASIC, files=files)
            destination = root / "inputs.tar.gz"
            runner.staging_archive(root, destination, profile)
            with tarfile.open(destination) as archive:
                self.assertEqual(list(files), archive.getnames())
                for name in files:
                    self.assertEqual((root / name).read_bytes(), archive.extractfile(name).read())
            for invalid in [(), (files[0], files[0]), ("../input.s",), ("/input.s",), ("./runner.py",)]:
                with self.subTest(files=invalid), self.assertRaises(ValueError):
                    runner.staging_archive(root, destination, replace(profile, files=invalid))
            (root / "alias.py").symlink_to(root / "runner.py")
            with self.assertRaises(ValueError):
                runner.staging_archive(root, destination, replace(profile, files=("alias.py",)))

    def test_device_identity_requires_actual_versions_target_and_physical_identifier(
        self,
    ):
        runner.validate_device_identity(identity())
        for status, error in (("not_supported", 801), ("all_zero", 0)):
            value = identity()
            value.update(uuid_status=status, uuid_hex=None, uuid_hip_error=error)
            runner.validate_device_identity(value)
        for field, bad in (
            ("logical_ordinal", 1),
            ("visible_device_count", 4),
            ("wave_size", 64),
            ("architecture", "gfx950"),
            ("name", ""),
            ("pci_bus_id", "unknown"),
            ("hip_runtime_version", 0),
            ("hip_driver_version", True),
            ("uuid_status", "missing"),
            ("uuid_hex", "0" * 32),
            ("uuid_hex", "bad"),
            ("uuid_hip_error", 1),
        ):
            value = identity()
            value[field] = bad
            with self.subTest(field=field, bad=bad), self.assertRaises(ValueError):
                runner.validate_device_identity(value)
        for field in identity():
            value = identity()
            del value[field]
            with self.subTest(missing=field), self.assertRaises(ValueError):
                runner.validate_device_identity(value)

    def test_object_codeobject_and_identity_probe_artifacts_are_all_hashed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            paths = [
                root / name
                for name in (
                    "driver",
                    "attention.o",
                    "attention.hsaco",
                    "device_identity.cpp",
                    "device_identity",
                )
            ]
            for path in paths:
                path.write_text(path.name)
            hashes = runner.built_artifact_hashes(paths[0], [paths[2]], paths[3:])
            self.assertEqual({path.name: runner.sha256(path) for path in paths}, hashes)
            paths[1].unlink()
            with self.assertRaises(FileNotFoundError):
                runner.built_artifact_hashes(paths[0], [paths[2]], paths[3:])
            with self.assertRaises(ValueError):
                runner.built_artifact_hashes(paths[0], [], paths[3:])

    def test_matrix_gate_rejects_missing_padding_accounting(self):
        from original_matrix_run import MATRIX

        report = {**result(), "patterns": 4, "cases": []}
        for name, (outputs, inputs, buffers) in MATRIX.contract.items():
            report["cases"].append(
                {
                    "kernel": name,
                    "outputs": outputs * 4,
                    "launches": 4,
                    "unchanged_input_bytes": inputs * 4,
                    "unchanged_guard_bytes": buffers * 8192 * 4,
                    "unchanged_gap_bytes": MATRIX.gaps[name] * 4,
                    "max_absolute_error": 0,
                }
            )
        runner.validate_result(report, 4, MATRIX)
        report["cases"][0]["unchanged_gap_bytes"] -= 2
        with self.assertRaises(ValueError):
            runner.validate_result(report, 4, MATRIX)

    def test_rejects_incomplete_or_invalid_execution(self):
        baseline = result()
        runner.validate_result(baseline, 3)
        variants = []
        for key, value in [("status", "unsupported"), ("architecture", "gfx950"),
                           ("wave_size", 64), ("patterns", 2), ("reference_controls", "fail")]:
            changed = copy.deepcopy(baseline)
            changed[key] = value
            variants.append(changed)
        variants.append({**baseline, "cases": baseline["cases"][:-1]})
        variants.append({**baseline, "cases": baseline["cases"][:-1] + [baseline["cases"][0]]})
        for key in ("outputs", "launches", "unchanged_input_bytes", "unchanged_guard_bytes"):
            changed = copy.deepcopy(baseline)
            changed["cases"][0][key] -= 1
            variants.append(changed)
        for value in (float("nan"), float("inf"), -1, True):
            changed = copy.deepcopy(baseline)
            changed["cases"][0]["max_absolute_error"] = value
            variants.append(changed)
        for changed in variants:
            with self.subTest(changed=changed), self.assertRaises(ValueError):
                runner.validate_result(changed, 3)

    def test_failed_preflight_invalidates_previous_success(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "receipt.json"
            path.write_text(json.dumps({"status": "pass", "invocation_id": "old"}))
            process = subprocess.run(
                [sys.executable, str(SCRIPT), "--local", "--device", "-1", "--result", str(path)],
                capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(process.returncode, 1)
            receipt = json.loads(path.read_text())
            self.assertEqual(receipt["status"], "fail")
            self.assertNotEqual(receipt["invocation_id"], "old")

    def test_rejects_device_or_architecture_override(self):
        for key in ("HIP_VISIBLE_DEVICES", "ROCR_VISIBLE_DEVICES", "CUDA_VISIBLE_DEVICES",
                    "GPU_DEVICE_ORDINAL", "HSA_OVERRIDE_GFX_VERSION", "HSA_OVERRIDE_GFX_VERSION_0"):
            with self.subTest(key=key), self.assertRaises(ValueError):
                runner.device_environment(2, {key: "0"})


if __name__ == "__main__":
    unittest.main()
