// Only the six safe, genuine compiler positives; no barrier mutants execute here.
#include "original_common.hpp"

int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "8", "requires exact module and eight patterns");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get actual device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load exact compiler module");
    const char *kernels[] = {"named_identity", "named_encoded_wait_uses_last_join",
        "named_reinitialized_identity", "named_subset_drop", "named_null_unjoin",
        "named_two_arrivals_one_wave"};
    const unsigned blocks[] = {64, 64, 64, 96, 64, 1};
    std::vector<Row> rows;
    for (const char *kernel : kernels) rows.push_back(Row{kernel});
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      for (size_t index = 0; index < rows.size(); ++index) {
        const size_t count = index == 2 ? 2 : 1;
        Buffer input(Type::Float, count), out(Type::Float, count, true);
        std::vector<double> expected;
        for (size_t i = 0; i < count; ++i) {
          input.set(i, pattern == 0 ? 0. : (int((pattern * 7 + i * 13) % 31) - 15) * .125);
          expected.push_back(input.get(i));
        }
        run(module, kernels[index], dim3(blocks[index]), {&input.pointer, &out.pointer},
            {&input, &out}, out, expected, rows[index], 0, 0);
      }
    }
    hip_check(hipModuleUnload(module), "unload exact module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":8,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,"
                  "\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "named barrier hardware validation failed: %s\n", error.what());
    return 1;
  }
}
