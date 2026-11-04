// Safe numerical controls only; CPU-only harmful variants are never selected.
// Assemble/link native-lifetime-boundaries.s and native-matrix-ordering.s
// unchanged. Build with the same host flags as matrix_features.cpp and pass
// those two code objects in that order. Keep device identity and run records
// outside the repository.
#include "original_common.hpp"

int main(int argc, char **argv) {
  try {
    require(argc == 3, "usage: mechanism_features lifetime.hsaco ordering.hsaco");
    for (const char *name : {"HSA_OVERRIDE_GFX_VERSION", "HSA_OVERRIDE_GFX_VERSION_0"})
      require(std::getenv(name) == nullptr, "architecture override is forbidden");
    hipDeviceProp_t properties{};
    hip_check(hipGetDeviceProperties(&properties, 0), "get selected device properties");
    require(std::string(properties.gcnArchName).substr(0, 7) == "gfx1250" &&
                properties.warpSize == 32, "a real gfx1250 wave32 device is required");
    hipModule_t lifetime{}, ordering{};
    hip_check(hipModuleLoad(&lifetime, argv[1]), "load lifetime assembly");
    hip_check(hipModuleLoad(&ordering, argv[2]), "load ordering assembly");
    Row total;
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      {
        Buffer input(Type::Float, 64), output(Type::Float, 64, true);
        input.fill(pattern, 5);
        std::vector<double> expected(64);
        for (unsigned i = 0; i < 64; ++i) expected[i] = input.get(i);
        run(lifetime, "async_source128_reuse", dim3(64),
            {&input.pointer, &output.pointer}, {&input, &output},
            output, expected, total, 0, 0);
      }
      Buffer input(Type::Half, 256), output(Type::Float, 256, true);
      input.fill(pattern, 3);
      std::vector<double> product(256);
      for (unsigned r = 0; r < 16; ++r) {
        double sum = 0;
        for (unsigned k = 0; k < 16; ++k) sum += input.get(r * 16 + k) * (k + 1);
        for (unsigned c = 0; c < 16; ++c) product[r * 16 + c] = sum;
      }
      run(ordering, "matrix_input_cross_wave", dim3(64),
          {&input.pointer, &output.pointer}, {&input, &output},
          output, product, total, 0, 0);
      Buffer metadata(Type::U32, 1), copied(Type::U32, 1, true);
      const uint32_t word = uint32_t(0xfedcba98u ^ (pattern * 0x19834765u));
      std::memcpy(metadata.before.data() + Buffer::guard, &word, sizeof(word));
      launch(ordering, "matrix_completion_keeps_metadata_separate", dim3(64),
             {&input.pointer, &output.pointer, &metadata.pointer, &copied.pointer},
             {&input, &output, &metadata, &copied}, total);
      compare("matrix_completion_keeps_metadata_separate", output, product, total, 0, 0);
      require(std::memcmp(metadata.before.data() + Buffer::guard,
                          copied.after.data() + Buffer::guard, sizeof(word)) == 0,
              "unrelated metadata raw word mismatch");
      ++total.outputs;
    }
    hip_check(hipModuleUnload(lifetime), "unload lifetime");
    hip_check(hipModuleUnload(ordering), "unload ordering");
    require(total.launches == 24 && total.outputs == 4616 &&
                total.unchanged_input_bytes == 10272 && total.unchanged_guard_bytes == 524288,
            "incomplete mechanism feature accounting");
    std::printf("PASS: %zu launches, %zu complete outputs, %zu input bytes, %zu guard bytes\n",
                total.launches, total.outputs, total.unchanged_input_bytes, total.unchanged_guard_bytes);
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "FAIL: %s\n", error.what());
    return 1;
  }
}
