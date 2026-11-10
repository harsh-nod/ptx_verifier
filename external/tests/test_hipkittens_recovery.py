"""Recovery identity, incomplete-premise and full rotary-footprint controls."""
import copy
import hashlib
import io
import json
import os
import stat
from pathlib import Path
import struct
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest import mock
import zipfile
import warnings

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "extraction"))
import hipkittens_recovery as recovery


def digest(data):
    return hashlib.sha256(data).hexdigest()


def search_catalog(assembly=b"whole original assembly\n", obj=b"whole original object"):
    return {"modules": [{"id": "original", "compiler_attempt": {
        "assembly_sha256": digest(assembly), "object_sha256": digest(obj)}}]}


class RecoveryTests(unittest.TestCase):
    def test_zip_symlink_member_bytes_do_not_count_as_regular_assembly(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "links.zip"
            with zipfile.ZipFile(path, "w") as archive:
                member = zipfile.ZipInfo("kernel.s")
                member.create_system = 3
                member.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(member, b"whole original assembly\n")
            result = recovery.scan(search_catalog(), [path])
            self.assertFalse(result["matches"])
            self.assertEqual(result["statistics"]["archive_nonregular_members"], 1)

    def test_fifo_and_file_symlinks_are_refused_without_opening_or_blocking(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            os.mkfifo(root / "blocked.s")
            (root / "device.s").symlink_to("/dev/zero")
            outside = root / "outside"
            outside.mkdir()
            (outside / "original.s").write_bytes(b"whole original assembly\n")
            selected = root / "selected"
            selected.mkdir()
            (selected / "escape.s").symlink_to(outside / "original.s")
            code = ("import sys,json;sys.path.insert(0,sys.argv[1]);import hipkittens_recovery as r;"
                    "catalog=json.loads(sys.argv[2]);print(json.dumps(r.scan(catalog,sys.argv[3:])))")
            process = subprocess.run([sys.executable, "-c", code, str(Path(recovery.__file__).parent),
                                      json.dumps(search_catalog()), str(root / "blocked.s"), str(root / "device.s"),
                                      str(selected)], capture_output=True, text=True, timeout=3)
            self.assertEqual(process.returncode, 0, process.stderr)
            result = json.loads(process.stdout)
            self.assertEqual(len(result["errors"]), 3)
            self.assertFalse(result["matches"])
            self.assertFalse(result["summary"]["search_complete_within_declared_scope"])

    def test_actual_reads_and_total_tar_decompression_have_byte_limits(self):
        with self.assertRaisesRegex(ValueError, "actual consumed bytes"):
            recovery.bounded_digest(io.BytesIO(b"more than four bytes"), 4)
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "expanded.tar.gz"
            with tarfile.open(archive, "w:gz") as tar:
                member = tarfile.TarInfo("ignored.txt")
                member.size = 100000
                tar.addfile(member, io.BytesIO(bytes(member.size)))
            self.assertLess(archive.stat().st_size, 1000)
            result = recovery.scan(search_catalog(), [archive], max_member_bytes=1000)
            self.assertEqual(len(result["errors"]), 1)
            self.assertIn("actual consumed bytes", result["errors"][0]["reason"])
            self.assertFalse(result["summary"]["search_complete_within_declared_scope"])

    def test_corrupt_deflate_member_becomes_an_incomplete_receipt(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "broken.zip"
            with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
                archive.writestr("kernel.s", b"whole original assembly\n")
            data = bytearray(path.read_bytes())
            name_length, extra_length = struct.unpack_from("<HH", data, 26)
            data[30 + name_length + extra_length] = 7  # reserved DEFLATE block type
            path.write_bytes(data)
            result = recovery.scan(search_catalog(), [path])
            self.assertEqual(len(result["errors"]), 1)
            self.assertFalse(result["matches"])
            self.assertFalse(result["summary"]["search_complete_within_declared_scope"])

    def test_archive_changes_invalidate_matches_and_duplicate_names_have_offsets(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "duplicate.zip"
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", UserWarning)
                with zipfile.ZipFile(path, "w") as archive:
                    archive.writestr("kernel.s", b"whole original assembly\n")
                    archive.writestr("kernel.s", b"changed same-name member")
            result = recovery.scan(search_catalog(), [path])
            self.assertEqual(len(result["matches"]), 1)
            matched = result["matches"][0]
            self.assertEqual(matched["member_ordinal"], 0)
            self.assertEqual(matched["member_header_offset"], 0)
            self.assertEqual(matched["bytes"], len(b"whole original assembly\n"))
            original_digest = recovery.bounded_digest
            calls = 0

            def changed_after_hash(stream, limit):
                nonlocal calls
                answer = original_digest(stream, limit)
                calls += 1
                if calls == 1:
                    with zipfile.ZipFile(path, "w") as archive:
                        archive.writestr("kernel.s", b"whole original assembly\n")
                return answer

            with mock.patch.object(recovery, "bounded_digest", side_effect=changed_after_hash):
                result = recovery.scan(search_catalog(), [path])
            self.assertFalse(result["matches"])
            self.assertFalse(result["archives"])
            self.assertTrue(result["errors"])
            self.assertFalse(result["summary"]["search_complete_within_declared_scope"])

    def test_published_attempt_binds_generated_inputs_without_qualifying_originals(self):
        catalog = recovery.read(recovery.DEFAULT_CATALOG)
        audit = recovery.read(recovery.DEFAULT_CATALOG.with_name("device-call-recovery-audit-20261110.json"))
        self.assertEqual(audit["catalog_sha256"], recovery.sha(recovery.DEFAULT_CATALOG))
        attempt = audit["regenerated_rotary_attempt"]
        module = next(m for m in catalog["modules"] if m["id"] == attempt["module_id"])
        config, spec, _, details = recovery.rotary_inputs(module)
        self.assertEqual(digest((json.dumps(config, indent=2) + "\n").encode()), attempt["launch_sha256"])
        self.assertEqual(digest(spec.encode()), attempt["specification_sha256"])
        self.assertEqual(details["spec_dimensions"], attempt["spec_dimensions"])
        self.assertEqual(module["compiler_attempt"]["assembly_sha256"], attempt["original_assembly_sha256"])
        self.assertNotEqual(attempt["original_assembly_sha256"], attempt["regenerated_assembly_sha256"])
        self.assertEqual(attempt["original_metadata_sha256"], attempt["regenerated_metadata_sha256"])
        self.assertEqual(attempt["required_output_coordinates"], 4096)
        self.assertIsNone(attempt["graph_result"])
        self.assertIsNone(attempt["mathematical_result"])
        self.assertFalse(attempt["qualified"])
        self.assertFalse(attempt["original_replayed"])
        self.assertEqual(audit["summary"]["qualified_originals"], 0)

    def test_changed_public_source_cannot_generate_an_original_contract(self):
        frontier = recovery.read(recovery.DEFAULT_FRONTIER)
        module = recovery.original_modules(frontier)[0]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / module["source"]
            path.parent.mkdir(parents=True)
            path.write_text("source with an invented simpler workload\n")
            with mock.patch.object(recovery.inventory, "build_inventory", return_value=frontier["upstream"]):
                with self.assertRaisesRegex(ValueError, "original source hash differs"):
                    recovery.build_catalog(root)

    def test_original_population_and_absent_contracts_are_explicit(self):
        catalog = recovery.read(recovery.DEFAULT_CATALOG)
        frontier = recovery.read(recovery.DEFAULT_FRONTIER)
        modules = recovery.original_modules(frontier)
        self.assertEqual(len(modules), 16)
        self.assertEqual(sum(len(m["entries"]) for m in modules), 18)
        self.assertEqual({m["target"] for m in modules}, {"gfx950"})
        self.assertEqual(catalog["frontier_sha256"], recovery.sha(recovery.DEFAULT_FRONTIER))
        self.assertEqual(catalog["baseline_sha256"], recovery.sha(recovery.DEFAULT_BASELINE))
        families = {}
        for module in catalog["modules"]:
            for entry in module["entries"]:
                contract = entry["source_contract"]
                for field in ("original_launch_snapshot", "original_argument_layout", "original_allocation_bases", "complete_specification"):
                    self.assertIsNone(contract[field])
                self.assertFalse(contract["qualified"])
                self.assertFalse(contract["replayed"])
                families[contract["family"]] = families.get(contract["family"], 0) + 1
                if contract["family"] == "layernorm_dropout":
                    self.assertIn("clock64-seeded", contract["blockers"][0])
                if contract["family"].startswith("attention_"):
                    self.assertIsNone(contract["geometry"]["original_compiler_defines"])
                    self.assertNotEqual(contract["geometry"]["source_defaults"], contract["geometry"]["makefile_defaults"])
        self.assertEqual(families, {"layernorm_dropout": 5, "rotary": 5, "lds_microbenchmark": 4,
                                   "attention_prep": 2, "attention_dq_shuffle": 2})

    def test_missing_duplicate_or_wrong_selected_attempt_is_refused(self):
        original = recovery.read(recovery.DEFAULT_FRONTIER)
        selected = next(p for p in original["probes"] if p.get("parse", {}).get("first_blocker", {}).get("category")
                        == "noninteger_assembly_constant")
        for mutate in (lambda f, p: f["probes"].remove(p), lambda f, p: f["probes"].append(copy.deepcopy(p)),
                       lambda f, p: p.update(selected_attempt="unknown"),
                       lambda f, p: p["entries"].append(copy.deepcopy(p["entries"][0])),
                       lambda f, p: p.update(target="gfx1250")):
            frontier = copy.deepcopy(original)
            probe = next(p for p in frontier["probes"] if p["id"] == selected["id"])
            mutate(frontier, probe)
            with self.assertRaises(ValueError):
                recovery.original_modules(frontier)

    def test_renamed_exact_bytes_match_but_comments_or_truncation_do_not(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = b"whole original assembly\n"
            (root / "renamed.asm").write_bytes(original)
            (root / "same-symbol-but-changed.s").write_bytes(original + b"; added comment\n")
            (root / "truncated.s").write_bytes(original[:-1])
            result = recovery.scan(search_catalog(), [root])
            self.assertEqual(len(result["matches"]), 1)
            self.assertEqual(result["matches"][0]["role"], "assembly")
            self.assertEqual(result["summary"]["assembly_recovered_modules"], 1)
            self.assertEqual(result["summary"]["qualified_originals"], 0)
            self.assertEqual(result["summary"]["original_replays"], 0)

    def test_objects_do_not_count_as_recovered_assembly(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kernel.o").write_bytes(b"whole original object")
            result = recovery.scan(search_catalog(), [root])
            self.assertEqual(result["matches"][0]["role"], "object")
            self.assertEqual(result["summary"]["assembly_recovered_modules"], 0)
            self.assertEqual(result["summary"]["assembly_missing_module_ids"], ["original"])

    def test_tar_and_zip_members_are_streamed_and_never_extracted(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            assembly = b"whole original assembly\n"
            with tarfile.open(root / "retained.tar.gz", "w:gz") as archive:
                member = tarfile.TarInfo("../../escape.s")
                member.size = len(assembly)
                archive.addfile(member, io.BytesIO(assembly))
                link = tarfile.TarInfo("symlink.s")
                link.type = tarfile.SYMTYPE
                link.linkname = "../../escape.s"
                archive.addfile(link)
            with zipfile.ZipFile(root / "retained.zip", "w") as archive:
                archive.writestr("/absolute.s", assembly)
            before = set(root.parent.iterdir())
            result = recovery.scan(search_catalog(), [root])
            self.assertEqual(set(root.parent.iterdir()), before)
            self.assertEqual(len(result["matches"]), 2)
            self.assertEqual(result["summary"]["assembly_recovered_modules"], 1)
            self.assertTrue(result["summary"]["search_complete_within_declared_scope"])
            self.assertEqual({m["member"] for m in result["matches"]}, {"../../escape.s", "/absolute.s"})
            self.assertEqual(sorted(p.name for p in root.iterdir()), ["retained.tar.gz", "retained.zip"])

    def test_missing_roots_size_limits_and_corrupt_archives_remain_incomplete(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kernel.s").write_bytes(b"whole original assembly\n")
            (root / "broken.tar.gz").write_bytes(b"not an archive")
            result = recovery.scan(search_catalog(), [root, root / "absent"], max_member_bytes=4)
            self.assertEqual(len(result["errors"]), 3)
            self.assertFalse(result["summary"]["search_complete_within_declared_scope"])
            self.assertEqual(result["summary"]["assembly_recovered_modules"], 0)
            self.assertEqual(result["summary"]["qualified_originals"], 0)

    def test_repeated_roots_and_hardlinks_do_not_multiply_matches(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "kernel.s").write_bytes(b"whole original assembly\n")
            (root / "hardlink.s").hardlink_to(root / "kernel.s")
            result = recovery.scan(search_catalog(), [root, root / "kernel.s", root])
            self.assertEqual(len(result["matches"]), 1)

    def test_rotary_preserves_every_full_input_and_all_absolute_wg0_writes(self):
        catalog = recovery.read(recovery.DEFAULT_CATALOG)
        for module in catalog["modules"]:
            if module["entries"][0]["source_contract"]["family"] != "rotary":
                with self.assertRaises(ValueError):
                    recovery.rotary_inputs(module)
                continue
            config, spec, layout, details = recovery.rotary_inputs(module)
            n = module["entries"][0]["source_contract"]["arrays"]["x_o"]["shape"][2]
            self.assertEqual((config["grid"], config["block"], config["dynamic_shared_bytes"]),
                             ([16, 16, n // 32], [64, 1, 1], 0))
            self.assertEqual([a["shape"] for a in config["arrays"][:3]], [[16, 16, n, 128], [n, 64], [n, 64]])
            outputs = config["arrays"][3:]
            addresses = {a["base"] + 2 * i for a in outputs for i in range(a["shape"][0])}
            base = details["original_allocations"]["o"]["base"]
            self.assertEqual(addresses, {base + 2 * i for i in range(4096)})
            self.assertEqual(len(outputs), 64)
            self.assertEqual(spec.count(" = "), 64)
            self.assertEqual(details["spec_dimensions"], {"B": 16, "H": 16, "N": n, "D": 128, "C": 64})
            self.assertIn("x[0,0,31,d+64]", spec)
            self.assertIn(f"ATTN_N == {n}", layout)
            self.assertFalse(details["qualified"])
            payload = bytes(config["params"][0]["bytes"])
            self.assertEqual(len(payload), 200)
            for offset, name, shape in ((0, "x", [16, 16, n, 128]), (48, "o", [16, 16, n, 128]),
                                        (96, "sin", [1, 1, n, 64]), (144, "cos", [1, 1, n, 64])):
                self.assertEqual(struct.unpack_from("<5Q", payload, offset),
                                 (details["original_allocations"][name]["base"], *shape))
                self.assertEqual(payload[offset + 40:offset + 48], bytes(8))
            self.assertEqual(payload[192:], bytes(8))


if __name__ == "__main__":
    unittest.main()
