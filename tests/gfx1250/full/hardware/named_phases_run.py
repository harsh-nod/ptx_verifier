#!/usr/bin/env python3
"""Safe allocated-object handshake/independent-count/expression controls."""
from original_run import Profile, main
KERNELS = ("named_two_object_handshake", "named_independent_object_counts",
           "named_three_arrivals_expression", "named_selected_object_copy")
PROFILE = Profile(
    contract=dict(zip(KERNELS, ((2, 8, 2), (0, 0, 0), (1, 12, 2), (1, 4, 2)))),
    modules=("named-phases",), assemblies=("portable-graph/native-named-phases.s",),
    driver="full/hardware/named_phases.cpp", runner="full/hardware/named_phases_run.py",
    files=("hardware/portable_run.py", "full/hardware/original_run.py",
           "full/hardware/original_common.hpp", "full/hardware/named_phases.cpp",
           "full/hardware/named_phases_run.py", "portable-graph/native-named-phases.ll",
           "portable-graph/native-named-phases.s", "portable-graph/named-phases-profile-evidence.json"),
    gaps=dict(zip(KERNELS, (0, 0, 8, 0))), patterns=8, minimum_patterns=8, maximum_patterns=8,
    scope="Four genuine allocated named-object positives: complete two-generation handshake, independent per-object counts and phases, exact three-arrival expression, same runtime object selector (flag0). Eight exact binary-fraction patterns and every payload/input/guard/gap checked. No missing-handshake, wrong-count or flag1 deadlock mutants execute on hardware. Other portable barrier/async/lifecycle rows require separate validation.",
)
if __name__ == "__main__":
    main(PROFILE)
