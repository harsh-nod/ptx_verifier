// Physical checks of the exact pinned module-globals, dynamic-LDS and grid
// assembly. This driver contains no GPU kernels. Assemble each fixture with
// llvm-mc --triple=amdgcn-amd-amdhsa --mcpu=gfx950 -filetype=obj, then link
// with ld.lld -shared. Build: hipcc -O2 -std=c++17 -Wall -Wextra native_abi.cpp
// Run: a.out module-globals.hsaco dynamic-lds.hsaco grid-output.hsaco
// [mixed-byvalue.hsaco]
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <hip/hip_runtime.h>
#include <stdexcept>
#include <string>
#include <vector>

static void check(hipError_t e, const char *what) {
  if (e != hipSuccess)
    throw std::runtime_error(std::string(what) + ": " + hipGetErrorString(e));
}
struct Module {
  hipModule_t value{};
  explicit Module(const char *path) {
    check(hipModuleLoad(&value, path), "load exact assembly");
  }
  ~Module() { if (value) (void)hipModuleUnload(value); }
  Module(const Module &) = delete;
  hipFunction_t function(const char *name) const {
    hipFunction_t result{};
    check(hipModuleGetFunction(&result, value, name), name);
    return result;
  }
  void bind(const char *name, int32_t integer) const {
    hipDeviceptr_t address{};
    size_t bytes{};
    check(hipModuleGetGlobal(&address, &bytes, value, name), name);
    if (bytes != sizeof(integer)) throw std::runtime_error("global size");
    check(hipMemcpy(reinterpret_cast<void *>(address), &integer, bytes,
                    hipMemcpyHostToDevice), "bind global");
  }
};
template<class T> struct Buffer {
  T *device{};
  std::vector<T> host;
  explicit Buffer(size_t n) : host(n) {
    check(hipMalloc(&device, n * sizeof(T)), "allocate");
  }
  ~Buffer() { if (device) (void)hipFree(device); }
  Buffer(const Buffer &) = delete;
  void upload() {
    check(hipMemcpy(device, host.data(), host.size() * sizeof(T),
                    hipMemcpyHostToDevice), "upload");
  }
  void download() {
    check(hipMemcpy(host.data(), device, host.size() * sizeof(T),
                    hipMemcpyDeviceToHost), "download");
  }
};
constexpr size_t Guard = 32;
constexpr uint32_t Marker = 0xa55ac33c;
template<class T> struct Output {
  Buffer<T> storage;
  T *pointer;
  explicit Output(size_t n) : storage(n + 2 * Guard),
                             pointer(storage.device + Guard) {}
  void reset() {
    static_assert(sizeof(T) == sizeof(Marker));
    for (T &item : storage.host) std::memcpy(&item, &Marker, sizeof(item));
    storage.upload();
  }
  void verify(const std::vector<T> &expected, const char *name, unsigned pattern) {
    if (storage.host.size() != expected.size() + 2 * Guard)
      throw std::runtime_error("output checker size");
    storage.download();
    for (size_t i = 0; i < storage.host.size(); ++i) {
      if (i < Guard || i >= Guard + expected.size()) {
        uint32_t bits{};
        std::memcpy(&bits, &storage.host[i], sizeof(bits));
        if (bits != Marker) throw std::runtime_error("output guard changed");
      } else if (storage.host[i] != expected[i - Guard]) {
        throw std::runtime_error(std::string(name) + " mismatch index " +
                                 std::to_string(i - Guard));
      }
    }
    std::printf("PASS %s pattern=%u outputs=%zu guards=%zu exact=true\n",
                name, pattern, expected.size(), 2 * Guard);
  }
};
static void launch(hipFunction_t fn, dim3 grid, dim3 block, unsigned shared,
                   void **args) {
  check(hipModuleLaunchKernel(fn, grid.x, grid.y, grid.z, block.x, block.y,
                              block.z, shared, nullptr, args, nullptr), "launch");
  check(hipDeviceSynchronize(), "synchronize");
}
int main(int argc, char **argv) {
  try {
    if (argc != 4 && argc != 5)
      throw std::runtime_error("expected three or four code objects");
    check(hipSetDevice(0), "select device");
    hipDeviceProp_t prop{};
    check(hipGetDeviceProperties(&prop, 0), "device properties");
    std::printf("DEVICE %s %s\n", prop.name, prop.gcnArchName);
    if (std::string(prop.gcnArchName).find("gfx950") != 0)
      throw std::runtime_error("requires gfx950");
    {
      Module module(argv[1]);
      Output<int32_t> out(4);
      auto fn = module.function("module_globals");
      const int32_t values[3][2] = {{0, 3}, {17, 5}, {-31, 11}};
      const int32_t table[4] = {2, 3, 5, 7};
      for (unsigned p = 0; p < 3; ++p) {
        // Pattern0 exercises the object initializers without host overrides.
        if (p) { module.bind("bound_global", values[p][0]);
                 module.bind("global_bias", values[p][1]); }
        out.reset();
        void *args[] = {&out.pointer};
        launch(fn, dim3(1), dim3(4), 0, args);
        std::vector<int32_t> expected(4);
        for (unsigned i = 0; i < 4; ++i)
          expected[i] = values[p][0] + values[p][1] + table[i];
        out.verify(expected, "module_globals", p);
      }
    }
    {
      Module module(argv[2]);
      Buffer<float> x(4);
      Output<float> out(2);
      auto fn = module.function("dynamic_lds");
      const float patterns[3][4] = {{1, 2, 4, 8}, {-3.5f, 7.25f, 2, -1},
                                   {0.125f, -16, 0.5f, 32}};
      for (unsigned p = 0; p < 3; ++p) {
        std::copy(patterns[p], patterns[p] + 4, x.host.begin());
        x.upload(); out.reset();
        void *args[] = {&x.device, &out.pointer};
        launch(fn, dim3(1), dim3(2), 8, args);
        out.verify({patterns[p][1] + patterns[p][3],
                    patterns[p][0] + patterns[p][2]}, "dynamic_lds", p);
      }
    }
    {
      Module module(argv[3]);
      Output<uint32_t> out(2 * 3 * 4 * 9);
      std::vector<uint32_t> expected(2 * 3 * 4 * 9);
      for (unsigned z = 0; z < 4; ++z)
        for (unsigned y = 0; y < 3; ++y)
          for (unsigned x = 0; x < 2; ++x) {
            size_t row = (x + 2 * (y + 3 * z)) * 9;
            const uint32_t fields[9] = {2, 3, 4, x, y, z, 4, 3, 2};
            std::copy(fields, fields + 9, expected.begin() + row);
          }
      for (unsigned p = 0; p < 3; ++p) {
        out.reset();
        void *args[] = {&out.pointer};
        launch(module.function("grid_output"), dim3(2, 3, 4), dim3(4, 3, 2), 0,
               args);
        out.verify(expected, "grid_output", p);
      }
    }
    if (argc == 5) {
      Module module(argv[4]);
      Output<float> out(4);
      const float alphas[3] = {1.25f, -128.5f, 0};
      const double betas[3] = {0.5, 2, -3};
      const int16_t shorts[3] = {-3, 32767, -32768};
      const uint8_t bytes[3] = {250, 0, 255};
      for (unsigned p = 0; p < 3; ++p) {
        float alpha = alphas[p]; double beta = betas[p];
        int32_t n = 4; int16_t s = shorts[p]; uint8_t b = bytes[p];
        out.reset();
        void *args[] = {&out.pointer, &alpha, &beta, &n, &s, &b};
        launch(module.function("mixed_byvalue"), dim3(1), dim3(4), 0, args);
        float expected = alpha + float(beta) + float(s) + float(b);
        out.verify(std::vector<float>(4, expected), "mixed_byvalue", p);
      }
    }
    std::printf("SUMMARY launches=%u outputs=%u guards=%u exact=true PASS\n",
                argc == 5 ? 12 : 9, argc == 5 ? 678 : 666,
                argc == 5 ? 768 : 576);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "FAIL %s\n", error.what());
    return 1;
  }
}
