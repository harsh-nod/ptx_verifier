// Execute the exact checked-in assembly after llvm-mc + ld.lld, independently of
// the symbolic interpreter. This program checks values; it does not prove races absent.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

static void check(hipError_t error, const char *operation) {
  if (error != hipSuccess) {
    std::fprintf(stderr, "%s: %s\n", operation, hipGetErrorString(error));
    std::exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc != 2 && argc != 3) { std::fprintf(stderr, "usage: %s copy-add.hsaco [mfma.hsaco]\n", argv[0]); return 2; }
  hipDeviceProp_t properties{};
  check(hipGetDeviceProperties(&properties, 0), "device properties");
  if (std::string(properties.gcnArchName).find("gfx950") != 0) {
    std::fprintf(stderr, "expected gfx950, found %s\n", properties.gcnArchName); return 2;
  }
  hipModule_t module{};
  check(hipModuleLoad(&module, argv[1]), "load checked-in native assembly");
  hipFunction_t copy{}, add{};
  check(hipModuleGetFunction(&copy, module, "copy"), "get copy");
  check(hipModuleGetFunction(&add, module, "add"), "get add");
  unsigned cases = 0;
  for (unsigned block : {1u, 63u, 64u, 65u, 128u, 256u}) {
    for (unsigned n : {1u, 65u, 257u}) {
      std::vector<float> x(n), y(n), out(n, -9999.f);
      for (unsigned i = 0; i < n; ++i) { x[i] = static_cast<int>(i % 37) - 18.f; y[i] = (i % 11) * .25f; }
      float *dx{}, *dy{}, *dout{};
      check(hipMalloc(&dx, n * sizeof(float)), "allocate x");
      check(hipMalloc(&dy, n * sizeof(float)), "allocate y");
      check(hipMalloc(&dout, n * sizeof(float)), "allocate out");
      check(hipMemcpy(dx, x.data(), n * sizeof(float), hipMemcpyHostToDevice), "upload x");
      check(hipMemcpy(dy, y.data(), n * sizeof(float), hipMemcpyHostToDevice), "upload y");
      for (bool addition : {false, true}) {
        check(hipMemcpy(dout, out.data(), n * sizeof(float), hipMemcpyHostToDevice), "initialize output");
        void *copy_arguments[] = {&dx, &dout, &n};
        void *add_arguments[] = {&dx, &dy, &dout, &n};
        check(hipModuleLaunchKernel(addition ? add : copy, (n + block - 1) / block, 1, 1,
              block, 1, 1, 0, nullptr, addition ? add_arguments : copy_arguments, nullptr), "launch");
        check(hipDeviceSynchronize(), "synchronize");
        std::vector<float> actual(n);
        check(hipMemcpy(actual.data(), dout, n * sizeof(float), hipMemcpyDeviceToHost), "download");
        for (unsigned i = 0; i < n; ++i) {
          float expected = addition ? x[i] + y[i] : x[i];
          if (actual[i] != expected) {
            std::fprintf(stderr, "%s block=%u n=%u i=%u expected=%g actual=%g\n",
                addition ? "add" : "copy", block, n, i, expected, actual[i]); return 1;
          }
        }
        ++cases;
      }
      check(hipFree(dx), "free x"); check(hipFree(dy), "free y"); check(hipFree(dout), "free out");
    }
  }
  check(hipModuleUnload(module), "unload");
  std::printf("PASS exact-native-assembly copy/add: %u cases, device=%s arch=%s\n",
      cases, properties.name, properties.gcnArchName);
  if (argc == 3) {
    check(hipModuleLoad(&module, argv[2]), "load native MFMA assembly");
    hipFunction_t mfma{};
    check(hipModuleGetFunction(&mfma, module, "mfma_f32"), "get MFMA");
    float *da{}, *db{}, *dout{};
    check(hipMalloc(&da, 64 * sizeof(float)), "allocate MFMA A");
    check(hipMalloc(&db, 64 * sizeof(float)), "allocate MFMA B");
    check(hipMalloc(&dout, 256 * sizeof(float)), "allocate MFMA output");
    for (unsigned pattern = 0; pattern < 129; ++pattern) {
      std::vector<float> a(64), b(64), out(256);
      for (unsigned i = 0; i < 64; ++i) {
        a[i] = pattern < 64 ? float(i == pattern) : float(int(i % 19) - 9);
        b[i] = pattern >= 64 && pattern < 128 ? float(i == pattern - 64) : float(int(i % 23) - 11);
      }
      check(hipMemcpy(da, a.data(), 64 * sizeof(float), hipMemcpyHostToDevice), "upload MFMA A");
      check(hipMemcpy(db, b.data(), 64 * sizeof(float), hipMemcpyHostToDevice), "upload MFMA B");
      check(hipMemset(dout, 0xff, 256 * sizeof(float)), "initialize MFMA output sentinel");
      void *arguments[] = {&da, &db, &dout};
      check(hipModuleLaunchKernel(mfma, 1, 1, 1, 64, 1, 1, 0, nullptr, arguments, nullptr), "launch MFMA");
      check(hipDeviceSynchronize(), "synchronize MFMA");
      check(hipMemcpy(out.data(), dout, 256 * sizeof(float), hipMemcpyDeviceToHost), "download MFMA");
      // CDNA4 16x16x4 f32 layout, expressed independently as matrix coordinates:
      // A[k*16+row], B[k*16+column], D lane=16*(row/4)+column, register=row%4.
      for (unsigned row = 0; row < 16; ++row) for (unsigned column = 0; column < 16; ++column) {
        float expected = 0;
        for (unsigned k = 0; k < 4; ++k) expected += a[k * 16 + row] * b[k * 16 + column];
        unsigned index = 4 * (16 * (row / 4) + column) + row % 4;
        if (out[index] != expected) {
          std::fprintf(stderr, "MFMA basis=%u row=%u column=%u expected=%g actual=%g\n",
              pattern, row, column, expected, out[index]); return 1;
        }
      }
    }
    check(hipFree(da), "free MFMA A"); check(hipFree(db), "free MFMA B"); check(hipFree(dout), "free MFMA output");
    check(hipModuleUnload(module), "unload MFMA");
    std::printf("PASS exact-native-assembly MFMA 16x16x4 f32: 129 patterns, 33024 output checks\n");
  }
  return 0;
}
