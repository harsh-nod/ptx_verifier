"""Publication must preserve failures and exclude machine-specific artifacts."""
import importlib.util
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parent))
spec = importlib.util.spec_from_file_location("trace_cost_publish", Path(__file__).with_name("publish.py"))
publication = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publication)


class PublicationTests(unittest.TestCase):
    def test_projection_excludes_artifact_paths_even_from_first_observations(self):
        raw = {"id": "case", "arm": "candidate", "round": 0, "seconds": 2,
               "classification": "finding", "detected_expected_hazard": True,
               "command": ["/private/host/binary"], "directory": "/private/host/run",
               "launch_contract": {"source": "/private/host/source"}}
        rows, samples = publication.projection({"summaries": [{"id": "case", "baseline": {"first": raw}, "candidate": {"first": raw}}], "samples": [raw]})
        for row in (samples[0], rows[0]["baseline"]["first"], rows[0]["candidate"]["first"]):
            self.assertEqual(row["seconds"], 2)
            self.assertTrue(row["detected_expected_hazard"])
            self.assertFalse({"command", "directory", "launch_contract"} & row.keys())

    def test_failed_and_unknown_outcomes_are_not_filtered_from_public_samples(self):
        raw = [dict(id="case", arm="candidate", round=i, classification=kind, timed_out=kind == "timeout",
                    detected_expected_hazard=False, time_to_detection_seconds=None)
               for i, kind in enumerate(("inconclusive", "timeout", "finding"))]
        _, samples = publication.projection({"summaries": [], "samples": raw})
        self.assertEqual(samples, raw)

    def test_first_observation_failure_blocks_public_adoption(self):
        first = {"seconds": 0.02, "time_to_detection_seconds": 0.01, "timed_out": False,
                 "measurement_errors": [], "detected_expected_hazard": True}
        row = {"id": "hazard", "expectation": "hazard", "baseline_qualified": True,
               "baseline": {"first": first}, "candidate": {"first": first}}
        report = {"summaries": [row], "adoption": {"accepted": True, "failures": []}}
        self.assertTrue(publication.publication_gate(report)["accepted"])
        row["candidate"] = {"first": {**first, "timed_out": True, "detected_expected_hazard": False}}
        self.assertFalse(publication.publication_gate(report)["accepted"])
        self.assertTrue(report["adoption"]["accepted"])


if __name__ == "__main__":
    unittest.main()
