// Load the exact assembled integer probes, checking every output and guard byte.
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>
#include <vector>
#include "probes.hpp"

static void check(bool condition, const char *message) {
  if (!condition) throw std::runtime_error(message);
}
static void hip(hipError_t error) {
  if (error != hipSuccess) throw std::runtime_error(hipGetErrorString(error));
}

struct Buffer {
  static constexpr size_t guard = 4096;
  std::vector<uint8_t> before, after;
  uint8_t *allocation{};
  void *pointer{};
  explicit Buffer(size_t bytes) : before(bytes + guard * 2, 0xa5), after(before.size()) {
    hip(hipMalloc(&allocation, before.size()));
    pointer = allocation + guard;
  }
  Buffer(const Buffer &) = delete;
  Buffer &operator=(const Buffer &) = delete;
  ~Buffer() { if (allocation) (void)hipFree(allocation); }
  void upload() { hip(hipMemcpy(allocation, before.data(), before.size(), hipMemcpyHostToDevice)); }
  void download() { hip(hipMemcpy(after.data(), allocation, after.size(), hipMemcpyDeviceToHost)); }
  void guards() const {
    for (size_t i = 0; i < guard; ++i)
      check(before[i] == after[i] && before[before.size()-1-i] == after[after.size()-1-i],
            "allocation guard changed");
  }
};

int main(int argc, char **argv) {
  try {
    check(argc == 3, "usage: probes TARGET MODULE_DIRECTORY");
    check(std::getenv("HSA_OVERRIDE_GFX_VERSION") == nullptr, "architecture override is forbidden");
    int count = 0;
    hip(hipGetDeviceCount(&count));
    check(count == 1, "select exactly one device through HIP_VISIBLE_DEVICES");
    hipDeviceProp_t properties{};
    hip(hipGetDeviceProperties(&properties, 0));
    std::string target = properties.gcnArchName;
    target = target.substr(0, target.find(':'));
    check(target == argv[1], "selected device architecture differs from requested target");
    check(properties.warpSize == (target == "gfx1250" ? 32 : 64), "unexpected wave size");
    size_t cases = 0, outputs = 0;
    for (const auto &probe : probes) {
      Buffer input(128), out(probe.expected.size() * sizeof(uint32_t));
      for (size_t i = 0; i < 128; ++i) input.before[Buffer::guard+i] = uint8_t(i);
      // Complement each required result so an unwritten zero cannot pass.
      for (size_t i = 0; i < probe.expected.size(); ++i) {
        const uint32_t sentinel = ~probe.expected[i];
        std::memcpy(out.before.data()+Buffer::guard+i*4, &sentinel, 4);
      }
      input.upload();
      out.upload();
      hipModule_t module{};
      const std::string path = std::string(argv[2]) + "/" + probe.name + ".hsaco";
      hip(hipModuleLoad(&module, path.c_str()));
      hipFunction_t kernel{};
      hip(hipModuleGetFunction(&kernel, module, probe.name));
      void *scalar_args[] = {&input.pointer, &out.pointer};
      void *launch_args[] = {&out.pointer};
      hip(hipModuleLaunchKernel(kernel, probe.nx, probe.ny, probe.nz,
                               probe.scalar ? 1 : 64, 1, 1, 0, nullptr,
                               probe.scalar ? scalar_args : launch_args, nullptr));
      hip(hipDeviceSynchronize());
      input.download();
      out.download();
      check(input.before == input.after, "input changed");
      input.guards();
      out.guards();
      for (size_t i = 0; i < probe.expected.size(); ++i) {
        uint32_t actual{};
        std::memcpy(&actual, out.after.data()+Buffer::guard+i*4, 4);
        if (actual != probe.expected[i]) {
          std::fprintf(stderr, "%s output[%zu]: expected%u observed%u\n",
                       probe.name, i, probe.expected[i], actual);
          throw std::runtime_error("complete hardware output mismatch");
        }
      }
      outputs += probe.expected.size();
      ++cases;
      hip(hipModuleUnload(module));
    }
    std::printf("{\"status\":\"pass\",\"target\":\"%s\",\"cases\":%zu,\"outputs\":%zu}\n",
                target.c_str(), cases, outputs);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "probe validation failed: %s\n", error.what());
    return 1;
  }
}
