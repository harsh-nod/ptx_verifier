"""Synthetic-only projection controls; no verifier or real study data is read."""

from __future__ import annotations

import copy
import contextlib
import csv
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "native_input_publication", Path(__file__).with_name("publication.py")
)
pub = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pub)
H = "a" * 64
PRIVATE = "private-host-DO-NOT-PUBLISH"


def identity():
    return {
        "revision": "b" * 40,
        "source_clean": True,
        "trust": "caller_attested",
        "binary_sha256": H,
        "build_record_sha256": H,
        "profile": "release",
        "default_features": True,
        "features": [],
        "command": ["cargo", "build", "--release", "-p", "volta_cli"],
        "rust_workspace_fingerprint": {
            "algorithm": "sha256-git-tree-v1",
            "sha256": H,
            "file_count": 1217,
        },
        "rustc": "rustc 1.97.1 (8bab26f4f 2026-07-14)",
        "cargo": "cargo 1.97.1 (c980f4866 2026-06-30)",
    }


def expression():
    return {
        "compression": "gzip",
        "artifact_bytes": 123,
        "decoded_vexpr_bytes": 512,
        "node_records": 7,
        "node_table_payload_bytes": 231,
        "output_count": 2,
        "output_counts": {"out": 2},
        **{
            key: H
            for key in (
                "artifact_sha256",
                "decoded_vexpr_sha256",
                "coordinate_map_sha256",
                "structural_output_map_sha256",
            )
        },
    }


def observation(cid, arm, *, hazard=False, timeout=False):
    value = 0.1 if arm == "baseline" else 0.101
    if hazard and int(cid[-2:]) < 3 and arm == "candidate":
        value = 0.05
    status = (
        "timeout"
        if timeout
        else "certified_rejection"
        if hazard
        else "graph_accepted_without_output_proof"
    )
    return {
        "case": cid,
        "role": arm,
        "status": status,
        "returncode": -9 if timeout else 1 if hazard else 0,
        "timed_out": timeout,
        "log_limit_exceeded": False,
        "seconds": 60.1234567890123 if timeout else value + 0.001234567890123,
        "raw_log_bytes": 125,
        "first_marker_seconds": value if hazard else None,
        "qualified": not timeout,
        "detected": hazard,
        "detection_mode": "certified_prefix" if hazard else None,
        "graph_accepted": not hazard and not timeout,
        "false_positive": False,
        "unsafe_acceptance": False,
        "endpoint_seconds": None if timeout else value,
        "new_contract_witness_audit_required": False,
        "new_coverage_credited": False,
        "measurement_errors": ["missing resources " + PRIVATE] if timeout else [],
        "command": ["/home/" + PRIVATE + "/candidate-volta", "analyze"],
        "usage": {}
        if timeout
        else {
            "max_rss_kib": 9216.0,
            "user_seconds": 0.123456789,
            "system_seconds": 0.0123456789,
        },
        "stdout_sha256": H,
        "stderr_sha256": H,
        "resources_sha256": H,
        "signature": {
            "status": status,
            "returncode": -9 if timeout else 1 if hazard else 0,
            "executed_instructions": 10,
            "diagnostics_sha256": H,
            "certificate_frame": [2, 3, 0, 0, 1] if hazard else None,
            "prefix_counts": [10, 12, 20] if hazard else None,
            "first_typed_witness": [["Shared", "0", "4", "5"]] if hazard else [],
        },
    }


def fixture():
    hashes = {key: pub.sha(key.encode()) for key in pub.REPORT_SHA256}
    ids = [f"case-{index:02d}" for index in range(28)]
    cases, pins = [], {}
    for index, cid in enumerate(ids):
        module = f"/tmp/{PRIVATE}/{cid}/complete-module.s"
        config = f"/tmp/{PRIVATE}/{cid}/enabled.launch.json"
        pins[module] = pins[config] = H
        case = {
            "id": cid,
            "target": "gfx950" if index % 2 else "gfx1250",
            "kernel": "safe_kernel",
            "expectation": "hazard" if index < 14 else "safe",
            "dimensions": {"N": 2},
            "block": [64, 1, 1],
            "grid": [1, 1, 1],
            "workgroup": [0, 0, 0],
            "arrays": [
                {
                    "name": "x",
                    "base_address": 65536,
                    "element_size": 4,
                    "length": 2,
                    "kind": "in",
                },
                {
                    "name": "out",
                    "base_address": 131072,
                    "element_size": 4,
                    "length": 2,
                    "kind": "out",
                },
            ],
            "output_indices": {"out": [0, 1]},
            "expected_outputs": 2,
            "source": "tests/fixtures/source.hip",
            "source_sha256": H,
            "assembly": "tests/fixtures/source.s",
            "assembly_sha256": H,
            "spec": "tests/fixtures/source.spec",
            "spec_sha256": H,
            "materialized_assembly_sha256": H,
            "params": ["ptr:x", "ptr:out"],
        }
        definition = {
            "primary": index < 3,
            "previous_complete_equation_proved": 14 <= index < 25
            if index >= 14
            else None,
            "input_elements": 2,
            "input_bytes": 8,
        }
        cases.append(
            {
                "case": case,
                "definition": definition,
                "assembly": module,
                "configuration": config,
            }
        )
    eligible, safe = ids[:-1], ids[14:-1]
    bq = {
        "role": "baseline",
        "plan_sha256": hashes["baseline_plan"],
        "build": identity(),
        "timing_eligible": eligible,
        "results": [
            observation(cid, "baseline", hazard=i < 14, timeout=i == 27)
            for i, cid in enumerate(ids)
        ],
    }
    cq = {
        "role": "candidate",
        "plan_sha256": hashes["baseline_plan"],
        "build": identity(),
        "timing_eligible": eligible,
        "results": [
            observation(cid, "candidate", hazard=i < 14, timeout=i == 27)
            for i, cid in enumerate(ids)
        ],
    }
    schedule = [
        [cid, repeat, arm]
        for repeat in range(1, 6)
        for cid in eligible
        for arm in ("baseline", "candidate")
    ]
    semantic_schedule = [
        [cid, arm, stage]
        for cid in safe
        for arm in ("baseline", "candidate")
        for stage in ("export", "verify")
    ]
    samples = [
        {**observation(cid, arm, hazard=int(cid[-2:]) < 14), "repeat": repeat}
        for cid, repeat, arm in schedule
    ]
    summaries = []
    for index, cid in enumerate(eligible):
        b, c = 0.1, 0.05 if index < 3 else 0.101
        summaries.append(
            {
                "case": cid,
                "primary": index < 3,
                "valid": True,
                "benefit": index < 3,
                "endpoint_nonregression": True,
                "rss_nonregression": True,
                "baseline_median_seconds": b,
                "candidate_median_seconds": c,
                "baseline_max_rss_kib": 9216.0,
                "candidate_max_rss_kib": 9216.0,
            }
        )
    functional = {
        "candidate_cases": 28,
        "baseline_qualified": 27,
        "all_baseline_qualifiers_retained": True,
        "false_findings": 0,
        "unsafe_acceptances": 0,
        "passed": True,
        "safe_graph_failures": [],
        "baseline_unqualified_outcomes": [
            {
                "case": ids[-1],
                "status": "timeout",
                "qualified": False,
                "measurement_errors": [PRIVATE],
            }
        ],
    }
    paired = {
        "plan_sha256": hashes["comparison_plan"],
        "candidate_qualification_sha256": hashes["candidate_qualification"],
        "samples": samples,
        "functional": functional,
        "summary": {
            "cases": summaries,
            "primary_wins": 3,
            "primaries_required": 2,
            "performance_point_gates_pass": True,
        },
        "runtime_context": {
            "architecture": "x86_64",
            "kernel_release": "6.6.87.2-microsoft-standard-WSL2",
            "python_version": "3.12.3 (" + PRIVATE + ")",
            "logical_cpus": 32,
            "allowed_logical_cpus": 32,
            "cpu_model": PRIVATE,
            "hostname": PRIVATE,
        },
    }
    processes, comparisons, others = [], [], []
    for cid, arm, stage in semantic_schedule:
        r = observation(cid, arm, timeout=stage == "verify" and int(cid[-2:]) >= 25)
        r.update(stage=stage, graph_failure_names=[], mathematical_mismatch_elements=[])
        if stage == "export":
            r.update(
                expressions=expression(),
                full_output_artifact_valid=True,
                gzip_capture={
                    "compression": "gzip-level1-mtime0-empty-filename",
                    "received_decoded_bytes": 512,
                    "received_decoded_sha256": H,
                    "writer_eof": True,
                    "complete": True,
                    "artifact_bytes": 123,
                    "artifact_sha256": H,
                    "errors": [],
                },
            )
        elif not r["timed_out"]:
            r["status"] = r["signature"]["status"] = "spec_verified"
        else:
            others.append(
                {
                    "case": cid,
                    "role": arm,
                    "status": "timeout",
                    "measurement_errors": r["measurement_errors"],
                }
            )
        processes.append(r)
    for cid in safe:
        comparisons.append(
            {
                "case": cid,
                "all_coordinates_valid": True,
                "structural_match": True,
                "baseline": expression(),
                "candidate": expression(),
            }
        )
    semantic = {
        "plan_sha256": hashes["comparison_plan"],
        "candidate_qualification_sha256": hashes["candidate_qualification"],
        "process_records": processes,
        "output_comparisons": comparisons,
        "functional": copy.deepcopy(functional),
        "proofs": {
            "previously_proved_cases": ids[14:25],
            "all_previous_complete_proofs_retained": True,
            "other_equations": others,
        },
        "all_semantic_controls_pass": True,
        "false_findings": 0,
        "unsafe_acceptances": 0,
        "mathematical_refutations": 0,
        "compressed_bytes": 3198,
    }
    all_pins = dict(pins)
    all_pins.update(
        {f"/home/{PRIVATE}/opaque-input-{i}": H for i in range(195 - len(pins))}
    )
    bp = {
        "cases": cases,
        "input_sha256": pins,
        "baseline": {
            "binary": f"/tmp/{PRIVATE}/baseline-volta",
            "build": f"/tmp/{PRIVATE}/baseline-build.json",
            "identity": identity(),
        },
        "protocol_sha256": H,
        "selection_sha256": H,
    }
    cp = {
        "eligible": eligible,
        "baseline_plan": f"/tmp/{PRIVATE}/plan.json",
        "baseline_report": f"/tmp/{PRIVATE}/baseline-qualification.json",
        "baseline_report_sha256": hashes["baseline_qualification"],
        "candidate": {
            "binary": f"/tmp/{PRIVATE}/candidate-volta",
            "build": f"/tmp/{PRIVATE}/candidate-build.json",
            "identity": identity(),
            "reviewed_patch_sha256": H,
        },
        "schedule": schedule,
        "safe_semantic_cases": safe,
        "semantic_schedule": semantic_schedule,
        "input_sha256": all_pins,
        "budgets": {
            "timeout_seconds": 60,
            "repeats": 5,
            "seed": 20261031,
            "gzip_bytes": 2**31,
            "reserve_bytes": 2**31,
            "other_bytes": 256 * 2**20,
        },
        "structural_comparator": {"sha256": H, "tests_sha256": H},
    }
    return dict(zip(pub.REPORT_SHA256, (bp, cp, bq, cq, paired, semantic))), hashes


class ProjectionTests(unittest.TestCase):
    def setUp(self):
        self.documents, self.hashes = fixture()

    def project(self):
        return pub.project(self.documents, self.hashes)

    def test_all_denominators_failures_and_numeric_observations_remain(self):
        result = self.project()
        self.assertEqual(
            [
                len(result[k])
                for k in (
                    "baseline_qualification",
                    "candidate_qualification",
                    "paired_observations",
                    "semantic_observations",
                    "case_summaries",
                    "output_comparisons",
                )
            ],
            [28, 28, 270, 52, 27, 13],
        )
        self.assertEqual(result["baseline_qualification"][-1]["status"], "timeout")
        self.assertEqual(result["candidate_qualification"][-1]["usage"], {})
        self.assertEqual(len(result["proofs"]["other_equations"]), 4)
        self.assertEqual(
            result["paired_observations"][0]["seconds"],
            self.documents["paired"]["samples"][0]["seconds"],
        )
        self.assertEqual(result["runtime"]["platform"], "WSL2")
        self.assertEqual(result["case_summaries"][0]["baseline_over_candidate"], 2)

    def test_deterministic_json_csv_and_artifact_hashes(self):
        first = pub.artifacts(self.project())
        self.assertEqual(first, pub.artifacts(self.project()))
        rows = list(csv.DictReader(io.StringIO(first["observations.csv"].decode())))
        self.assertEqual(len(rows), 378)
        original = self.documents["baseline_qualification"]["results"][0]
        self.assertEqual(float(rows[0]["seconds"]), original["seconds"])
        self.assertEqual(
            json.loads(rows[0]["signature"])["certificate_frame"], [2, 3, 0, 0, 1]
        )
        meta = json.loads(first["metadata.json"])
        for name, expected in meta["public_artifact_sha256"].items():
            self.assertEqual(pub.sha(first[name]), expected)

    def test_private_context_diagnostics_commands_and_unknown_fields_do_not_leak(self):
        self.documents["semantics"]["proofs"]["other_equations"][0]["private_note"] = (
            PRIVATE
        )
        self.documents["paired"]["samples"][0]["private_note"] = PRIVATE
        self.documents["comparison_plan"]["input_sha256"].pop(
            next(iter(self.documents["comparison_plan"]["input_sha256"]))
        )
        self.documents["comparison_plan"]["input_sha256"][
            f"/tmp/tests/{PRIVATE}/secret"
        ] = H
        for data in pub.artifacts(self.project()).values():
            text = data.decode()
            self.assertNotIn(PRIVATE, text)
            self.assertNotIn("/tmp/", text)
            self.assertNotIn("/home/", text)

    def test_unknown_status_and_nonfinite_values_refuse(self):
        for key, value in (
            ("status", "free " + PRIVATE),
            ("seconds", float("nan")),
            ("endpoint_seconds", float("inf")),
        ):
            with self.subTest(key=key):
                docs, hashes = fixture()
                docs["candidate_qualification"]["results"][0][key] = value
                with self.assertRaises(ValueError):
                    pub.project(docs, hashes)

    def test_missing_duplicate_or_wrong_order_records_refuse(self):
        for name, key in (
            ("candidate_qualification", "results"),
            ("paired", "samples"),
            ("semantics", "process_records"),
        ):
            with self.subTest(dataset=name):
                docs, hashes = fixture()
                docs[name][key].pop()
                with self.assertRaises(ValueError):
                    pub.project(docs, hashes)
        (
            self.documents["paired"]["samples"][0],
            self.documents["paired"]["samples"][1],
        ) = (
            self.documents["paired"]["samples"][1],
            self.documents["paired"]["samples"][0],
        )
        with self.assertRaises(ValueError):
            self.project()

    def test_wrong_hash_chain_and_build_profile_refuse(self):
        for alter in (
            lambda d: d["semantics"].update(candidate_qualification_sha256="c" * 64),
            lambda d: d["candidate_qualification"]["build"].update(profile="debug"),
            lambda d: d["baseline_plan"]["baseline"]["identity"].update(
                trust="fabricated"
            ),
        ):
            docs, hashes = fixture()
            alter(docs)
            with self.assertRaises(ValueError):
                pub.project(docs, hashes)

    def test_changed_budget_summary_or_aggregate_gate_refuses(self):
        for alter in (
            lambda d: d["comparison_plan"]["budgets"].update(timeout_seconds=61),
            lambda d: d["paired"]["summary"]["cases"][0].update(
                candidate_median_seconds=0.0499
            ),
            lambda d: d["paired"]["summary"].update(primary_wins=2),
        ):
            docs, hashes = fixture()
            alter(docs)
            with self.assertRaises(ValueError):
                pub.project(docs, hashes)

    def test_refusals_regressions_and_false_findings_are_preserved(self):
        self.documents["semantics"].update(
            all_semantic_controls_pass=False, false_findings=1
        )
        row = self.documents["semantics"]["process_records"][-1]
        row.update(graph_failure_names=["AMD wait and register readiness"])
        result = self.project()
        self.assertEqual(result["semantic_gates"]["false_findings"], 1)
        self.assertEqual(
            result["semantic_observations"][-1]["graph_failure_names"],
            ["AMD wait and register readiness"],
        )
        self.assertIn("did not pass every", pub.readme(result).decode())
        self.assertGreater(len(result["slower_cases"]), 0)

    def test_source_module_spec_config_and_all_coordinate_contracts_bound(self):
        result = self.project()
        case = result["contracts"][0]
        self.assertEqual(case["configuration_sha256"], H)
        self.assertEqual(case["materialized_assembly_sha256"], H)
        self.assertEqual(case["output_indices"], {"out": [0, 1]})
        self.assertEqual(len(result["bound_inputs"]), 195)
        self.assertIn(
            "launches/case-00/complete-module.s",
            [r["alias"] for r in result["bound_inputs"]],
        )

    def test_malformed_public_geometry_and_repository_path_refuse(self):
        for alter in (
            lambda d: d["baseline_plan"]["cases"][0]["case"].update(
                block=[64, PRIVATE, 1]
            ),
            lambda d: d["baseline_plan"]["cases"][0]["case"].update(
                source="/home/" + PRIVATE
            ),
            lambda d: d["baseline_plan"]["cases"][0]["case"].update(params=[PRIVATE]),
        ):
            docs, hashes = fixture()
            alter(docs)
            with self.assertRaises(ValueError):
                pub.project(docs, hashes)

    def test_load_requires_exact_report_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "report.json"
            path.write_text('{"synthetic":1}\n')
            with patch.dict(pub.REPORT_SHA256, {"paired": pub.sha(path.read_bytes())}):
                documents, hashes = pub.load({"paired": path})
                self.assertEqual(documents["paired"], {"synthetic": 1})
                self.assertEqual(hashes["paired"], pub.sha(path.read_bytes()))
                path.write_text('{"synthetic":2}\n')
                with self.assertRaises(ValueError):
                    pub.load({"paired": path})

    def test_recorded_nonzero_failure_counts_are_not_iterated_or_dropped(self):
        self.documents["semantics"].update(
            false_findings=2,
            unsafe_acceptances=3,
            mathematical_refutations=1,
            all_semantic_controls_pass=False,
        )
        result = self.project()
        self.assertEqual(result["semantic_gates"]["false_findings"], 2)
        self.assertEqual(result["semantic_gates"]["unsafe_acceptances"], 3)
        self.assertEqual(result["semantic_gates"]["mathematical_refutations"], 1)
        self.assertEqual(len(pub.artifacts(result)), 5)

    def test_public_only_arithmetic_replay_and_regression_list(self):
        result = self.project()
        self.assertEqual(pub.check_public(result)["case_summaries"], 27)
        result["case_summaries"][0]["endpoint_change_percent"] += 0.01
        with self.assertRaises(ValueError):
            pub.check_public(result)

    def test_public_only_refuses_every_missing_population(self):
        for key in (
            "baseline_qualification",
            "candidate_qualification",
            "semantic_observations",
            "output_comparisons",
            "proof_ids",
        ):
            with self.subTest(population=key):
                result = self.project()
                if key == "proof_ids":
                    result["proofs"]["previously_proved_cases"] = []
                else:
                    result[key] = []
                with self.assertRaises(ValueError):
                    pub.check_public(result)

    def test_public_cli_refuses_missing_and_extra_sibling_hashes(self):
        for extra in (False, True):
            with self.subTest(extra=extra), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                output = pub.artifacts(self.project())
                for name, raw in output.items():
                    (root / name).write_bytes(raw)
                meta = json.loads(output["metadata.json"])
                if extra:
                    meta["public_artifact_sha256"]["unexpected.txt"] = H
                else:
                    del meta["public_artifact_sha256"]["audit.json"]
                (root / "metadata.json").write_bytes(pub.encoded(meta))
                with (
                    patch(
                        "sys.argv",
                        [
                            "publication.py",
                            "--check-public",
                            str(root / "metadata.json"),
                        ],
                    ),
                    self.assertRaises(ValueError),
                ):
                    pub.main()

    def test_public_only_cli_checks_sibling_artifact_hashes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name, raw in pub.artifacts(self.project()).items():
                (root / name).write_bytes(raw)
            with (
                patch(
                    "sys.argv",
                    ["publication.py", "--check-public", str(root / "metadata.json")],
                ),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                pub.main()
                (root / "observations.csv").write_text("changed")
                with self.assertRaises(ValueError):
                    pub.main()

    def test_audits_keep_counts_and_hashes_without_private_details(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "receipt.json"
            p.write_text(
                json.dumps(
                    {
                        "checks": 123,
                        "pass": True,
                        "errors": [],
                        "script_sha256": H,
                        "private_note": PRIVATE,
                    }
                )
            )
            binding = f"paired={pub.sha(p.read_bytes())}={p}"
            public = pub.audit_receipts([binding])
            self.assertEqual(public[0]["checks"], 123)
            self.assertNotIn(PRIVATE, json.dumps(public))
            with self.assertRaises(ValueError):
                pub.audit_receipts([binding, binding])
            p.write_text("changed")
            with self.assertRaises(ValueError):
                pub.audit_receipts([binding])


if __name__ == "__main__":
    unittest.main()
