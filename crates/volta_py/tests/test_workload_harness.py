"""Accounting and mutation regressions for the shared workload runner."""
import importlib.util
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("volta_workload_runner", ROOT / "ai_compiler_kernels/check_races.py")
RUNNER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = RUNNER
SPEC.loader.exec_module(RUNNER)


def test_native_check_names_and_hazards_are_not_dropped():
    report = RUNNER.parse_cli("""kernel: graph verification
  AMD trace completeness (gfx950 graph contract)                 PASS
  AMD wait and register readiness (CDNA4 counters and register dependencies) FAIL
      ReadBeforeReady at v2
GRAPH VERIFICATION: REJECTED
""")
    outcome, detail = RUNNER.classify(report, "", 65)
    assert outcome is RUNNER.Outcome.RACE_CONDITION
    assert "ReadBeforeReady" in detail


def test_verified_graph_does_not_hide_incomplete_output_footprint():
    report = RUNNER.parse_cli("  output 'out': 1 element(s) written\nGRAPH VERIFICATION: VERIFIED\n")
    outcome, detail = RUNNER.classify(report, "", 65)
    assert outcome is RUNNER.Outcome.CHECK_FAILED
    assert "1/65" in detail


def test_native_mutations_stay_inside_selected_kernel_and_keep_locations():
    source = (ROOT / "crates/volta_amdgpu_analysis/src/frontend/fixtures/clang22-copy-add.s").read_text()
    copy_sites = RUNNER.mutation_sites(source, "amdgpu", "copy")
    add_sites = RUNNER.mutation_sites(source, "amdgpu", "add")
    assert len(copy_sites) == 3 and len(add_sites) == 3
    assert max(site.line for site in copy_sites) < min(site.line for site in add_sites)
    patched = RUNNER.remove_statement(source, copy_sites[0], "amdgpu", "copy")
    assert len(patched) == len(source)
    assert patched.count("\n") == source.count("\n")
    assert patched[source.index("add:"):] == source[source.index("add:"):]
    assert len(RUNNER.mutation_sites(patched, "amdgpu", "copy")) == 2


def test_native_launch_does_not_inherit_ptx_dummy_parameters():
    variant = RUNNER.load_amdgpu_variants()["copy"][0]
    args = RUNNER.launch_args(variant, variant.path.read_text())
    assert args.count("--param") == 3
    assert "gfx950" in args and "amdgpu" in args
    assert args[args.index("--dyn-shared") + 1] == "0"


def test_disjoint_output_slices_keep_native_pitches_without_extra_parameters():
    x = RUNNER.Array("x", 2, 64, RUNNER.Kind.INPUT, 0x10000)
    out0 = RUNNER.Array("out0", 2, 32, RUNNER.Kind.OUTPUT, 0x100000)
    out1 = RUNNER.Array("out1", 2, 32, RUNNER.Kind.OUTPUT, 0x100000 + 2916 * 2)
    variant = RUNNER.Variant("conv2d", "pitched", (128, 1, 1), (x, out0), 64,
                             backend="amdgpu", dynamic_shared=0, dummy_params=0,
                             declared_arrays=(x, out0, out1))
    args = RUNNER.launch_args(variant, "")
    arrays = [args[i + 1] for i, arg in enumerate(args) if arg == "--array"]
    assert arrays == ["x:0x10000:2:64:in", "out0:0x100000:2:32:out", "out1:0x1016c8:2:32:out"]
    assert args.count("--param") == 2
