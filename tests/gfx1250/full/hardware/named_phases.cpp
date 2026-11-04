// Safe allocated-object phase controls; mismatched selectors never execute here.
#include "original_common.hpp"
int main(int argc, char **argv) {
  try {
    validate_reference_controls();
    if (argc == 2 && std::string(argv[1]) == "--cpu-only") return 0;
    require(argc == 3 && std::string(argv[2]) == "8", "requires exact module and eight patterns");
    hipDeviceProp_t device{};
    hip_check(hipGetDeviceProperties(&device, 0), "get device");
    const std::string architecture = device.gcnArchName;
    require(architecture.substr(0, architecture.find(':')) == "gfx1250" && device.warpSize == 32,
            "requires actual gfx1250 wave32");
    hipModule_t module{};
    hip_check(hipModuleLoad(&module, argv[1]), "load compiler module");
    const char *kernels[] = {"named_two_object_handshake", "named_independent_object_counts",
        "named_three_arrivals_expression", "named_selected_object_copy"};
    std::vector<Row> rows;
    for (const char *kernel : kernels) rows.push_back(Row{kernel});
    for (unsigned pattern = 0; pattern < 8; ++pattern) {
      for (size_t index = 0; index < rows.size(); ++index) {
        if (index == 1) {
          hipFunction_t function{};
          hip_check(hipModuleGetFunction(&function, module, kernels[index]), "get count control");
          hip_check(hipModuleLaunchKernel(function, 1, 1, 1, 64, 1, 1, 0, nullptr, nullptr, nullptr),
                    "launch count control");
          hip_check(hipDeviceSynchronize(), "complete count control");
          ++rows[index].launches;
          continue;
        }
        const size_t count = index == 0 ? 2 : index == 2 ? 3 : 1;
        Buffer input(Type::Float, count), out(Type::Float, count, true);
        std::vector<double> expected;
        for (size_t i = 0; i < count; ++i) {
          input.set(i, pattern == 0 ? 0. : (int((pattern * 7 + i * 13) % 31) - 15) * .125);
          expected.push_back(input.get(i));
        }
        if (index == 2) {
          expected[0] = (input.get(0) + input.get(1)) * input.get(2) - input.get(0);
          expected[1] = expected[2] = std::numeric_limits<double>::quiet_NaN();
        }
        uint32_t different = 0; // Flag1 is the CPU-only deliberate deadlock.
        std::vector<void *> arguments = {&input.pointer, &out.pointer};
        if (index == 3) arguments.push_back(&different);
        run(module, kernels[index], dim3(index == 2 ? 32 : 64), arguments,
            {&input, &out}, out, expected, rows[index], 0, 0);
      }
    }
    hip_check(hipModuleUnload(module), "unload module");
    std::printf("{\"status\":\"pass\",\"architecture\":\"gfx1250\",\"wave_size\":32,"
                "\"reference_controls\":\"pass\",\"patterns\":8,\"cases\":[");
    for (size_t i = 0; i < rows.size(); ++i) {
      const auto &r = rows[i];
      std::printf("%s{\"kernel\":\"%s\",\"outputs\":%zu,\"launches\":%zu,"
                  "\"unchanged_input_bytes\":%zu,\"unchanged_guard_bytes\":%zu,"
                  "\"unchanged_gap_bytes\":%zu,\"max_absolute_error\":%.12g}",
                  i ? "," : "", r.kernel.c_str(), r.outputs, r.launches,
                  r.unchanged_input_bytes, r.unchanged_guard_bytes, r.unchanged_gap_bytes, r.maximum);
    }
    std::puts("]}");
    return 0;
  } catch (const std::exception &error) {
    std::fprintf(stderr, "named phase hardware validation failed: %s\n", error.what());
    return 1;
  }
}
