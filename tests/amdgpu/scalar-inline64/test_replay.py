"""Refusal controls for the finite two-word public replayer."""

from pathlib import Path
import tempfile
import re
import unittest
from unittest import mock

import replay

DATA = Path(__file__).parent / "results/baseline"


class ReplayTests(unittest.TestCase):
    def check(self, stdout=None, stderr=None, mode="verify", code=None, baseline=True):
        text = (
            (DATA / f"gfx950-{mode}.stdout").read_text() if stdout is None else stdout
        )
        error = (
            (DATA / f"gfx950-{mode}.stderr").read_text() if stderr is None else stderr
        )
        replay.check_transcript(
            text,
            error,
            (1 if baseline and mode == "verify" else 0) if code is None else code,
            "gfx950",
            mode,
            baseline,
        )

    def test_actual_retained_complete_baselines(self):
        for target in ("gfx950", "gfx1250"):
            for mode in ("verify", "analyze"):
                replay.check_transcript(
                    (DATA / f"{target}-{mode}.stdout").read_text(),
                    (DATA / f"{target}-{mode}.stderr").read_text(),
                    1 if mode == "verify" else 0,
                    target,
                    mode,
                    True,
                )
            replay.check_graph(DATA / f"{target}.graph", target)
            replay.check_expressions(DATA / f"{target}.vexpr", replay.BASELINE_WORDS)

    def test_actual_complete_candidate_records(self):
        directory = DATA.parent / "candidate"
        for target in replay.TARGETS:
            for mode in ("verify", "analyze"):
                replay.check_transcript(
                    (directory / f"{target}-{mode}.stdout").read_text(),
                    (directory / f"{target}-{mode}.stderr").read_text(),
                    0,
                    target,
                    mode,
                    False,
                )
            replay.check_graph(directory / f"{target}.graph", target)
            replay.check_expressions(
                directory / f"{target}.vexpr", replay.CORRECT_WORDS
            )

    def test_unknown_abort_or_conflicting_verdict_refuses(self):
        base = (DATA / "gfx950-verify.stdout").read_text()
        for extra in (
            "execution stopped: unsupported AMD instruction `foo`",
            "UNKNOWN",
            "AMD memory-conflict freedom FAIL",
            "VERDICT: ACCEPT",
            "EQUIVALENT (matches spec)",
            "  equivalence: all 2 compared elements proved equivalent",
        ):
            with self.subTest(extra=extra), self.assertRaises(ValueError):
                self.check(base + "\n" + extra + "\n")
        with self.assertRaises(ValueError):
            self.check(stderr="unsupported AMD instruction `foo`")

    def test_typed_hazard_diagnostics_refuse_despite_passing_summary(self):
        directory = DATA.parent / "candidate"
        for baseline, source in ((True, DATA), (False, directory)):
            for mode in ("verify", "analyze"):
                base = (source / f"gfx950-{mode}.stdout").read_text()
                stderr = (source / f"gfx950-{mode}.stderr").read_text()
                code = 1 if baseline and mode == "verify" else 0
                for diagnostic in (
                    "MemoryConflict { kind: WriteWrite, first: EventId(1), second: EventId(2), space: Global, byte: 65536 }",
                    "ReadBeforeReady",
                    "ValuScalarReadBeforeReady",
                    "WriteBeforeReady",
                    "VmemWriteBeforeReady",
                ):
                    with self.subTest(baseline=baseline, mode=mode, diagnostic=diagnostic):
                        with self.assertRaisesRegex(ValueError, "contradictory"):
                            replay.check_transcript(
                                base + "\n" + diagnostic + "\n",
                                stderr, code, "gfx950", mode, baseline,
                            )

    def test_missing_or_duplicate_properties_refuse(self):
        base = (DATA / "gfx950-verify.stdout").read_text()
        line = next(
            line
            for line in base.splitlines()
            if line.startswith("  AMD trace completeness")
        )
        for text in (
            base.replace(line + "\n", ""),
            base + line + "\n",
            base.replace(line, line.replace("PASS", "UNKNOWN")),
        ):
            with self.assertRaises(ValueError):
                self.check(text)

    def test_wrong_process_code_sample_or_numeric_coordinates_refuse(self):
        base = (DATA / "gfx950-verify.stdout").read_text()
        for text in (
            base.replace("elements: 2", "elements: 1/2"),
            base.replace("  out[1]\n", ""),
            base.replace("first out[0]", "first out[1]"),
        ):
            with self.assertRaises(ValueError):
                self.check(text)
        for code in (0, 2, -9, None):
            with self.assertRaises(ValueError):
                replay.check_transcript(base, "", code, "gfx950", "verify", True)

    def test_graph_acceptance_alone_is_not_numeric_correctness(self):
        with self.assertRaises(ValueError):
            self.check(mode="analyze", baseline=False)
        base = (DATA / "gfx950-verify.stdout").read_text()
        with self.assertRaises(ValueError):
            self.check(
                base.replace("VERDICT: REJECT", "VERDICT: ACCEPT"),
                code=0,
                baseline=False,
            )

    def test_incomplete_or_wrong_typed_analysis_outputs_refuse(self):
        base = (DATA / "gfx950-analyze.stdout").read_text()
        for text in (
            base.replace("    out[1] = 0\n", ""),
            base.replace("out[1] = 0", "out[1] = 1"),
            base.replace("out[1] = 0", "out[0] = 0"),
            base + "    out[2] = 0\n",
            base.replace("2 element(s) written", "1 element(s) written"),
        ):
            with self.assertRaises(ValueError):
                self.check(text, mode="analyze")

    def test_bad_expression_roots_aliases_and_types_refuse(self):
        original = (DATA / "gfx950.vexpr").read_text()
        mutants = [
            original.replace('out "out" 1 n1\n', ""),
            original.replace('out "out" 1 n1', 'out "out" 1 n0'),
            original.replace('out "out" 1 n1', 'out "out" 0 n1'),
            original.replace("n1 = int 0", "n1 = real 0"),
            original.replace("n1 = int 0", "n1 = int 1"),
            original + 'out "out" 2 n1\n',
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.vexpr"
            for text in mutants:
                path.write_text(text)
                with self.assertRaises(ValueError):
                    replay.check_expressions(path, replay.BASELINE_WORDS)

    def test_incomplete_graph_wrong_target_and_shifted_output_refuse(self):
        original = (DATA / "gfx950.graph").read_text()
        mutants = [
            original.replace("terminal completed", "terminal aborted"),
            original.replace("targets gfx950", "targets gfx1250"),
            original.replace("[0x10004,+4)", "[0x10008,+4)"),
            re.sub(r"e\d+ t0 pc11 exit\n", "", original),
            original.replace(
                "pc6 amd wave=0 Instruction", "pc5 amd wave=0 Instruction"
            ),
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.graph"
            for text in mutants:
                path.write_text(text)
                with self.assertRaises(ValueError):
                    replay.check_graph(path, "gfx950")

    def test_all_inputs_rechecked_after_collection(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            binary = root / "binary"
            binary.write_bytes(b"baseline")
            fixture = root / "fixture"
            fixture.write_bytes(b"same")
            fake_paths = dict.fromkeys(replay.PINS, fixture)
            pins = dict.fromkeys(replay.PINS, replay.sha(fixture))
            calls = []

            def capture(command, stem, cwd, *args):
                calls.append(command)
                mode = command[1]
                if mode == "analyze":
                    binary.write_bytes(b"changed")
                    (cwd / "gfx950.graph").write_bytes(
                        (DATA / "gfx950.graph").read_bytes()
                    )
                    (cwd / "gfx950.vexpr").write_bytes(
                        (DATA / "gfx950.vexpr").read_bytes()
                    )
                return (
                    {"returncode": 1 if mode == "verify" else 0},
                    (DATA / f"gfx950-{mode}.stdout").read_text(),
                    (DATA / f"gfx950-{mode}.stderr").read_text(),
                )

            with (
                mock.patch.object(replay, "fixture_paths", return_value=fake_paths),
                mock.patch.object(replay, "PINS", pins),
                mock.patch.object(replay, "capture", side_effect=capture),
                self.assertRaisesRegex(ValueError, "input changed"),
            ):
                replay.collect(binary, root / "output", root, True, ("gfx950",))
            self.assertIn("--verify-numeric", calls[0])
            self.assertEqual(calls[0][calls[0].index("--sample") + 1], "0")

    def test_fixture_drift_and_existing_output_refuse(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            directory = root / replay.FIXTURES
            directory.mkdir(parents=True)
            for name in replay.PINS:
                (directory / name).write_text("changed")
            with self.assertRaisesRegex(ValueError, "fixture hash changed"):
                replay.fixture_paths(root)
            with self.assertRaisesRegex(ValueError, "invalid targets"):
                replay.collect(
                    Path(__file__), root / "out", root, targets=("gfx950", "gfx950")
                )
            with (
                mock.patch.object(replay, "fixture_paths", return_value={}),
                self.assertRaisesRegex(ValueError, "output already exists"),
            ):
                replay.collect(Path(__file__), root, root)


if __name__ == "__main__":
    unittest.main()
