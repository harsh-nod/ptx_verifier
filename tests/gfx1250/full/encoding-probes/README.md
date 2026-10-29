# gfx1250 true16 destination controls

These single-active-workitem kernels exercise the selected interpreter's narrow
destination behavior. Inputs use distinct upper halves so the host driver can
check every low and high half and untouched guards. They are test expectations,
not published device observations.

Build the HIP source with the public ROCm LLVM toolchain for gfx1250 using
`--offload-device-only -O2 -S`; assemble the committed `.s` with
`llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx1250 --filetype=obj`, link with
`ld.lld -shared`, and pass that code object to the ordinary C++ HIP Module API
host driver. The compiler is recorded in the adjacent full fixture provenance.

The controls cover e32/e64 fmac, add, mul, sub, max_num, min_num and F32-to-F16
conversion. Hardware results and machine-specific metadata are local artifacts
and are not retained. Reproduce observations for the revision and device under
review; these sources alone do not establish hardware behavior.
