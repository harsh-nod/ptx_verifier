"""Refuse unsupported, incomplete or contradictory measurement claims."""

from pathlib import Path
import subprocess
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
TensorBoundsViolation { address: 256, bytes: 256, configured_lds_bytes: 256 }
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
        ):
            with self.subTest(text=text), self.assertRaises(AssertionError):
                self.classify(text, 0, True)

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
            with self.subTest(text=text, code=code), self.assertRaises(AssertionError):
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
                        self.assertRaises(AssertionError),
                    ):
                        self.classify(stdout, code, safe, stderr)

    def test_unknown_is_retained_without_detection_credit(self):
        self.assertEqual(
            self.classify("GRAPH VERIFICATION: UNKNOWN", 2)["outcome"], "unknown"
        )
        with self.assertRaises(AssertionError):
            self.classify("unrelated error", 1)


if __name__ == "__main__":
    unittest.main()
