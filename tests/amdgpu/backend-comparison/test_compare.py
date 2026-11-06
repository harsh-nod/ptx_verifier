"""Controls for incomplete transcripts and denominator-preserving summaries."""

import importlib.util
import copy
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location(
    "amd_backend_comparison", Path(__file__).with_name("compare.py")
)
comparison = importlib.util.module_from_spec(spec)
spec.loader.exec_module(comparison)

PASS = """  AMD trace completeness (native) PASS
  AMD wait and register readiness (native) PASS
  AMD memory-conflict freedom (native) PASS
  AMD workgroup barrier generations (native) PASS
GRAPH VERIFICATION: VERIFIED
"""


class ComparisonTests(unittest.TestCase):
    def observation(
        self, stdout, *, code=0, timeout=False, verify=False, case=None, **fields
    ):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "stdout").write_text(stdout)
            (directory / "stderr").write_text("")
            return comparison.observations(
                {"returncode": code, "timed_out": timeout, **fields},
                directory,
                verify=verify,
                case=case,
            )

    def test_complete_graph_and_all_four_properties_are_required(self):
        self.assertTrue(self.observation(PASS)["graph_accepted"])
        for changed in (
            PASS.replace("AMD trace completeness", "unrelated property"),
            PASS.replace("  AMD memory-conflict freedom (native) PASS\n", ""),
            PASS.replace("VERIFIED", "UNKNOWN"),
            PASS + "execution stopped: unsupported\n",
            PASS + "  AMD trace completeness (native) PASS\n",
        ):
            self.assertFalse(self.observation(changed)["graph_accepted"])
        self.assertFalse(self.observation(PASS, code=2)["graph_accepted"])
        self.assertFalse(self.observation(PASS, timeout=True)["graph_accepted"])

    def test_partial_or_contradictory_hazard_cannot_count_as_detection(self):
        prop = "AMD wait and register readiness"
        case = {"expectation": "hazard", "required_property": prop}
        text = PASS.replace(prop + " (native) PASS", prop + " (native) FAIL").replace(
            "VERIFIED", "REJECTED"
        )
        values = dict(
            code=1,
            case=case,
            detected_property=prop,
            detected_expected_hazard=True,
            time_to_detection_seconds=0.01,
            seconds=0.02,
        )
        self.assertTrue(self.observation(text, **values)["detected_expected_hazard"])
        for changed in (
            text + "GRAPH VERIFICATION: VERIFIED\n",
            text + "VERDICT: UNKNOWN\n",
            text.replace(
                "barrier generations (native) PASS",
                "barrier generations (native) UNKNOWN",
            ),
            text + "  AMD trace completeness (native) PASS\n",
            text.replace(
                "AMD trace completeness (native) PASS",
                "AMD trace completeness (native) FAIL",
            ),
        ):
            self.assertFalse(
                self.observation(changed, **values)["detected_expected_hazard"]
            )
        for invalid in (None, -1, float("nan"), float("inf"), 0.03):
            self.assertFalse(
                self.observation(
                    text, **{**values, "time_to_detection_seconds": invalid}
                )["detected_expected_hazard"]
            )

    def test_proof_requires_all_checks_and_complete_acceptance(self):
        text = (
            PASS
            + "VC check: spec  elements: 64\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
        )
        self.assertTrue(self.observation(text, verify=True)["proof_accepted"])
        for changed in (
            text.replace("ACCEPT", "UNKNOWN"),
            text.replace("EQUIVALENT (matches spec)", ""),
            text + "NOT EQUIVALENT\n",
            text.replace(
                "barrier generations (native) PASS", "barrier generations (native) FAIL"
            ),
            text + "GRAPH VERIFICATION: REJECTED\n",
            text + "VERDICT: ACCEPT\n",
            text + "EQUIVALENT (matches spec)\n",
            text + "EARLY_READINESS: unexpected\n",
        ):
            self.assertFalse(self.observation(changed, verify=True)["proof_accepted"])

    def test_candidate_miss_cannot_create_a_speedup_from_partial_success(self):
        case = {
            "id": "x",
            "target": "gfx950",
            "family": "copy",
            "expectation": "hazard",
        }
        analysis = {"classification": "finding", "detected_expected_hazard": True}
        baseline = {"x": {"qualified": True, "analysis": analysis}}
        candidate = {
            "x": {
                "qualified": False,
                "analysis": {**analysis, "detected_expected_hazard": False},
            }
        }
        samples = []
        for arm in ("baseline", "candidate"):
            for index in range(32):
                detected = arm == "baseline" or index != 31
                samples.append(
                    {
                        "id": "x",
                        "arm": arm,
                        "round": index,
                        "time_to_detection_seconds": 0.01 if detected else None,
                        "detected_expected_hazard": detected,
                        "seconds": 0.02,
                        "timed_out": False,
                        "measurement_errors": [],
                    }
                )
        row = comparison.summaries([{"case": case}], samples, baseline, candidate)[0]
        self.assertIsNone(row["candidate"]["median_seconds"])
        self.assertIsNone(row["candidate_over_baseline_median"])
        self.assertEqual(row["candidate"]["repeats"], 31)
        self.assertEqual(row["candidate"]["successful_repeats"], 30)

    def retained(self, directory, binary, item, *, verify=False, export=False):
        directory.mkdir(parents=True)
        text = PASS
        if verify:
            text += "VC check: spec  elements: 2\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
        else:
            text += "  output 'out': 2 element(s) written\n"
        (directory / "stdout").write_text(text)
        (directory / "stderr").write_text("")
        (directory / "resources.txt").write_text(
            "max_rss_kib=1024\nuser_seconds=0.01\nsystem_seconds=0.00\n"
        )
        if export:
            (directory / "outputs.vexpr").write_text(
                'volta-expr 1\nn0 = int 0\nout "out" 0 n0\nout "out" 1 n0\n'
            )
        return comparison.finish_observation(
            {
                "command": comparison.expected_command(
                    binary, item, directory, verify=verify, export=export
                ),
                "seconds": 0.02,
                "returncode": 0,
                "timed_out": False,
                "early_readiness_enabled": False,
                "launch_contract": None,
                "time_to_detection_seconds": None,
                "detected_property": None,
            },
            item,
            directory,
            verify=verify,
            export=export,
        )

    def qualification_fixture(self, root, role="baseline"):
        root.mkdir(parents=True)
        binary = root / "volta"
        binary.write_bytes(b"fixture executable")
        assembly = root / "copy.s"
        assembly.write_text("s_endpgm\n")
        item = {
            "case": {
                "id": "copy",
                "target": "gfx950",
                "family": "copy",
                "expectation": "safe",
                "kernel": "copy",
                "spec": "fixture.spec",
                "expected_outputs": 2,
                "output_indices": {"out": [0, 1]},
                "block": [64, 1, 1],
                "grid": [1, 1, 1],
                "workgroup": [0, 0, 0],
                "arrays": [
                    {
                        "name": "out",
                        "base_address": 4096,
                        "element_size": 4,
                        "length": 2,
                        "kind": "out",
                    }
                ],
                "params": [],
            },
            "assembly": str(assembly),
            "assembly_sha256": comparison.sha(assembly),
        }
        record = {
            "trust": "caller_attested",
            "source_clean": True,
            "revision": comparison.BASE,
            "source_tree": subprocess.check_output(
                [
                    "git",
                    "-C",
                    str(comparison.ROOT),
                    "rev-parse",
                    comparison.BASE + "^{tree}",
                ],
                text=True,
            ).strip(),
            "binary_sha256": comparison.sha(binary),
            "comparison_role": role,
            "profile": "release",
            "default_features": True,
            "features": [],
            "rustc": "test rustc",
            "cargo": "test cargo",
        }
        record_path = root / "build.json"
        comparison.write(record_path, record)
        identity = comparison.build_identity(binary, record_path, comparison.BASE)
        directory = root / "copy"
        row = {
            "id": "copy",
            "expectation": "safe",
            "qualified": True,
            "analysis": self.retained(
                directory / "analysis", binary, item, export=True
            ),
            "proof": self.retained(directory / "proof", binary, item, verify=True),
        }
        report = {
            "status": "COMPLETE",
            "role": role,
            "plan_sha256": "frozen",
            "identity": identity,
            "results": [row],
            "eligible": ["copy"],
        }
        path = root / "report.json"
        comparison.write(path, report)
        return path, report, {"cases": [item], "input_sha256": {}}

    def test_qualification_audit_rechecks_every_retained_artifact(self):
        for name in ("stdout", "stderr", "resources.txt", "outputs.vexpr"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                path, _, plan = self.qualification_fixture(
                    Path(temporary) / "qualification"
                )
                comparison.audit_qualification(path, plan, "frozen", "baseline")
                artifact = path.parent / "copy" / "analysis" / name
                artifact.write_bytes(artifact.read_bytes() + b"tampered\n")
                with self.assertRaisesRegex(ValueError, "artifact changed"):
                    comparison.audit_qualification(path, plan, "frozen", "baseline")

    def test_complete_coordinates_and_proof_count_are_recomputed(self):
        for change in ("coordinates", "coverage", "proof count", "unknown"):
            with (
                self.subTest(change=change),
                tempfile.TemporaryDirectory() as temporary,
            ):
                path, report, plan = self.qualification_fixture(
                    Path(temporary) / "qualification"
                )
                analysis = path.parent / "copy" / "analysis"
                proof = path.parent / "copy" / "proof"
                if change == "coordinates":
                    artifact = analysis / "outputs.vexpr"
                    artifact.write_text(
                        artifact.read_text().replace('out "out" 1 n0\n', "")
                    )
                    report["results"][0]["analysis"]["output_expressions_sha256"] = (
                        comparison.sha(artifact)
                    )
                else:
                    directory = proof if change == "proof count" else analysis
                    artifact = directory / "stdout"
                    text = artifact.read_text()
                    if change == "coverage":
                        text = text.replace("2 element(s)", "1 element(s)")
                    elif change == "proof count":
                        text = text.replace("elements: 2", "elements: 1")
                    else:
                        text += "UNKNOWN\n"
                    artifact.write_text(text)
                    field = "proof" if directory == proof else "analysis"
                    report["results"][0][field]["stdout_sha256"] = comparison.sha(
                        artifact
                    )
                comparison.write(path, report)
                with self.assertRaisesRegex(
                    ValueError, "observation differs|proof count differs"
                ):
                    comparison.audit_qualification(path, plan, "frozen", "baseline")

    def test_qualification_refuses_changed_command_identity_and_eligibility(self):
        for change in (
            "sample",
            "launch",
            "eligibility",
            "binary",
            "build record",
            "diagnostics",
            "resources",
        ):
            with (
                self.subTest(change=change),
                tempfile.TemporaryDirectory() as temporary,
            ):
                path, report, plan = self.qualification_fixture(
                    Path(temporary) / "qualification"
                )
                row = report["results"][0]
                if change == "sample":
                    argv = row["proof"]["command"]
                    argv[argv.index("--sample") + 1] = "1"
                elif change == "launch":
                    argv = row["analysis"]["command"]
                    argv[argv.index("--block") + 1] = "1,1,1"
                elif change == "eligibility":
                    row["qualified"] = False
                elif change == "binary":
                    Path(report["identity"]["binary"]).write_bytes(
                        b"changed executable"
                    )
                elif change == "build record":
                    receipt = Path(report["identity"]["build_record"])
                    receipt.write_text(receipt.read_text() + "\n")
                elif change == "diagnostics":
                    row["analysis"]["diagnostics_sha256"] = "fabricated"
                else:
                    row["analysis"]["peak_rss_kib"] = 1
                comparison.write(path, report)
                with self.assertRaises(ValueError):
                    comparison.audit_qualification(path, plan, "frozen", "baseline")

    def test_materialized_assembly_and_plan_are_pinned_alongside_helpers(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            helper, assembly, plan_path = (
                root / name for name in ("helper.py", "kernel.s", "plan.json")
            )
            for artifact in (helper, assembly, plan_path):
                artifact.write_text("original")
            plan = {
                "input_sha256": {str(helper): comparison.sha(helper)},
                "cases": [
                    {
                        "assembly": str(assembly),
                        "assembly_sha256": comparison.sha(assembly),
                    }
                ],
            }
            pins = comparison.plan_pins(plan_path, comparison.sha(plan_path), plan)
            comparison.unchanged(pins)
            for artifact in (helper, assembly, plan_path):
                artifact.write_text("changed")
                with self.assertRaises(ValueError):
                    comparison.unchanged(pins)
                artifact.write_text("original")

    def test_comparisons_require_identical_toolchain_profile_and_features(self):
        baseline = dict(
            rustc="a", cargo="b", profile="release", default_features=True, features=[]
        )
        comparison.matching_builds(baseline, copy.deepcopy(baseline))
        for key in baseline:
            changed = {**baseline, key: "different"}
            with self.subTest(field=key), self.assertRaisesRegex(ValueError, key):
                comparison.matching_builds(baseline, changed)

    def test_duplicate_missing_rounds_and_invalid_metrics_cannot_make_ratios(self):
        case = {
            "id": "x",
            "target": "gfx950",
            "family": "copy",
            "expectation": "hazard",
        }
        qualification = {
            "x": {
                "qualified": True,
                "analysis": {
                    "classification": "finding",
                    "detected_expected_hazard": True,
                },
            }
        }
        samples = [
            {
                "id": "x",
                "arm": arm,
                "round": index,
                "seconds": 0.02,
                "time_to_detection_seconds": 0.01,
                "detected_expected_hazard": True,
                "timed_out": False,
                "measurement_errors": [],
            }
            for arm in ("baseline", "candidate")
            for index in range(32)
        ]
        result = comparison.summaries(
            [{"case": case}], samples, qualification, qualification
        )[0]
        self.assertEqual(result["candidate_over_baseline_median"], 1)
        for change in (
            "duplicate",
            "missing",
            "resource",
            "nan",
            "inf",
            "negative",
            "after completion",
        ):
            altered = copy.deepcopy(samples)
            row = altered[-1]
            if change == "duplicate":
                row["round"] = 30
            elif change == "missing":
                altered.pop()
            elif change == "resource":
                row["measurement_errors"] = ["missing resource"]
            else:
                row["time_to_detection_seconds"] = {
                    "nan": float("nan"),
                    "inf": float("inf"),
                    "negative": -1,
                    "after completion": 1,
                }[change]
            with self.subTest(change=change):
                result = comparison.summaries(
                    [{"case": case}], altered, qualification, qualification
                )[0]
                self.assertIsNone(result["candidate_over_baseline_median"])

    def test_missing_and_duplicate_resource_fields_are_ineligible(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            self.assertTrue(
                comparison.resource_observations(path)["measurement_errors"]
            )
            (path / "resources.txt").write_text(
                "max_rss_kib=1024\nmax_rss_kib=2\nuser_seconds=0.01\nsystem_seconds=0\n"
            )
            self.assertTrue(
                comparison.resource_observations(path)["measurement_errors"]
            )
            (path / "resources.txt").write_text(
                "max_rss_kib=1024\nuser_seconds=nan\nsystem_seconds=-1\n"
            )
            self.assertTrue(
                comparison.resource_observations(path)["measurement_errors"]
            )

    def test_collection_audit_binds_schedule_samples_commands_and_published_numbers(
        self,
    ):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            baseline_path, baseline, plan = self.qualification_fixture(
                root / "baseline"
            )
            candidate_path, candidate, _ = self.qualification_fixture(
                root / "candidate", "candidate"
            )
            item = plan["cases"][0]
            # Both arms must execute the same materialized assembly, even though
            # their retained logs and executable declarations live separately.
            for mode, options in (
                ("analysis", {"export": True}),
                ("proof", {"verify": True}),
            ):
                candidate["results"][0][mode]["command"] = comparison.expected_command(
                    Path(candidate["identity"]["binary"]),
                    item,
                    candidate_path.parent / "copy" / mode,
                    **options,
                )
            plan_path = root / "plan.json"
            comparison.write(plan_path, plan)
            plan_hash = comparison.sha(plan_path)
            for path, qualification in (
                (baseline_path, baseline),
                (candidate_path, candidate),
            ):
                qualification["plan_sha256"] = plan_hash
                comparison.write(path, qualification)
            output = root / "timing"
            output.mkdir()
            schedule = comparison.schedule_for(plan["cases"])
            qualifications = {"baseline": baseline, "candidate": candidate}
            samples = []
            for pair in schedule:
                for arm in pair["arms"]:
                    directory = output / f"{pair['round']}-copy-{arm}"
                    observation = self.retained(
                        directory, Path(qualifications[arm]["identity"]["binary"]), item
                    )
                    samples.append(
                        {
                            "round": pair["round"],
                            "id": "copy",
                            "arm": arm,
                            **observation,
                        }
                    )
            comparison.write(output / "schedule.json", schedule)
            comparison.write(output / "samples.json", samples)
            rows = {
                arm: {"copy": value["results"][0]}
                for arm, value in qualifications.items()
            }
            report = {
                "status": "COMPLETE",
                "plan_sha256": plan_hash,
                "repeats": comparison.REPEATS,
                "seed": comparison.SEED,
                "qualification_paths": {
                    "baseline": str(baseline_path),
                    "candidate": str(candidate_path),
                },
                "qualification_sha256": {
                    "baseline": comparison.sha(baseline_path),
                    "candidate": comparison.sha(candidate_path),
                },
                "identities": {
                    arm: value["identity"] for arm, value in qualifications.items()
                },
                "eligible": ["copy"],
                "samples_sha256": comparison.sha(output / "samples.json"),
                "schedule_sha256": comparison.sha(output / "schedule.json"),
                "results": comparison.summaries(
                    plan["cases"], samples, rows["baseline"], rows["candidate"]
                ),
            }
            report_path = output / "report.json"
            comparison.write(report_path, report)
            with mock.patch.object(comparison, "plan_at", return_value=plan):
                comparison.audit_collection(report_path, plan_path, plan_hash)
                for change in (
                    "duplicate",
                    "missing",
                    "command",
                    "ratio",
                    "seed",
                    "schedule",
                    "transcript",
                ):
                    altered, altered_samples, altered_schedule = (
                        copy.deepcopy(report),
                        copy.deepcopy(samples),
                        copy.deepcopy(schedule),
                    )
                    transcript = (
                        output
                        / f"{samples[0]['round']}-copy-{samples[0]['arm']}"
                        / "stdout"
                    )
                    original = transcript.read_bytes()
                    if change == "duplicate":
                        altered_samples[-1]["round"] = 30
                    elif change == "missing":
                        altered_samples.pop()
                    elif change == "command":
                        altered_samples[-1]["command"].append("--early-readiness")
                    elif change == "ratio":
                        altered["results"][0]["candidate_over_baseline_median"] = 0.1
                    elif change == "seed":
                        altered["seed"] += 1
                    elif change == "schedule":
                        altered_schedule[0]["arms"].reverse()
                    else:
                        transcript.write_bytes(original + b"UNKNOWN\n")
                    comparison.write(output / "samples.json", altered_samples)
                    comparison.write(output / "schedule.json", altered_schedule)
                    altered["samples_sha256"] = comparison.sha(output / "samples.json")
                    altered["schedule_sha256"] = comparison.sha(
                        output / "schedule.json"
                    )
                    comparison.write(report_path, altered)
                    with self.subTest(change=change), self.assertRaises(ValueError):
                        comparison.audit_collection(report_path, plan_path, plan_hash)
                    transcript.write_bytes(original)

    def test_frozen_population_retains_all_three_targets_and_only_development(self):
        cases = comparison.selected()
        self.assertEqual(len(cases), 67)
        self.assertEqual(
            {case["target"] for case in cases}, {"gfx942", "gfx950", "gfx1250"}
        )
        self.assertTrue(all(case["split"] == "development" for case in cases))


if __name__ == "__main__":
    unittest.main()
