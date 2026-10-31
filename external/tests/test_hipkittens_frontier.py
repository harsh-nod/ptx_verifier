"""Frontier accounting/refusal controls; no ROCm, verifier or GPU execution."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "external/extraction"))
SPEC = importlib.util.spec_from_file_location("hipkittens_frontier", ROOT / "external/extraction/hipkittens_frontier.py")
FRONTIER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(FRONTIER)
sys.path.pop(0)


class HipKittensFrontierTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.campaign = self.root / "campaign"
        self.replay = self.root / "replay"
        self.replay.mkdir()
        self.binary = self.root / "volta"
        self.binary.write_bytes(b"frozen binary")
        self.sources = ["unit.cpp", "fragment.cpp", "unused.cpp"]
        profile = {"target": "gfx950", "architecture": "cdna4"}
        self.document = {"revision": "a" * 40, "tree": "b" * 40, "repository": "https://example.invalid/public",
                         "source_sha256": {source: "c" * 64 for source in self.sources + ["wrapper.cuh"]},
                         "source_roles": dict.fromkeys(self.sources, "translation_unit_source") | {"wrapper.cuh": "kernel_header"},
                         "compilation_units": [{"source": source, "source_role": "translation_unit_source", "scope": "unit_test",
                                                "translation_unit_probe": True, "profiles": [profile]} for source in self.sources],
                         "literal_include_edges": [{"source": "unit.cpp", "included_source": "wrapper.cuh"}],
                         "kernels": [{"source": source, "line": 1, "name": name, "scope": "unit_test", "definition": True,
                                      "declaration_sha256": "d" * 64, "profiles": [profile]}
                                     for source, name in [("wrapper.cuh", "wrapper"), ("unused.cpp", "unused")]]}
        self.identity = FRONTIER.probe_id("unit.cpp", "gfx950")
        metadata = [{".name": "_Z7wrapperIiEvT_", ".wavefront_size": 64},
                    {".name": "_Z7wrapperIfEvT_", ".wavefront_size": 64}]
        self.rows = [{"id": FRONTIER.probe_id(source, "gfx950"), "source": source, "source_sha256": "c" * 64,
                      "profile": profile, "status": "compile_rejected", "analysis": {"status": "not_reached"}}
                     for source in self.sources]
        for origin in FRONTIER.ORIGINS:
            (self.campaign / origin).mkdir(parents=True)
        unit = self.campaign / "baseline-all" / self.identity
        unit.mkdir()
        (unit / "kernel.s").write_text(".type wrapper,@function\nwrapper:\n s_endpgm\n")
        (unit / "kernel.o").write_bytes(b"object")
        FRONTIER.write(unit / "assemble.json", {"status": "succeeded", "returncode": 0})
        self.rows[0].update(status="parsed", assembly_sha256=FRONTIER.sha(unit / "kernel.s"),
                            object_sha256=FRONTIER.sha(unit / "kernel.o"), emitted_kernels=metadata)
        for row in self.rows:
            directory = self.campaign / "baseline-all" / row["id"]
            directory.mkdir(exist_ok=True)
            FRONTIER.write(directory / "result.json", row)
        self.reports = {}
        for origin, rows in (("baseline-all", self.rows), ("recipe-followup", [self.rows[1]])):
            for row in rows:
                directory = self.campaign / origin / row["id"]
                directory.mkdir(exist_ok=True)
                FRONTIER.write(directory / "result.json", row)
            report = {"schema_version": 2, "source_revision": self.document["revision"], "inventory_sha256": "e" * 64,
                      "driver_sha256": "f" * 64, "compiler_sha256": "1" * 64, "assembler_sha256": "2" * 64, "results": rows}
            FRONTIER.write(self.campaign / origin / "report.json", report)
            self.reports[origin] = {"sha256": FRONTIER.sha(self.campaign / origin / "report.json")}
        destination = self.replay / self.identity
        destination.mkdir()
        (destination / "parse.stdout").write_text("Parsed successfully: original\n  Entries (kernels): 2\n")
        (destination / "parse.stderr").write_bytes(b"")
        self.parse_row = {"id": self.identity, "source": "unit.cpp", "target": "gfx950", "attempt_origin": "baseline-all",
                          "assembly_sha256": self.rows[0]["assembly_sha256"], "object_sha256": self.rows[0]["object_sha256"],
                          "metadata_sha256": FRONTIER.digest(metadata), "emitted_entry_occurrences": 2,
                          "status": "parsed", "returncode": 0, "timed_out": False, "first_diagnostic": "",
                          "stdout_sha256": FRONTIER.sha(destination / "parse.stdout"), "stderr_sha256": FRONTIER.sha(destination / "parse.stderr"),
                          "command": [str(self.binary), "--no-log-file", "--backend", "amdgpu", "--target", "gfx950", "parse", str(unit / "kernel.s")]}
        self.parse_report = {"analysis_revision": "9" * 40, "binary_sha256": FRONTIER.sha(self.binary), "reports": self.reports,
                             "probes": 3, "modules": 1, "entry_occurrences": 2, "outcomes": {"parsed": 1}, "results": [self.parse_row]}
        self.save_parse()
        self.proof_path = self.root / "proofs.json"
        cases = [{"kernel": entry[".name"], "id": "case" + str(n), "elements": 16, "launch_sha256": "3" * 64,
                  "candidate": {"status": "verified" if n == 0 else "graph_rejected", "full_output_math_proved": True,
                                "process_status": "succeeded" if n == 0 else "rejected", "returncode": 0 if n == 0 else 1}}
                 for n, entry in enumerate(metadata)]
        self.proof = {"upstream": {"revision": self.document["revision"]},
                      "verifiers": {"candidate": {"revision": "8" * 40, "binary_sha256": "7" * 64}},
                      "families": [{"source": "unit.cpp", "source_sha256": {"unit.cpp": "c" * 64},
                                    "shared_input_sha256": {"assembly": self.rows[0]["assembly_sha256"], "object": self.rows[0]["object_sha256"]},
                                    "cases": 2, "results": cases, "outcomes": {"candidate": {"verified": 1, "graph_rejected": 1}},
                                    "candidate_report_sha256": "6" * 64, "spec_sha256": "5" * 64}]}
        FRONTIER.write(self.proof_path, self.proof)

    def save_parse(self):
        FRONTIER.write(self.replay / self.identity / "parse.json", self.parse_row)
        FRONTIER.write(self.replay / "report.json", self.parse_report)

    def summarize(self):
        return FRONTIER.summarize(self.campaign, self.replay, self.document, self.proof_path)

    def test_distinct_populations_all_attempts_headers_and_uninstantiated_definitions(self):
        ledger = self.summarize()
        summary = ledger["summary"]
        self.assertEqual((summary["lexical_definitions"], summary["source_profile_probes"], summary["preserved_compiler_attempts"],
                          summary["accepted_nonempty_modules"], summary["emitted_entry_occurrences"]), (2, 3, 4, 1, 2))
        header = ledger["definitions"][0]["profiles"][0]
        self.assertIsNone(header["direct_probe"])
        self.assertEqual(len(header["entry_candidates"]), 2)
        self.assertEqual(header["lexically_reachable_probes"], [self.identity])
        unused = ledger["definitions"][1]["profiles"][0]
        self.assertEqual(unused["disposition"], "no_entry_candidate_observed")
        self.assertEqual(sum(len(p["attempts"]) for p in ledger["probes"]), 4)

    def test_missing_duplicate_or_unknown_probe_refused(self):
        path = self.campaign / "baseline-all/report.json"
        original = FRONTIER.read(path)
        for mutation in (original["results"][:-1], original["results"] + [original["results"][0]]):
            changed = copy.deepcopy(original)
            changed["results"] = mutation
            FRONTIER.write(path, changed)
            with self.assertRaises(ValueError):
                self.summarize()
        FRONTIER.write(path, original)
        changed = FRONTIER.read(self.campaign / "recipe-followup/report.json")
        changed["results"][0]["id"] = "unknown"
        FRONTIER.write(self.campaign / "recipe-followup/report.json", changed)
        with self.assertRaises(ValueError):
            self.summarize()

    def test_source_wave_and_artifact_drift_refused(self):
        for field, replacement in (("source_sha256", "0" * 64), ("profile", {"target": "gfx1250"})):
            path = self.campaign / "baseline-all/report.json"
            original = FRONTIER.read(path)
            changed = copy.deepcopy(original)
            changed["results"][0][field] = replacement
            FRONTIER.write(path, changed)
            with self.assertRaises(ValueError):
                self.summarize()
            FRONTIER.write(path, original)
        (self.campaign / "baseline-all" / self.identity / "kernel.o").write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "artifact drift"):
            self.summarize()

    def test_missing_module_or_stale_metadata_refused(self):
        self.parse_report["results"] = []
        self.save_parse()
        with self.assertRaisesRegex(ValueError, "omits or adds"):
            self.summarize()
        self.parse_report["results"] = [self.parse_row]
        self.parse_row["metadata_sha256"] = "0" * 64
        self.save_parse()
        with self.assertRaisesRegex(ValueError, "metadata_sha256"):
            self.summarize()

    def test_log_binary_and_trimmed_command_refused(self):
        original = self.parse_row["command"][-1]
        self.parse_row["command"][-1] = str(self.root / "trimmed.s")
        self.save_parse()
        with self.assertRaisesRegex(ValueError, "whole-module"):
            self.summarize()
        self.parse_row["command"][-1] = original
        self.save_parse()
        self.binary.write_bytes(b"different executable")
        with self.assertRaisesRegex(ValueError, "binary drift"):
            self.summarize()
        self.binary.write_bytes(b"frozen binary")
        (self.replay / self.identity / "parse.stdout").write_text("different log")
        with self.assertRaisesRegex(ValueError, "log drift"):
            self.summarize()

    def test_parse_and_math_only_never_become_current_combined_acceptance(self):
        ledger = self.summarize()
        entries = next(row for row in ledger["probes"] if row["id"] == self.identity)["entries"]
        self.assertEqual(entries[1]["evidence"]["status"], "graph_rejected")
        self.assertTrue(entries[1]["evidence"]["full_output_math_proved"])
        self.assertEqual(entries[0]["verification"], "separate_revision_evidence")
        self.assertNotEqual(entries[0]["evidence"]["verifier_revision"], ledger["parse_replay"]["revision"])
        self.proof["families"][0]["results"][0]["candidate"]["full_output_math_proved"] = False
        FRONTIER.write(self.proof_path, self.proof)
        with self.assertRaisesRegex(ValueError, "incomplete proof"):
            self.summarize()

    def test_unqualified_symbol_decoder_does_not_guess_namespace_or_template_types(self):
        self.assertEqual(FRONTIER.symbol_name("_ZL7wrapperITk4gl_tEvT_"), "wrapper")
        self.assertIsNone(FRONTIER.symbol_name("_ZN7kittens7wrapperEv"))
        self.assertIsNone(FRONTIER.symbol_name("_Z99short"))
        self.assertEqual(FRONTIER.symbol_name("plain_kernel"), "plain_kernel")
        rows = self.document["kernels"] + [dict(self.document["kernels"][0], source="other.cuh")]
        basis, candidates = FRONTIER.definition_candidates("wrapper", "unit.cpp", rows, {"unit.cpp"})
        self.assertEqual(basis, "ambiguous_lexical_name_candidates")
        self.assertEqual(len(candidates), 2)

    def test_blocker_has_only_public_instruction_location_not_arbitrary_error_text(self):
        path = self.campaign / "baseline-all" / self.identity / "kernel.s"
        row = {"first_diagnostic": "error: /private/machine/or/host: 3:2: unsupported AMD instruction `s_endpgm`; host=secret", "status": "parse_unsupported"}
        result = FRONTIER.blocker(row, path)
        self.assertEqual(result["opcode_or_directive"], "s_endpgm")
        self.assertEqual(result["line"], 3)
        self.assertNotIn("secret", json.dumps(result))
        self.assertNotIn("/private", json.dumps(result))

    def test_crashes_timeouts_and_unknown_parser_errors_are_separate(self):
        self.assertEqual(FRONTIER.parse_status(-11, False, "unsupported AMD instruction"), "crash")
        self.assertEqual(FRONTIER.parse_status(-9, True, ""), "timeout")
        self.assertEqual(FRONTIER.parse_status(1, False, "unknown grammar"), "parse_rejected")
        self.assertEqual(FRONTIER.parse_status(1, False, "unsupported AMD instruction `x`"), "parse_unsupported")

    def test_replay_is_parse_only_and_requires_fresh_output_and_exact_binary(self):
        output = self.root / "new-replay"
        process = Mock(returncode=0)
        process.communicate.return_value = (b"Parsed successfully: original\n  Entries (kernels): 2\n", b"")
        with patch.object(FRONTIER.subprocess, "Popen", return_value=process) as popen:
            report = FRONTIER.replay(self.campaign, self.document, self.binary, "9" * 40,
                                     FRONTIER.sha(self.binary), output, 1, 60)
            self.assertEqual(report["outcomes"], {"parsed": 1})
            self.assertEqual(popen.call_args.args[0][-2], "parse")
            self.assertNotIn("analyze", popen.call_args.args[0])
            self.assertNotIn("verify", popen.call_args.args[0])
        with self.assertRaisesRegex(ValueError, "fresh"):
            FRONTIER.replay(self.campaign, self.document, self.binary, "9" * 40, FRONTIER.sha(self.binary), output, 1, 60)
        with self.assertRaisesRegex(ValueError, "identity"):
            FRONTIER.replay(self.campaign, self.document, self.binary, "9" * 40, "0" * 64, self.root / "wrong", 1, 60)

    def test_checked_in_ledger_covers_every_definition_probe_and_occurrence(self):
        ledger_path = ROOT / "external/hipkittens/corpus/frontier.json"
        if not ledger_path.exists():
            self.skipTest("ledger not generated")
        ledger = FRONTIER.read(ledger_path)
        document = FRONTIER.read(ROOT / "external/hipkittens/corpus/inventory.json")
        self.assertEqual(ledger["inventory_sha256"], FRONTIER.digest(document))
        self.assertEqual({d["id"] for d in ledger["definitions"]}, {FRONTIER.definition_id(d) for d in document["kernels"] if d["definition"]})
        self.assertEqual(set(FRONTIER.probe_universe(document)), {p["id"] for p in ledger["probes"]})
        self.assertEqual(len(ledger["probes"]), len({p["id"] for p in ledger["probes"]}))
        self.assertEqual(sum(len(p["entries"]) for p in ledger["probes"]), ledger["summary"]["emitted_entry_occurrences"])
        for probe in ledger["probes"]:
            self.assertEqual([entry["ordinal"] for entry in probe["entries"]], list(range(len(probe["entries"]))))
        self.assertEqual(ledger["generator_sha256"], FRONTIER.sha(Path(FRONTIER.__file__)))


if __name__ == "__main__":
    unittest.main()
