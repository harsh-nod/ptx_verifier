#include <hip/hip_runtime.h>
#include <array>
#include <cstdio>
#include <stdexcept>
#include <string>

static void check(hipError_t error) {
  if (error != hipSuccess) throw std::runtime_error(hipGetErrorString(error));
}
int main(int argc, char **argv) {
  try {
    if (argc != 2) throw std::runtime_error("expected exact-assembly code object");
    hipDeviceProp_t device{};
    check(hipGetDeviceProperties(&device, 0));
    const std::string architecture = device.gcnArchName;
    if (architecture.substr(0, architecture.find(':')) != "gfx1250" || device.warpSize != 32)
      throw std::runtime_error("requires actual wave32 gfx1250");
    hipModule_t module{}; hipFunction_t function{};
    check(hipModuleLoad(&module, argv[1]));
    check(hipModuleGetFunction(&function, module, "halfword_policy"));
    std::array<unsigned, 8> words;
    words.fill(0xdeadbeef);
    unsigned *device_words{};
    check(hipMalloc(&device_words, sizeof(words)));
    check(hipMemcpy(device_words, words.data(), sizeof(words), hipMemcpyHostToDevice));
    void *args[] = {&device_words};
    check(hipModuleLaunchKernel(function, 1, 1, 1, 32, 1, 1, 0, nullptr, args, nullptr));
    check(hipDeviceSynchronize());
    check(hipMemcpy(words.data(), device_words, sizeof(words), hipMemcpyDeviceToHost));
    check(hipFree(device_words)); check(hipModuleUnload(module));
    if (words[6] != 0xdeadbeef || words[7] != 0xdeadbeef) throw std::runtime_error("guard modified");
    std::printf("arch=%s wave=%d launches=1 guarded_outputs=6\n", device.gcnArchName, device.warpSize);
    for (size_t i = 0; i < 6; ++i) std::printf("output[%zu]=0x%08x high16=0x%04x low16=0x%04x\n", i, words[i], words[i] >> 16, words[i] & 65535);
    return 0;
  } catch (const std::exception &error) { std::fprintf(stderr, "%s\n", error.what()); return 1; }
}
