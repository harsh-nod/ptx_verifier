"""Host-only publication controls for completeness, precision and privacy."""

from collections import Counter
import copy
import csv
import gzip
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "publication", Path(__file__).with_name("publish.py")
)
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)


class SyntheticPublicationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="readiness-publication-test-")
        self.base = Path(self.tmp.name)
        self.root = self.base / "source"
        self.root.mkdir()
        for name in ["module.s", "source.hip", "spec.spec", *p.DRIVERS.values()]:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("synthetic public source\n")
        source_sha = p.sha((self.root / "source.hip").read_bytes())
        assembly_sha = p.sha((self.root / "module.s").read_bytes())
        spec_sha = p.sha((self.root / "spec.spec").read_bytes())
        self.document = {
            "schema_version": 1,
            "cases": [
                {
                    "id": f"case{i}",
                    "split": "development" if i < 71 else "heldout",
                    "expectation": "safe" if i == 0 else "hazard",
                    "assembly": "module.s",
                    "assembly_sha256": assembly_sha,
                    "source": "source.hip",
                    "source_sha256": source_sha,
                    "spec": "spec.spec",
                    "spec_sha256": spec_sha,
                }
                for i in range(77)
            ],
            "mathematical_controls": [
                {
                    "id": "wrong-spec",
                    "case": "case0",
                    "spec": "spec.spec",
                    "spec_sha256": spec_sha,
                }
            ],
        }
        self.manifest = self.base / "manifest.json"
        self.manifest.write_text(json.dumps(self.document))
        self.manifest_sha = p.sha(self.manifest.read_bytes())
        self.pin = patch.object(p, "MANIFEST_SHA", self.manifest_sha)
        self.pin.start()
        self.builds = {
            "baseline_revision": "a" * 40,
            "candidate_revision": "b" * 40,
            "baseline_sha256": "c" * 64,
            "candidate_sha256": "d" * 64,
            "source_dirty": False,
            "candidate_source_dirty": False,
            "command": "CARGO_TARGET_DIR=/private/build cargo build --release",
            "build_log": "/private/worker-host/build.log",
            "hostname": "private-worker",
        }
        self.build_path = self.base / "builds.json"
        self.build_path.write_text(json.dumps(self.builds))
        self.drivers = {
            key: p.sha((self.root / path).read_bytes())
            for key, path in p.DRIVERS.items()
        }

    def tearDown(self):
        self.pin.stop()
        self.tmp.cleanup()

    def report(self, repeats=1, seed=1):
        ids = [f"case{i}" for i in range(71)]

        def sample(case, variant, repeat=None):
            row = {
                "case": case,
                "variant": variant,
                "classification": "timeout" if case == "case1" else "verified",
                "seconds": 0.012345678901234567,
                "peak_rss_kib": 8123,
                "time_to_detection_seconds": None,
                "executed_instructions": 123456789,
                "detected_expected_hazard": False,
                "timed_out": case == "case1",
                "false_acceptance": case != "case0",
                "false_positive": False,
                "reason": "/private/worker-host/raw diagnostic",
                "measurement_errors": [],
                "diagnostics_sha256": "e" * 64,
                "output_expressions_sha256": "f" * 64,
                "command": [
                    "/private/bin/verifier",
                    "analyze",
                    str(self.root / "module.s"),
                    "--emit-exprs",
                    "/private/raw/outputs.vexpr",
                ],
                "launch_contract": {
                    "effective_path": "/private/raw/launch.json",
                    "effective_sha256": "1" * 64,
                },
                "early_readiness_enabled": variant == "candidate",
            }
            if repeat is not None:
                row["repeat"] = repeat
            return row

        samples = [
            sample(case, variant, repeat)
            for repeat in range(repeats + 1)
            for case in ids
            for variant in ("baseline", "candidate")
        ]
        stage = {
            "seconds": 0.12345678901234567,
            "returncode": 1,
            "timed_out": False,
            "command": ["/private/bin/verifier", "verify", str(self.root / "module.s")],
            "launch_contract": None,
        }
        return {
            "variants": [
                {
                    "name": name,
                    "binary_revision": self.builds[name + "_revision"],
                    "binary_sha256": self.builds[name + "_sha256"],
                    "early_readiness": name == "candidate",
                }
                for name in ("baseline", "candidate")
            ],
            "source_comparison": {
                "common_parent": "a" * 40,
                "baseline_revision": "a" * 40,
                "candidate_revision": "b" * 40,
                "source_diff_sha256": "9" * 64,
                "changed_paths": ["module.s"],
            },
            "case_manifest_sha256": self.manifest_sha,
            **self.drivers,
            "runtime_context": {
                "hostname": "private-worker",
                "cpu_model": "private-device",
                "kernel_release": "6.0-private-worker",
                "architecture": "x86_64",
            },
            "load_observations": [],
            "seed": seed,
            "timeout_seconds": 60,
            "repeated_process_samples": repeats,
            "cache_policy": "declared policy",
            "safe_spec_preflight": {
                variant: [
                    {
                        "case": "case0",
                        "classification": "spec_verified",
                        "reason": "every complete specification element proved before timing",
                        "stage": stage,
                    }
                ]
                for variant in ("baseline", "candidate", "candidate-off")
            },
            "mathematical_controls": {
                variant: [
                    {
                        "id": "wrong-spec",
                        "classification": "mathematical_refutation",
                        "stage": stage,
                    }
                ]
                for variant in ("baseline", "candidate", "candidate-off")
            },
            "baseline_off": [sample(case, "baseline-off") for case in ids],
            "candidate_off": [sample(case, "candidate-off") for case in ids],
            "samples": samples,
            "summary": {
                "cases": [{"case": case} for case in ids],
                "total_configurations": 71,
                "variants": {
                    variant: [{"case": case} for case in ids]
                    for variant in ("baseline", "candidate")
                },
                "adoption_gates_pass": False,
            },
            "measurement_scope": "synthetic host bookkeeping only",
            "sample_order": [
                {key: row[key] for key in ("repeat", "case", "variant")}
                for row in samples
            ],
        }

    def check(self, report):
        return p.check_report(
            report, "development", 1, 1, self.document, self.builds, self.drivers
        )

    def test_synthetic_export_retains_both_datasets_all_samples_controls_and_precision(
        self,
    ):
        paths = []
        for name, repeats, seed in [("initial", 1, 1), ("confirmation", 2, 2)]:
            path = self.base / (name + ".json")
            path.write_text(json.dumps(self.report(repeats, seed)))
            paths.extend(
                ["--dataset", name, "development", str(repeats), str(seed), str(path)]
            )
        output = self.base / "publication"
        argv = [
            "publication",
            "--source-root",
            str(self.root),
            "--manifest",
            str(self.manifest),
            "--builds",
            str(self.build_path),
            "--output",
            str(output),
            *paths,
        ]
        with patch.object(sys, "argv", argv):
            p.main()
        self.assertEqual(
            {path.name for path in output.iterdir()},
            {"metadata.json", "summary.json", "samples.csv.gz", "README.md"},
        )
        summaries = json.loads((output / "summary.json").read_text())["datasets"]
        self.assertEqual(set(summaries), {"initial", "confirmation"})
        self.assertTrue(
            all(not item["adoption_gates_pass"] for item in summaries.values())
        )
        with gzip.open(
            output / "samples.csv.gz", "rt", encoding="utf-8", newline=""
        ) as stream:
            rows = list(csv.DictReader(stream))
        self.assertEqual(len(rows), 1006)
        self.assertEqual(
            Counter(row["phase"] for row in rows),
            {
                "first": 284,
                "repeated": 426,
                "default_off": 284,
                "safe_spec_preflight": 6,
                "mathematical_controls": 6,
            },
        )
        self.assertEqual(float(rows[0]["seconds"]), 0.012345678901234567)
        self.assertEqual(int(rows[0]["executed_instructions"]), 123456789)
        self.assertEqual(rows[0]["time_to_detection_seconds"], "null")
        self.assertEqual(sum(row["timed_out"] == "true" for row in rows), 14)
        compressed = (output / "samples.csv.gz").read_bytes()
        self.assertEqual(compressed[:3], b"\x1f\x8b\x08")
        self.assertEqual(compressed[3] & 8, 0)  # No filename in the gzip header.
        self.assertEqual(compressed[4:8], b"\x00" * 4)  # mtime=0.
        for path in output.iterdir():
            text = (
                gzip.decompress(path.read_bytes()).decode("utf-8")
                if path.suffix == ".gz"
                else path.read_text()
            )
            self.assertNotIn("/private/", text)
            self.assertNotIn("private-worker", text)
            self.assertNotIn("private-device", text)
            self.assertNotIn('"hostname":', text)
        metadata = json.loads((output / "metadata.json").read_text())
        self.assertEqual(len(metadata["materialized_assembly_sha256"]), 77)
        self.assertEqual(metadata["builds"]["baseline_sha256"], "c" * 64)
        self.assertEqual(
            metadata["publication_artifact_sha256"]["samples.csv.gz"], p.sha(compressed)
        )
        second = self.base / "publication-again"
        repeated_argv = argv.copy()
        repeated_argv[repeated_argv.index("--output") + 1] = str(second)
        with patch.object(sys, "argv", repeated_argv):
            p.main()
        for path in output.iterdir():
            self.assertEqual(path.read_bytes(), (second / path.name).read_bytes())
        with patch.object(sys, "argv", argv), self.assertRaises(ValueError):
            p.main()

    def test_partial_duplicate_or_extra_samples_refuse(self):
        for mutate in [
            lambda r: r["samples"].pop(),
            lambda r: r["samples"].__setitem__(0, copy.deepcopy(r["samples"][1])),
            lambda r: r["samples"][0].__setitem__("case", "unregistered"),
        ]:
            report = self.report()
            mutate(report)
            with self.assertRaises(ValueError):
                self.check(report)

    def test_missing_preflight_math_or_default_off_refuse(self):
        for mutate in [
            lambda r: r["baseline_off"].pop(),
            lambda r: r["safe_spec_preflight"]["candidate"].clear(),
            lambda r: r["mathematical_controls"]["candidate-off"].clear(),
        ]:
            report = self.report()
            mutate(report)
            with self.assertRaises(ValueError):
                self.check(report)

    def test_driver_binary_manifest_seed_repeats_or_order_drift_refuse(self):
        mutations = [
            lambda r: r.__setitem__("driver_sha256", "0" * 64),
            lambda r: r["variants"][0].__setitem__("binary_sha256", "0" * 64),
            lambda r: r.__setitem__("case_manifest_sha256", "0" * 64),
            lambda r: r.__setitem__("seed", 2),
            lambda r: r.__setitem__("repeated_process_samples", 2),
            lambda r: r["sample_order"].reverse(),
            lambda r: r.__setitem__("timeout_seconds", 59.9),
            lambda r: r.__setitem__("timeout_seconds", 61),
        ]
        for mutate in mutations:
            report = self.report()
            mutate(report)
            with self.assertRaises(ValueError):
                self.check(report)

    def test_path_identity_and_stale_source_refuse(self):
        for text in ["/private/path", "../outside", "C:\\private\\path"]:
            with self.assertRaises(ValueError):
                p.relative(text)
        with self.assertRaises(ValueError):
            p.sanitize({"unexpected_path": "/private/path"}, self.root)
        (self.root / "module.s").write_text("changed")
        with self.assertRaises(ValueError):
            p.frozen_assets(self.document, self.root)

    def test_duplicate_json_keys_and_nan_refuse(self):
        path = self.base / "invalid.json"
        for text in ['{"x":1,"x":2}', '{"x":NaN}']:
            path.write_text(text)
            with self.assertRaises(ValueError):
                p.load(path)

    def test_public_primary_source_urls_preserved_private_urls_refuse(self):
        urls = [
            "https://github.com/llvm/llvm-project/blob/main/README.md",
            "https://llvm.org/docs/AMDGPUUsage.html",
            "https://docs.llvm.org/AMDGPUUsage.html",
            "https://arxiv.org/html/2511.12638v1",
            "https://export.arxiv.org/pdf/2511.12638",
            "https://docs.amd.com/v/u/en-US/manual",
        ]
        for url in urls:
            self.assertEqual(
                p.sanitize({"source_url": url}, self.root), {"source_url": url}
            )
        for url in [
            "https://private-worker/internal",
            "https://127.0.0.1/file",
            "http://arxiv.org/file",
            "https://token@llvm.org/docs/file",
            "https://github.com/private-worker/private/file",
        ]:
            with self.assertRaises(ValueError):
                p.sanitize({"source_url": url}, self.root)

    def test_platform_retains_virtualization_without_machine_suffix(self):
        for release in [
            "6.6.87.2-microsoft-standard-WSL2-private-worker",
            "6.6-Microsoft-PRIVATE",
        ]:
            self.assertEqual(
                p.sanitize(
                    {
                        "kernel_release": release,
                        "architecture": "x86_64",
                        "allowed_logical_cpus": 32,
                    },
                    self.root,
                ),
                {
                    "platform": "WSL2",
                    "architecture": "x86_64",
                    "allowed_logical_cpus": 32,
                },
            )
        self.assertEqual(
            p.sanitize({"kernel_release": "6.6-private-worker"}, self.root),
            {"platform": "Linux"},
        )

    def test_numeric_summary_error_count_preserved_list_diagnostics_sanitized(self):
        value = {
            "summary": {"measurement_errors": 3},
            "sample": {
                "measurement_errors": [
                    "missing per-process resource observation",
                    "/private/worker-host/error",
                ]
            },
        }
        result = p.sanitize(value, self.root)
        self.assertEqual(result["summary"], {"measurement_errors": 3})
        self.assertEqual(
            result["sample"]["measurement_errors"],
            [
                "missing per-process resource observation",
                "Measurement error text omitted; hash retained.",
            ],
        )
        self.assertEqual(
            result["sample"]["measurement_error_sha256"],
            [p.sha(text.encode()) for text in value["sample"]["measurement_errors"]],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
