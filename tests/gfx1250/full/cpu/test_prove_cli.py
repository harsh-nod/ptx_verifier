"""CPU proof orchestration controls; synthetic logs are never proof evidence."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

import aggregate_cli as aggregate
import prove_cli as driver

HERE = Path(__file__).resolve().parent
REGISTRY = HERE.parent / "cases.json"


def accepted(elements):
    return (
        "\n".join(f"  {name} (algorithm) PASS" for name in driver.RUNTIME.PROPERTIES)
        + f"\nVC check: 1.0s (decision procedure 1.0s)  elements: {elements}\n"
        + "EQUIVALENT (matches spec)\nVERDICT: ACCEPT\n"
    )


class FullCliControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root, cls.cases, cls.pins, cls.outputs = driver.load_registry(REGISTRY)

    def fixture(self):
        temp = tempfile.TemporaryDirectory(prefix="ptx-cli-accounting-control-")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        snapshot = root / "snapshot"
        snapshot.mkdir()
        binary = snapshot / "volta"
        binary.write_bytes(b"host schema control, not an executed verifier")
        runtime = root / "runtime-control"
        runtime.write_bytes(b"host schema control")
        for name in self.pins:
            target = snapshot / "corpus" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(self.root / name, target)
        identity = {
            "binary_revision_supplied_by_builder": "1" * 40,
            "fixture_revision_supplied_by_builder": "2" * 40,
            "driver_sha256": driver.sha(HERE / "prove_cli.py"),
            "bounded_driver_sha256": driver.sha(HERE / "prove_advanced.py"),
            "binary_sha256": driver.sha(binary),
            "runtime_sha256": {str(runtime): driver.sha(runtime)},
            "input_sha256": self.pins,
            "output_contracts": self.outputs,
            "mode": "default",
            "log_level": "info",
            "host": "host schema control",
            "platform": "host schema control",
        }
        paths = []
        for index in range(4):
            directory = root / f"group{index}"
            directory.mkdir()
            cases = self.cases[index * 8 : (index + 1) * 8]
            record = {
                **identity,
                "schema_version": 1,
                "gate": driver.GATE,
                "status": "partial",
                "all_required_complete": False,
                "hardware_execution": False,
                "sampling": False,
                "selected_kernels": [case["kernel"] for case in cases],
                "expected_outputs": sum(case["expected_outputs"] for case in cases),
                "started_unix": 1,
                "finished_unix": 2,
                "snapshot": str(snapshot),
                "capability_probe": {"argv": [str(binary), "--help"], "exit_code": 0},
                "limits": {
                    "wall_seconds": 7200,
                    "cpu_seconds": 6900,
                    "rss_bytes": 512 * 1024**3,
                    "address_space_bytes": 768 * 1024**3,
                },
                "results": [],
            }
            for case in cases:
                name = case["kernel"]
                artifacts = directory / name
                artifacts.mkdir()
                (artifacts / "stdout.txt").write_text(
                    accepted(case["expected_outputs"])
                )
                (artifacts / "stderr.txt").write_text("")
                resources = artifacts / "resources.txt"
                resources.write_text(
                    "user=1.0 system=0.1 peak_rss_kib=1024 wall=1.0 exit=0\n"
                )
                argv = driver.command(
                    binary, snapshot / "corpus", case, "default", "info"
                )
                record["results"].append(
                    {
                        "kernel": name,
                        "baseline_id": case["baseline_id"],
                        "passed": True,
                        "outcome": "passed",
                        "expected_outputs": case["expected_outputs"],
                        "output_contract": self.outputs[name],
                        "argv": argv,
                        "measured_argv": [
                            "/usr/bin/time",
                            "-f",
                            driver.TIME_FORMAT,
                            "-o",
                            str(resources),
                            *argv,
                        ],
                        "exit_code": 0,
                        "termination": None,
                        "elapsed_seconds": 1,
                        "resources": resources.read_text(),
                        "stdout_sha256": driver.sha(artifacts / "stdout.txt"),
                        "stderr_sha256": driver.sha(artifacts / "stderr.txt"),
                    }
                )
            path = directory / "receipt.json"
            path.write_text(json.dumps(record))
            paths.append(path)
        return root, paths

    def change(self, path, mutate):
        record = json.loads(path.read_text())
        mutate(record)
        path.write_text(json.dumps(record))

    def test_all32_disjoint_groups_retain_every_original_output(self):
        _, paths = self.fixture()
        result = aggregate.aggregate(REGISTRY, paths)
        self.assertEqual(
            (result["case_count"], result["expected_outputs"]), (32, 395394)
        )
        scan = self.outputs["mamba_scan_original"]
        self.assertEqual(set(scan["baseline"]), {"out", "out_x"})
        self.assertEqual(len(scan["native"]), 64)
        self.assertEqual(scan["baseline"]["out"]["elements"], 4096)
        flash = self.outputs["flash_attention_original"]
        self.assertEqual(
            sorted(value["elements"] for value in flash["baseline"].values()),
            [128, 8192],
        )

    def test_exact_original_commands_keep_target_sampling_dtype_and_geometry_configs(
        self,
    ):
        for case in self.cases:
            argv = driver.command(
                Path("/snapshot/volta"),
                Path("/snapshot/corpus"),
                case,
                "logging",
                "debug",
            )
            self.assertEqual(argv[argv.index("--target") + 1], "gfx1250")
            self.assertEqual(argv[argv.index("--sample") + 1], "0")
            self.assertIn("--verify-numeric", argv)
            self.assertNotIn("--no-profile", argv)
            self.assertIn("--log-level", argv)
            self.assertEqual(
                argv[argv.index("--config") + 1],
                f"/snapshot/corpus/tests/gfx1250/full/{case['launch_config']}",
            )
        self.assertEqual(len(driver.selected_cases(self.cases, [])), 32)
        for names in (["unknown"], ["relu_f16"] * 2):
            with self.assertRaises(ValueError):
                driver.selected_cases(self.cases, names)

    def test_missing_duplicate_and_overlapping_groups_fail(self):
        _, paths = self.fixture()
        for bad in ([], paths[:-1], paths + [paths[0]]):
            with self.subTest(paths=bad), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, bad)
        self.change(
            paths[1], lambda record: record.update(selected_kernels=["relu_f16"])
        )
        with self.assertRaisesRegex(ValueError, "overlapping"):
            aggregate.aggregate(REGISTRY, paths)

    def test_mixed_partial_stale_or_changed_contract_groups_fail(self):
        _, paths = self.fixture()
        saved = paths[0].read_text()
        mutations = {
            "failed": lambda r: r.update(status="failed"),
            "empty": lambda r: r.update(selected_kernels=[]),
            "sampled": lambda r: r.update(sampling=True),
            "hardware": lambda r: r.update(hardware_execution=True),
            "wrong_gate": lambda r: r.update(gate="bounded workload"),
            "count": lambda r: r.update(expected_outputs=1),
            "fixture_revision": lambda r: r.update(
                fixture_revision_supplied_by_builder="3" * 40
            ),
            "binary_revision": lambda r: r.update(
                binary_revision_supplied_by_builder="3" * 40
            ),
            "driver": lambda r: r.update(driver_sha256="0" * 64),
            "missing_input": lambda r: r["input_sha256"].pop(
                next(iter(r["input_sha256"]))
            ),
            "missing_array": lambda r: r["output_contracts"][
                "flash_attention_original"
            ]["baseline"].pop("lse"),
            "missing_result": lambda r: r["results"].pop(),
            "duplicate_result": lambda r: r["results"].append(r["results"][0]),
            "unfinished": lambda r: r.update(finished_unix=0),
            "fake_complete": lambda r: r.update(
                status="pass", all_required_complete=True
            ),
        }
        for name, mutate in mutations.items():
            paths[0].write_text(saved)
            self.change(paths[0], mutate)
            with self.subTest(name=name), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, paths)

    def test_nonzero_unknown_reduced_or_changed_case_results_fail(self):
        _, paths = self.fixture()
        saved = paths[0].read_text()
        mutations = {
            "nonzero_with_pass_stdout": lambda r: r.update(exit_code=1),
            "timeout": lambda r: r.update(termination="wall_timeout"),
            "unexecuted": lambda r: r.update(elapsed_seconds=0),
            "infinite_elapsed": lambda r: r.update(elapsed_seconds=float("inf")),
            "unsupported": lambda r: r.update(outcome="unsupported"),
            "failed": lambda r: r.update(passed=False),
            "baseline": lambda r: r.update(baseline_id="W32"),
            "coordinates": lambda r: r["output_contract"]["native"]["output"].update(
                indices_sha256="0" * 64
            ),
            "sample": lambda r: r["argv"].__setitem__(
                r["argv"].index("--sample") + 1, "1"
            ),
            "target": lambda r: r["argv"].__setitem__(
                r["argv"].index("--target") + 1, "gfx950"
            ),
            "no_numeric": lambda r: r["argv"].remove("--verify-numeric"),
        }
        for name, mutate in mutations.items():
            paths[0].write_text(saved)
            self.change(paths[0], lambda record: mutate(record["results"][0]))
            with self.subTest(name=name), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, paths)

    def test_actual_logs_are_checked_even_when_their_updated_hash_matches(self):
        _, paths = self.fixture()
        record = json.loads(paths[0].read_text())
        name = record["results"][0]["kernel"]
        log = paths[0].parent / name / "stdout.txt"
        original = log.read_text()
        variants = [
            original.replace("elements: 1024", "elements: 1/1024"),
            original.replace("elements: 1024", "elements: 1"),
            original.replace("VERDICT: ACCEPT", "VERDICT: UNKNOWN"),
            original.replace("EQUIVALENT (matches spec)", ""),
            original + "VERDICT: ACCEPT\n",
        ]
        variants += [
            original.replace(prop + " (algorithm) PASS", prop + " (algorithm) UNKNOWN")
            for prop in driver.RUNTIME.PROPERTIES
        ]
        for text in variants:
            log.write_text(text)
            self.change(
                paths[0],
                lambda receipt: receipt["results"][0].update(
                    stdout_sha256=driver.sha(log)
                ),
            )
            with self.subTest(text=text[-100:]), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, paths)

    def test_snapshot_runtime_and_log_mutations_fail(self):
        root, paths = self.fixture()
        targets = [
            root / "snapshot/volta",
            root / "runtime-control",
            root / "snapshot/corpus" / next(iter(self.pins)),
            paths[0].parent / self.cases[0]["kernel"] / "stderr.txt",
        ]
        for target in targets:
            saved = target.read_bytes()
            target.write_bytes(saved + b" changed")
            with self.subTest(path=target), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, paths)
            target.write_bytes(saved)

    def test_resource_artifact_must_match_success_and_budget(self):
        _, paths = self.fixture()
        path = paths[0].parent / self.cases[0]["kernel"] / "resources.txt"
        original = path.read_text()
        path.write_text(original + "changed")
        with self.assertRaises(ValueError):
            aggregate.aggregate(REGISTRY, paths)
        for text in (
            original.replace("exit=0", "exit=1"),
            original.replace("peak_rss_kib=1024", "peak_rss_kib=999999999999"),
        ):
            path.write_text(text)
            self.change(
                paths[0], lambda record: record["results"][0].update(resources=text)
            )
            with self.subTest(text=text), self.assertRaises(ValueError):
                aggregate.aggregate(REGISTRY, paths)

    def test_failures_have_explicit_nonacceptance_outcomes(self):
        examples = [
            ({"termination": "wall_timeout"}, "", "", "timeout"),
            ({"termination": "rss_limit"}, "", "", "resource_limit"),
            ({"exit_code": -11}, "", "", "crash"),
            ({"exit_code": 2}, "VERDICT: UNKNOWN\n", "", "unknown"),
            ({"exit_code": 1}, "", "Unsupported instruction", "unsupported"),
            ({"exit_code": 1}, "", "unwritten output[9]", "missing_output"),
            ({"exit_code": 1}, "VERDICT: REJECT\n", "", "refuted"),
            ({"exit_code": 1}, accepted(1024), "", "process_error"),
        ]
        for result, stdout, stderr, outcome in examples:
            self.assertEqual(driver.failed_outcome(result, stdout, stderr), outcome)

    def test_preflight_invalidates_stale_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "receipt.json").write_text('{"status":"pass"}')
            result = subprocess.run(
                [
                    sys.executable,
                    driver.__file__,
                    "--binary",
                    "/missing",
                    "--registry",
                    "/missing",
                    "--binary-revision",
                    "1" * 40,
                    "--fixture-revision",
                    "2" * 40,
                    "--output",
                    str(root),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 1, result.stderr)
            record = json.loads((root / "receipt.json").read_text())
            self.assertEqual(record["status"], "incomplete")
            self.assertEqual(record["results"], [])

    def test_aggregate_failure_invalidates_stale_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "aggregate.json"
            output.write_text('{"status":"pass"}')
            result = subprocess.run(
                [
                    sys.executable,
                    aggregate.__file__,
                    "--registry",
                    str(REGISTRY),
                    "--receipt",
                    "/missing",
                    "--output",
                    str(output),
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertEqual(json.loads(output.read_text())["status"], "fail")

    def test_output_aliases_do_not_overwrite_retained_source_or_proof(self):
        root, paths = self.fixture()
        protected = aggregate.retained_artifacts(REGISTRY, paths)
        for path in (
            paths[0],
            root / "snapshot/volta",
            root / "runtime-control",
            paths[0].parent / self.cases[0]["kernel"] / "stdout.txt",
        ):
            alias = root / "alias.json"
            os.link(path, alias)
            with self.subTest(path=path), self.assertRaisesRegex(ValueError, "aliases"):
                driver.refuse_alias(alias, protected)
            alias.unlink()
        alias = root / "receipt.json"
        source = self.root / "tests/gfx1250/full/fixtures/original-f16.hip"
        os.link(source, alias)
        digest = driver.sha(source)
        result = subprocess.run(
            [
                sys.executable,
                driver.__file__,
                "--binary",
                "/missing",
                "--registry",
                str(REGISTRY),
                "--binary-revision",
                "1" * 40,
                "--fixture-revision",
                "2" * 40,
                "--output",
                str(root),
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertEqual(driver.sha(source), digest)


if __name__ == "__main__":
    unittest.main()
