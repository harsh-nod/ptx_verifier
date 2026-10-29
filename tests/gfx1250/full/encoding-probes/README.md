# gfx1250 true16 destination probes

These single-active-workitem kernels distinguish preservation of the old destination upper half from clearing it. Each low-half arithmetic operand carries a different upper half. The host loads the exact assembled compiler output with the HIP Module API, checks the actual architecture/wave size, and checks untouched guard words.

The six-operation receipt covers fmac/add/mul with both e32 and e64 encodings on mi400 device 2. It establishes only those six observed behaviors. The expected low halves are 7, 5, and 6 as F16. The upper half remains the destination's `0x3555`.

Build the HIP source with ROCm 7.2's clang for gfx1250 using `--offload-device-only -O2 -S`; assemble the committed `.s` with `llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx1250 --filetype=obj`, link with `ld.lld -shared`, and pass that code object to the ordinary C++ HIP Module API host driver. The compiler is the same ROCm toolchain recorded in the adjacent full fixture provenance. Source and code-object hashes are retained in the receipt.
