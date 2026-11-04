"""Finite original template/ABI and complete-math refusal controls; no GPU."""
import importlib.util
import itertools
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "external/extraction"))
SPEC = importlib.util.spec_from_file_location("hipkittens_vectors", ROOT / "external/extraction/hipkittens_vectors.py")
VECTORS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VECTORS)


def kernel(dtype="f32", shape=(16, 32, 8), size=1, layout="naive"):
    if dtype == "f32":
        encoded, ns, gl, value, end = "f", 3, 2, "f", "E"
    else:
        encoded, ns, gl, value, end = {"bf16": "14__hip_bfloat16", "f16": "6__half"}[dtype], 4, 3, "S1_", "F"
    rows, cols, packing = shape
    symbol = (f"_ZL17global_wrapper_1dI18reg_vec_load_storeI{encoded}EN7kittens5ducks8rt_shape8rt_shape"
              f"ILi{rows}ELi{cols}ELi{packing}EEENS{ns}_8st_shape8st_16x16E{value}Li{size}ELi1E"
              f"TkNS{ns}_2gl3allENS{gl}_2glI{value}Li1ELi1ELi1ELi{cols*size}EJEEE"
              f"JNS{ns}_9rv_layout5{layout}EEEvT5_S{end}_")
    return {".name": symbol, ".wavefront_size": 64, ".group_segment_fixed_size": 0,
            ".kernarg_segment_size": 32,
            ".args": [{".offset": offset, ".size": 16, ".value_kind": "by_value"} for offset in (0, 16)]}


def all_kernels():
    return [kernel(dtype, shape, size, layout) for dtype, shape, size, layout in itertools.product(
        ("f32", "bf16", "f16"), sorted(VECTORS.SHAPES), range(1, 5), sorted(VECTORS.LAYOUTS))]


def add1_kernel(shape=(16, 32, 8), size=1, layout="naive"):
    result = kernel("f32", shape, size, layout)
    result['.name'] = result['.name'].replace('I18reg_vec_load_storeIfE', 'I8vec_add1').replace(
        'NS3_', 'NS2_').replace('ENS2_2glIf', 'ENS1_2glIf').replace('T5_SE_', 'T5_SD_')
    return result


def all_add1_kernels():
    return [add1_kernel(shape, size, layout) for shape, size, layout in itertools.product(
        sorted(VECTORS.SHAPES), range(1, 5), sorted(VECTORS.LAYOUTS))]


def verify_output(elements=32, verdict="ACCEPT", equivalent=True):
    checks = "\n".join(f"  {name} (target algorithm) PASS" for name in sorted(VECTORS.EXPECTED_PROPERTIES))
    outcome = "EQUIVALENT (matches spec)" if equivalent else "NOT EQUIVALENT: 32 mismatched element(s) vs spec"
    return f"{checks}\nVC check: 0.001s (decision procedure 0.001s)  elements: {elements}\n{outcome}\nVERDICT: {verdict}\n"


class HipKittensVectorTests(unittest.TestCase):
    def test_add_one_profile_is_exactly_original_f32_cross_product(self):
        cases = VECTORS.make_cases(all_add1_kernels(), VECTORS.ADD1)
        self.assertEqual(len(cases), 84)
        self.assertEqual({row['dtype'] for row in cases}, {'f32'})
        self.assertEqual({layout: sum(row['layout'] == layout for row in cases)
                          for layout in VECTORS.LAYOUTS}, {'naive': 28, 'align': 28, 'ortho': 28})
        self.assertEqual(VECTORS.COPY.spec, VECTORS.SPEC)
        self.assertEqual(VECTORS.COPY.wrong_spec, VECTORS.WRONG_SPEC)
        self.assertIn('out[i] = x[i] + 1;', VECTORS.ADD1.spec)
        self.assertIn('out[i] = x[i] + 2;', VECTORS.ADD1.wrong_spec)
        self.assertNotEqual(VECTORS.ADD1.spec, VECTORS.ADD1.wrong_spec)
        self.assertEqual(VECTORS.ADD1.dtypes, ('f32',))
        self.assertIn('kittens::gl<float, 1, 1, 1, 128>', VECTORS.layout_check_source(cases))
        self.assertNotIn('kittens::bf16', VECTORS.layout_check_source(cases))
        for changed in [all_add1_kernels()[:-1], all_add1_kernels() + [add1_kernel()],
                        all_add1_kernels()[1:] + [add1_kernel()]]:
            with self.subTest(length=len(changed)), self.assertRaisesRegex(ValueError, 'missing, duplicate or extra'):
                VECTORS.make_cases(changed, VECTORS.ADD1)

    def test_add_one_profile_refuses_other_families_types_and_substitutions(self):
        for old, new in [('I8vec_add1', 'I8vec_norm'), ('EfLi1ELi1E', 'EdLi1ELi1E'),
                         ('NS2_8st_shape', 'NS3_8st_shape'), ('ENS1_2gl', 'ENS2_2gl'),
                         ('T5_SD_', 'T5_SE_'), ('layout5naive', 'layout5other'),
                         ('ELi32EJEEE', 'ELi31EJEEE'), ('EfLi1ELi1E', 'EfLi1ELi2E')]:
            changed = add1_kernel()
            self.assertIn(old, changed['.name'])
            changed['.name'] = changed['.name'].replace(old, new)
            with self.subTest(old=old, new=new), self.assertRaises(ValueError):
                VECTORS.decode_kernel(changed, VECTORS.ADD1)
        with self.assertRaises(ValueError):
            VECTORS.decode_kernel(kernel(), VECTORS.ADD1)
        with self.assertRaises(ValueError):
            VECTORS.decode_kernel(add1_kernel())
        for mutate in [lambda k: k.update({'.wavefront_size': 32}),
                       lambda k: k['.args'][1].update({'.offset': 8}),
                       lambda k: k['.args'][0].update({'.size': 8})]:
            changed = add1_kernel()
            mutate(changed)
            with self.assertRaises(ValueError):
                VECTORS.decode_kernel(changed, VECTORS.ADD1)

    def test_add_one_full_original_launch_and_math_only_wrong_control(self):
        case = VECTORS.decode_kernel(add1_kernel((32, 32, 8), 4, 'align'), VECTORS.ADD1)
        actual = VECTORS.launch(case)
        self.assertEqual(actual['block'], [64, 1, 1])
        self.assertEqual(actual['grid'], [1, 1, 1])
        self.assertEqual(actual['workgroup_id'], [0, 0, 0])
        self.assertEqual(actual['dynamic_shared_bytes'], 80000)
        self.assertEqual([(row['dtype'], row['shape'], row['base']) for row in actual['arrays']],
                         [('f32', [128], 0x10000), ('f32', [128], 0x20000)])
        self.assertEqual([bytes(row['bytes']) for row in actual['params']],
                         [struct.pack('<Q8x', base) for base in (0x10000, 0x20000)])
        record = {'status': 'rejected', 'returncode': 1}
        wrong = verify_output(elements=128, verdict='REJECT', equivalent=False)
        racy = wrong.replace('AMD memory-conflict freedom (target algorithm) PASS',
                             'AMD memory-conflict freedom (target algorithm) FAIL')
        control = VECTORS.math_control({**case, 'status': 'graph_rejected'}, record, racy, '', VECTORS.ADD1)
        self.assertTrue(control['math_refuted'])
        self.assertFalse(control['graph_verified'])
        self.assertNotIn('passed', control)
        self.assertEqual(control['status'], 'graph_rejected')
        safe_control = VECTORS.math_control({**case, 'status': 'verified'}, record, wrong, '', VECTORS.ADD1)
        self.assertTrue(safe_control['graph_verified'])
        self.assertTrue(safe_control['passed'])
        for refused in [racy.replace('elements: 128', 'elements: 1/128'),
                        racy.replace('AMD trace completeness (target algorithm) PASS',
                                     'AMD trace completeness (target algorithm) UNKNOWN')]:
            self.assertFalse(VECTORS.math_control({**case, 'status': 'graph_rejected'}, record,
                                                 refused, '', VECTORS.ADD1)['math_refuted'])

    def test_original_full_cross_product_and_host_size_formula(self):
        cases = VECTORS.make_cases(all_kernels())
        self.assertEqual(len(cases), 252)
        self.assertEqual({row["dtype"] for row in cases}, {"f32", "bf16", "f16"})
        self.assertTrue(all(row["elements"] == row["rt_shape"][1] * row["size_multiplier"] for row in cases))
        for changed in [all_kernels()[:-1], all_kernels() + [kernel()], all_kernels()[1:] + [kernel()]]:
            with self.assertRaisesRegex(ValueError, "missing, duplicate or extra"):
                VECTORS.make_cases(changed)

    def test_changed_template_dtype_shape_or_byvalue_abi_is_refused(self):
        for mutate in [lambda k: k.update({".wavefront_size": 32}),
                       lambda k: k[".args"][1].update({".size": 8}),
                       lambda k: k[".args"][0].update({".value_kind": "global_buffer"}),
                       lambda k: k[".args"][1].update({".offset": 8}),
                       lambda k: k.update({".kernarg_segment_size": 24}),
                       lambda k: k.update({".name": k[".name"].replace("ELi32EJEEE", "ELi31EJEEE")}),
                       lambda k: k.update({".name": k[".name"].replace("Li1ELi1ETk", "Li1ELi2ETk")}),
                       lambda k: k.update({".name": k[".name"].replace("IfEN7", "IdEN7")})]:
            changed = kernel()
            mutate(changed)
            with self.subTest(changed=changed), self.assertRaises(ValueError):
                VECTORS.decode_kernel(changed)

    def test_full_original_launch_retains_dtype_length_and_static_gl_padding(self):
        case = VECTORS.decode_kernel(kernel("f16", (32, 32, 8), 4, "align"))
        launch = VECTORS.launch(case)
        self.assertEqual(launch["block"], [64, 1, 1])
        self.assertEqual(launch["grid"], [1, 1, 1])
        self.assertEqual(launch["dynamic_shared_bytes"], 80000)
        self.assertEqual([array["shape"] for array in launch["arrays"]], [[128], [128]])
        self.assertEqual([array["dtype"] for array in launch["arrays"]], ["f16", "f16"])
        for param, base in zip(launch["params"], [0x10000, 0x20000]):
            self.assertEqual(bytes(param["bytes"]), struct.pack("<Q8x", base))

    def test_layout_proof_covers_all_instantiated_gl_types(self):
        text = VECTORS.layout_check_source(VECTORS.make_cases(all_kernels()))
        self.assertEqual(text.count("static_assert(sizeof("), 18)
        self.assertEqual(text.count("static_assert(offsetof("), 18)
        for dtype in ["float", "kittens::bf16", "kittens::half"]:
            self.assertIn("kittens::gl<" + dtype, text)

    def test_acceptance_needs_complete_properties_count_and_overall_verdict(self):
        record = {"status": "succeeded", "returncode": 0}
        output = verify_output()
        self.assertEqual(VECTORS.classify_verify(record, output, "", 32), "verified")
        for changed in ["VERDICT: ACCEPT\n", output.replace("elements: 32", "elements: 1/32"),
                        output.replace("elements: 32", "elements: 31"), output.replace("VERDICT: ACCEPT", "VERDICT: UNKNOWN"),
                        output.replace("AMD trace completeness (target algorithm) PASS", "AMD trace completeness (target algorithm) UNKNOWN"),
                        output.replace("AMD memory-conflict freedom", "unrecognized property"),
                        output + "  AMD trace completeness (target algorithm) PASS\n"]:
            with self.subTest(output=changed), self.assertRaises(ValueError):
                VECTORS.classify_verify(record, changed, "", 32)
        with self.assertRaises(ValueError):
            VECTORS.classify_verify({"status": "rejected", "returncode": 1}, output, "", 32)

    def test_wrong_spec_is_separate_from_graph_failure_or_incomplete_math(self):
        record = {"status": "rejected", "returncode": 1}
        output = verify_output(verdict="REJECT", equivalent=False)
        self.assertEqual(VECTORS.classify_verify(record, output, "", 32), "mathematical_mismatch")
        failed = output.replace("AMD wait and register readiness (target algorithm) PASS",
                                "AMD wait and register readiness (target algorithm) FAIL")
        self.assertEqual(VECTORS.classify_verify(record, failed, "", 32), "graph_rejected")
        equivalent_but_racy = verify_output(verdict="REJECT").replace(
            "AMD memory-conflict freedom (target algorithm) PASS", "AMD memory-conflict freedom (target algorithm) FAIL")
        self.assertEqual(VECTORS.classify_verify(record, equivalent_but_racy, "", 32), "graph_rejected")
        for incomplete in ["NOT EQUIVALENT\nVERDICT: REJECT\n", output.replace("elements: 32", "elements: 1/32")]:
            self.assertNotEqual(VECTORS.classify_verify(record, incomplete, "", 32), "mathematical_mismatch")

    def test_crash_timeout_and_unknown_cannot_be_verified(self):
        for status in ["process_crash", "process_error", "timeout"]:
            self.assertEqual(VECTORS.classify_verify({"status": status, "returncode": None}, "", "", 32), status)
        self.assertEqual(VECTORS.classify_verify({"status": "rejected", "returncode": 2}, "VERDICT: UNKNOWN\n", "", 32), "inconclusive")

    def test_aborted_or_unsupported_transcript_cannot_prove_or_refute_math(self):
        for record, output in [({'status': 'succeeded', 'returncode': 0}, verify_output()),
                               ({'status': 'rejected', 'returncode': 1}, verify_output(verdict='REJECT', equivalent=False))]:
            for diagnostic in ['execution stopped: unsupported AMD instruction `foo`',
                               'the trace generator aborted, so the graph is only a prefix',
                               'execution aborted after incomplete memory access']:
                with self.subTest(diagnostic=diagnostic), self.assertRaisesRegex(ValueError, 'contradicts'):
                    VECTORS.classify_verify(record, output, diagnostic, 32)
                self.assertFalse(VECTORS.full_identity_proved(record, output, diagnostic, 32))

    def test_reused_complete_module_and_metadata_are_source_and_byte_bound(self):
        with tempfile.TemporaryDirectory() as name:
            campaign = Path(name)
            directory = campaign / 'unit'
            directory.mkdir()
            kernels = all_kernels()
            text = ('.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\n.amdgpu_metadata\n'
                    + json.dumps({'amdhsa.target': 'amdgcn-amd-amdhsa--gfx950', 'amdhsa.kernels': kernels})
                    + '\n.end_amdgpu_metadata\n')
            (directory/'kernel.s').write_text(text)
            (directory/'kernel.o').write_bytes(b'original-object')
            compile_record = {'status': 'succeeded', 'returncode': 0,
                              'command': ['clang++', '-DTEST_ALL', '-DTEST_INTENSITY=2']}
            (directory/'compile.json').write_text(json.dumps(compile_record))
            (directory/'assemble.json').write_text(json.dumps({'status': 'succeeded', 'returncode': 0}))
            row = {'id': 'unit', 'source': VECTORS.SOURCE, 'profile': {'target': 'gfx950'},
                   'source_sha256': 'original-source', 'assembly_sha256': VECTORS.inventory.sha(text.encode()),
                   'object_sha256': VECTORS.inventory.sha(b'original-object'), 'emitted_kernels': kernels}
            report = {'source_revision': VECTORS.inventory.REVISION, 'results': [row]}
            (campaign/'report.json').write_text(json.dumps(report))
            document = {'source_sha256': {VECTORS.SOURCE: 'original-source'}}
            self.assertEqual(len(VECTORS.load_module(campaign, document)[2]), 252)
            for filename in ('kernel.s', 'kernel.o'):
                path = directory/filename
                original = path.read_bytes()
                path.write_bytes(original+b'changed')
                with self.assertRaisesRegex(ValueError, 'stale original module'):
                    VECTORS.load_module(campaign, document)
                path.write_bytes(original)
            compile_record['command'][-1] = '-DTEST_INTENSITY=3'
            (directory/'compile.json').write_text(json.dumps(compile_record))
            with self.assertRaisesRegex(ValueError, 'template sweep'):
                VECTORS.load_module(campaign, document)


if __name__ == '__main__':
    unittest.main()
