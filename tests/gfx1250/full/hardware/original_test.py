"""CPU-only negative controls for the full-shape hardware receipt gate."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("original_run.py")
SPEC = importlib.util.spec_from_file_location("original_run", SCRIPT)
runner = importlib.util.module_from_spec(SPEC)
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


class ReceiptControls(unittest.TestCase):
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
