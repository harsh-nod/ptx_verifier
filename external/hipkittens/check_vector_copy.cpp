// Check the exact extracted assembly on hardware, without recompiling its kernel.
#include <hip/hip_runtime.h>
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

static void check(hipError_t result, const char *operation) {
    if (result != hipSuccess) {
        std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(result));
        std::exit(1);
    }
}

int main(int argc, char **argv) {
    if (argc != 2) {
        std::fprintf(stderr, "usage: %s vector_copy.hsaco\n", argv[0]);
        return 2;
    }
    hipDeviceProp_t device{};
    check(hipGetDeviceProperties(&device, 0), "device");
    if (std::string(device.gcnArchName).find("gfx950") != 0) return 2;
    hipModule_t module{};
    hipFunction_t kernel{};
    check(hipModuleLoad(&module, argv[1]), "load exact extracted assembly");
    check(hipModuleGetFunction(&kernel, module, "hk_vector_copy"), "find kernel");
    float *input{}, *output{};
    check(hipMalloc(&input, 256 * sizeof(float)), "allocate input");
    check(hipMalloc(&output, 256 * sizeof(float)), "allocate output");
    // The compiled layout check pins the descriptor to six 64-bit words.
    std::array<uint64_t, 6> x{reinterpret_cast<uint64_t>(input), 1, 1, 1, 256, 0};
    std::array<uint64_t, 6> out{reinterpret_cast<uint64_t>(output), 1, 1, 1, 256, 0};
    unsigned checked = 0;
    for (unsigned pattern = 0; pattern < 257; ++pattern) {
        std::array<float, 256> expected{}, actual{};
        for (unsigned i = 0; i < 256; ++i)
            expected[i] = pattern < 256 ? float(i == pattern) : float(int(i % 37) - 18) * .25f;
        check(hipMemcpy(input, expected.data(), sizeof(expected), hipMemcpyHostToDevice), "upload");
        check(hipMemset(output, 0xff, sizeof(actual)), "sentinel");
        void *arguments[] = {x.data(), out.data()};
        check(hipModuleLaunchKernel(kernel, 1, 1, 1, 64, 1, 1, 0, nullptr, arguments, nullptr), "launch");
        check(hipDeviceSynchronize(), "synchronize");
        check(hipMemcpy(actual.data(), output, sizeof(actual), hipMemcpyDeviceToHost), "download");
        for (unsigned i = 0; i < 256; ++i) {
            if (actual[i] != expected[i]) {
                std::fprintf(stderr, "pattern=%u index=%u expected=%g actual=%g\n", pattern, i, expected[i], actual[i]);
                return 1;
            }
            ++checked;
        }
    }
    check(hipFree(input), "free input");
    check(hipFree(output), "free output");
    check(hipModuleUnload(module), "unload");
    std::printf("PASS HipKittens vector_copy exact assembly: 257 patterns, %u output checks, device=%s arch=%s\n", checked, device.name, device.gcnArchName);
}
