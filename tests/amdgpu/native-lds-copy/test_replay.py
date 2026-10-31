"""Host-only refusal controls over copied, already captured records."""

import copy
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("lds_replay", ROOT / "replay.py")
replay = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(replay)


class ReplayControls(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((ROOT / "manifest.json").read_text())
        self.kernel = self.manifest["kernel"]
        self.candidate = ROOT / "results/candidate"
        self.baseline = ROOT / "results/baseline"

    def text(self, role, name):
        return (ROOT / "results" / role / name).read_text()

    def refused_transcript(
        self, text, *, stderr="", baseline=False, verify=True, code=None
    ):
        with self.assertRaises(ValueError):
            replay.check_transcript(
                text,
                stderr,
                (2 if baseline else 0) if code is None else code,
                baseline,
                verify,
            )

    def test_retained_records_and_inputs(self):
        replay.check_recorded()

    def test_prefix_pass_never_means_complete(self):
        text = self.text("baseline", "verify.stdout")
        self.refused_transcript(text, code=2)
        self.refused_transcript(
            text.replace("VERDICT: UNKNOWN", "VERDICT: ACCEPT"), baseline=True
        )
        self.refused_transcript(text + "EQUIVALENT (matches spec)\n", baseline=True)
        self.refused_transcript(text + "    out[0] = x[0]\n", baseline=True)

    def test_typed_hazards_and_errors_in_either_stream_refused(self):
        good = self.text("candidate", "verify.stdout")
        diagnostics = (
            "MemoryConflict { kind: WriteWrite, first: EventId(1), second: EventId(2), space: Global, byte: 65536 }",
            "AmdRegisterHazard { kind: ReadBeforeReady }",
            "AmdBarrierViolation { kind: MissingArrival }",
            "execution stopped: unsupported AMD instruction `bad`",
            "EARLY_MEMORY_CONFLICTS: CERTIFIED_REJECTION",
            "kernel: FAIL",
            "panic: failed",
        )
        for diagnostic in diagnostics:
            for stream in ("stdout", "stderr"):
                with self.subTest(diagnostic=diagnostic, stream=stream):
                    self.refused_transcript(
                        good + (diagnostic + "\n" if stream == "stdout" else ""),
                        stderr=diagnostic if stream == "stderr" else "",
                    )
        self.refused_transcript(
            self.text("baseline", "verify.stdout") + diagnostics[0], baseline=True
        )

    def test_property_population_and_endpoints(self):
        good = self.text("candidate", "verify.stdout")
        mutations = (
            good.replace("      PASS", "      UNKNOWN", 1),
            good.replace("AMD trace completeness", "AMD invented property", 1),
            good + "  AMD trace completeness (duplicate) PASS\n",
            good.replace("VERDICT: ACCEPT", "VERDICT: UNKNOWN"),
            good + "VERDICT: ACCEPT\n",
            good + "GRAPH VERIFICATION: UNKNOWN\n",
            good.replace("elements: 64", "elements: 63"),
            good.replace("all 64 compared", "all 63 compared"),
            good.replace("instructions: 31", "instructions: 30"),
            good.replace("block syncs: 1", "block syncs: 0"),
        )
        for text in mutations:
            with self.subTest(text=text[-100:]):
                self.refused_transcript(text)
        self.refused_transcript(good, code=1)

    def test_printed_complete_roots(self):
        good = self.text("candidate", "analyze.stdout")
        stderr = self.text("candidate", "analyze.stderr")
        for text in (
            good.replace("    out[63] = x[63]\n", ""),
            good + "    out[0] = x[0]\n",
            good.replace("out[1] = x[1]", "out[1] = x[0]"),
            good.replace("out[63] = x[63]", "out[64] = x[64]"),
        ):
            self.refused_transcript(text, stderr=stderr, verify=False)

    def test_expression_identity_and_all_coordinates(self):
        good = self.text("candidate", "original.vexpr")
        for text in (
            good.replace('out "out" 63 n63\n', ""),
            good + 'out "out" 0 n0\n',
            good.replace('out "out" 63 n63', 'out "out" 64 n63'),
            good.replace('out "out" 63 n63', 'out "out" 63 n0'),
            good.replace('out "out" 63 n63', 'out "out" 63 n999'),
            good + 'n64 = elem "x" 0\n',
            good.replace('n1 = elem "x" 1', 'n0 = elem "x" 1'),
            good.replace('n1 = elem "x" 1', "n1 = const 1"),
        ):
            with self.assertRaises(ValueError):
                replay.check_identity(text)

    def test_graph_terminal_pcs_geometry_and_assumptions(self):
        good = self.text("candidate", "original.graph")
        for text in (
            good.replace("terminal completed", "terminal aborted error t0 pc30: bad"),
            good.replace("pc24 amd wave=0 Instruction", "pc23 amd wave=0 Instruction"),
            good.replace("workgroup 0,0,0", "workgroup 1,0,0"),
            good.replace("ConfiguredLdsBytes(80000)", "ConfiguredLdsBytes(256)"),
            good + "terminal completed\n",
            good.replace("e365 t63 pc30 exit\n", ""),
        ):
            with self.assertRaises(ValueError):
                replay.check_graph(text, self.kernel, False)
        with self.assertRaises(ValueError):
            replay.check_graph(
                self.text("baseline", "original.graph"), self.kernel, False
            )

    def test_dma_flat_wait_barrier_and_memory_links(self):
        good = self.text("candidate", "original.graph")
        replacements = (
            ("class: BufferLoadToLds32", "class: VectorMemory"),
            ("counters: [(Vm, 1), (Lgkm, 1)]", "counters: [(Vm, 1)]"),
            (
                "pc25 amd wave=0 Wait { vmcnt: Some(0)",
                "pc25 amd wave=0 Wait { vmcnt: Some(1)",
            ),
            (
                "pc28 amd wave=0 Wait { vmcnt: Some(0), lgkmcnt: Some(0)",
                "pc28 amd wave=0 Wait { vmcnt: Some(0), lgkmcnt: None",
            ),
            ("BarrierRelease { generation: 0 }", "BarrierRelease { generation: 1 }"),
            (
                "t63 pc21 read ordinary generic global Plain by t63 [0x100fc,+4)",
                "t63 pc21 read ordinary generic global Plain by t63 [0x100f8,+4)",
            ),
            ("amd-memory issue=e29 effect=e30\n", ""),
            (
                "e299 t63 pc29 write ordinary generic global Plain by t63 [0x200fc,+4) = n447",
                "e299 t63 pc29 write ordinary generic global Plain by t63 [0x200fc,+4) = n446",
            ),
        )
        for before, after in replacements:
            with self.subTest(before=before):
                self.assertIn(before, good)
                with self.assertRaises(ValueError):
                    replay.check_graph(good.replace(before, after), self.kernel, False)

    def test_baseline_is_exact_refusal_without_outputs(self):
        good = self.text("baseline", "original.graph")
        replay.check_graph(good, self.kernel, True)
        with self.assertRaises(ValueError):
            replay.check_graph(
                good.replace("pc24: wave", "pc23: wave"), self.kernel, True
            )
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory)
            shutil.copyfile(self.baseline / "original.graph", tmp / "original.graph")
            (tmp / "original.vexpr").write_text("")
            with self.assertRaises(ValueError):
                replay.check_artifacts(tmp, self.kernel, True)

    def test_changed_input_or_inventory_is_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory) / "package"
            shutil.copytree(ROOT, tmp, ignore=shutil.ignore_patterns("__pycache__"))
            (tmp / "identity.spec").write_text("out[i] = 0;\n")
            with self.assertRaisesRegex(ValueError, "package input changed"):
                replay.inputs(tmp)
            shutil.copyfile(ROOT / "identity.spec", tmp / "identity.spec")
            inventory = json.loads((tmp / "checksums.json").read_text())
            changed = copy.deepcopy(inventory)
            changed.pop("identity.spec")
            (tmp / "checksums.json").write_text(json.dumps(changed))
            with self.assertRaisesRegex(ValueError, "inventory changed"):
                replay.inputs(tmp)

    def test_changed_capture_hash_is_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            tmp = Path(directory) / "package"
            shutil.copytree(ROOT, tmp, ignore=shutil.ignore_patterns("__pycache__"))
            (tmp / "results/candidate/verify.stdout").write_text("VERDICT: ACCEPT\n")
            with self.assertRaises(ValueError):
                replay.check_recorded(tmp)


if __name__ == "__main__":
    unittest.main()
