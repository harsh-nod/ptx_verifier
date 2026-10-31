"""Ground-truth/source and fail-closed qualification controls; no verifier/GPU."""

import copy
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "memory_conflicts_study", HERE / "study.py"
)
STUDY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STUDY)


def output(*, rejected=False, trace_unknown=False):
    lines = []
    for name in sorted(STUDY.PROPERTIES):
        verdict = "FAIL" if rejected and name == STUDY.PROPERTY else "PASS"
        if trace_unknown and name == "AMD trace completeness":
            verdict = "UNKNOWN"
        lines.append(f"  {name} (target algorithm) {verdict}")
    if rejected:
        lines.append(
            "      MemoryConflict { kind: WriteWrite, location: ByteLocation { space: Shared, addr: 0 }, earlier: EventId(3), later: EventId(4) }"
        )
    lines.append(
        "GRAPH VERIFICATION: "
        + ("UNKNOWN" if trace_unknown else "REJECTED" if rejected else "VERIFIED")
    )
    return "\n".join(lines) + "\n"


class MemoryConflictsStudyTests(unittest.TestCase):
    def setUp(self):
        self.document = STUDY.load_cases()
        self.workloads = {row["id"]: row for row in self.document["workloads"]}

    def test_finite_preregistration_shapes_and_holdouts(self):
        self.assertEqual(len(self.document["workloads"]), 20)
        self.assertEqual(len(self.document["cases"]), 46)
        self.assertEqual(
            sum(c["split"] == "development" for c in self.document["cases"]), 40
        )
        self.assertEqual(len(STUDY.HELDOUTS), 6)
        self.assertEqual(len(STUDY.PRIMARIES), 4)
        for case in self.document["cases"]:
            expanded = STUDY.expanded_case(self.workloads[case["workload"]], case)
            self.assertEqual(
                sum(map(len, expanded["output_indices"].values())),
                expanded["expected_outputs"],
            )
        gemm = next(
            c
            for c in self.document["cases"]
            if c["id"] == "memory-wide-gfx1250-gemm_f16_full-safe"
        )
        expanded = STUDY.expanded_case(self.workloads[gemm["workload"]], gemm)
        self.assertEqual(expanded["dimensions"]["K"], 4096)
        self.assertEqual(expanded["expected_outputs"], 65536)
        self.assertEqual(expanded["block"], [1024, 1, 1])
        self.assertEqual(len(expanded["output_indices"]), 256)

    def test_primary_mutation_is_one_extra_ds_store_in_selected_full_function(self):
        for case in self.document["cases"]:
            if not case["primary_latency"]:
                continue
            w = self.workloads[case["workload"]]
            original = (STUDY.ROOT / w["assembly"]).read_bytes()
            changed = STUDY.changed_source(w, case)
            self.assertEqual(len(changed.splitlines()), len(original.splitlines()) + 1)
            e = case["edits"][0]
            zero = case["ground_truth"]["constant_address"]["register"]
            self.assertEqual(
                changed.splitlines()[e["source_line"]].decode().strip(),
                "ds_store_b16 " + zero + ", " + e["original"].split(", ")[1],
            )
            self.assertEqual(
                changed.splitlines()[e["source_line"] - 1].decode().strip(),
                e["original"],
            )
            self.assertEqual(
                case["ground_truth"]["distinct_overlap_bytes_hex"],
                [struct.pack("<e", value).hex() for value in (1, 2)],
            )
            self.assertTrue(
                case["ground_truth"]["preserves_all_original_initializing_stores"]
            )

    def test_partial_overlap_counterexample_compares_intersection_bytes(self):
        row = next(
            c
            for c in self.document["cases"]
            if c["id"].endswith("heldout-partial-overlap")
        )
        left, right = struct.pack("<HH", 0, 1), struct.pack("<HH", 2, 3)
        self.assertEqual(row["ground_truth"]["overlap_bytes"], 2)
        self.assertEqual(
            [left[2:].hex(), right[:2].hex()],
            row["ground_truth"]["distinct_overlap_bytes_hex"],
        )
        self.assertNotEqual(left[2:], right[:2])
        self.assertEqual(row["ground_truth"]["mutation_instructions"], 2)

    def test_missing_duplicate_swapped_source_and_budget_are_refused(self):
        for mutate in [
            lambda d: d["cases"].append(d["cases"][0]),
            lambda d: d["cases"].pop(),
            lambda d: d["protocol"].update({"repeats": 30}),
            lambda d: d["workloads"][0].update({"assembly_sha256": "0" * 64}),
            lambda d: d["workloads"][0].update({"manifest_row_sha256": "0" * 64}),
            lambda d: d["cases"][1].update({"materialized_assembly_sha256": "0" * 64}),
        ]:
            document = copy.deepcopy(self.document)
            mutate(document)
            with tempfile.TemporaryDirectory() as name:
                path = Path(name) / "cases.json"
                path.write_text(json.dumps(document))
                with self.assertRaises(ValueError):
                    STUDY.load_cases(path)
        case = copy.deepcopy(
            next(c for c in self.document["cases"] if c["primary_latency"])
        )
        case["edits"][0]["source_line"] = 1
        with self.assertRaisesRegex(ValueError, "selected kernel"):
            STUDY.changed_source(self.workloads[case["workload"]], case)

    def test_captured_ordinary_cli_format_and_missing_typed_witness_refusal(self):
        text = (HERE / "fixtures/ordinary-analyze.stdout").read_text()
        self.assertEqual(len(STUDY.ORDINARY_WITNESS.findall(text)), 3)
        self.assertEqual(STUDY.classify(1, text, "")["status"], "ordinary_rejection")
        self.assertFalse(STUDY.WITNESS.findall(text))
        for changed in [
            STUDY.ORDINARY_WITNESS.sub("", text),
            text.replace("GRAPH VERIFICATION: REJECTED", "GRAPH VERIFICATION: UNKNOWN"),
            text + STUDY.MARKER + "\n",
        ]:
            self.assertFalse(STUDY.classify(1, changed, "")["detected"])
        self.assertFalse(
            STUDY.classify(
                1, text, "execution stopped: unsupported AMD instruction `foo`"
            )["detected"]
        )

    def test_config_enable_is_a_bool_only_change_without_conflicting_flag(self):
        row = next(
            c
            for c in self.document["cases"]
            if c["id"] == "memory-wide-gfx1250-matvec_f16-safe"
        )
        case = STUDY.expanded_case(self.workloads[row["workload"]], row)
        original = json.loads((STUDY.ROOT / case["launch_config"]).read_text())
        with tempfile.TemporaryDirectory() as name:
            directory = Path(name)
            argv = STUDY.command(
                Path("/verifier"), case, directory / "whole.s", directory, enabled=True
            )
            self.assertNotIn("--early-memory-conflicts", argv)
            derived = json.loads(Path(argv[argv.index("--config") + 1]).read_text())
            self.assertEqual(derived.pop("early_memory_conflicts"), True)
            self.assertEqual(derived, original)

    def test_no_export_hazard_acceptance_remains_visible(self):
        result = STUDY.classify(0, output(), "")
        self.assertTrue(result["graph_accepted"])
        self.assertEqual(result["status"], "graph_accepted_without_output_proof")
        self.assertFalse(result["detected"])
        incomplete = 'volta-expr 1\nout "out" 1 n0\n'
        self.assertEqual(
            STUDY.classify(
                0,
                output(),
                "",
                expected_outputs={"out": [0, 1]},
                expressions=incomplete,
            )["status"],
            "contract_error",
        )

    def test_typed_complete_rejection_is_distinct_from_abort_or_unknown(self):
        text = output(rejected=True)
        self.assertEqual(STUDY.classify(1, text, "")["status"], "ordinary_rejection")
        for stdout, stderr, code in [
            (output(rejected=True, trace_unknown=True), "", 2),
            (text, "execution stopped: unsupported AMD instruction `foo`", 2),
            (text, "the trace generator aborted, so the graph is only a prefix", 2),
        ]:
            self.assertFalse(STUDY.classify(code, stdout, stderr)["detected"])
        self.assertFalse(STUDY.classify(-9, text, "")["detected"])
        self.assertFalse(STUDY.classify(1, text, "", timed_out=True)["detected"])

    def test_certified_prefix_needs_exact_marker_typed_pair_and_no_outputs(self):
        witness = next(
            line
            for line in output(rejected=True).splitlines()
            if line.startswith("      MemoryConflict")
        )
        witness = "  kernel: " + witness.strip()
        text = (
            STUDY.MARKER
            + "\n  AMD memory-conflict freedom (certified prefix) FAIL\n"
            + witness
            + "\nVERDICT: REJECT\n"
        )
        self.assertEqual(STUDY.classify(1, text, "")["status"], "certified_rejection")
        for changed in [
            text.replace(witness, ""),
            text + "VERDICT: UNKNOWN\n",
            text + STUDY.MARKER + "\n",
            text.replace("WriteWrite", "ReadWrite"),
            text.replace("EventId(4)", "EventId(3)"),
            text + "VC check: 0.001s  elements: 64\n",
            text + "EQUIVALENT (matches spec)\n",
            text + "unsupported profile\n",
        ]:
            self.assertFalse(STUDY.classify(1, changed, "")["detected"])
        self.assertFalse(
            STUDY.classify(1, text, "", expressions="volta-expr 1\n")["detected"]
        )

    def test_safe_spec_and_wrong_equation_require_all_elements(self):
        good = (
            output()
            + "VC check: 0.001s  elements: 64\nEQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
        )
        self.assertEqual(
            STUDY.classify(0, good, "", expected_outputs=64, verify=True)["status"],
            "spec_verified",
        )
        wrong = (
            output()
            + "VC check: 0.001s  elements: 64\nNOT EQUIVALENT: 64 mismatched element(s) vs spec\nVERDICT: REJECT\n"
        )
        self.assertEqual(
            STUDY.classify(1, wrong, "", expected_outputs=64, verify=True)["status"],
            "mathematical_refutation",
        )
        for changed in [
            wrong.replace("elements: 64", "elements: 1/64"),
            wrong.replace("64 mismatched", "1 mismatched"),
        ]:
            self.assertNotEqual(
                STUDY.classify(1, changed, "", expected_outputs=64, verify=True)[
                    "status"
                ],
                "mathematical_refutation",
            )


if __name__ == "__main__":
    unittest.main()
