"""Positive host-driver inventory; assembly names and driver argument order are exact."""
from dataclasses import dataclass


@dataclass(frozen=True)
class Driver:
    name: str
    source: str
    assemblies: tuple[str, ...] = ()
    assembly_directory: str | None = None
    expected_counts: tuple[int, int, int, int] | None = None


FIXTURES = "crates/volta_amdgpu_analysis/src/frontend/fixtures/"


def cdna_driver(name: str, *modules: str) -> Driver:
    return Driver(name, f"tests/gfx950/hardware/{name}.cpp",
                  tuple(FIXTURES + module + ".s" for module in modules))


CDNA_DRIVERS = (
    cdna_driver("native_copy_add", "clang22-copy-add", "clang22-mfma-f32"),
    cdna_driver("native_portable_f16", "portable-f16"),
    cdna_driver("native_portable_f8", "portable-f8"),
    cdna_driver("native_pipeline", "clang22-ids-3d", "clang22-pipelined-mfma-f32",
                "clang22-pipelined-mfma-f16"),
    cdna_driver("native_attention", "native-flash-attention"),
    cdna_driver("native_mfma_types", "clang22-cdna4-mfma-types"),
    cdna_driver("native_abi", "clang22-module-globals", "clang22-dynamic-lds",
                "clang22-grid-output", "clang22-mixed-byvalue"),
    cdna_driver("native_full_workloads", "native-full-gemm", "native-full-convolution"),
    cdna_driver("native_advanced_workloads", "native-mamba2-state",
                "native-forgetting-attention", "native-flash-sinkhorn", "native-sage-attention"),
    cdna_driver("native_scan_workloads", "native-mamba2-scan"),
    Driver("native_portable_matrix", "tests/gfx950/hardware/native_portable_matrix.cpp",
           assembly_directory="tests/gfx950/portable-matrix"),
)

FEATURE_DRIVERS = (
    Driver("matrix_features", "tests/gfx1250/full/hardware/matrix_features.cpp",
           tuple("tests/gfx1250/fixtures/native-matrix-" + name + ".s"
                 for name in ("layout", "numeric", "publication")),
           expected_counts=(120, 674056, 24576, 2162688)),
    Driver("mechanism_features", "tests/gfx1250/full/hardware/mechanism_features.cpp",
           ("tests/gfx1250/fixtures/native-lifetime-boundaries.s",
            "tests/gfx1250/fixtures/native-matrix-ordering.s"),
           expected_counts=(24, 4616, 10272, 524288)),
)

GFX1250_RUNNERS = (
    "original", "original_convolution", "original_matrix", "original_advanced",
    "exact_integer", "exact_f64", "exact_wave", "upstream_adapters",
    "unaligned_global", "named_barrier", "named_phases", "signal_counts",
)


def drivers(target: str) -> tuple[Driver, ...]:
    if target == "gfx942":
        return (Driver("compiler-corpus", "tests/gfx942/hardware/native.cpp",
                       assembly_directory="tests/gfx942/fixtures"),)
    if target == "gfx950":
        return CDNA_DRIVERS
    if target == "gfx1250":
        return FEATURE_DRIVERS
    raise ValueError("unsupported target: " + target)


def suite_names(target: str) -> tuple[str, ...]:
    nested = ("core", "portable", *GFX1250_RUNNERS) if target == "gfx1250" else ()
    return (*nested, *(driver.name for driver in drivers(target)), "address-launch-probes")


def validate_inventory(root, target: str) -> None:
    """A newly added host driver cannot silently disappear from the complete gate."""
    expected = {driver.source for driver in drivers(target)}
    if target == "gfx1250":
        expected.update(("tests/gfx1250/hardware/core.cpp", "tests/gfx1250/hardware/portable.cpp"))
        expected.update(f"tests/gfx1250/full/hardware/{name}.cpp" for name in GFX1250_RUNNERS)
    actual = {path.relative_to(root).as_posix()
              for directory in (root / f"tests/{target}/hardware",
                                root / f"tests/{target}/full/hardware")
              if directory.is_dir() for path in directory.glob("*.cpp")}
    if actual != expected:
        raise ValueError(f"{target}: host driver inventory mismatch; missing={sorted(expected-actual)}, "
                         f"unregistered={sorted(actual-expected)}")
