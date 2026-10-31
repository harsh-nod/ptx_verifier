"""Source inventory controls; no compiler, GPU or optional Python package needed."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("hipkittens_inventory", ROOT / "external/extraction/hipkittens_inventory.py")
INVENTORY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INVENTORY)


class HipKittensInventoryTests(unittest.TestCase):
    def test_comments_literals_and_documentation_do_not_become_kernels(self):
        source = '''// __global__ void commented() {}
/* template<class T> __global__ void example(T x); */
const char *s = "__global__ void text() {}";
const char *r = R"tag(__global__ void raw_text() {})tag";
template<int N>
__global__ __launch_bounds__(N, 1) void actual(int x) { if (x) { return; } }
'''
        rows = INVENTORY.declarations(source)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["name"], "actual")
        self.assertEqual(rows[0]["template"], "template<int N>")
        self.assertEqual(rows[0]["line"], 6)
        self.assertTrue(rows[0]["definition"])

    def test_attributes_cluster_and_forward_declarations_keep_distinct_roles(self):
        source = '''template<class T> __global__ static void forward(T x);
__global__ __cluster_dims__(4,4,1) __launch_bounds__(256,1)
__attribute__((amdgpu_num_vgpr(128))) void clustered(int x) { }
'''
        rows = INVENTORY.declarations(source)
        self.assertEqual([(row["name"], row["definition"]) for row in rows], [("forward", False), ("clustered", True)])
        self.assertIn("__cluster_dims__(4,4,1)", rows[1]["signature"])
        self.assertIsNone(rows[1]["template"])

    def test_unknown_or_truncated_global_cannot_silently_disappear(self):
        for source in ["__global__ strange_function() {}", "__global__ void k() {", "__global__\n__global__ void k() {}"]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                INVENTORY.declarations(source)

    def test_template_launch_expression_is_retained_without_guessing_dimensions(self):
        rows = INVENTORY.launches('''f<T, nested<N>><<<g.grid(), g.block(), shared>>>(g);
hipLaunchKernelGGL(k, grid, block, 0, stream, g);
// ignored<<<1,1>>>();
''')
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["callee"], "f<T, nested<N>>")
        self.assertIn("hipLaunchKernelGGL(k, grid, block", rows[1]["expression"])

    def test_profiles_preserve_architecture_and_shared_wrapper_scope(self):
        self.assertEqual(INVENTORY.profiles("kernels/cdna5/gemm/k.cpp", "")[0]["target"], "gfx1250")
        self.assertEqual(INVENTORY.profiles("analysis/bf16_gemm/mi325x/k.cpp", "")[0]["target"], "gfx942")
        self.assertEqual({row["target"] for row in INVENTORY.profiles("tests/unit/common/wrapper.cuh", "")}, {"gfx950", "gfx1250"})

    def test_exact_tracked_sources_and_build_recipes_are_bound(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "include").mkdir()
            (root / "include/kittens.cuh").write_bytes(b"// fixture\r\n")
            (root / "kernels/cdna4/x").mkdir(parents=True)
            (root / "kernels/cdna4/x/kernel.cpp").write_text("__global__ void k() {}\n")
            (root / "kernels/cdna4/x/Makefile").write_text("GPU_TARGET ?= CDNA4\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], check=True)
            revision = INVENTORY.git(root, "rev-parse", "HEAD").decode().strip()
            with patch.object(INVENTORY, "REVISION", revision):
                document = INVENTORY.build_inventory(root)
                self.assertEqual(document["summary"]["kernel_definitions"], 1)
                self.assertEqual(document["source_sha256"]["include/kittens.cuh"], INVENTORY.sha(b"// fixture\r\n"))
                (root / "include/untracked.cuh").write_text("// can change source resolution\n")
                with self.assertRaisesRegex(ValueError, "untracked"):
                    INVENTORY.build_inventory(root)
                (root / "include/untracked.cuh").unlink()
                (root / "kernels/cdna4/x/Makefile").write_text("GPU_TARGET ?= CDNA5\n")
                with self.assertRaisesRegex(ValueError, "modified"):
                    INVENTORY.build_inventory(root)

    def test_checked_in_inventory_has_no_duplicate_definition_coordinates(self):
        document = json.loads((ROOT / "external/hipkittens/corpus/inventory.json").read_text())
        rows = document["kernels"]
        self.assertEqual(len(rows), len({(row["source"], row["line"]) for row in rows}))
        self.assertEqual(sum(row["definition"] for row in rows), document["summary"]["kernel_definitions"])
        self.assertTrue(all(row["source"] in document["source_sha256"] for row in rows))


if __name__ == "__main__":
    unittest.main()
